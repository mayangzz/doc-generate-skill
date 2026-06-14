#!/usr/bin/env bash
# publish-doc.sh — 文档发布工作流(确定性核心)。
# 输入 md(可选 html)→(html?→ 上传拿在线链接)→ 飞书知识库建新文档 → 顺序灌内容(含内联图)
#   → 输出飞书文档链接 →(可选)发飞书消息。
# 落点 token、密钥全部从 ../config.local.env 读,脚本内不写死任何私有值。
#
# 用法:
#   publish-doc.sh --kind share --title "标题" --md x.md [--html x.html] [--notify]
#   publish-doc.sh --kind daily [--title "..."]  --md x.md [--html x.html] [--notify]
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
CONF="$HERE/../config.local.env"
[ -f "$CONF" ] || { echo "method=publish-doc error: 缺 config.local.env,先跑 ./setup.sh" >&2; exit 2; }
# shellcheck disable=SC1090
source "$CONF"
: "${FEISHU_WIKI_SPACE:?缺 FEISHU_WIKI_SPACE}"; : "${FEISHU_PARENT_SHARE:?缺 FEISHU_PARENT_SHARE}"; : "${FEISHU_ROOT_AUTO:?缺 FEISHU_ROOT_AUTO}"
SPACE="$FEISHU_WIKI_SPACE"; UPLOAD_SH="$HERE/upload-html.sh"; SELF="publish-doc"

KIND="share"; TITLE=""; MD=""; HTML=""; NOTIFY=0
while [ $# -gt 0 ]; do case "$1" in
  --kind) KIND="$2"; shift 2;; --title) TITLE="$2"; shift 2;;
  --md) MD="$2"; shift 2;; --html) HTML="$2"; shift 2;;
  --notify) NOTIFY=1; shift;;
  *) echo "method=$SELF unknown arg: $1" >&2; exit 1;;
esac; done
[ -n "$MD" ] && [ -f "$MD" ] || { echo "method=$SELF error: --md <file> required" >&2; exit 1; }

list_children() {
  lark-cli api GET "/open-apis/wiki/v2/spaces/$SPACE/nodes" --params "{\"parent_node_token\":\"$1\",\"page_size\":50}" \
    | python3 -c 'import json,sys;[print(i["title"]+"\t"+i["node_token"]) for i in json.load(sys.stdin).get("data",{}).get("items",[])]'
}
create_node() {
  lark-cli api POST "/open-apis/wiki/v2/spaces/$SPACE/nodes" \
    --data "{\"obj_type\":\"docx\",\"node_type\":\"origin\",\"parent_node_token\":\"$1\",\"title\":\"$2\"}" \
    | python3 -c 'import json,sys;n=json.load(sys.stdin)["data"]["node"];print(n["url"]+"\t"+n["obj_token"]+"\t"+n["node_token"])'
}
ensure_child() {
  local tok; tok=$(list_children "$1" | awk -F'\t' -v t="$2" '$1==t{print $2; exit}')
  [ -z "$tok" ] && tok=$(create_node "$1" "$2" | cut -f3); echo "$tok"
}

# 1. 父节点 + 标题
if [ "$KIND" = "daily" ]; then
  Y=$(date +%Y); M=$((10#$(date +%m))); D=$((10#$(date +%d)))
  MONTH_TOK=$(ensure_child "$FEISHU_ROOT_AUTO" "$(date +%Y-%m)")
  PARENT=$(ensure_child "$MONTH_TOK" "Agent ${Y}-${M}-${D}")
  [ -n "$TITLE" ] || TITLE="文档"
  case "$TITLE" in *[0-9]-[0-9]*) : ;; *) TITLE="[$(date '+%m-%d %H:%M')] $TITLE";; esac
else
  PARENT="$FEISHU_PARENT_SHARE"
  [ -n "$TITLE" ] || { echo "method=$SELF error: share 模式需 --title" >&2; exit 1; }
fi

# 2. html?→ 上传拿在线链接
HTML_URL=""
if [ -n "$HTML" ]; then
  [ -f "$HTML" ] || { echo "method=$SELF error: --html not found: $HTML" >&2; exit 1; }
  HTML_URL=$(bash "$UPLOAD_SH" "$HTML" 2>/dev/null | grep -oE 'https?://[^[:space:]]+' | tail -1)
fi

# 3. 建文档
read -r DOC_URL OBJ_TOKEN NODE_TOKEN < <(create_node "$PARENT" "$TITLE")

# 4. 灌内容:html 链接置顶,正文按 @@IMG 顺序构建(文字 append + 图 media-insert)
[ -n "$HTML_URL" ] && lark-cli docs +update --doc "$DOC_URL" --mode append --markdown "在线页面：$HTML_URL" >/dev/null
DOC_URL="$DOC_URL" OBJ_TOKEN="$OBJ_TOKEN" python3 - "$MD" <<'PY'
import os, re, subprocess, sys
md=open(sys.argv[1],encoding="utf-8").read(); doc_url=os.environ["DOC_URL"]; obj=os.environ["OBJ_TOKEN"]
def append_text(t):
    t=t.strip("\n")
    if t.strip(): subprocess.run(["lark-cli","docs","+update","--doc",doc_url,"--mode","append","--markdown",t],check=True,stdout=subprocess.DEVNULL)
def insert_img(path,cap):
    d,fn=os.path.split(os.path.abspath(path)); args=["lark-cli","docs","+media-insert","--doc",obj,"--file",fn,"--align","center"]
    if cap: args+=["--caption",cap]
    subprocess.run(args,check=True,stdout=subprocess.DEVNULL,cwd=d)
buf=[]
for line in md.splitlines():
    m=re.match(r'^@@IMG:(.+?)(?:\|(.*))?@@\s*$',line)
    if m: append_text("\n".join(buf)); buf=[]; insert_img(m.group(1).strip(),(m.group(2) or "").strip())
    else: buf.append(line)
append_text("\n".join(buf))
PY

# 5. 输出
echo "method=$SELF ok title=$TITLE kind=$KIND"
echo "doc_url=$DOC_URL"
[ -n "$HTML_URL" ] && echo "html_url=$HTML_URL"

# 6. 可选发飞书消息
if [ "$NOTIFY" = "1" ] && [ -n "${NOTIFY_URL:-}" ]; then
  body="$TITLE"$'\n'"$DOC_URL"; [ -n "$HTML_URL" ] && body="$body"$'\n'"在线页面 $HTML_URL"
  curl -sf -m 5 -X POST "$NOTIFY_URL" -H 'Content-Type: application/json' \
    -d "$(python3 -c 'import json,sys;print(json.dumps({"title":"📄 文档已生成","body":sys.argv[1]}))' "$body")" \
    >/dev/null 2>&1 && echo "notify=sent" || echo "notify=failed(ignore)"
fi
