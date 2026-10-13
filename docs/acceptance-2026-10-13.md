# Arachne 工程验收记录 · 2026-10-13

本记录由 Codex 辅助执行检查并整理。人工主导范围选择、允许的行为差异和
最终验收判断；本地工程检查通过不表示人工验收、远端 CI 或发布已完成。

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
