# Reproducible backend migration example

From the repository root, with MoonBit on PATH:

```sh
moon update
moon check --deny-warn
moon run examples/demo
moon run examples/demo-json
node tools/verify-demo.mjs
```

`moon.mod` pins `moonbitlang/regexp@0.3.5` and `walkzzz/re-mbt@0.1.0`.
`../migration-fixtures/fixtures.mbt` supplies every case to the existing
`run_contracts`, adapters, Unicode generator, and report formatters. No mock
engine, parser, matcher, or alternative comparison policy is introduced.

| Suite | Scope | Expected observation |
| --- | --- | --- |
| `shared-ascii` | Both real adapters; five application contracts | Request-ID match and rejection, search span, unmatched optional capture, empty capture; zero findings |
| `syntax-difference` | Both real adapters; one existing probe | `^([a-z])\1$` on `aa`: regexp matches, re-mbt Perl rejects; one compile-acceptance finding |
| `adapter-domain` | Both adapters; two boundary probes | Literal `猫` pattern is rejected at compile time by the ASCII adapter; ASCII `(a)` on `🦊a` is refused at execution time; two findings |
| `unicode-official-only` | Official adapter; six cases | BMP literal `猫`, supplementary-prefix span, and four generated `Lu` boundaries: `A`, `@`, `Z`, `[`; zero findings |

The text output includes every engine outcome, so matching common cases,
non-matches, captures, spans, and rejection reasons are observable.
An unmatched capture is `None`; a participating empty capture is `Some("")`.
The probe suites omit shared golden expectations: their findings preserve
observations for review without requiring both engines to accept a feature.

`expected.txt` pins all text observations; `expected.json` pins the equivalent
structured output. The JSON envelope has `demo_version: 1` and named `suites`,
each containing the existing report v1 object. It distinguishes unmatched
captures (`null`) from participating empty captures (`""`).
`node tools/verify-demo.mjs` needs Node.js 22+ and runs both executables, compares
text after newline normalization, and compares parsed JSON without depending
on object key order. Any unexpected difference fails the regression with a
nonzero exit, even though the demo itself displays intentional findings and
exits normally. The command never rewrites snapshots. To verify another
execution target, pass `js` or `native` as its final argument.

When dependencies or fixtures change, inspect both engine outcomes and discuss
any difference with the application owner before editing the expected files.
Pinned dependencies reproduce these particular observations; they are not
a general guarantee about all releases or inputs.

## Adapter and Unicode limits

`rembt_ascii_perl_adapter` accepts only ASCII **pattern strings and input
strings** (all characters U+0000 through U+007F). This is the first-party
adapter's domain, not a claim that the entire upstream re-mbt project lacks
Unicode capabilities. Non-ASCII patterns return `CompileRejected`; non-ASCII
inputs to a successfully compiled pattern return `ExecutionFailed`. Their
`adapter-domain:` messages explain the guard; they do not measure an upstream
Unicode disagreement. Even an ASCII spelling such as `\p{Lu}` is still
subject to the Perl frontend's syntax support and does not bypass the input
guard.

All observed spans are zero-based, end-exclusive MoonBit `StringView`
**UTF-16 code-unit** offsets. For accepted ASCII, re-mbt's byte offsets equal
these code-unit offsets. On `🦊a`, the official adapter reports `a` at `[2, 3)`:
the supplementary scalar occupies two code units. UTF-8 byte offsets would be
`[4, 5)` and scalar offsets `[1, 2)`. The ASCII adapter refuses this input
instead of performing a speculative conversion.

The Unicode suite only exercises the official adapter. Its two explicit
non-ASCII fixtures and first four `Lu` boundary samples are a small regression
sample from the existing Unicode 17.0 data. The generated four samples happen
to be ASCII; they do not cover all categories, scripts, or supplementary
scalars, prove engine equivalence, or compare re-mbt Unicode matching.

## Human decisions and AI assistance

The application owner chooses required behavior, permitted differences, and
whether a migration is acceptable. This example retains the existing
backreference interpretation and comparison rules. Codex assists with fixture
implementation, documentation, and execution of regression checks; generated
changes and snapshots still require human review. A normal demo exit displays
the report, including expected differences. It does not approve migration or
declare either engine wrong. This run does not claim completed human review.

## Local validation, 2026-10-13

Toolchain: `moon 0.1.20260827 (d0aaa07)`, `moonc v0.10.11+6ff76a5f9`,
`moonrun 0.1.20260827`; Node.js `v24.19.0`.

- First implementation commit, exported without other working-tree changes:
  `moon update`, `moon check --deny-warn`, all 18 existing tests, and text demo
  passed.
- Final implementation: `moon check --deny-warn`, `moon test --deny-warn`, and
  `moon test --target js --deny-warn` passed (22 tests per target).
- Both executables matched the checked-in text and JSON via
  `node tools/verify-demo.mjs` (default wasm) and `node tools/verify-demo.mjs js`.
- In a temporary export of the staged files, extra text and an incorrect
  Unicode start offset each made the regression fail; restored files passed.
- `moon build`, `moon fmt`, `moon info`, and whitespace checks passed.
- `moon test --target native --deny-warn` could not build: no C compiler
  (`cl`, `cc`, `gcc`, or `clang`) was available. Native remains unverified locally.
- Explicit `wasm-gc` could not build with this installation's missing target
  standard library. The regression's default follows `moon run` rather than
  assuming a particular target.

Codex generated and checked the result files against the observed outcomes.
Human acceptance of migration behavior remains pending; CI configuration is
included, but remote CI has not been run and these commits are not pushed.
