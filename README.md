# Arachne

**Arachne 是 MoonBit 正则行为契约与兼容性测试工具。**它将共享的模式、输入和预期结果运行在正则引擎适配器上，比较编译接受、匹配文本、跨度和捕获值，并输出文本或 JSON 报告，帮助开发者检查依赖升级与后端替换的行为变化。

Arachne 还包含一个自有的 ASCII 子集参考引擎：递归下降解析器将模式编译为 Thompson NFA，再以去重状态集执行，作为可审查的第三个对照后端。官方 `moonbitlang/regexp` 与 `walkzzz/re-mbt` 仍是独立公开依赖。参考引擎只支持文档列明的语法，不实现捕获值或完整 Unicode，也不替代通用正则库；它与后端的差异会由契约报告呈现。

## 快速开始

需要 MoonBit（`moonc` 0.10.14 或更新版本）和 Node.js 22 或更新版本：

```sh
moon update
moon check --deny-warn
moon test --deny-warn
moon build --deny-warn
moon run examples/demo
moon run examples/demo-json
moon run examples/reference-engine
node tools/verify-demo.mjs
```

文本与 JSON 示例演示迁移报告；参考引擎示例将其与官方引擎运行同一组契约。`moon update` 获取 `moon.mod` 中固定版本的依赖；检查及示例命令用于验证当前检出版本。

## 功能

- 编写匹配、非匹配、捕获值和整段跨度契约。
- 用 MoonBit 实现有限 ASCII 正则解析、Thompson NFA 编译和状态集匹配，作为独立参考后端。
- 通过适配器比较自有参考引擎与公开正则后端的实际结果。
- 获取稳定文本结果与 JSON v1 报告。
- 运行迁移夹具、示例和回归检查。

参考引擎支持字面量、`.`、`^` / `$`、字符类与范围、`\d` / `\w` / `\s` 及其反类、分组、`|`、`*` / `+` / `?`。分组只影响优先级，不产出捕获值；匹配采用左侧起点优先、同一起点最长结果。模式上限为 4096 个 ASCII 字符，输入上限为 16384 个 ASCII 字符，分组最多嵌套 64 层。回引用、环视、计数重复、其他字母数字转义和非 ASCII 输入会明确拒绝。

查看[迁移示例](examples/demo/README.md)、[JSON v1 格式](docs/json-report-v1.md)、[项目边界](docs/positioning.md)和[十月申报书](docs/十月项目申报书.md)。

## 示例观察

当前共享 ASCII 夹具在两套后端上执行；回引用夹具 `^([a-z])\1$` 在官方引擎接受并匹配，在 re-mbt Perl 前端被拒绝编译。该结果表示选定用例上的行为差异，不自动说明任何一方存在缺陷。迁移是否可接受由使用者结合应用需求判断。

整段跨度使用 MoonBit `StringView` UTF-16 代码单元。例如 `🦊a` 中的 `a` 跨度为 `[2, 3)`。适配器须遵守仓库所定义的偏移约定。

## 验证与贡献边界

[GitHub Actions CI](https://github.com/wallll-wal6/arachne/actions/workflows/ci.yml) 在 default、JS、native 目标执行检查、测试、构建和示例验证，并记录工具链版本及运行报告。正则行为报告针对有限夹具，不提供超时、沙箱或性能保证；Unicode 类别数据的来源和限制见[第三方说明](THIRD_PARTY_NOTICES.md)及[项目边界](docs/positioning.md)。

项目由韦安良一人维护。AI（Codex）辅助部分代码与测试编写、排查和文档整理；项目范围与最终取舍由负责人负责。公开依赖维护者不是本项目成员，项目不申报上游贡献。AI 辅助披露和数据限制见[申报书](docs/十月项目申报书.md)。

## 许可

Arachne 源码采用 Apache-2.0。第三方依赖及 Unicode 数据许可见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)、[LICENSE](LICENSE) 和 [UNICODE-LICENSE.txt](UNICODE-LICENSE.txt)。
