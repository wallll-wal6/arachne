# Project boundary

Arachne is a **test runner for regex behavior contracts**. It is not a regular
expression implementation. A backend parses and executes patterns; an Arachne
adapter exposes those results through one small observation type. Arachne runs
shared cases, checks optional expected results, compares adapters, and emits
deterministic findings.

## Competition disclosure

The 2026-10-13 remediation request identifies the September review concern:
Arachne must be described as a behavior-contract / compatibility-testing project
built on public MoonBit regex engines. Describing it as a self-developed
regular-expression engine does not match the current repository. The project is a
behavior-contract and regression-testing library; it does not parse regular
expressions or perform matching. The original September application and review
are not included here, so their exact wording must be confirmed by the applicant
before submission. All revisions and capability statements in this document are
**待韦安良复核 / pending Wei Anliang's review**; Codex's code inspection and local
checks do not record human approval.

The module declares `moonbitlang/regexp@0.3.5` and `walkzzz/re-mbt@0.1.0`
as direct dependencies in `moon.mod`.
Its adapters call those packages and translate their observed results into a
shared contract format. The matcher implementations remain in their upstream
repositories; Arachne neither vendors nor modifies them in this repository.
The `re-mbt` adapter is intentionally limited to ASCII patterns and inputs because the
upstream interface reports byte offsets.

The existing application identifies 韦安良 as the individual developer and
maintainer; that staffing and authorship disclosure is pending his review.
Upstream package maintainers are not Arachne team members merely
because Arachne depends on or calls their public packages. The repository
history and dependency declarations show integration through public packages;
they do not by themselves establish joint development or maintenance.

Arachne's contribution is the layer around those engines: reusable contract
cases, normalized observations, cross-engine comparisons, bounded Unicode
boundary fixtures, and stable findings for regression review. An observed
difference is reported for the application owner to evaluate; Arachne does
not claim that one engine is correct or that finite fixtures prove full
equivalence. Whether the applicant has contributed to either upstream project
is **待确认 / pending applicant confirmation**. Any confirmed contribution must
be listed separately with a verifiable link and scope; dependency declarations
and local Git identity are not evidence of such contributions.

First-party implementation is in `contract.mbt` and `rembt_adapter.mbt`, with
tests in `contract_test.mbt` and a runnable example in `examples/demo/main.mbt`.
The generator `tools/generate_unicode.mjs` produces `unicode_data.mbt` from
Unicode data: that generated range table is separately licensed data, not
an original matching algorithm. Source paths and dependency imports make
these responsibilities reviewable without attributing upstream work to Arachne.

### Code and dependency evidence

“First-party” identifies repository responsibilities, not proof of entirely
manual authorship or of the applicant's historical upstream contributions.

| Repository file / public dependency | Actual responsibility and boundary |
| --- | --- |
| `contract.mbt` | Contract cases, golden expectations, per-run compile reuse, baseline comparison and text findings; the official adapter calls `@regexp.compile` and `execute`, then reads match text/captures and computes the whole-match span |
| `rembt_adapter.mbt` | Reject non-ASCII patterns/inputs; call `@rembt.Perl::compile_pat` and `exec_opt`, then normalize `GroupT` capture text and offsets |
| `json_report.mbt` | Build and serialize JSON v1 observations/findings; does not match patterns |
| `tools/generate_unicode.mjs`, `unicode_data.mbt` | Generate Unicode 17.0 category ranges and bounded scalar fixtures; the range data is separately licensed, not an original regex algorithm |
| `contract_test.mbt`, `json_report_test.mbt`, `examples/migration-fixtures/*`, `tools/verify-demo.mjs` | Regression tests, shared real-engine demo fixtures, text/JSON snapshot and repeat-output checks |
| `moonbitlang/regexp@0.3.5` | Direct public module dependency; imported as `moonbitlang/regexp` in `moon.pkg`; parser and matcher come from [regexp.mbt](https://github.com/moonbitlang/regexp.mbt) |
| `walkzzz/re-mbt@0.1.0` | Separate direct public module dependency; `walkzzz/re-mbt/re` imported as `@rembt`; parser and matcher come from [re-mbt](https://github.com/walkzzz/re-mbt), an upstream port of ocaml-re; Arachne calls only its Perl frontend |

These are two public backend integrations, not Arachne implementations of their
engines. The locally resolved package manifests match the declared versions.
The re-mbt manifest also declares `moonbitlang/x@0.4.48` as its dependency;
Arachne's direct imports do not turn this transitive package into first-party work.
No Arachne contribution to either upstream or joint-maintenance relationship is
established by these imports. The upstream feature lists are not an Arachne
acceptance result, and Arachne does not claim to verify every frontend.

### Capability observations from this remediation run

On 2026-10-13, Codex ran default and JS `moon check --deny-warn`,
`moon test --deny-warn` (24 passed on each target), and `verify-demo.mjs` against
that run's checkout. Both demos matched their checked-in text/JSON snapshots
and repeated identically. See the [run record](initial-review-2026-10-13.md)
for exact commands and responsibility disclosure.

After the first documentation push, [remote CI run 38384999859](https://github.com/wallll-wal6/arachne/actions/runs/38384999859)
failed on default, JS and native before tests: its installed MoonBit no longer
supports the `moon.mod.json` manifest in `regexp@0.3.5`. The local checks used
MoonBit `0.1.20260827 (d0aaa07)`; they do not establish compatibility with the
CI toolchain or other releases. This second material correction records that
new evidence; it does not migrate an upstream manifest or change CI.

| Real fixture suite | Observed result | Limit of the evidence |
| --- | --- | --- |
| `shared-ascii` | Five cases, two backends, zero findings; includes whole-match spans, unmatched optional capture and empty capture | Only the selected ASCII patterns/inputs |
| `syntax-difference` | `^([a-z])\1$` with `aa`: official backend compiles and matches; re-mbt Perl rejects compilation; one compile-acceptance finding | This fixture at these versions, not a universal syntax-equivalence result |
| `adapter-domain` | Non-ASCII pattern yields compile rejection; non-ASCII input yields execution failure in the ASCII adapter; two findings | Explicit Arachne adapter restriction, not evidence that all re-mbt frontends cannot process such data |
| `unicode-official-only` | Six cases, official backend only, zero findings; BMP literal, supplementary-prefix span `[2, 3)`, and four `Lu` boundary cases | No cross-engine Unicode verification, no exhaustive category coverage |

The table records the earlier 18:31 review. The later
[19:48 example remediation](demo-review-2026-10-13.md) expands shared ASCII to
seven cases and official-only Unicode to eight, adding multiple captures,
empty whole matches, a supplementary literal, and a non-ASCII `Lu` match.
Default and JS now each pass 29 tests; the syntax/domain differences and
cross-engine Unicode limits remain the same. These implementation choices and
interpretations are Codex assistance, **待韦安良复核**.

The public adapters expose a single whole-match observation with numeric capture
text. They do not expose every match, named-group maps or capture-group spans.
The reported offset unit is zero-based MoonBit `StringView` code units
(UTF-16 in these checks), not byte offsets or Unicode scalar indices.

This makes the project useful when an application changes regex backends, wraps
a backend behind its own API, or needs to pin behavior across dependency
updates. A contract can state that a pattern must compile, match (or not match),
produce particular capture text, and return a match span in the agreed offset
unit. A run can then detect accidental changes before they reach an application.

## Boundary against regex libraries

The distinction is architectural and testable:

| Concern | Arachne | External regex dependencies |
| --- | --- | --- |
| Parse a pattern and implement syntax | No; delegated to an adapter | Yes |
| Execute matching | No; delegated to an adapter | Yes |
| Publish Arachne's reusable contract-case API | `ContractCase` and `run_contracts` | Supplies the backend called by an adapter |
| Ship an adapter to call the real `re-mbt` Perl frontend | Yes, with an explicit ASCII-only domain | It supplies the engine |
| Run the same caller-supplied cases through multiple real adapters | Yes; both bundled adapters are executed in tests | Each engine supplies its own observations |
| Compare compile, match, span, and capture observations | Yes | The documented package is the engine being observed |
| Produce Arachne's ordered findings for a CI log | Yes | Does not supply Arachne's report implementation |
| Generate bounded Unicode boundary inputs | Yes; current Unicode corpus is exercised with the official adapter, not the ASCII-only re-mbt adapter | The engine implements its own Unicode behavior |

This table describes the responsibilities exercised in this repository, not
an inventory of all upstream features or tests. Arachne exercises `re-mbt`
directly through a first-party Perl
adapter as well as the official `moonbitlang/regexp` adapter. The checked-in
integration contract includes ordinary shared patterns plus a backreference
case; the real engines disagree on compile acceptance for that case, and
Arachne reports the difference. This makes the migration-audit value
demonstrable in code rather than only a proposed extension point. See the
[re-mbt repository](https://github.com/walkzzz/re-mbt) and the
[official MoonBit regexp package](https://github.com/moonbitlang/regexp.mbt)
for the behavior supplied by those engines.

## What an adapter must do

An adapter compiles the supplied pattern with the backend under test and
converts its result to `MatchObservation`:

- matched text;
- start and end offsets in zero-based MoonBit `StringView` code units;
- capture text in numeric group order, excluding group zero;
- `None` for an optional capture that did not participate.

Adapters must report the backend's actual behavior. They must not rewrite
patterns or silently adjust results to make a comparison pass. If a backend
cannot provide the documented offset unit reliably, omit span assertions for
that integration or implement a separately documented observation contract.

## Scope and current limits

The owner defines fixture scope, required behavior, accepted differences, and
the final migration decision. AI assistance can implement documentation and
checks and record observations; it cannot turn a passing regression into
human acceptance. JSON v1 and the demo snapshots expose measured outcomes,
including expected differences and adapter refusals. Neither is a release,
publication, upstream contribution, or competition eligibility certificate.

- The bundled official adapter targets `moonbitlang/regexp@0.3.5` as declared
  in `moon.mod`; this does not establish compatibility with other releases.
- The bundled `re-mbt` adapter targets its Perl frontend and accepts ASCII-only
  patterns and inputs. That restriction follows from the byte-oriented upstream
  API; non-ASCII offsets are not silently converted or guessed.
- Other engines or versions are connected by caller-supplied adapters; Arachne
  does not bundle or vendor their matching code.
- The included Unicode corpus creates a bounded set of boundary-focused
  fixtures. It is not an exhaustive proof of Unicode behavior or engine
  equivalence.
- Arachne invokes adapters synchronously. It does not sandbox engines or
  enforce runtime timeouts.
- A compatibility report describes only the patterns and inputs actually
  tested. It is not a proof of equivalence for all possible inputs.
