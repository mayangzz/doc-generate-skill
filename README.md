# doc-generate-skill

一个把 AI 生成内容**自动整理成高质量文档并归档到飞书知识库**的工作流 skill。

不只是"存个文件":它约束 AI 用**四遍 Loop 精修**把内容写到"能当权威参考"的水准,自动在复杂处**配浅色高级风格的图**,需要时生成**精致排版的 HTML 在线页**,最后**一条命令**建飞书文档、灌内容(图随文走)、出链接、可选发消息。

> 配套一篇给 AI 读的规范 [`SKILL.md`](SKILL.md)(文档大师约束 + 四遍 Loop + 视觉语言),和一个确定性编排脚本 [`scripts/publish-doc.sh`](scripts/publish-doc.sh)。

## 能干嘛

- **四遍 Loop 精修**:初稿 → 强化/精简/定结构 → 充实例子与用途(一句话+例子+用途,不晦涩)→ 整体审校。每遍守"审美 + 格式"两条不变量。
- **飞书归档**:分享/学习类 → 知识库父节点;日常自动生成 → 按 月/日 目录(`Agent Y-M-D` 文件夹)。每篇新建。
- **浅色高级配图**:手写 SVG → `rsvg-convert` 转 PNG,暖白底 + 祖母绿 accent,用 `@@IMG:路径|说明@@` 内联到对应章节。
- **HTML 在线页**:`assets/taste-light.css` 一套现成浅色高级样式;`--html` 自动上传拿链接。

## 前置依赖与权限(`setup.sh` 会逐项检查)

| 项 | 必需 | 用途 / 怎么准备 |
|---|---|---|
| **lark-cli** | 必需 | 建 wiki 节点、读写 docx、插图、发消息都靠它。需 `lark-cli auth login` 以 **user** 身份授权,scope 覆盖 wiki 节点创建 / docx 读写 / drive 媒体上传 / im 发消息。 |
| **飞书 wiki 落点** | 必需 | 一个 wiki 空间 + 两个父节点(分享类 `FEISHU_PARENT_SHARE`、日常类 `FEISHU_ROOT_AUTO`)。在飞书里建好,把 token 填进配置。 |
| **python3** | 必需 | 脚本解析 JSON / 顺序灌内容。 |
| **rsvg-convert** | 配图需要 | SVG→PNG。`brew install librsvg`。 |
| matplotlib / Pillow | 可选 | 仅画数据图表时需要。 |
| **HTML 上传通道** | `--html` 需要 | 一台 SSH 可达的服务器(或自行改成 S3)+ 私钥 + 个人目录。不配则 `--html` 不可用,纯 md 文档不受影响。 |
| 通知 webhook | 可选 | `--notify` 把链接 POST 过去(如本地通知服务)。 |

> taste 浅色高级视觉**无需额外下载**——CSS 已内置在 `assets/taste-light.css`,配图配色常量写在 `SKILL.md`。

## 安装 / 配置

```bash
git clone https://github.com/mayangzz/doc-generate-skill.git
cd doc-generate-skill
./setup.sh        # 检查依赖 + 引导填写,生成 config.local.env(已 gitignore,含密钥/token,不会上传)
```

`config.local.env` 由 `setup.sh` 生成,模板见 [`config.example.env`](config.example.env)。**所有私有值只在这里,绝不进 git。**

让 AI 工具(如 Claude Code)用这个 skill:把本目录链接/复制到它的 skills 目录,或直接让它读 `SKILL.md`。

## 用法

```bash
# 分享/学习类 → 知识库
scripts/publish-doc.sh --kind share --title "大模型核心概念" --md doc.md [--html doc.html] [--notify]

# 日常自动生成 → AI 自动生成 / 当月 / Agent Y-M-D
scripts/publish-doc.sh --kind daily --md daily.md [--notify]
```

输出 `doc_url=`(飞书文档链接),用了 `--html` 还会有 `html_url=`。

md 里用单独一行 `@@IMG:/abs/path.png|图说明@@` 标记配图,脚本会自上而下顺序构建,把图落在那一节。

## 目录结构

```
doc-generate-skill/
├── README.md
├── SKILL.md              # 给 AI 读的规范(文档大师约束 + 四遍 Loop + 视觉语言)
├── setup.sh              # 首次启动:检查依赖 + 写 config.local.env
├── config.example.env    # 配置模板(committed)
├── .gitignore            # 忽略 config.local.env
├── scripts/
│   ├── publish-doc.sh    # 编排:建文档→灌内容(含内联图)→出链接→可选通知(读 config)
│   └── upload-html.sh    # HTML 上传(scp 到服务器;可改 S3)
└── assets/
    └── taste-light.css   # 浅色高级 HTML 样式
```

## 安全

- 密钥、私有 token 只在 `config.local.env`(权限 600,gitignored)。
- 仓库里不含任何真实 token / 私钥;`config.example.env` 全是占位。
