# Arachne｜已有项目与十月增量

核对日期：2026-10-14。项目为 MoonBit 正则行为契约 / 兼容性测试工具，九月已经存在；十月按持续维护已有项目组织成果。这里的“十月增量”仅表示 Git 历史中的十月改动，不表示已获赛事认可或通过验收。

## 类别与规则依据

[官方十月赛事页](https://moonbitlang.github.io/Hackathon2026/)说明已有项目需有本期实质新增工作，重复提交、拆分或简单修改不计入验收与奖励；报名与验收截止为 2026-10-31。[官方章程](https://bxup9uklfcb.feishu.cn/wiki/Dx4Bwd6D1i3GfHkajQCcF7SznEd)（页面标注 10 月 10 日修改）3.2、4.2、5.2 提供维护既有社区项目的季度评选路径，并要求参赛者本人为主要贡献者。

[十月报名表](https://bxup9uklfcb.feishu.cn/share/base/form/shrcnWUMlgpbwHaXgzV7HmNhNhg)的“参赛方向”实际包含“已有项目维护”，材料拟采用该选项，技术方向为基础库 / 开发者工具。类别有公开依据；Arachne 是否符合审核条件仍由赛事方判断。

待确认点：

- 九月被驳回的 Arachne 改正定位后，按已有项目维护申报时的具体审核要求；公开规则允许有独立可验证新成果的历史参赛项目重新申报，但没有给出对本项目的审核结论。
- 十月审核通过前的开发成果如何划入本期有效贡献。官网以审核前最后一次有效提交或修改确定报名时间，同时要求本期新增；Git 的十月时间戳不足以证明全部可计入。
- 官网列十月截止，章程 5.1 仍保留九月日期。不能据旧日期推定十月已截止，也不能自行改写章程；具体执行口径须确认。
- 社区维护方向的最终验收材料及发布要求。章程 5.1 的新项目清单含 Mooncakes 发布，5.2 未逐项复述；本项目尚无已核实发布成果，不据此宣称满足发布或完整验收条件。

## 九月已有基础

最早提交为 [361542e](https://github.com/wallll-wal6/arachne/commit/361542e3088c7cee7881cf0aed55fa3fa2af989d)（2026-09-29）。九月曾有自研匹配方向的代码和申报表述；[96296ca](https://github.com/wallll-wal6/arachne/commit/96296cadf383ae891d4a2295fa73e2bf6d9cd7d6)于 9 月 30 日移除旧引擎文件并转为行为契约测试。这次定位和实现转换已经发生在九月，不是十月新功能。

以九月最后提交 [2357942](https://github.com/wallll-wal6/arachne/commit/2357942bea79a7a0dc9b47a560981bade0b35386)为比较基线：

| 九月已存在 | 提交与代码证据 | 十月申报处理 |
| --- | --- | --- |
| 契约执行、黄金预期、基线比较、编译复用、文本报告、官方引擎适配、有限 Unicode 类别边界样例 | 96296ca；基线中的 `contract.mbt`、`unicode_data.mbt`、18 项测试 | 全部作为已有基础 |
| 整段跨度断言和补充平面字符偏移回归 | [61a8c5d](https://github.com/wallll-wal6/arachne/commit/61a8c5dcb18afe01302784bd1b1b8a42473fcae9) | 不申报为十月新增偏移能力 |
| re-mbt ASCII Perl 适配、真实双后端比较及域拒绝 | [056fd19](https://github.com/wallll-wal6/arachne/commit/056fd19687b1389b5dd397bfbe6cbe8459231b11) | 不申报为十月首次接入双引擎 |
| 可运行双引擎 demo、请求编号及反向引用差异 | 2357942；原 demo 为两个用例 | 十月仅申报扩展示例及验证 |

从该基线到 588d9eb，`contract.mbt`、`contract_test.mbt`、`rembt_adapter.mbt`、`unicode_data.mbt` 与 `moon.mod` 没有提交内容差异。两套公开引擎的解析、匹配和算法始终属于依赖能力，不计入 Arachne 十月自有成果。

## 十月逐项增量

下表覆盖九月基线之后、截至 588d9eb 的全部 15 个提交。每项按实际 diff 分类，同一实现的后续测试、修复和说明不重复计为多项新功能；提交数量及增删行数不用作有效贡献结论。

| 提交 | 可证明的变化 | 成果性质及边界 |
| --- | --- | --- |
| [ca712b5](https://github.com/wallll-wal6/arachne/commit/ca712b58dfbae559272247da57c84885b6416c7b)、[259f26c](https://github.com/wallll-wal6/arachne/commit/259f26cf4a84d51b337dfdc23221ff465ed65f1c) | 依赖归属说明、十月申报及披露材料 | 文档整改，无新增运行能力 |
| [152dbaf](https://github.com/wallll-wal6/arachne/commit/152dbafd47d2e194cffd983b58c5ac78ae200474) | 将示例夹具集中维护，扩为共享 ASCII、语法差异、适配域、官方 Unicode 四套件；逐项打印观测 | 示例工程扩展，复用九月 runner / 适配器 |
| [47a7291](https://github.com/wallll-wal6/arachne/commit/47a7291a5ef9b43b3a55c394b240ed44652f0925) | 新增 `json_report.mbt`、类型化 JSON v1 / nullable 观测与差异上下文；JSON 可执行示例、文本 / JSON 黄金文件、验证脚本；3 项 JSON 测试和 1 项夹具回归 | 十月新增机器可读报告与回归入口，18 → 22 项测试；不是新增引擎 |
| [a1f7623](https://github.com/wallll-wal6/arachne/commit/a1f7623c0a8da792307243399d56dad20ae989be) | JSON v1 演进约定与使用说明 | 报告契约文档，不再次申报 JSON 功能 |
| [8bcf7dc](https://github.com/wallll-wal6/arachne/commit/8bcf7dcffd9fb1418fd0d7a1a1e04285940b2564) | 重复运行校验、失败清理成功标记、CI 报告留存；新增快照独立性 / 后置基线和共同失败语义 2 项测试 | 工程与回归增强，22 → 24；配置存在不等于 CI 通过 |
| [1cedfd1](https://github.com/wallll-wal6/arachne/commit/1cedfd1d744b76f6ee68b615bc5bc14ef2759d25)、[7f1f11e](https://github.com/wallll-wal6/arachne/commit/7f1f11e6f7b6f159db1095dd564a93e1d6550b7d) | 明确项目边界及远端旧依赖清单失败 | 文档纠正和问题披露，不是修复或新增功能 |
| [f6fd031](https://github.com/wallll-wal6/arachne/commit/f6fd0312f10c1d3dbd117a0814a3413d7ae2b6ef) | JSON 对象键递归排序，数组维持原顺序；3 项序列化回归 | 修复输出依赖 Map 遍历顺序的问题，24 → 27；schema 仍为 v1 |
| [06ab261](https://github.com/wallll-wal6/arachne/commit/06ab26132e69a0956da43f0c2eaa88878f79fbae) | 增加多捕获、空整段匹配、补充平面字面量跨度和非 ASCII 大写类别匹配四个夹具；2 项集成回归及真实输出快照 | 增强迁移验证，27 → 29；复用已有偏移 / Unicode API |
| [0f7065b](https://github.com/wallll-wal6/arachne/commit/0f7065b69fa83ab5e68cdec1f688de39a8826666) | 使用说明与证据同步 | 文档维护，不重复计入夹具或 JSON 实现 |
| [be830f5](https://github.com/wallll-wal6/arachne/commit/be830f54488f3bf09878aa9968545762c2d29e28) | 旧依赖清单定向转换、源文件校验、CI 工具链漂移检测和日志留存；显式 ToJson 声明 / 测试导入兼容修订 | 工具链兼容与工程改进，不修改上游匹配实现；新格式器问题仍未解决 |
| [9bfd719](https://github.com/wallll-wal6/arachne/commit/9bfd71949eea1a349432281258050de98fadc813)、[5d4ee01](https://github.com/wallll-wal6/arachne/commit/5d4ee01172c7688cdfb2a45e376b2a7437f8a6bd)、[588d9eb](https://github.com/wallll-wal6/arachne/commit/588d9ebe6715a592c47b66cd3ccd34e4309bfd6b) | 统一定位、精简申报、完整场景和团队 / 九月驳回说明 | 材料整改，不申报为新增软件功能 |

## 已验证结果与问题

2026-10-14 在 MoonBit `0.1.20260827 (d0aaa07)` / Node.js `v24.19.0` 重跑：严格 check 通过，default / JS 各 29 项测试全部通过，两个目标的真实文本 / JSON 示例均与黄金文件一致，每个可执行程序两次输出一致。本次只修订材料，没有新增代码或测试。

当前四套件用例 / 后端 / 差异数量依次为 7/2/0、1/2/1、2/2/2、8/1/0。反向引用的编译接受差异九月已经存在；两项非 ASCII 拒绝是 ASCII 适配器边界，不能据此判定上游引擎缺陷。Unicode 套件只测官方后端，不宣称跨引擎 Unicode 等价。

[远端 CI 38439036536](https://github.com/wallll-wal6/arachne/actions/runs/38439036536)对应 588d9eb：default / JS / native 的严格检查、测试、构建、示例快照及重复输出、公共接口检查均成功，三个目标均在格式检查失败，整体结论为 failure。失败日志要求把源码的 `Int` 迁移到 `Int32`；不能宣称已适配全部新工具链要求或完整 CI 通过。旧依赖清单准备已通过，该项旧阻塞不能继续写成最新失败原因。

尚无已核实的注册表发布 / 安装验收、外部用户迁移验证或性能基准。Unicode 原始数据版本仍缺独立溯源记录。测试数量、所选夹具无差异和提交链接可读均不构成赛事资格或最终验收结论。

### 格式兼容修订

后续修订将源码、JSON 示例和 Unicode 表生成器统一为 `Int32`，满足新格式器要求；这是工具链兼容维护。公开 API 仍使用同一 32 位整数类型，JSON v1 的字段、数值、null 与顺序及演示快照不变。增加公共整数 API / JSON 上界值回归，测试总数为 30。[源码构建说明](../README.md#quick-start)采用 MoonBit `0.1.20261012` / moonc `v0.10.15+943464bfa`；`0.1.20260827` 不识别该拼写，不能继续宣称本修订支持该旧版。上面的旧 CI 失败记录属于修订前状态，后续 CI 结论应以修订提交的运行结果为准。
