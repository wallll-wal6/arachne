# Arachne JSON 契约整改记录 · 2026-10-13 19:21

本记录由 Codex 辅助检查与编写。全部实现、测试设计、兼容性约定和成果归属
**待韦安良人工复核**；自动测试通过不表示已人工审查、批准迁移或完成申报。

## 实际人工指令与已有成果

人工任务指定第 2 项：提供稳定、版本化、机器可读的 JSON 行为契约报告，
先检查并复用现有模型、文本/JSON 报告、测试及工作区 diff；解析与匹配由
公开依赖承担；至多两个实质提交，保留已有修改，逐次核验身份后正常推送。
这些是本次实际收到的人工范围决定；未收到逐项代码复核或正式验收结论。

起点为 `7f1f11e6f7b6f159db1095dd564a93e1d6550b7d`，远端 main 当时相同。
JSON v1 模型、状态/差异标签、显式 null、捕获字符串、独立快照、差异上下文、
字段/版本文档和真实 demo 已入库，本次复用，不重复声称为新成果。
基线 default 检查通过，24 项测试通过。五个预存工作区修改
`contract.mbt`、`contract_test.mbt`、`moon.mod`、`rembt_adapter.mbt`、
`unicode_data.mbt` 的 Git 内容 diff 为空，且暂存为空；本次不暂存它们，
以原始文件 SHA-256 核对其字节保留情况，最终值记入自动化 memory。

## 此次实质变更与 Codex 辅助

只形成一个报告稳定性成果提交：

- `json_report.mbt` 复用 v1 的 ToJson 模型，在每层对象显式按字典序排序键；
  保持数组顺序，由核心 JSON 库处理标量与转义。没有增加解析/匹配实现，
  没有改动适配器、依赖版本、比较规则或公共接口。
- `json_report_test.mbt` 新增三项针对性回归：嵌套键序与捕获数组顺序的精确
  JSON 快照；全部 U+0000–U+001F 控制字符、引号、反斜杠、中文、补充平面
  字符及 U+2028/U+2029 在标识、文本、捕获、错误与详情中的往返；契约执行
  产生的七类差异及完整 baseline/actual 上下文、四类结果状态、重复执行
  字节一致性、格式化不再调用引擎。保留原有五项 JSON 回归和真实后端测试。
- [JSON v1 契约](json-report-v1.md)补充当前确定性实现与工具链边界：字段、
  null、标签、数组顺序仍按 v1；消费者按解析后的值比较，不依赖对象键顺序。
  不保证升级工具链/适配器后错误文本或转义拼写完全一致。

Codex 实际辅助范围：读取状态、历史、源码及本地核心 JSON/排序实现；补充
报告序列化、测试、文档；执行检查、构建、真实 demo；核验 Git/GitHub 身份、
限定暂存范围、提交和推送；保存验证证据与自动化记忆。无需另建重复模型，
也不按提交数量拆分。具体实现选择由 Codex 提出，仍待韦安良采纳/复核。

## 实际验证与限制

本地工具链为 `moon 0.1.20260827 (d0aaa07)`，沿用已有公开依赖。
最终检查时间为 2026-10-13 19:26（Asia/Shanghai）。

| 命令/检查 | 实际结果 |
| --- | --- |
| `moon check --deny-warn` | 通过，exit 0 |
| `moon test --deny-warn` | 27 passed，0 failed，exit 0 |
| `moon build --deny-warn` | 通过，exit 0 |
| `moon check --target js --deny-warn` | 通过，exit 0 |
| `moon test --target js --deny-warn` | 27 passed，0 failed，exit 0 |
| `moon build --target js --deny-warn` | 通过，exit 0 |
| `node tools/verify-demo.mjs default artifacts/json-contract-1921/default` | 通过；真实文本/JSON 快照和各两次输出一致 |
| `node tools/verify-demo.mjs js artifacts/json-contract-1921/js` | 通过；真实文本/JSON 快照和各两次输出一致 |
| `moon info` | 通过；已跟踪公共接口无内容变化 |
| `moon fmt --check` | 通过；没有格式改动 |
| `git diff --check` | 通过；提交前再次检查 |
| native、显式 wasm-gc、发布/安装、人工验收 | 本次未运行/未完成，不扩大本地验证结论 |

中间失败如实保留：首次新测试用了不合法的 `_` 计数循环，`moon check`
失败、测试未执行；修正后 default 和 JS 各出现 26 passed/1 failed，精确
键序快照指出默认 String Compare 是先按长度排序。改用 `lexical_compare`
后，最终 default/JS 各 27 项全部通过；没有改写预期快照来掩盖此失败。
另用独立构建目录复现了同一键序失败，不计作额外通过的检查。

最终检查和 demo 原始输出保存在 Git 忽略的
`artifacts/json-contract-1921`，其中 demo 由程序实际运行得到，使用 Node
标准 JSON 解析和既有黄金文件校验，没有从黄金文件复制实际结果。
demo 自有 envelope 使用核心 ToJson 序列化；报告的新增明确键序由本次
精确字节回归在 default/JS 两目标直接验证。

此前远端 CI 已观测依赖 `regexp@0.3.5` 的旧清单与最新安装器不兼容，见
[初审记录](initial-review-2026-10-13.md)。本次未更改工具链、CI 或上游依赖；
推送后 CI 的实际状态另记 memory，不能用本地通过宣称远端通过。
每次提交/推送前使用 `gh api user`、Git 作者/提交者身份、origin fetch/push
URL 核验；任何不符即停止该 Git 写操作。实际哈希、推送 exit code、远端
确认、最终时间及人工复核状态记入自动化 `arachne-19-21-json/memory.md`。
