/**
 * 离线确定性验证脚本（与设备无关的逻辑验证）。
 *
 * 本文件是 entry/src/main/ets/common/BrownianSim.ets 的逐行等值移植
 * （ArkTS 与 JS 同为 IEEE 754 双精度语义，Math.imul / Math.round 位级一致），
 * 用于在无真机环境下验证契约 3 的核心逻辑：
 *   同一组 (dot_count, dot_radius, seed) 运行两次 → 每帧状态与 CHECKSUM 完全一致。
 *
 * 用法：node determinism-check.mjs
 */
'use strict';

const DOMAIN_W = 360;
const DOMAIN_H = 720;
const DT = 1 / 60;
const V0 = 60;
const ACCEL = 400;
const VMAX = 120;
const QUANT = 1024;

class BrownianSim {
  constructor() {
    this.count = 0;
    this.radius = 0;
    this.seed = 0;
    this.frame = 0;
    this.xs = [];
    this.ys = [];
    this.vxs = [];
    this.vys = [];
    this.rngState = 0;
  }

  reset(count, radius, seed) {
    this.count = count;
    this.radius = radius;
    this.seed = seed >>> 0;
    this.rngState = (this.seed ^ 0x9E3779B9) >>> 0;
    this.frame = 0;
    this.xs = new Array(count);
    this.ys = new Array(count);
    this.vxs = new Array(count);
    this.vys = new Array(count);
    const r = radius;
    const spanW = DOMAIN_W - 2 * r;
    const spanH = DOMAIN_H - 2 * r;
    for (let i = 0; i < count; i++) {
      this.xs[i] = r + this.next() * spanW;
      this.ys[i] = r + this.next() * spanH;
      this.vxs[i] = (this.next() * 2 - 1) * V0;
      this.vys[i] = (this.next() * 2 - 1) * V0;
    }
  }

  step() {
    const dt = DT;
    const r = this.radius;
    const maxX = DOMAIN_W - r;
    const maxY = DOMAIN_H - r;
    const kick = ACCEL * dt;
    for (let i = 0; i < this.count; i++) {
      let vx = this.vxs[i] + (this.next() * 2 - 1) * kick;
      let vy = this.vys[i] + (this.next() * 2 - 1) * kick;
      if (vx > VMAX) vx = VMAX; else if (vx < -VMAX) vx = -VMAX;
      if (vy > VMAX) vy = VMAX; else if (vy < -VMAX) vy = -VMAX;
      let x = this.xs[i] + vx * dt;
      let y = this.ys[i] + vy * dt;
      if (x < r) { x = 2 * r - x; vx = -vx; }
      else if (x > maxX) { x = 2 * maxX - x; vx = -vx; }
      if (y < r) { y = 2 * r - y; vy = -vy; }
      else if (y > maxY) { y = 2 * maxY - y; vy = -vy; }
      if (x < r) x = r; else if (x > maxX) x = maxX;
      if (y < r) y = r; else if (y > maxY) y = maxY;
      this.vxs[i] = vx;
      this.vys[i] = vy;
      this.xs[i] = x;
      this.ys[i] = y;
    }
    this.frame++;
  }

  checksumHex() {
    let h = 2166136261 >>> 0;
    for (let i = 0; i < this.count; i++) {
      h = Math.imul(h ^ (Math.round(this.xs[i] * QUANT) & 0x7FFFFFFF), 16777619) >>> 0;
      h = Math.imul(h ^ (Math.round(this.ys[i] * QUANT) & 0x7FFFFFFF), 16777619) >>> 0;
    }
    let hex = (h >>> 0).toString(16);
    while (hex.length < 8) hex = '0' + hex;
    return hex;
  }

  next() {
    this.rngState = (Math.imul(this.rngState, 1103515245) + 12345) >>> 0;
    return (this.rngState & 0x7FFFFFFF) / 0x80000000;
  }
}

/** 模拟一次启动：reset 后推进 frames 帧，返回沿途 CHECKSUM 记录 */
function runLaunch(dotCount, dotRadius, seed, frames) {
  const sim = new BrownianSim();
  sim.reset(dotCount, dotRadius, seed);
  const logs = [];
  for (let f = 0; f < frames; f++) {
    sim.step();
    if (sim.frame % 300 === 0) {
      logs.push(`CHECKSUM frame=${sim.frame} hash=${sim.checksumHex()} dots=${dotCount} radius=${dotRadius} seed=${seed}`);
    }
  }
  return logs;
}

const FRAMES = 900;
let failures = 0;

function checkEqual(label, a, b) {
  const same = JSON.stringify(a) === JSON.stringify(b);
  console.log(`[${same ? 'PASS' : 'FAIL'}] ${label}`);
  if (!same) {
    failures++;
    console.log('  run A:', JSON.stringify(a));
    console.log('  run B:', JSON.stringify(b));
  }
}

// 1) 同参数两次“启动”：轨迹哈希必须逐条一致（默认参数与两组扫描参数）
for (const [c, r, s] of [[500, 4, 20240521], [100, 4, 20240521], [5000, 2, 20240521]]) {
  const runA = runLaunch(c, r, s, FRAMES);
  const runB = runLaunch(c, r, s, FRAMES);
  checkEqual(`same params (dots=${c}, r=${r}, seed=${s}) x2 launches -> identical checksums`, runA, runB);
  console.log(`       sample: ${runA[0]}  ...  ${runA[runA.length - 1]}`);
}

// 2) 反向对照：不同参数必须产生不同哈希（防止校验恒真）
function checkDiffer(label, a, b) {
  const differ = a !== b;
  console.log(`[${differ ? 'PASS' : 'FAIL'}] ${label}`);
  if (!differ) failures++;
}

const base = runLaunch(500, 4, 20240521, FRAMES);
const diffSeed = runLaunch(500, 4, 20240522, FRAMES);
const diffCount = runLaunch(501, 4, 20240521, FRAMES);
const diffRadius = runLaunch(500, 5, 20240521, FRAMES);
checkDiffer(`different seed   -> different checksum (${base[0]} vs ${diffSeed[0]})`, base[0], diffSeed[0]);
checkDiffer(`different count  -> different checksum (${base[0]} vs ${diffCount[0]})`, base[0], diffCount[0]);
checkDiffer(`different radius -> different checksum (${base[0]} vs ${diffRadius[0]})`, base[0], diffRadius[0]);

console.log(failures === 0 ? '\nALL CHECKS PASSED' : `\n${failures} CHECK(S) FAILED`);
process.exit(failures === 0 ? 0 : 1);
