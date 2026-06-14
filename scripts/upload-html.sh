#!/usr/bin/env bash
# upload-html.sh — 把本地 HTML 上传到 SSH 服务器的个人子目录,输出可在浏览器打开的链接。
# 配置从 ../config.local.env 读(UPLOAD_* 字段)。也可改成真 S3:把 scp 段换成 aws s3 cp。
#
# 用法: upload-html.sh [--name 自定义名] <html文件>
# 文件名规则: <名字>_<YYYYMMDD-HHMMSS>.html(时间戳防覆盖)
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
CONF="$HERE/../config.local.env"
[ -f "$CONF" ] || { echo "method=upload-html error: 缺 config.local.env,先跑 ./setup.sh" >&2; exit 2; }
# shellcheck disable=SC1090
source "$CONF"
: "${UPLOAD_SSH_KEY:?缺 UPLOAD_SSH_KEY}"; : "${UPLOAD_USER_DIR:?缺 UPLOAD_USER_DIR}"
: "${UPLOAD_SERVER:?缺 UPLOAD_SERVER}"; : "${UPLOAD_BASE_DIR:?缺 UPLOAD_BASE_DIR}"; : "${UPLOAD_BASE_URL:?缺 UPLOAD_BASE_URL}"

NAME=""
while [ $# -gt 0 ]; do case "$1" in
  --name) NAME="$2"; shift 2;;
  *) FILE="$1"; shift;;
esac; done
[ -n "${FILE:-}" ] && [ -f "$FILE" ] || { echo "method=upload-html error: 需要 <html文件>" >&2; exit 1; }

base="${NAME:-$(basename "$FILE" .html)}"
base=$(echo "$base" | tr ' /' '--')
remote="${base}_$(date '+%Y%m%d-%H%M%S').html"

ssh -i "$UPLOAD_SSH_KEY" -o StrictHostKeyChecking=no "$UPLOAD_SERVER" "mkdir -p $UPLOAD_BASE_DIR/$UPLOAD_USER_DIR" >/dev/null 2>&1
scp -i "$UPLOAD_SSH_KEY" -o StrictHostKeyChecking=no "$FILE" "$UPLOAD_SERVER:$UPLOAD_BASE_DIR/$UPLOAD_USER_DIR/$remote" >/dev/null
echo "$UPLOAD_BASE_URL/$UPLOAD_USER_DIR/$remote"
