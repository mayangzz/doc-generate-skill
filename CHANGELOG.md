# Changelog

本项目遵循[语义化版本](https://semver.org/lang/zh-CN/)，格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)。

## [0.1.0] - 2026-06-14

首个公开版本。

### 新增
- **四遍 Loop 精修工作流** —— 初稿 → 强化/精简/定结构 → 充实例子与用途 → 整体审校；每遍守「审美 + 格式」两条不变量。
- **文档大师约束** —— 零草稿痕迹、真实多级层次、配图随文走、不写干巴一句话、可读性优先。
- **编排脚本 `publish-doc.sh`** —— 输入 md（可选 html）→ 上传拿在线链接 → 飞书知识库建新文档 → 按 `@@IMG` 顺序灌内容（含内联图）→ 出链接 → 可选发飞书消息。`--kind share`（知识库）/ `--kind daily`（按月/日目录）。
- **HTML 上传脚本 `upload-html.sh`** —— scp 上传到个人目录，输出可打开链接（可改 S3）。
- **首次启动脚本 `setup.sh`** —— 逐项检查前置依赖（lark-cli / python3 / rsvg-convert / matplotlib / css），交互收集落点 token 与密钥，写入 `config.local.env`（权限 600，gitignored）。
- **浅色高级视觉** —— 内置 `taste-light.css`，配图配色常量写在 `SKILL.md`。
- 配置全部外置到 `config.local.env`，仓库零敏感信息，`config.example.env` 为占位模板。

[0.1.0]: https://github.com/mayangzz/doc-generate-skill/releases/tag/v0.1.0
