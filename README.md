# Arachne

Arachne is a MoonBit library for checking regular-expression behavior contracts across real regex backends. It runs the same pattern/input fixtures through caller-supplied engine adapters, compares compile acceptance, match presence, matched text, spans, and captures, then returns stable findings suitable for tests and CI.

Arachne does not implement a regex syntax, parser, or matching engine. Its first-party adapters call the official [`moonbitlang/regexp`](https://github.com/moonbitlang/regexp.mbt) package and the Perl frontend of [`walkzzz/re-mbt`](https://github.com/walkzzz/re-mbt). The re-mbt adapter is deliberately limited to ASCII patterns and inputs because that backend exposes byte-oriented APIs; it refuses non-ASCII data rather than guessing at offset conversion. Applications can add adapters for another engine or a newer engine version without copying either implementation.

This places Arachne above regex libraries: engines parse and match; Arachne
checks that their observable behavior satisfies shared contracts. The
[project boundary](docs/positioning.md) compares these responsibilities with
engine projects and documents the adapter requirements and limits.

## What it checks

- **Behavior drift:** compare a selected baseline against one or more candidate adapters.
- **Golden expectations:** assert match presence, whole-match text, capture text, and—when important—normalized whole-match spans.
- **Unicode boundary fixtures:** generate deterministic positive and adjacent-negative cases from Unicode 17.0 general-category ranges, with a caller-selected case cap.
- **Stable reports:** preserve fixture and adapter order, and format findings for build logs.
- **Compile reuse:** compile each distinct pattern once per adapter during a run, then reuse the compiled matcher for all matching cases.

When callers need to pin an offset as well as text, `expect_match_span` asserts
the adapter's normalized whole-match offsets. For example, with the bundled
adapter, matching `a` after the supplementary scalar `🦊` has span `[2, 3)` in
MoonBit `StringView` code units. This catches byte/scalar/code-unit conversion
mistakes at an adapter boundary.

This is a fixture-based compatibility check, not a proof that two engines are equivalent for every pattern or input. It does not impose execution timeouts or resource limits on an adapter; use engines and test inputs appropriate for the environment.

## Quick start

Add Arachne to a MoonBit project after publishing:

```sh
moon add wallll-wal6/arachne
```

Run a set of golden cases against the bundled official-engine adapter:

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

It executes one shared request-ID contract and one backreference probe. The
program prints the comparison report and exits normally so the finding can be
reviewed as a compatibility decision rather than treated as a test failure.

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

## Unicode category corpus

`unicode_category_cases(category="Lu", max_cases=128)` creates bounded test fixtures from the generated Unicode 17.0 table. Positive cases exercise the start/end of category ranges; adjacent negative cases exercise transitions out of the category. Surrogate code points are skipped because they are not Unicode scalar values. Unknown categories and invalid limits return an error.

The corpus is a boundary-focused regression aid, not an exhaustive test of every scalar value. Engines may ship different Unicode versions; report differences rather than assuming one version is universally correct. Generation steps and the Unicode data license are in [tools/README.md](tools/README.md) and [UNICODE-LICENSE.txt](UNICODE-LICENSE.txt).

## Development

```sh
moon update
moon check --deny-warn
moon test
moon build
moon info
```

The test suite covers adapter normalization, cache reuse behavior, expected outcomes, compile and execution differences, capture/span drift, invalid suite configuration, Unicode boundary fixture construction, and real comparisons between the two bundled backends.

It also verifies that a golden span contract catches a supplementary-character
offset error, so adapters can pin the offset convention before comparing
backends.

## Scope

Arachne is a compatibility-test library above regex engines. It complements engine projects by exercising their observable behavior against shared fixtures; it is not an alternative matcher. Its concrete integration with two independently implemented MoonBit engines reports differences in syntax acceptance and match results, while caller-owned contracts let applications pin the behavior they rely on.

## License

The Arachne source is Apache-2.0. See [LICENSE](LICENSE). Unicode category range data is separately covered by [UNICODE-LICENSE.txt](UNICODE-LICENSE.txt). The re-mbt backend is a separately licensed dependency; see [third-party notices](THIRD_PARTY_NOTICES.md).
