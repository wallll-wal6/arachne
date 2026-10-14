# Arachne

**Arachne 是 MoonBit 正则行为契约与兼容性测试工具。**它将共享的模式、输入和预期结果运行在正则引擎适配器上，比较编译接受、匹配文本、跨度和捕获值，并输出文本或 JSON 报告，帮助开发者检查依赖升级与后端替换的行为变化。

Arachne 实现契约、适配、比较和报告；正则解析与匹配由公开依赖 [`moonbitlang/regexp`](https://github.com/moonbitlang/regexp.mbt) 和 [`walkzzz/re-mbt`](https://github.com/walkzzz/re-mbt) 提供。本项目不实现正则引擎，不宣称对所有模式和输入等价。`re-mbt` Perl 适配器只接受 ASCII 模式和输入；有限 Unicode 类别样例仅用于回归。

## 快速开始

需要 MoonBit `0.1.20261012` 和 Node.js 22 或更新版本：

```sh
moon update
node tools/prepare-dependencies.mjs
moon check --deny-warn
moon test --deny-warn
moon run examples/demo
moon run examples/demo-json
node tools/verify-demo.mjs
```

两个示例分别运行文本与 JSON 报告。`node tools/prepare-dependencies.mjs` 只为下载缓存中的旧依赖清单做兼容准备，不改写依赖引擎源码；检查及示例命令用于验证当前检出版本。

## 功能

- 编写匹配、非匹配、捕获值和整段跨度契约。
- 通过适配器比较公开正则后端的实际结果。
- 获取稳定文本结果与 JSON v1 报告。
- 运行迁移夹具、示例和回归检查。

查看[迁移示例](examples/demo/README.md)、[JSON v1 格式](docs/json-report-v1.md)、[项目边界](docs/positioning.md)和[十月申报书](docs/十月项目申报书.md)。

## 示例观察

当前共享 ASCII 夹具在两套后端上执行；回引用夹具 `^([a-z])\1$` 在官方引擎接受并匹配，在 re-mbt Perl 前端被拒绝编译。该结果表示选定用例上的行为差异，不自动说明任何一方存在缺陷。迁移是否可接受由使用者结合应用需求判断。

整段跨度使用 MoonBit `StringView` UTF-16 代码单元。例如 `🦊a` 中的 `a` 跨度为 `[2, 3)`。适配器须遵守仓库所定义的偏移约定。

## 验证与贡献边界

主分支 [CI](https://github.com/wallll-wal6/arachne/actions/runs/38509773560) 在 default、JS、native 目标通过检查、测试、构建和示例。正则行为报告针对有限夹具，不提供超时、沙箱或性能保证；Unicode 类别数据的来源限制见[第三方说明](THIRD_PARTY_NOTICES.md)及[项目边界](docs/positioning.md)。

项目由韦安良一人维护。AI（Codex）辅助部分代码与测试编写、排查和文档整理；项目范围与最终取舍由负责人负责。公开依赖维护者不是本项目成员，项目不申报上游贡献。AI 辅助披露和数据限制见[申报书](docs/十月项目申报书.md)。

## 许可

Arachne 源码采用 Apache-2.0。第三方依赖及 Unicode 数据许可见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)、[LICENSE](LICENSE) 和 [UNICODE-LICENSE.txt](UNICODE-LICENSE.txt)。
