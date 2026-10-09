#!/usr/bin/env bash
# 刷新归档：按 references/api-docs/manifest.txt 从 OpenHarmony docs master 重新拉取
# 用法：bash scripts/refresh-api-docs.sh
set -u
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$SKILL_DIR/references/api-docs"
BASE="https://gitee.com/openharmony/docs/raw/master/zh-cn"
ok=0; fail=0
while read -r p; do
  [ -z "$p" ] && continue
  # 目标路径推导：与归档脚本一致
  case "$p" in
    application-dev/ui/*)                 sub=guides; name=$(basename "$p") ;;
    application-dev/quick-start/*)        sub=guides; name=$(basename "$p") ;;
    application-dev/tools/*)              sub=tools;  name=$(basename "$p") ;;
    application-dev/reference/apis-arkui/arkui-ts/*) sub=api; name=$(basename "$p") ;;
    application-dev/reference/apis-arkui/*)          sub=api; name=$(basename "$p") ;;
    application-dev/reference/apis-arkgraphics2d/*)  sub=api; name=$(basename "$p") ;;
    *) echo "SKIP: $p"; continue ;;
  esac
  for attempt in 1 2 3; do
    if curl -sSL --max-time 60 --fail -o "$DEST/$sub/$name" "$BASE/$p" 2>/dev/null \
       && [ -s "$DEST/$sub/$name" ] && ! head -c 20 "$DEST/$sub/$name" | grep -q '<a href'; then
      ok=$((ok+1)); break
    fi
    [ $attempt -eq 3 ] && { fail=$((fail+1)); echo "FAIL: $p"; }
    sleep 2
  done
done < "$DEST/manifest.txt"
echo "refresh done: ok=$ok fail=$fail"
echo "刷新后请同步更新 INDEX.md 顶部的归档日期"
