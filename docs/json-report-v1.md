# JSON report v1

`CompatibilityReport::format_json()` emits a compact JSON document.
`CompatibilityReport::json_v1()` returns an independent `ReportJsonV1` snapshot
whose `stringify()` method emits the same schema. Formatting never invokes an
adapter. The existing text summary and findings remain available.

The 21:32 toolchain compatibility change uses explicit `ToJson` calls and
five explicit method extensions (also shown in the generated interface).
It preserves the v1 fields, values, nulls, lexical key order and snapshots;
there is no schema version increment. The `json` package import is test-only.
See the [current acceptance record](acceptance-2026-10-13.md) for checked
toolchains and the remaining formatting limitation.

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

All listed keys are required on emitted objects. `baseline_id`, `case_id`,
`engine_id`, `status`, `kind`, `detail`, and matched `text` are strings.
`case_count` and `engine_count` are nonnegative integers; `runs`, `findings`,
and `captures` are arrays (including empty arrays). `error` is a string or
`null`; `observation`, `baseline`, and `actual` are objects or `null`.
For reports from `run_contracts`, each case has one run per engine, so
`runs.length == case_count * engine_count`. Publicly constructed report
objects can contain incomplete context; formatting does not revalidate them.

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

## Version and compatibility policy

`schema_version: 1` is the report wire contract, independent of the module
version in `moon.mod`. A consumer must reject unsupported versions explicitly
rather than interpreting them as v1. Within v1, producers preserve required
keys, types, null semantics, status/kind labels, array ordering, and offset
units. A change to those meanings, removal of a key, or a new status/kind label
requires a new schema version. Additive optional metadata may be introduced
without changing these meanings; consumers should ignore unknown object keys.
JSON object key order, indentation, and escape spelling are not contractual:
parse JSON before comparing it. Array order and string values are contractual.

The current report formatter explicitly sorts object keys lexicographically
at every level and emits compact JSON. It delegates string escaping and scalar
encoding to the core JSON library, preserving all control characters, quotes,
backslashes, and Unicode values on a parse round trip. Given the same report
values and toolchain, repeated formatting is byte-identical; deterministic
adapters also produce identical reports on repeated contract runs. This is not
a canonical JSON standard or a guarantee of identical adapter error messages
and escape spellings across dependency/toolchain upgrades. `ToJson::to_json`
exposes the same model values; callers serializing that value themselves choose
their own formatting.

Diagnostic text comes from the comparison layer and the selected adapters.
Use `kind` and `status` for program logic; do not parse prose or assume error
messages remain unchanged across dependency upgrades. Pin dependencies and
fixtures when reproducing a recorded result. Formatting a report adds no
engine/version provenance, original inputs, human approval, or execution
limits; save those separately when needed.

## Copyable demo consumption

From the repository root, `moon run examples/demo-json` prints one JSON object
with `demo_version: 1` and `suites: [{name, report}, ...]`. Each `report` follows
the contract above; the demo version describes only this example envelope.
The following commands parse the actual output and print suite decisions:

```sh
moon run examples/demo-json > demo-report.json
node --input-type=module -e 'import fs from "node:fs"; const d = JSON.parse(fs.readFileSync("demo-report.json", "utf8").replace(/^\uFEFF/, "")); if (d.demo_version !== 1) throw Error("unsupported demo version"); for (const s of d.suites) { if (s.report.schema_version !== 1) throw Error("unsupported report version"); console.log(s.name, s.report.compatible, s.report.findings.length); }'
```

Use a UTF-8 shell for redirection (PowerShell 7 or a POSIX shell); older Windows
PowerShell may write UTF-16 instead. The BOM removal handles a UTF-8 BOM only.
`node tools/verify-demo.mjs` avoids shell redirection and checks the text/JSON
snapshots directly. The intentional syntax/domain findings are evidence for
owner review, not a successful migration decision.
