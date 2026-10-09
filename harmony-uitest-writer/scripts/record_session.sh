#!/usr/bin/env bash
# record_session.sh — HarmonyOS 操作录制采集封装（方案 C：结构化事件流）
#
# 用法:
#   bash record_session.sh <输出目录> [--no-layout]
#
# 流程:
#   1. 检查 hdc 与设备连接
#   2. 清理旧录制产物
#   3. 后台启动 `hdc shell uitest uiRecord record -l`（每步操作存布局快照）
#   4. 提示用户在设备上操作（同时建议系统录屏 + 开发者选项「显示指针位置」）
#   5. 用户回车结束 → 停止录制 → 拉取 record.csv 与 layout_*.json
#
# 注意: 官方要求每步操作后等待命令行输出识别结果，再进行下一步操作。

set -euo pipefail

OUT_DIR="${1:-}"
NO_LAYOUT="${2:-}"

if [[ -z "$OUT_DIR" ]]; then
  echo "用法: bash record_session.sh <输出目录> [--no-layout]" >&2
  exit 1
fi

if ! command -v hdc >/dev/null 2>&1; then
  echo "错误: 未找到 hdc。请确认已安装 HarmonyOS SDK 工具链并把 hdc 加入 PATH。" >&2
  exit 1
fi

if ! hdc list targets 2>/dev/null | grep -q .; then
  echo "错误: 没有已连接的 HarmonyOS 设备（hdc list targets 为空）。" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

LAYOUT_FLAG="-l"
if [[ "$NO_LAYOUT" == "--no-layout" ]]; then
  LAYOUT_FLAG=""
fi

# 记录启动时间戳，便于事后识别本次产生的 layout 文件
SESSION_TS="$(date +%s)"
echo "==> 清理设备上旧的录制产物（仅 /data/local/tmp/ 下 record.csv / layout_*.json）"
hdc shell "rm -f /data/local/tmp/record.csv" || true

echo "==> 启动 uiRecord（事件+控件信息记录到 /data/local/tmp/record.csv）"
echo "    操作提示："
echo "      1) 建议在开发者选项打开「显示指针位置」，并同时用系统录屏记录画面；"
echo "      2) 文本输入不会被 uiRecord 记录，请记下输入内容（或依赖录屏复核）；"
echo "      3) 每步操作后，等下方终端打印出识别结果再进行下一步。"
echo

# 后台运行录制进程，事件输出到本地日志
hdc shell uitest uiRecord record $LAYOUT_FLAG > "$OUT_DIR/uirecord_console.log" 2>&1 &
RECORD_PID=$!

echo "==> 录制中（PID $RECORD_PID）。请在设备上执行被测操作……"
read -r -p "    操作完成后按回车结束录制: " _

kill "$RECORD_PID" 2>/dev/null || true
sleep 1

echo "==> 拉取 record.csv"
hdc file recv /data/local/tmp/record.csv "$OUT_DIR/record.csv"

if [[ -n "$LAYOUT_FLAG" ]]; then
  echo "==> 拉取本次录制的布局快照 layout_*.json"
  # layout 文件名带录制启动时间戳；全量拉取后按 mtime 过滤的意义不大，直接全拉再提示
  LAYOUT_FILES="$(hdc shell ls /data/local/tmp/ | grep '^layout_' || true)"
  if [[ -n "$LAYOUT_FILES" ]]; then
    while IFS= read -r f; do
      hdc file recv "/data/local/tmp/$f" "$OUT_DIR/$f" >/dev/null
    done <<< "$LAYOUT_FILES"
    echo "    已拉取 $(echo "$LAYOUT_FILES" | wc -l | tr -d ' ') 个布局快照"
  else
    echo "    未发现布局快照（设备可能低于 API 20 或未启用 -l）"
  fi
fi

echo
echo "==> 采集完成，产物位于 $OUT_DIR ："
ls -la "$OUT_DIR"
echo
echo "下一步："
echo "  python3 scripts/parse_uirecord.py --record $OUT_DIR/record.csv --layouts $OUT_DIR --out $OUT_DIR/timeline.json"
