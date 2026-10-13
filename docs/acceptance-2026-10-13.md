# Arachne 工程验收记录 · 2026-10-13

本记录由 Codex 辅助执行检查并整理。人工主导范围选择、允许的行为差异和
最终验收判断；本地工程检查通过不表示人工验收、远端 CI 或发布已完成。

前面的记录保留 17:51 阶段的实际结果（24 项测试、当时未推送 / 未运行远端）。
当前结果在末尾“第 4 项：21:32 实际核验”；不要将历史表格当作最新状态。

## 实际基线与本次交付

检查起点为 `47a7291`：已有 JSON v1 API、四组真实后端迁移夹具、
文本/JSON 快照、22 项测试和 CI。没有重复增加解析器、匹配器或 JSON API。
五个原有工作区修改（`contract.mbt`、`contract_test.mbt`、`moon.mod`、
`rembt_adapter.mbt`、`unicode_data.mbt`）与 HEAD 无内容差异，未暂存到本次提交。

1. `a1f7623`，`docs: define JSON v1 compatibility and reproducible usage`：
   完善 JSON 字段、兼容演进、源码复现入口、项目限制和人工验收边界。
2. `ci: verify repeatable reports across targets and record acceptance`：
   完善 CI 的 default/JS/native 矩阵、构建和严格警告检查；保存实际输出并
   验证重复运行；增加两项 JSON 回归测试；更新本记录与申报材料状态。

提交前本地 `user.name` 为 `wallll-wal6`，`user.email` 为
`299455855+wallll-wal6@users.noreply.github.com`；提交仅使用该身份，不推送。
本记录第二项提交哈希可用 `git log -2 --format=fuller` 获取。

## 环境与复现

本地 Windows、PowerShell 7.6.5；`moon 0.1.20260827 (d0aaa07)`、
`moonc v0.10.11+6ff76a5f9`、`moonrun 0.1.20260827`；Node.js `v24.19.0`。
直接依赖声明为 `moonbitlang/regexp@0.3.5`、`walkzzz/re-mbt@0.1.0`。
隔离副本的 `moon update` 还报告缓存中的传递依赖 `moonbitlang/x@0.4.48`。

从仓库根目录执行：

```sh
moon update
moon check --deny-warn
moon test --deny-warn
moon build --deny-warn
node tools/verify-demo.mjs default artifacts/default
moon check --target js --deny-warn
moon test --target js --deny-warn
moon build --target js --deny-warn
node tools/verify-demo.mjs js artifacts/js
moon info
moon fmt
git diff --check
```

在干净 checkout 中，`moon info`、`moon fmt` 后还要执行
`git diff --exit-code`，确认接口和格式没有漂移。已有开发修改时应审查差异，
不能将自己的未提交修改误判为生成器漂移。本次用 `git checkout-index`
导出暂存版本到临时目录，在隔离副本重新执行 default/JS 全套检查；
`moon info` 和 `moon fmt` 后按换行归一化比较全部已跟踪内容，没有变化。

## 本次观察结果

| 检查 | 实际结果 | 证据范围 |
| --- | --- | --- |
| `moon update` | 通过 | 工作区和隔离暂存副本均成功解析依赖 |
| default 的 check/test/build，均带 `--deny-warn` | 通过 | 隔离副本 24 项测试，24 通过、0 失败 |
| JS 的 check/test/build，均带 `--deny-warn` | 通过 | 隔离副本 24 项测试，24 通过、0 失败 |
| default/JS 的 `verify-demo.mjs` | 通过 | 标准 JSON 解析、文本与 JSON 快照一致；各可执行程序重复两次输出一致 |
| JSON 回归 | 通过 | 原有空报告、真实 Unicode 偏移与 nullable 捕获、转义和缺失上下文；新增快照独立性、后置基线查找及共同失败/空错误字符串检查 |
| `moon info`、`moon fmt` | 通过 | 隔离暂存副本生成后已跟踪内容无漂移（仅忽略 CRLF/LF 差别） |
| Node 脚本语法 | 通过 | `node --check tools/verify-demo.mjs` |
| CI 静态校验 | 通过 | `actionlint 1.7.12 -shellcheck= .github/workflows/ci.yml`；未运行 ShellCheck |
| native 的 `moon test --target native --deny-warn` | 环境受限，未通过 | 构建计划失败：`no system C compiler found; tried cl, cc, gcc, clang`；未执行 native 测试或 demo |
| 显式 wasm-gc 的测试 | 环境受限，未通过 | 安装缺少 `lib/core/_build/wasm-gc/release/bundle/prelude/prelude.mi`，编译器报 `Sys_error`；不能把默认目标通过推广到 wasm-gc |
| 远端 GitHub Actions | 未执行 | 仅修改并静态校验配置；未推送，无远端运行链接 |
| 发布与注册表安装 | 未执行/未验证 | 没有发布命令、发布结果或可安装版本验收 |
| 人工迁移与申报验收 | 待人工判断 | 未声称完成审查、比赛资格认定或允许所有报告差异 |

第一提交前也执行了默认 check、22 项测试和原有 demo 回归，均通过。
24 项是新增两项 JSON 回归后的实际数量，不追溯改写早先 18/22 项记录。

## 失败路径与真实报告证据

在临时暂存副本里先验证正常输出，再分别修改预期文件：

- 给 `expected.txt` 增加额外文本，脚本非零退出，旧 `verified.json` 被移除。
- 恢复文本后通过；将 JSON 的 `supplementary-prefix-offset` 开始偏移从
  `2` 改为 `1`，脚本非零退出，旧成功标记再次被移除。
- 按原始字节恢复两个快照后检查通过，原仓库快照未改动。

`artifacts/default`、`artifacts/js` 保存实际 `demo.txt`、`demo.json`、
重复输出、stderr、`run.json` 与 `verified.json`，由脚本直接写入 UTF-8，
不依赖 shell 重定向编码。这些本地产物被 Git 忽略；可用上面的命令重建。
`verified.json` 只证明 demo 快照与重复输出检查通过，不能证明整个 CI 或
人工验收通过。失败时没有该标记；同一目录里的其他文件只作诊断，新的
调查应使用新目录。原始标准输出留在产物里，没有从 expected 文件复制报告。

四组观测分别为：shared-ascii 零差异；syntax-difference 一条编译接受差异；
adapter-domain 两条适配器域拒绝差异；unicode-official-only 零差异。
差异是夹具预期观测，正常 demo 退出不会自动批准迁移。

## CI 与人工复核入口

CI 为 default、JS、native 各自执行 check/test/build、文本与 JSON 快照及
重复运行检查、公共接口和格式漂移检查。矩阵禁用 fail-fast，保留各目标
结果；`always()` 上传可用诊断和实际报告，目录还包括工具链版本与提交号。
核心检查失败不会被上传步骤改写为通过；测试或构建提前失败时可能没有
demo 报告，这应以该 job 的失败日志解释。

CI 使用 Ubuntu 24.04、Node.js 22 与 MoonBit 官方安装脚本。
MoonBit 安装器未锁定工具链版本，Actions 使用主版本标签，不能宣称未来
运行与本机环境完全相同；每次产物里的版本和提交号用于定位环境差异。
此配置增加了可复验入口，远端可用性仍须通过实际 Actions 运行确认。

人工重点复核 JSON v1 演进约定、ASCII 适配器域拒绝与真实引擎差异的区别、
哪些差异允许进入应用，以及申报的赛期归属和完整 AI 使用披露。
本次 AI 辅助修改文档、CI、测试与检查；需求范围由用户提出，最终采纳、
发布、申报和迁移验收判断留给项目负责人。

## 第 4 项：21:32 实际核验

起点 `06ab261` 已在远端 main；[前三项索引](review-evidence-2026-10-13.md)
列真实 diff、提交和各阶段检查。第 4 项第一独立成果是使用 / 边界材料同步，
提交 `0f7065b`，五份文档 81 增 / 10 删；本地 48 个文件链接存在，暂存白名单
与 whitespace 检查通过。第二成果是 CI 兼容准备、严格检查日志与本节记录。
不是重复实现 JSON schema、匹配器或新增行为夹具。

保护：起点的 `contract.mbt`、`contract_test.mbt`、`moon.mod`、
`rembt_adapter.mbt`、`unicode_data.mbt` 仍保持原字节，SHA-256 前后核对；
没有还原或暂存。当前格式迁移会涉及其中两份文件，因此未写回。

### 实际变更与依赖边界

- 使用原双适配器、29 项测试、文本 / JSON 黄金文件及重复输出验证器。
- 新增 `prepare-dependencies.mjs`：仅对实际下载的 regexp@0.3.5 六份旧清单
  用 standalone moonfmt 转换；其他文件逐一 SHA-256 检查，保存转换前后清单。
  未复制 / 修改引擎源文件，未升级两个直接依赖。清单缓存不再与原归档逐字相同。
- 依赖准备先作严格 check 探针；新工具链因旧清单拒绝而非零退出是预期的
  准备诊断，日志与 exit 保存，不能计作通过的 check。只有明确指向 regexp
  缓存的旧清单错误可触发转换；无关编译失败仍退出且删除旧 prepared 标记。
- JSON 代码 / 测试改用显式 `ToJson::to_json`，五个类型声明显式方法扩展，
  `moon.pkg` 的 json 导入限测试；生成接口显式增加五个 to_json 方法声明。
  这是兼容弃用警告的声明修复，未放宽 `--deny-warn`，未改 v1 wire / 快照。
- CI 保存安装脚本、版本、提交、update/check/test/build/demo/info/format 日志
  及实际报告；保留 default / JS / native 矩阵及 fail-fast=false、always 上传。
  Bash pipefail 保留检查退出码，无 continue-on-error。新增版本漂移守卫。

### 实际运行，2026-10-13 21:45 起（Asia/Shanghai）

Windows / PowerShell `7.6.5` / Node.js `v24.19.0`。
旧工具链：moon `0.1.20260827 (d0aaa07)`、moonc `v0.10.11+6ff76a5f9`、
moonrun `0.1.20260827`。新工具链下载到 Git 忽略的隔离目录，未替换原安装：
moon / moonrun `0.1.20261012 (748b63c)`、moonc `v0.10.15+943464bfa`。
直接依赖仍 regexp@0.3.5、re-mbt@0.1.0，传递依赖为 x@0.4.48。

| 检查 | 实际结果 / 证据范围 |
| --- | --- |
| 旧工具链 moon update | exit 0，注册表更新成功 |
| 旧工具链依赖准备 | exit 0；探针 exit 0，转换 0 文件 |
| 旧工具链 default / JS check、test、build，均 --deny-warn | 全部 exit 0；每目标 29 passed / 0 failed |
| 旧工具链 default / JS verify-demo | exit 0；文本及 parsed JSON 快照、每程序两次输出一致 |
| 旧工具链 moon info / moon fmt --check | exit 0；仅预期的五个方法声明进入接口，格式通过 |
| 新工具链隔离 fresh 副本 update / 注册表依赖下载 | exit 0 更新；旧清单拒绝如实记录，准备转换六份清单后 exit 0，源文件 hashes 不变 |
| 新工具链 default / JS check、test、build，均 --deny-warn | 全部 exit 0；每目标 29 passed / 0 failed，不使用警告豁免 |
| 新工具链 default / JS verify-demo | exit 0；原黄金文件不变，实际文本 / JSON 快照及重复输出一致 |
| 新工具链 moon info | exit 0；生成接口与本次更新的旧工具链接口逐内容一致 |
| 新工具链 moon fmt --check | **失败**，exit -1；格式器要求 Int 改 Int32，涉及 contract、unicode_data、json_report 及 demo-json；未将原工作区改写为新格式 |
| 准备脚本无关失败控制 | 隔离副本追加非法源码，exit 1 且旧 prepared.json 消失；恢复原字节后 exit 0、0 转换 |
| Node 语法检查 | prepare-dependencies.mjs exit 0 |
| CI 静态检查 | actionlint 1.7.12 -shellcheck= exit 0；未执行 ShellCheck |
| 本地 native / 显式 wasm-gc | 本项未运行；不把 default 结果推广到显式目标 |
| 发布 / 注册表安装 / 人工验收 | 未运行 / 未完成；仍待人工 |

日志与原始输出在忽略的 `artifacts/acceptance-2132/legacy`、
`fresh/artifacts/new`，包含命令、退出码与运行时间；准备成功和 demo verified
只覆盖各自检查，不表示整个 CI 通过。原始报告由可执行程序生成。

探索过程也保留限制：官方旧日期二进制 / core 归档 HEAD 返回 HTTP 403，
不能把 CI 安装器改为一个已观测不可下载的旧版本。隔离尝试直接 `moon fmt`
会重写依赖源码，故弃用；重建 fresh 副本后用 standalone moonfmt 只转清单。
首次新工具链严格 check 暴露弃用 / 未使用导入错误；一度关闭 20/29/79 警告
仅作定位诊断，不计入验收，最终严格通过没有豁免。格式失败仍未解决。

### 复现与远端状态

```sh
moon version --all
node --version
moon update
node tools/prepare-dependencies.mjs artifacts/dependency-preparation
moon check --deny-warn
moon test --deny-warn
moon build --deny-warn
node tools/verify-demo.mjs default artifacts/default
moon check --target js --deny-warn
moon test --target js --deny-warn
moon build --target js --deny-warn
node tools/verify-demo.mjs js artifacts/js
moon info
moon fmt --check
```

新工具链最后一个命令预期仍失败，不能省略后声称全部通过。
远端起点的[CI 38393726437](https://github.com/wallll-wal6/arachne/actions/runs/38393726437)
已读取日志确认失败：三个目标在旧清单处停止，tests/build/demo 跳过。
本次 CI 修订提交后才能取得远端结果；不能预写通过。实际 run 链接、SHA、
各步骤结论、身份 / 推送核验和最终时间写入 `arachne-21-32/memory.md`。
当前仍有新格式器限制，完整 CI 不应被描述为已经通过。

CI 下载 latest 后检查 moon / moonc 实际版本，只接受本次测试的版本；
这是漂移检测，不是工具链归档固定，版本变动会失败。Node 22 的补丁版本和
官方安装脚本未固定；实际版本、脚本与提交保存在产物，复现结论限已记录环境。

申报正文 / 披露表同步当前 29 项和四套件数量；schema v1 字段 / 兼容约定、
迁移步骤、限制及前三项增量已逐文件核对。人工须审阅功能语义、个人贡献、
作者 / 依赖关系、完整 AI 使用和官方申报事实，见证据索引。Codex 的修改 /
自动验证 / Git 操作不替代韦安良的实际审查，也没有生成已审或已递交状态。
