# 团队与 AI 辅助说明

Arachne 由韦安良一人负责和维护；`moonbitlang/regexp` 与 `walkzzz/re-mbt` 是独立公开依赖，其维护者不是本项目成员。本项目不申报与上游共同开发、共同维护或上游贡献。

项目实现契约执行、适配、比较和报告，正则解析与匹配由依赖提供。十月改进包括 JSON v1 报告、确定性序列化、迁移夹具及新版工具链兼容修订；范围和限制见[项目范围](2026-10-contribution-scope.md)与[项目边界](positioning.md)。

项目负责人对目标范围、功能取舍和最终提交负责。AI（Codex）曾辅助部分代码与测试编写、问题排查、依赖和工具链检查以及文档整理。AI 生成或修改的内容纳入代码审查范围；自动化检查只能说明相应命令通过，不能替代人工判断。负责人将在提交申报前复核代码变更、示例结果、申报事实和 AI 辅助范围。

Unicode 类别表使用官方 Unicode 17.0.0 `UnicodeData.txt`。我从 [Unicode 17.0.0 UCD 归档](https://www.unicode.org/Public/17.0.0/ucd/UnicodeData.txt)重新生成并核对了仓库中的生成段，逐行一致；该输入文件的 SHA-256 为 `2e1efc1dcb59c575eedf5ccae60f95229f706ee6d031835247d843c11d96470c`。许可与重建步骤见[第三方说明](../THIRD_PARTY_NOTICES.md)和[生成说明](../tools/README.md)。这些数据仅用于有限回归夹具，不代表完整 Unicode 覆盖或跨引擎一致性。
