# Arachne

**Arachne 是 MoonBit 正则行为契约 / 兼容性测试工具。**
本仓库实现契约、适配、比较与报告；正则解析及匹配由公开依赖
`moonbitlang/regexp@0.3.5` 和 `walkzzz/re-mbt@0.1.0` 提供。
项目目标与定位由人工明确，AI 辅助检查和修改。
负责人及唯一团队成员为韦安良；两套公开依赖的维护者不是 Arachne
团队成员，依赖接入不表示共同开发或上游贡献。
[十月申报正文](docs/2026-10-hackathon-application-draft.md)与
[项目边界](docs/positioning.md)说明实现职责；依赖、团队与历史定位说明见
[披露附表](docs/2026-10-disclosure.md)。

项目九月已存在，十月按已有项目维护组织材料；[九月基础与十月增量](docs/2026-10-contribution-scope.md)逐项链接提交，区分新增实现、修复、回归与文档维护，并列出官方类别依据、待确认点及当前 CI 格式检查失败。

Arachne is a MoonBit library for checking regular-expression behavior contracts across real regex backends. It runs the same pattern/input fixtures through caller-supplied engine adapters, compares compile acceptance, match presence, matched text, spans, and captures, then returns stable findings suitable for tests and CI.

Arachne does not implement a regex syntax, parser, or matching engine. Its first-party adapters call the official [`moonbitlang/regexp`](https://github.com/moonbitlang/regexp.mbt) package and the Perl frontend of [`walkzzz/re-mbt`](https://github.com/walkzzz/re-mbt). The re-mbt adapter is deliberately limited to ASCII patterns and inputs because that backend exposes byte-oriented APIs; it refuses non-ASCII data rather than guessing at offset conversion. Applications can add adapters for another engine or a newer engine version without copying either implementation.

This places Arachne above regex libraries: engines parse and match; Arachne
checks that their observable behavior satisfies shared contracts. The
[project boundary](docs/positioning.md) compares these responsibilities with
engine projects and documents the adapter requirements and limits.

## What it checks

- **Behavior drift:** compare a selected baseline against one or more candidate adapters.
- **Golden expectations:** assert match presence, whole-match text, capture text, and—when important—normalized whole-match spans.
- **Unicode boundary fixtures:** generate deterministic positive and adjacent-negative cases from the category range table labelled Unicode 17.0, with a caller-selected case cap.
- **Stable reports:** preserve fixture and adapter order, format findings for build logs, and export versioned JSON for CI consumers.
- **Compile reuse:** compile each distinct pattern once per adapter during a run, then reuse the compiled matcher for all matching cases.

When callers need to pin an offset as well as text, `expect_match_span` asserts
the adapter's normalized whole-match offsets. For example, with the bundled
adapter, matching `a` after the supplementary scalar `🦊` has span `[2, 3)` in
MoonBit `StringView` code units. This catches byte/scalar/code-unit conversion
mistakes at an adapter boundary.

This is a fixture-based compatibility check, not a proof that two engines are equivalent for every pattern or input. It does not impose execution timeouts or resource limits on an adapter; use engines and test inputs appropriate for the environment.

## Quick start

Run from a source checkout with MoonBit `0.1.20260827 (d0aaa07)` and
Node.js 22+ on PATH:

```sh
moon update
moon check --deny-warn
moon test --deny-warn
moon run examples/demo-json
node tools/verify-demo.mjs
```

These commands resolve the declared engine versions, run tests, print a JSON
demo envelope, and compare both real demos with checked-in expectations.
For MoonBit `0.1.20261012`, insert `node tools/prepare-dependencies.mjs`
after `moon update` to handle the dependency's legacy manifests. It converts only
the six legacy `regexp@0.3.5` manifests in the downloaded `.mooncakes` cache,
preserves every engine source file, and records the preparation probe.
An unrecognized check error fails preparation; always run the strict checks
afterwards. It does not upgrade dependencies or change the JSON v1 wire contract.
Manifest preparation does not resolve the source migration required by that
toolchain's formatter (`Int` to `Int32`); full CI acceptance remains unconfirmed.

These source-checkout commands do not establish registry publication, an
installable release or compatibility with every toolchain and execution target.
For an application consuming Arachne, import the package as
`@arachne` in its `moon.pkg` and use the following golden cases:

```moonbit
let cases = [
  @arachne.ContractCase::expect_match(
    id="tenant-field",
    pattern="user=([A-Za-z0-9_]+)",
    input="INFO user=wal6 action=login",
    text="user=wal6",
    captures=[Some("wal6")],
  ),
  @arachne.ContractCase::expect_no_match(
    id="reject-empty-user",
    pattern="user=([A-Za-z0-9_]+)",
    input="INFO user= action=login",
  ),
]
let engine = @arachne.moonbit_regexp_adapter()
let report = @arachne.run_contracts(cases, [engine], "moonbitlang/regexp")
match report {
  Ok(result) => {
    println(result.summary())
    println(result.format_findings())
  }
  Err(error) => println("invalid contract configuration: \{error}")
}
```

From a checkout, run the real two-engine example with:

```sh
moon run examples/demo
```

It runs seven shared ASCII contracts, the existing backreference difference,
two explicit ASCII-adapter domain probes, and eight official-engine Unicode
fixtures. Every observation is printed, including captures and spans.
See the [reproducible migration walkthrough](examples/demo/README.md) for the
JSON executable, expected results, regression command, Unicode sample scope,
and UTF-16 code-unit offset convention. A normal demo exit displays findings
for owner review; it does not approve migration.

For cross-engine checks over ASCII fixtures, use both real adapters directly:

```moonbit
let report = @arachne.run_contracts(
  cases,
  [
    @arachne.moonbit_regexp_adapter(),
    @arachne.rembt_ascii_perl_adapter(),
  ],
  "moonbitlang/regexp",
)
```

The integration suite includes common match/capture contracts and a real
backreference case that produces a compile-acceptance finding between the two
engines. Such a finding is a measured behavior difference, not automatically a
bug: the application owner decides which backend's behavior is required. For
other engines, create an `EngineAdapter`; the [adapter contract](DESIGN.md#engine-adapter-contract)
describes this boundary.

The checked-in comparison confirms that both engines pass the common ASCII
fixtures, while the official engine accepts the backreference fixture and
re-mbt's Perl frontend rejects it. The finding identifies the candidate and
both sides of the compile result:

```text
backreference-support-difference [walkzzz/re-mbt/Perl (ASCII)] compile-acceptance: baseline compiled the pattern; candidate rejected it
```

## Machine-readable reports

Call `result.format_json()` to export a JSON v1 report, or `result.json_v1()`
to inspect its typed model. The document includes its schema version, counts,
compatibility flag, every engine outcome, and findings with both baseline and
actual outcome context. Unmatched captures and absent observations use `null`.
See the [JSON v1 contract](docs/json-report-v1.md) for status labels, fields,
offset conventions, failure semantics, and consumer compatibility rules. The
demo wraps these reports in a separate `demo_version: 1` envelope; it is not a
single report object. Check versions before interpreting either format.

`compatible: true` means no findings in this fixture run. Inspect each outcome
as well: identical compile or execution failures can produce no comparison
finding. The application owner defines required behavior and accepts or
rejects a migration; neither demo exit status nor this flag records human
acceptance.

## Unicode category corpus

`unicode_category_cases(category="Lu", max_cases=128)` creates bounded test fixtures from the range table labelled Unicode 17.0. Positive cases exercise the start/end of category ranges; adjacent negative cases exercise transitions out of the category. Surrogate code points are skipped because they are not Unicode scalar values. Unknown categories and invalid limits return an error.

The generator labels its output as Unicode 17.0 but accepts an external input
file. The original input version lacks an independent provenance record, as
documented in the [disclosure](docs/2026-10-disclosure.md).

The corpus is a boundary-focused regression aid, not an exhaustive test of every scalar value. Engines may ship different Unicode versions; report differences rather than assuming one version is universally correct. Generation steps and the Unicode data license are in [tools/README.md](tools/README.md) and [UNICODE-LICENSE.txt](UNICODE-LICENSE.txt).

## Development

```sh
moon update
moon check --deny-warn
moon test --deny-warn
moon build --deny-warn
moon info
moon fmt
node tools/verify-demo.mjs default artifacts/default
node tools/verify-demo.mjs js artifacts/js
```

The test suite covers adapter normalization, cache reuse behavior, expected outcomes, compile and execution differences, capture/span drift, invalid suite configuration, Unicode boundary fixture construction, and real comparisons between the two bundled backends.

It also verifies that a golden span contract catches a supplementary-character
offset error, so adapters can pin the offset convention before comparing
backends.

CI is configured to preserve actual reports for default/JS/native targets; it does
not update expected files or decide which findings an application may accept.

## Scope

Arachne is a compatibility-test library above regex engines. It exercises their observable behavior against shared fixtures. Its integration with two public MoonBit engines reports differences in syntax acceptance and match results, while caller-owned contracts let applications pin the behavior they rely on.

The MoonBit contract runner, adapters, fixtures, and reporting code are separate
from the publicly distributed `moonbitlang/regexp@0.3.5` and
`walkzzz/re-mbt@0.1.0` dependencies declared in `moon.mod`. The dependencies
supply the parsers and matchers. Public API integration does not establish
team membership, joint development or upstream
contributions. See the [project boundary](docs/positioning.md) and
[third-party notices](THIRD_PARTY_NOTICES.md) for the source and data boundaries.

Compile reuse and bounded fixture generation describe repository behavior;
they are not performance benchmarks. Arachne makes no claim to implement an
engine algorithm or guarantee matching performance.

## License

The Arachne source is Apache-2.0. See [LICENSE](LICENSE). Unicode category range data is separately covered by [UNICODE-LICENSE.txt](UNICODE-LICENSE.txt). The re-mbt backend is a separately licensed dependency; see [third-party notices](THIRD_PARTY_NOTICES.md).
