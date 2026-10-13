# JSON report v1

`CompatibilityReport::format_json()` emits a compact JSON document.
`CompatibilityReport::json_v1()` returns an independent `ReportJsonV1` snapshot
whose `stringify()` method emits the same schema. Formatting never invokes an
adapter. The existing text summary and findings remain available.

Consumers must check the integer `schema_version` before interpreting fields.
Version 1 uses the following field structure; optional values are explicit
`null`, never omitted. Counts and offsets are JSON integers, and `compatible`
is a JSON boolean with the same meaning as `is_compatible()`.

| Object | Fields |
| --- | --- |
| Report | `schema_version`, `baseline_id`, `case_count`, `engine_count`, `compatible`, `runs`, `findings` |
| Run | `case_id`, `engine_id`, `outcome` |
| Outcome | `status`, `error`, `observation` |
| Observation | `text`, `start`, `end`, `captures` |
| Finding | `case_id`, `engine_id`, `kind`, `detail`, `baseline`, `actual` |

Outcome status values are `compile_rejected`, `execution_failed`, `no_match`,
and `matched`. Only the first two have a string `error`; only `matched` has an
observation object. All other slots are `null`. Error strings are preserved
exactly as supplied by adapters, including empty strings.

Observation offsets are zero-based, end-exclusive MoonBit `StringView`
UTF-16 code-unit offsets. Captures exclude group zero, retain numeric group order,
and distinguish an unmatched group (`null`) from an empty capture (`""`).

Finding kinds reuse the text report's stable labels: `compile-acceptance`,
`execution`, `match-presence`, `matched-text`, `match-span`, `captures`, and
`expectation`. `detail` preserves the existing diagnostic. `baseline` and
`actual` contain full outcome objects for this case's baseline and flagged
engine. A missing run in a manually constructed report produces `null` rather
than inventing an observation. For `expectation` findings, these are run
context; the baseline is not a golden expected value. Golden expectation
values and original pattern/input fixtures are not stored in the existing
report and are not added by this formatter.

Runs and findings retain the existing caller-controlled order. There are no
timestamps, environment metadata, dependency probes, or additional matching
steps. Both engines failing can still yield `compatible: true` when there is
no comparison or golden-expectation finding; the run outcomes retain those
errors for consumers to inspect.

Invalid suite configuration still returns `Err(ContractError)` before a
report exists. This schema serializes successful report objects, including
compile/execution failures recorded within them.
