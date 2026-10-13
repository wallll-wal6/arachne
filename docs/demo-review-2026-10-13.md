# Arachne 可复现迁移示例整改 · 2026-10-13 19:48

本记录由 Codex 辅助执行、整理。人工实际指令指定第 3 项：检查现有示例、
适配器、测试与 diff，复用真实双后端实现，补齐共同结果、已验证差异、ASCII /
Unicode / 偏移量边界及集成回归；最多两个实质提交，逐次核验身份后正常推送。
未收到人工逐项选定夹具、允许迁移差异或正式验收的结论。下面的实现选择、
行为解释与开发成果归属均 **待韦安良复核**。

## 起点与新增范围

起点 `f6fd031` 已包含真实适配器、四组示例、文本 / JSON 快照、重复运行校验、
27 项测试、JSON v1 稳定性实现及远端 CI 工具链限制说明。本次不重复增加
解析器、匹配器、报告模型或回归运行器；复用 `run_demo`、`run_contracts`、
两个真实适配器、报告格式与 `tools/verify-demo.mjs`。

预存五个修改 `contract.mbt`、`contract_test.mbt`、`moon.mod`、
`rembt_adapter.mbt`、`unicode_data.mbt` 的内容 diff 为空，暂存为空。
本次没有还原、改写或暂存它们，以前后 SHA-256 确认字节不变。

Codex 在同一夹具源增加四个示例：

| 契约 | 实际预期观测 |
| --- | --- |
| ASCII `^([A-Z]+)-([0-9]+)$` / `ORD-2048` | 两后端均匹配，捕获依次为 `ORD`、`2048`，span `[0, 8)` |
| ASCII `^(a*)$` / 空字符串 | 两后端均为 matched，空文本、参与的空捕获，span `[0, 0)`；与 no_match 不同 |
| 官方 `(🦊)` / `猫🦊a` | 捕获 `🦊`，span `[1, 3)`，验证匹配文本本身占两个 UTF-16 code units |
| 官方 `(\p{Lu})` / `éΩ🦊` | 跳过 `é`，匹配并捕获 `Ω`，span `[1, 2)`；验证实际非 ASCII 类别匹配 |

新增两项真实引擎集成回归直接检查上述 matched 状态、文本、捕获顺序和
偏移。原有集成回归仍检查回引用编译拒绝、ASCII 域拒绝与补充平面前缀。
两个程序实际运行后捕获文本 / JSON 更新黄金文件；去除新增行、恢复用例
计数后，解析后的旧 JSON 与旧黄金文件完全一致，原有观测没有漂移。
首次辅助比对脚本误认为报告存在 `cases` 字段而失败，未写入黄金文件；
按实际 v1 的 `runs` 和 `case_count` 修正后才通过并捕获新结果。

示例扩展、预期输出、对应回归与说明是一个完整成果，形成一个实质提交，
没有按提交数量拆分。README 和能力边界增加当前入口；早先验收记录保留
当时的 5 / 6 用例及 24 / 27 测试历史，不追溯改写。

## 真实差异及证据范围

| 套件 | cases / engines / findings | 观测 |
| --- | --- | --- |
| shared-ascii | 7 / 2 / 0 | 七个指定 ASCII 契约一致 |
| syntax-difference | 1 / 2 / 1 | `^([a-z])\1$` / `aa`：regexp 匹配 `aa`、捕获 `a`、`[0, 2)`；re-mbt Perl 编译拒绝 |
| adapter-domain | 2 / 2 / 2 | 非 ASCII 模式在适配器编译入口拒绝；ASCII 模式加非 ASCII 输入在执行入口拒绝 |
| unicode-official-only | 8 / 1 / 0 | 四个显式样例及四个 Lu 生成边界通过，仅调用官方适配器 |

ASCII 限制属于 Arachne `rembt_ascii_perl_adapter`：模式字符串和输入字符串
均须为 U+0000–U+007F。其域拒绝不表示整个上游 re-mbt 不具备 Unicode 能力，
也不与实际 Perl 回引用编译差异混同。ASCII 字符串形式的 `\p{Lu}` 仍受前端
语法和输入守卫约束，不能把官方 Unicode 测试当作双后端验证。

span 为零基、右端排除的 MoonBit `StringView` UTF-16 code-unit 偏移。
ASCII 接受域内 re-mbt byte offset 数值相同；不对非 ASCII 输入猜测转换。
`🦊a` 中的 `a` 为 `[2, 3)`；`猫🦊a` 中的 `🦊` 为 `[1, 3)`，对应 UTF-8 byte
span `[3, 7)`、scalar span `[1, 2)`。捕获只报告文本，没有捕获组 span。
生成的四个 Unicode 17.0 Lu 边界仍是 `A`、`@`、`Z`、`[`；新增 `Ω` 是手写
契约，不声称扩大生成器到全部脚本、类别或补充平面覆盖。

正常 demo 退出包括预期差异；不表示迁移获准或判定某后端错误。

## 实际执行结果

本地 Windows / PowerShell；`moon 0.1.20260827 (d0aaa07)`、
`moonc v0.10.11+6ff76a5f9`、`moonrun 0.1.20260827`、Node.js `v24.19.0`。
直接依赖仍为 `regexp@0.3.5`、`re-mbt@0.1.0`；本次不升级依赖 / 工具链。

| 命令 | 本次实际结果 |
| --- | --- |
| 起点 default check / test / demo 校验 | 通过；27 passed、0 failed；旧快照和重复输出一致 |
| `moon update` | 通过，exit 0 |
| `moon check --deny-warn` / `moon test --deny-warn` / `moon build --deny-warn` | 通过；29 passed、0 failed；均 exit 0 |
| 上述 check / test / build 加 `--target js` | 通过；29 passed、0 failed；均 exit 0 |
| `node tools/verify-demo.mjs default artifacts/demo-review-1948/default` | 文本、解析后 JSON 与黄金文件一致；两个程序各运行两次且输出一致 |
| `node tools/verify-demo.mjs js artifacts/demo-review-1948/js` | 同上，exit 0 |
| `moon info` / `moon fmt --check` / `git diff --check` | 通过；无公共接口内容变化 |
| `git checkout-index` 暂存导出副本的 update / check / default 与 JS test / JS demo | 通过；两个目标各 29 passed、0 failed；证明结果不依赖未暂存工作 |
| 隔离副本的错误黄金文件回归 | 额外文本、捕获逆序、空 matched 改为 no_match、补充平面 end 从 3 改为 2，四种均 exit 1；旧 verified 标记均移除；按原始字节恢复后 exit 0 |
| 当前 Markdown 本地链接 / 暂存 diff whitespace | 全部通过 |
| native / 显式 wasm-gc / 发布与安装 | 本次未运行，不扩大验证结论 |

日志与实际输出在 Git 忽略的 `artifacts/demo-review-1948`，不是从黄金文件
复制来的观测。default / JS 目录含原始 stdout、重复输出、stderr、run 元数据与
`verified.json`；隔离副本及失败日志在 `export/artifacts/negative`。故意改错
只发生于隔离副本；原仓库快照未受失败注入影响。最终本地验证于
2026-10-13 19:55（Asia/Shanghai）完成。复现命令和预期输出摘录见
[示例 README](../examples/demo/README.md)；完整结果见 `expected.txt` / `expected.json`。

此前[远端 CI](https://github.com/wallll-wal6/arachne/actions/runs/38384999859)
在检查阶段拒绝依赖的旧 `moon.mod.json`，未执行测试 / demo。本次没有修改
该限制相关实现；本地通过不能证明远端通过。推送后状态按实际 Actions 查询
写入本次自动化 memory，不追加记录用提交。

Codex 辅助范围为状态 / 源码 / 依赖检查、夹具与回归设计、快照捕获、文档
整理、执行验证、Git 身份核验、限定暂存、提交与推送。用户实际决定的是任务
范围和操作要求；具体夹具选择、结果解释、成果计入、允许差异与最终迁移
判断 **待人工复核**。提交 / 推送前分别核验 `gh api user`、作者 / 提交者和
origin HTTPS 地址；实际哈希、退出码、远端确认及当前时间记入自动化
`arachne-19-48/memory.md`。
