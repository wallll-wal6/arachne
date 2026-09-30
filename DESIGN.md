# Design

## Responsibility boundary

Arachne owns fixture validation, adapter coordination, result normalization, baseline comparison, Unicode boundary-case generation, and report formatting. A backend adapter owns pattern compilation and matching. This separation keeps parser and matcher behavior in the actual engine under test.

`run_contracts` validates that engine IDs and case IDs are non-empty and unique and that the requested baseline exists. It then compiles each distinct pattern once per adapter, executes the relevant cases, checks optional golden expectations, and compares each candidate with the baseline. The resulting rows and findings preserve caller-specified order so CI output stays reproducible.

## Engine adapter contract

An `EngineAdapter` contains a stable ID and a compile function. A successful compile returns a `CompiledMatcher` with an observation function. The adapter translates a successful engine result into:

- whole matched text;
- zero-based start and end offsets measured in MoonBit `StringView` code units;
- capture values in numeric group order, excluding group zero; `None` represents an unmatched optional group.

Different engines can have different anchoring, greediness, Unicode, and capture semantics. The adapter must represent what the engine actually did; it must not silently rewrite patterns or normalize away meaningful differences. If a backend cannot provide an offset reliably, the adapter should use a separate contract that does not claim span comparability rather than guess.

The bundled `moonbit_regexp_adapter` calls the official `moonbitlang/regexp` runtime API. The `rembt_ascii_perl_adapter` calls the real `walkzzz/re-mbt` Perl frontend and is intentionally restricted to ASCII patterns and inputs: for ASCII only, the backend's byte offsets equal Arachne's documented string-view code-unit offsets. Non-ASCII values are rejected by this adapter instead of being truncated or misreported. Other backends can be wrapped by constructing `EngineAdapter` and `CompiledMatcher` values. Arachne itself does not parse or execute regex syntax.

## Findings

For each candidate engine, Arachne reports differences in compile acceptance, execution success, match presence, matched text, whole-match span, and capture values. Optional expected outcomes are checked against every engine independently. Findings identify the case and engine, and a stable text formatter supports build logs.

Matching compile errors or execution errors on both engines are not treated as semantic differences; the suite can still report a failed golden expectation. Error details remain adapter-provided strings. The integration suite runs common ASCII contracts through both real engines and includes a backreference case: the official regexp backend accepts and matches it, while re-mbt's Perl frontend rejects it. Arachne reports that as a compile-acceptance difference. This demonstrates a concrete migration/release-audit use case; it does not imply either backend is wrong. No claim is made that a finite fixture corpus proves equivalence beyond the tested inputs.

## Unicode boundary corpus

The generated Unicode 17.0 tables store sorted, inclusive general-category ranges. `unicode_category_cases` turns each selected range boundary into a positive scalar sample and, where valid, tests the adjacent scalar outside the category. It skips surrogate code points and stops at the requested case count. This targets category transitions without running more than a million values by default.

The corpus is an oracle for constructing regression inputs, not a matching implementation or a universal statement about every backend's Unicode release. The suite deliberately reports a backend difference when its Unicode data does not agree with this pinned corpus; maintainers choose whether that difference is expected for their application.

## Limits

Arachne does not provide a timeout, cancellation mechanism, parser budget, or execution sandbox. Adapter functions run synchronously. A backtracking engine may spend substantial time on a pathological case before Arachne can produce a report. Keep fixtures bounded and select a backend appropriate to the input trust model.
