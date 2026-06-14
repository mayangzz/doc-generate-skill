# Changelog

本项目遵循[语义化版本](https://semver.org/lang/zh-CN/)，格式参考 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)。

## [0.1.1] - 2026-06-14

### 变更
- **内容写法升级（最重要）**：Loop 3 公式从「概括+例子+用途」扩成 **「描述痛点 → 概括 → 具体例子 → 实际用途」四段式**，明确「痛点 + 真实例子」为主线、「误区」只作补充。
- 新增 **文档大师约束 · 痛点驱动 + 篇幅给足**：先讲痛点再上例子最后给定义；篇幅宁长勿短，把四件套讲透、给用户留删减空间，禁止一上来就每点一句话。
- 四遍 Loop 编号从 1/2/4/5（迭代残留）理顺为连续 **1/2/3/4**，配图同步重画。
- SKILL.md 配图目录默认值去掉个人路径，改通用占位。

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

[0.1.1]: https://github.com/mayangzz/doc-generate-skill/releases/tag/v0.1.1
[0.1.0]: https://github.com/mayangzz/doc-generate-skill/releases/tag/v0.1.0
