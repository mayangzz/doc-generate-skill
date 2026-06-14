#!/usr/bin/env bash
# setup.sh — 首次启动配置脚本。
# 干两件事:① 逐项检查前置依赖与权限 ② 收集密钥/落点 token 写入 config.local.env(gitignore,不上传)。
# 幂等:已存在 config.local.env 会问是否重配。可用环境变量预填(非交互)。
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
CONF="$HERE/config.local.env"
ok(){ printf "  \033[32m✓\033[0m %s\n" "$1"; }
no(){ printf "  \033[31m✗\033[0m %s\n" "$1"; }
warn(){ printf "  \033[33m!\033[0m %s\n" "$1"; }
ask(){ # ask VAR "提示" "默认"
  local v d; eval v="\${$1:-}"; d="${3:-}"
  if [ -n "$v" ]; then echo "$v"; return; fi          # 环境变量预填 → 非交互
  read -r -p "    $2${d:+ [$d]}: " a </dev/tty || true
  echo "${a:-$d}"
}

echo "== doc-generate-skill 配置 =="
echo
echo "[1/3] 检查前置依赖与权限"

MISS=0
# lark-cli:建 wiki 节点 / 读写 docx / 插图 / 发消息都靠它,且需以 user 身份授权
if command -v lark-cli >/dev/null 2>&1; then
  ok "lark-cli 已安装"
  if lark-cli wiki spaces get_node --params '{"token":"x"}' >/dev/null 2>&1 || true; then
    ok "lark-cli 可调用(请确保已 lark-cli auth login,且授权 wiki/docx/drive/im 相关 scope)"
  fi
else
  no "lark-cli 未安装 —— 文档发布依赖它。装好后再跑本脚本。"; MISS=1
fi
# python3:脚本解析 JSON / 组装内容用
command -v python3 >/dev/null 2>&1 && ok "python3 已安装" || { no "python3 未安装"; MISS=1; }
# rsvg-convert:把 taste 风格 SVG 配图转 PNG(brew install librsvg)
command -v rsvg-convert >/dev/null 2>&1 && ok "rsvg-convert 已安装(配图 SVG→PNG)" || warn "rsvg-convert 未装(配图功能需要,可 'brew install librsvg';不发图可忽略)"
# 可选数据图
python3 -c "import matplotlib,PIL" >/dev/null 2>&1 && ok "matplotlib/Pillow 可用(数据图)" || warn "matplotlib/Pillow 未装(仅画数据图才需要)"
# taste 视觉:CSS 已随包内置,无需额外下载 taste-skill
[ -f "$HERE/assets/taste-light.css" ] && ok "taste 浅色高级 CSS 已内置(assets/taste-light.css)" || warn "缺 assets/taste-light.css"

[ "$MISS" = 1 ] && { echo; echo "有必需依赖缺失,补齐后重跑。"; exit 1; }

echo
echo "[2/3] 收集配置(写入 config.local.env,不会上传 git)"
if [ -f "$CONF" ]; then
  read -r -p "  config.local.env 已存在,重新配置?(y/N): " RE </dev/tty || true
  [ "${RE:-N}" = y ] || { ok "保留现有配置,不改动"; echo; echo "完成。"; exit 0; }
fi

echo "  飞书知识库落点(必填):"
FEISHU_WIKI_SPACE=$(ask FEISHU_WIKI_SPACE "wiki 空间 id")
FEISHU_PARENT_SHARE=$(ask FEISHU_PARENT_SHARE "分享/学习类 父节点 token")
FEISHU_ROOT_AUTO=$(ask FEISHU_ROOT_AUTO "日常自动生成 根节点 token")
echo "  HTML 在线发布(可选,直接回车跳过则 --html 不可用):"
UPLOAD_SSH_KEY=$(ask UPLOAD_SSH_KEY "SSH 私钥绝对路径(~/.ssh 下,chmod600)")
UPLOAD_USER_DIR=$(ask UPLOAD_USER_DIR "服务器个人子目录名")
UPLOAD_SERVER=$(ask UPLOAD_SERVER "服务器 user@host")
UPLOAD_BASE_DIR=$(ask UPLOAD_BASE_DIR "服务器根目录" "/var/www/htmls")
UPLOAD_BASE_URL=$(ask UPLOAD_BASE_URL "URL 前缀,如 http://1.2.3.4")
echo "  发飞书消息(可选):"
NOTIFY_URL=$(ask NOTIFY_URL "通知 webhook(留空跳过)")

umask 077
cat > "$CONF" <<EOF
FEISHU_WIKI_SPACE=$FEISHU_WIKI_SPACE
FEISHU_PARENT_SHARE=$FEISHU_PARENT_SHARE
FEISHU_ROOT_AUTO=$FEISHU_ROOT_AUTO
UPLOAD_SSH_KEY=$UPLOAD_SSH_KEY
UPLOAD_USER_DIR=$UPLOAD_USER_DIR
UPLOAD_SERVER=$UPLOAD_SERVER
UPLOAD_BASE_DIR=$UPLOAD_BASE_DIR
UPLOAD_BASE_URL=$UPLOAD_BASE_URL
NOTIFY_URL=$NOTIFY_URL
EOF
chmod 600 "$CONF"
ok "已写入 $CONF (权限 600)"

echo
echo "[3/3] 校验"
[ -n "$UPLOAD_SSH_KEY" ] && { [ -f "$UPLOAD_SSH_KEY" ] && ok "SSH 私钥存在" || warn "SSH 私钥路径不存在: $UPLOAD_SSH_KEY"; }
[ -n "$FEISHU_WIKI_SPACE" ] && [ -n "$FEISHU_PARENT_SHARE" ] && [ -n "$FEISHU_ROOT_AUTO" ] && ok "飞书落点已填" || warn "飞书落点未填全,文档发布会失败"
echo
echo "完成。用法见 README.md / SKILL.md。试跑:"
echo "  scripts/publish-doc.sh --kind share --title \"测试\" --md some.md"
