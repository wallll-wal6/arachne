# Project boundary

**Arachne is a MoonBit regex behavior-contract / compatibility-testing tool.**
It runs shared pattern/input fixtures through backend adapters, checks optional
golden expectations, compares a selected baseline with candidates, and emits
text and JSON findings. It also contains a bounded first-party ASCII reference
parser and Thompson NFA backend; two additional backends come from public
dependencies.

## Repository and dependency responsibilities

| Source / dependency | Responsibility |
| --- | --- |
| `contract.mbt` | Contract cases, expectations, configuration validation, per-adapter compile reuse, baseline comparison, text findings and the official backend adapter |
| `rembt_adapter.mbt` | ASCII domain guards, calls to `@rembt.Perl::compile_pat` / `exec_opt`, and normalization of `GroupT` text and offsets |
| `reference_engine.mbt` | ASCII-subset recursive-descent parser, Thompson NFA construction, epsilon-closure state-set execution, and explicit resource/syntax boundaries |
| `json_report.mbt` | JSON v1 report projection and serialization |
| `unicode_data.mbt` | Category ranges labelled Unicode 17.0 and bounded boundary-fixture construction; no regex parsing or matching |
| `tools/generate_unicode.mjs` | Read `UnicodeData.txt` and generate category range tables |
| Tests, `examples/migration-fixtures`, `tools/verify-demo.mjs` | Contract regressions, shared fixtures, text/JSON snapshot and repeat-output checks |
| `moonbitlang/regexp@0.3.5` | Direct dependency in `moon.mod`, imported in `moon.pkg`; the official adapter calls its `compile` / `execute` APIs; the dependency supplies its parser and matcher |
| `walkzzz/re-mbt@0.1.0` | Direct dependency in `moon.mod`; `walkzzz/re-mbt/re` is imported as `@rembt`; the dependency supplies its parser and matcher; Arachne calls only its Perl frontend |

The downloaded re-mbt manifest also declares `moonbitlang/x@0.4.48` as a
transitive dependency. Neither direct nor transitive dependencies are
Arachne engine implementations. The engine sources are distributed in their
own packages; this repository does not vendor them. See the
[official regexp source](https://github.com/moonbitlang/regexp.mbt),
[re-mbt source](https://github.com/walkzzz/re-mbt) and
[third-party notices](../THIRD_PARTY_NOTICES.md).

Arachne's owner and sole team member is Wei Anliang (韦安良).
The maintainers of `moonbitlang/regexp` and
`walkzzz/re-mbt` are not Arachne team members. Both engines are public
dependencies; this application claims no joint development, joint maintenance
or upstream contributions. Repository responsibilities do not establish
entirely manual authorship.

## Adapter contract

An adapter compiles with the backend under test and translates its actual
result into `MatchObservation`: whole matched text, zero-based end-exclusive
MoonBit `StringView` code-unit offsets, and numeric capture text excluding
group zero. An unmatched optional capture is `None`; a participating empty
capture is `Some("")`. The bundled adapters return one whole-match observation,
not all matches, named-group maps or capture-group spans.

The official adapter derives the start offset from `result.before().length()`
and the end from the whole match's length. In the checked-in UTF-16 examples,
`a` in `🦊a` has span `[2, 3)`.

The re-mbt adapter only accepts ASCII pattern and input strings. Its backend
APIs consume bytes and report byte offsets; those offsets equal the documented
code-unit offsets for ASCII. Non-ASCII patterns return `CompileRejected`, and
non-ASCII inputs return `ExecutionFailed`. These are Arachne adapter refusals,
not conclusions about every upstream frontend's Unicode capabilities.

Adapters must not rewrite patterns or adjust observations to hide meaningful
differences. A backend that cannot reliably supply the documented offsets needs
a separately documented observation contract.

## Reproducible evidence

The [migration example](../examples/demo/README.md) uses both real backends.
Its checked-in expected reports describe these selected fixtures:

| Suite | Cases / backends / findings | Evidence boundary |
| --- | --- | --- |
| `shared-ascii` | 7 / 2 / 0 | Selected matches, non-match, spans, optional / empty / multiple captures and empty whole match |
| `syntax-difference` | 1 / 2 / 1 | `^([a-z])\1$` on `aa`: regexp accepts and matches; re-mbt Perl rejects compilation |
| `adapter-domain` | 2 / 2 / 2 | Explicit non-ASCII pattern / input refusals in the ASCII adapter |
| `unicode-official-only` | 8 / 1 / 0 | Official-only literals, supplementary spans, non-ASCII `Lu` match and four generated boundary cases |

The example verifier executes both demos and checks snapshots and repeated
output. These fixtures do not prove equivalence for every pattern or input,
complete syntax support or cross-engine Unicode compatibility.

## Scope and ownership of decisions

Arachne invokes adapters synchronously, without execution timeouts or a
sandbox. The reference NFA merges ambiguous paths into state sets, while
unanchored search currently tries candidate start positions in order; runtime
can therefore grow quadratically with input length for some patterns. Pattern
and input limits bound that backend's accepted workload. Compile reuse is an
implementation behavior, not a benchmark or a performance guarantee. No
performance claim is made for the public dependency adapters.

The range table is labelled Unicode 17.0. The generator reads an externally
supplied `UnicodeData.txt` and emits that label; confirming the original input
version requires its provenance record. The bounded corpus constructs
regression inputs; it is not a matching implementation or proof of complete
Unicode coverage.

`compatible: true` means there were no findings in that fixture run. Inspect
outcomes as well: matching failures on both sides may yield no comparison
finding. The owner defines required behavior, permitted differences and the
final migration decision. The report does not record human approval.

For the project’s team, AI assistance and data-provenance notes, see the
[disclosure](2026-10-disclosure.md). The [October changes](2026-10-contribution-scope.md)
summarize the existing project scope and current improvements.
