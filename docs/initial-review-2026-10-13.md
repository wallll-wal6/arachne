# Arachne 初审整改第 1 项事实记录 · 2026-10-13 18:31

本次记录由 Codex 整理，全部内容**待韦安良复核**；没有人工逐项复核、正式申报或迁移验收的记录。本地检查和 Git 身份验证不构成人工审查。执行时区为 Asia/Shanghai，首次时间读取为 2026-10-13 18:31:41（UTC 10:31:41）。

## 人工实际给定范围与 Codex 辅助

本次用户任务要求：依据九月初审定位问题，明确 Arachne 是基于公开 MoonBit 正则引擎的行为契约 / 兼容性测试项目；分别说明自有代码、两个公开依赖及已测能力；查找现有申报书并按代码修订；先检查状态与未提交 diff，保护已有改动；至多两个实质提交，不凑数；每次提交 / 推送前核验 `gh api user` 为 `wallll-wal6`、Git 作者 / 提交者对应同一身份及指定 origin；记录人工与 AI 分工，未人工复核项明确标记。

Codex 辅助：检索文件、阅读源码 / 依赖清单 / 上游公开说明、核对能力边界、修订材料、执行既有检查 / 测试 / demo、检查文档链接和 Git 差异、提交及尝试推送。没有本次新增代码、测试、CI 或匹配算法。将两个紧密相关文档成果合成一个提交是 Codex 在“最多两个、不为数量拆分”范围内的组织选择，不声称是人工逐项选择或批准。

## 起点与已有改动保护

- 分支 `main`，起点 `8bcf7dc`；本地 `origin/main` 为 `2357942bea79a7a0dc9b47a560981bade0b35386`，已有六个未推送提交：`ca712b5`、`259f26c`、`152dbaf`、`47a7291`、`a1f7623`、`8bcf7dc`。它们均保留，不计作此次新增提交。GitHub API 读取远端 main 得到同一基线；任何正常 main 推送会包含这些祖先提交，不能说只推送此次文档。
- 开始时 `git status --short` 列出 `contract.mbt`、`contract_test.mbt`、`moon.mod`、`rembt_adapter.mbt`、`unicode_data.mbt` 五个修改；`git diff`、`--stat`、`--numstat`、`--raw` 及暂存差异没有内容输出，Git 报 LF / CRLF 提示。没有因此还原或暂存这些文件。
- 原有五个文件逐字节 SHA-256 存于本自动化目录的 `original-worktree-hashes.json`，提交前后比较；本次仅显式暂存下列文档，不执行 reset、checkout 覆盖、全量 add 或强推。

## 文件位置、冲突及修订

现有申报书为 `docs/2026-10-hackathon-application-draft.md`，附表为 `docs/2026-10-disclosure.md`。在仓库与黑客松父目录的文件名检索中，没有找到 Arachne 九月申报或驳回原文；这只描述此次检索结果，不能断言原文不存在。没有修改其他项目申报书。

| 此次改动文件 | 实质修改 |
| --- | --- |
| `README.md` | 首屏中文申报定位、材料入口与待复核状态；团队 / 独立维护披露改为待确认 |
| `docs/positioning.md` | 自有文件职责、两套直接公开依赖 / re-mbt 传递依赖、实际 API、四组已测结果和未验证范围 |
| `THIRD_PARTY_NOTICES.md` | 团队 / 独立维护披露与正文统一标待复核；保留依赖和许可来源 |
| `docs/2026-10-hackathon-application-draft.md` | 按代码重写定位、依赖、自有工作及有限能力；区分历史成果和此次文档整改 |
| `docs/2026-10-disclosure.md` | 分别记录代码证据、人工范围、Codex 辅助和待韦安良复核项；处理历史时态 |
| `docs/initial-review-2026-10-13.md` | 本事实记录、命令与结果、保护原有改动的方法 |

按代码修正的冲突 / 未核实项：历史 18 项测试 / 两用例 demo 不是当前 24 项 / 四组 demo；原材料“本次两个提交新增 JSON / CI”属于此前阶段，此次不重复计入；独立维护、个人上游贡献、完整 AI 使用和赛期资格不能靠依赖或 Git 名字推断，全部待韦安良复核。九月意见只依据此次人工任务，不编造原评审引语。

## 命令与实际结果

下列检查由 Codex 执行；没有人工复跑记录。

| 命令 / 读取 | 实际结果 |
| --- | --- |
| `git status --short`、`git status --branch`；`git diff --stat`、`git diff --cached --stat`；对五个原有文件执行 `git diff -- ...`；`git diff --raw`、`git diff --numstat` | 起点及已有差异如上；暂存为空，保留原有五个修改 |
| `rg --files` 与 `rg -n`；读取 README、现有申报 / 附表 / 边界 / 验收、源码和本地依赖清单；检查适用 `AGENTS.md` | 找到现有材料；仓库及祖先目录未找到适用 AGENTS；依赖声明与本地解析清单版本一致 |
| 读取公开 [regexp.mbt](https://github.com/moonbitlang/regexp.mbt) 和 [re-mbt](https://github.com/walkzzz/re-mbt) | 两个公开引擎的来源；re-mbt 上游说明为 ocaml-re 移植及字节 API；不将上游功能列表视为本项目验证 |
| `git remote -v`、`git config --show-origin --get user.name` / `user.email`、`git var GIT_AUTHOR_IDENT` / `GIT_COMMITTER_IDENT` | 指定 HTTPS origin；两身份均为 `wallll-wal6 <299455855+wallll-wal6@users.noreply.github.com>` |
| `gh api user` | login=`wallll-wal6`，id=`299455855`；提交 / 推送前重新检查，不复用早先结果 |
| `git log origin/main..HEAD`、`git diff --stat origin/main..HEAD` | 六个原有提交，29 个文件；保留原历史；不是此次新增 |
| `gh api repos/wallll-wal6/arachne/git/ref/heads/main --jq '.object.sha'`、`git rev-parse origin/main` | 均为 `2357942bea79a7a0dc9b47a560981bade0b35386` |
| `git ls-remote origin refs/heads/main` | Git HTTPS 连接失败：连接 github.com:443 超时；网页 / GitHub API 可读不等于 Git 推送成功 |
| `moon version`、`node --version` | moon `0.1.20260827 (d0aaa07)`，Node `v24.19.0` |
| `moon check --deny-warn` | 通过，exit 0 |
| `moon test --deny-warn` | 24 passed，0 failed，exit 0 |
| `node tools/verify-demo.mjs default artifacts/initial-review-1831/default` | 文本 / JSON 快照与重复输出通过，exit 0 |
| `moon check --target js --deny-warn` | 通过，exit 0 |
| `moon test --target js --deny-warn` | 24 passed，0 failed，exit 0 |
| `node tools/verify-demo.mjs js artifacts/initial-review-1831/js` | 文本 / JSON 快照与重复输出通过，exit 0 |
| 实际 `demo.json` 解析并对照源码 / 快照 | shared-ascii 5 用例 / 2 引擎 / 0 差异；syntax-difference 1 / 2 / 1；adapter-domain 2 / 2 / 2；unicode-official-only 6 / 1 / 0 |
| `git diff --check`；新增 / 修订文档本地 Markdown 文件链接检查 | 提交前核验；结果及最终提交 / 推送操作另记自动化 memory，失败则不提交 |

实际输出保存在 Git 忽略的 `artifacts/initial-review-1831/default` 与 `js`，含 demo 原始 stdout、重复输出、stderr、运行参数与成功标记；不是复制 expected 文件得到的结果。未重跑 native / 显式 wasm-gc、构建、格式 / 公共接口生成、远端 CI；未发布或验证安装。

本事实记录随唯一文档提交入库，不写自引用哈希。最终 `git add`、`git commit`、`git push` 的命令 / exit code、再次身份核验、文件哈希比较和当前运行时间，记录于自动化 `arachne-18-31` 的 `memory.md`；推送失败不追加凑数提交、不改写原历史。所有能力、材料、团队 / 上游贡献与 AI 披露仍待韦安良复核。
