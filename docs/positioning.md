# Arachne's scope

MoonBit users already have multiple regex options, including a runtime-compilable engine with Unicode properties. Arachne should therefore be chosen for its specific matching contract and published resource limits, not simply because it is written in MoonBit or supports Unicode. This is a scope guide, not a claim that Arachne is the default choice for every application.

## Where it fits

- **Explicit search contract:** `find` selects the earliest start and then the longest end at that start. For example, `=|==` finds `==` at the beginning of `==>`; branch order does not shorten the result.
- **Application-specific compile budgets:** `CompileLimits` lets a caller lower pattern length, nesting, capture count, repetition count, NFA state count, RegexSet size, and aggregate states below the published implementation ceilings. This is useful when an application accepts patterns from configuration and needs tighter per-tenant limits.
- **MoonBit string workflow:** patterns and inputs are MoonBit strings; scanning advances by Unicode scalar values and returned spans use UTF-16 code-unit offsets for MoonBit string slicing. Unicode 17.0 General_Category ranges are included.
- **Text transformations:** one compiled pattern supports captures, replacement, splitting, membership checks, and matching indexes from a `RegexSet`.

## Relationship to other options

The table records project scope, not a ranking. Re-check upstream documentation before using this comparison in a release or submission; syntax and feature support can change.

| Option | Documented emphasis | Arachne's relationship |
| --- | --- | --- |
| MoonBit regex literals (`re"..."`) | Regex syntax integrated into MoonBit source, compiled and checked by the language toolchain; includes non-greedy quantifiers, named groups, scoped flags, and `lexmatch` with a longest-prefix mode for anchored cases. | Prefer these for statically written patterns and language-integrated matching. Arachne also compiles runtime pattern strings and supports unanchored leftmost-longest search with application-lowered budgets. |
| [`moonbitlang/regexp`](https://mooncakes.io/docs/moonbitlang/regexp@0.3.5) | Runtime `compile(StringView)` API, Unicode general-category properties, named groups, and a documented leftmost-first execution strategy. Its package page marks the API as alpha. | This is the closest general-purpose alternative. Prefer it when its feature set and first-match contract fit. Arachne's distinct policy here is allowing callers to lower its compile budgets for individual applications and rule sets. |
| [`walkzzz/re-mbt`](https://github.com/walkzzz/re-mbt) | Its project page describes an OCaml `re` port, six syntax frontends (Perl, PCRE, POSIX, Emacs, Glob, Str), byte-oriented input, and derivative-based lazy DFA. The POSIX frontend is part of the project scope; upstream OCaml `Re.Posix` defines compilation through `Core.longest`. | Prefer it when OCaml `re` compatibility or those dialects are the requirement. Arachne's separate fit is MoonBit `String` processing and caller-lowered compile budgets; leftmost-longest alone is not claimed as a unique feature. |
| Arachne | MoonBit `String` API; Unicode scalar scanning with UTF-16 public spans; leftmost-longest selection; caller-lowered compile budgets; `RegexSet`, replacement, and splitting. | A focused option when the application needs these behaviors together; the individual features are not all unique to Arachne. |

## Why this is a separate project

The overlap with `walkzzz/re-mbt` is real, and its Mooncakes page identifies a published `0.1.0` package with six frontends and a byte-oriented API. Its stated goal is to port OCaml `re` faithfully; changing that API to scan MoonBit `String` values by Unicode scalar and return UTF-16 code-unit offsets would change its input and position contract rather than add an OCaml-compatible feature. Arachne keeps that alternative intact and implements a separate contract for MoonBit callers that need `String` slicing offsets, Unicode category matching, and application-lowered compile budgets together. A conversion adapter is possible, but it does not provide those behaviors as one native `String` API.

This rationale is deliberately narrow: compile budgets alone do not justify another general-purpose regex engine, and applications that do not need this combined contract should choose an existing engine. The official [`moonbitlang/regexp` package](https://mooncakes.io/docs/moonbitlang/regexp) is a runtime-compiled option with Unicode properties and a documented leftmost-first strategy; MoonBit regex literals are the better fit for static, compile-time patterns. Arachne does not claim the alternatives are unusable or inferior.

The comparison summarizes the linked project pages and MoonBit language documentation as checked on 2026-09-30; release details may change. The OCaml `Re.Posix` behavior is documented in its [POSIX API reference](https://ocaml.org/p/re/latest/doc/re.posix/Re_posix/index.html). Arachne does not claim to be faster or more feature-complete than these options. No comparative benchmark has been run, so this comparison is about documented behavior and intended fit only.

## Example workloads

Extract a username that may contain letters and digits from different writing systems:

```moon
let pattern = @arachne.Regex::compile("user=([\\p{L}\\p{M}\\p{N}_]+)")
```

Choose the longest operator at the current leftmost position:

```moon
let operator = @arachne.Regex::compile("=|==")
```

These examples show the intended application scope. They do not imply support for a full programming-language lexer, every Unicode grapheme cluster, or every regex dialect.
