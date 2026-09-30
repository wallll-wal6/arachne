# Arachne's scope

MoonBit users already have multiple regex options, including a runtime-compilable engine with Unicode properties. Arachne should therefore be chosen for its specific matching contract and published resource limits, not simply because it is written in MoonBit or supports Unicode. This is a scope guide, not a claim that Arachne is the default choice for every application.

## Where it fits

- **Explicit search contract:** `find` selects the earliest start and then the longest end at that start. For example, `=|==` finds `==` at the beginning of `==>`; branch order does not shorten the result.
- **Published compile budgets:** pattern length, nesting, capture count, repetition count, NFA state count, and RegexSet aggregate size have explicit documented limits. This is useful when an application accepts patterns from configuration or other inputs and wants a clear rejection boundary.
- **MoonBit string workflow:** patterns and inputs are MoonBit strings; scanning advances by Unicode scalar values and returned spans use UTF-16 code-unit offsets for MoonBit string slicing. Unicode 17.0 General_Category ranges are included.
- **Text transformations:** one compiled pattern supports captures, replacement, splitting, membership checks, and matching indexes from a `RegexSet`.

## Relationship to other options

The table records project scope, not a ranking. Re-check upstream documentation before using this comparison in a release or submission; syntax and feature support can change.

| Option | Documented emphasis | Arachne's relationship |
| --- | --- | --- |
| MoonBit regex literals (`re"..."`) | Regex syntax integrated into MoonBit source, compiled and checked by the language toolchain; includes syntax such as non-greedy quantifiers, named groups, scoped flags, and `lexmatch`. | Prefer these for statically written patterns and language-integrated matching. Arachne is useful when callers need to compile pattern strings at runtime and rely on its leftmost-longest API and explicit budgets. |
| [`moonbitlang/regexp`](https://mooncakes.io/docs/moonbitlang/regexp@0.3.5) | Runtime `compile(StringView)` API, Unicode general-category properties, named groups, and a documented leftmost-first execution strategy. Its package page marks the API as alpha. | This is the closest general-purpose alternative. Prefer it when its feature set and first-match contract fit. Arachne serves callers who specifically want leftmost-longest results, explicit pattern/state limits, and its `RegexSet` / replacement / split API. |
| [`walkzzz/re-mbt`](https://github.com/walkzzz/re-mbt) | Its project page describes an OCaml `re` port, six syntax frontends (Perl, PCRE, POSIX, Emacs, Glob, Str), byte-oriented input, and derivative-based lazy DFA. | Prefer it when OCaml `re` compatibility or those dialects are the requirement. Arachne focuses on one MoonBit-string API and leftmost-longest search rather than dialect compatibility. |
| Arachne | MoonBit `String` API; Unicode scalar scanning with UTF-16 public spans; leftmost-longest selection; explicit compile budgets; `RegexSet`, replacement, and splitting. | A focused option for callers whose matching semantics and resource boundary are requirements, not a broad replacement for all MoonBit regex tools. |

The comparison summarizes the linked project pages and MoonBit language documentation as checked on 2026-09-30; release details may change. Arachne does not claim to be faster or more feature-complete than these options. No comparative benchmark has been run, so this comparison is about documented behavior and intended fit only.

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
