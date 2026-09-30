# Arachne

Arachne is a MoonBit library for checking regular-expression behavior contracts across real regex backends. It runs the same pattern/input fixtures through caller-supplied engine adapters, compares compile acceptance, match presence, matched text, spans, and captures, then returns stable findings suitable for tests and CI.

Arachne does not implement a regex syntax, parser, or matching engine. Its first-party adapter calls the official [`moonbitlang/regexp`](https://github.com/moonbitlang/regexp.mbt) package. Applications can add adapters for another engine or for a newer engine version without copying either implementation.

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

For cross-engine checks, create another `EngineAdapter`. Its compile callback calls the candidate engine and returns a `CompiledMatcher`; the matcher callback converts that engine's result to `MatchObservation`. Normalize start and end to zero-based MoonBit `StringView` code-unit offsets before comparing. The [adapter contract](DESIGN.md#engine-adapter-contract) describes this boundary.

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

The test suite covers adapter normalization, cache reuse behavior, expected outcomes, compile and execution differences, capture/span drift, invalid suite configuration, and Unicode boundary fixture construction.

It also verifies that a golden span contract catches a supplementary-character
offset error, so adapters can pin the offset convention before comparing
backends.

## Scope

Arachne is a compatibility-test library above regex engines. It complements engine projects by exercising their observable behavior against shared fixtures; it is not an alternative matcher and does not claim that a MoonBit regex engine or compatibility checker is absent elsewhere.

## License

Apache-2.0. See [LICENSE](LICENSE). Unicode category range data is separately covered by [UNICODE-LICENSE.txt](UNICODE-LICENSE.txt).
