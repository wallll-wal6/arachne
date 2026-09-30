# Project boundary

Arachne is a **test runner for regex behavior contracts**. It is not a regular
expression implementation. A backend parses and executes patterns; an Arachne
adapter exposes those results through one small observation type. Arachne runs
shared cases, checks optional expected results, compares adapters, and emits
deterministic findings.

This makes the project useful when an application changes regex backends, wraps
a backend behind its own API, or needs to pin behavior across dependency
updates. A contract can state that a pattern must compile, match (or not match),
produce particular capture text, and return a match span in the agreed offset
unit. A run can then detect accidental changes before they reach an application.

## Boundary against regex libraries

The distinction is architectural and testable:

| Concern | Arachne | A regex engine such as `walkzzz/re-mbt` |
| --- | --- | --- |
| Parse a pattern and implement syntax | No; delegated to an adapter | Yes |
| Execute matching | No; delegated to an adapter | Yes |
| Publish a caller-facing API for reusable contract cases | Yes | Not documented in its public README/API |
| Ship an adapter to call the real `re-mbt` Perl frontend | Yes, with an explicit ASCII-only domain | It supplies the engine |
| Run the same caller-supplied cases through multiple real adapters | Yes; both bundled adapters are executed in tests | Not documented as a public capability |
| Compare compile, match, span, and capture observations | Yes | The documented package is the engine being observed |
| Produce ordered findings for a CI log | Yes | Not documented as a package feature |
| Generate bounded Unicode boundary inputs | Yes; current Unicode corpus is exercised with the official adapter, not the ASCII-only re-mbt adapter | The engine implements its own Unicode behavior |

The `walkzzz/re-mbt` public project describes itself as an OCaml `re` port and
documents parsing, automata, matching, search, replacement, six syntax
frontends, and an extensive engine test suite. Those are engine capabilities;
Arachne does not claim those tests do not exist and does not reimplement those
facilities. Arachne now exercises `re-mbt` directly through a first-party Perl
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

- The bundled adapter targets `moonbitlang/regexp`.
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
