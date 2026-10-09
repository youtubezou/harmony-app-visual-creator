#!/bin/bash
# =============================================================================
# VfxBlurBench batch runner (macOS / Linux, requires hdc in PATH)
#
# Launches the app once per blur radius via:
#   hdc shell aa start -b <bundle> -a EntryAbility --ps blurRadius <r>
# waits SAMPLE_SECONDS, then samples RenderService FPS with hidumper and
# appends one CSV row per radius.
#
# Usage:
#   ./tools/run_blur_bench.sh                     # default radii 0..100
#   RADII="0 20 40" SAMPLE_SECONDS=8 ./tools/run_blur_bench.sh
#   OUT=result.csv ./tools/run_blur_bench.sh
# =============================================================================
set -u

BUNDLE="${BUNDLE:-com.example.vfxblurbench}"
ABILITY="${ABILITY:-EntryAbility}"
RADII="${RADII:-0 10 20 30 40 50 60 70 80 90 100}"
SAMPLE_SECONDS="${SAMPLE_SECONDS:-5}"
OUT="${OUT:-blur_bench_result.csv}"

echo "radius,fps_raw" > "$OUT"
echo "bundle=$BUNDLE ability=$ABILITY sample=${SAMPLE_SECONDS}s out=$OUT"

for r in $RADII; do
  echo "---- blurRadius=$r ----"
  hdc shell aa force-stop "$BUNDLE" >/dev/null 2>&1
  hdc shell aa start -b "$BUNDLE" -a "$ABILITY" --ps blurRadius "$r" >/dev/null
  sleep "$SAMPLE_SECONDS"
  # RenderService FPS snapshot (device-dependent format; raw text is kept in CSV).
  fps_raw=$(hdc shell "hidumper -s RenderService -a fps" 2>/dev/null | tr -d '\r' | tr '\n' ' ' | tr ',' ';')
  echo "radius=$r fps=$fps_raw"
  echo "$r,\"$fps_raw\"" >> "$OUT"
done

echo "done -> $OUT"
