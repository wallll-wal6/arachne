# Arachne

A small regular-expression engine written in pure MoonBit. It parses a pattern into an AST, compiles the tree into a Thompson NFA, and matches with a bounded lazy DFA cache of NFA state subsets.

## Current syntax

| Pattern form | Meaning |
| --- | --- |
| `a` | Literal character |
| `.` | Any single character |
| `ab` | Concatenation |
| `a|b` | Alternation |
| `(ab)` | Numbered capture group |
| `a*`, `a+`, `a?` | Zero-or-more, one-or-more, optional |
| `[abc]`, `[a-z]`, `[^0-9]` | Character class, inclusive range, negated class |
| `a{2}`, `a{2,}`, `a{2,4}` | Exact, lower-bounded, bounded repetition |
| `^`, `$` | Beginning and end of the input |
| `\.` | Escaped literal metacharacter |
| `\d`, `\w`, `\s` | ASCII digit, word, and whitespace categories |
| `\D`, `\W`, `\S` | Complements of the shorthand categories |
| `\p{L}`, `\p{Lu}`, `\p{N}` | Unicode general categories and category groups |
| `\P{M}` | Complement of a Unicode general category |
| `\n`, `\r`, `\t`, `\v` | Line-feed, carriage-return, tab, and vertical tab |
| `\b`, `\B` | ASCII word boundary and its complement |

Inside a class, `\` escapes the next character; escape `]`, `-`, `^`, or `\` to use them literally. Shorthand categories and Unicode properties can also appear in classes, but cannot be range endpoints. A `-` at the end of a class is literal. Empty classes and descending ranges are errors. Empty groups and empty alternation branches are supported. Repetition counts are limited to 1000 and the upper bound must be at least the lower bound. Patterns are limited to 1024 Unicode scalar values, 128 nested groups, 256 capture groups, and 65,536 compiled NFA states. A `RegexSet` accepts up to 1024 patterns and 65,536 aggregate NFA states. These limits bound compilation and set storage. Captures are numbered by opening-parenthesis order. Backreferences are not implemented.

## Use

Add the module to a MoonBit project, then compile and run:

```moon
match @arachne.Regex::compile("^(ab|cd)+$") {
  Ok(regex) => regex.full_match("abcd")
  Err(_) => false
}
```

The public API provides `Regex::compile`, `Regex::full_match`, `Regex::find`, `Regex::find_all`, `Regex::captures`, `Regex::replace_first`, `Regex::replace_all`, `Regex::replace_n`, `Regex::split`, `Regex::splitn`, `Regex::contains`, and `Regex::pattern`. `RegexSet` compiles multiple rules and returns all matching rule indexes, useful for categorizing log lines or routing requests. `Match::text` extracts a match span, `Captures::group` returns a numbered capture, and `Captures::text` extracts its text. Group zero is the complete match; optional groups that did not participate return `None`. Repeated groups report their last participating iteration. `parse` is public when callers need the syntax tree directly. `find_all` and replacement use non-overlapping leftmost-longest matches. Empty matches advance by one input character; `split` retains empty fields at boundaries. Replacement strings support `$0` through `$n`, `${n}`, and `$$`.

`find` returns the leftmost match and, at that start position, the longest possible end position. Empty matches are valid. `^` and `$` assert the boundaries of the entire input, including when searching with `find`; escape them to match literal characters. Dot matches any scalar value, including line breaks. Parsing and matching advance by Unicode scalar value, so a supplementary character such as an emoji is one regex atom. Public match offsets and substring extraction use MoonBit's UTF-16 code-unit offsets. `\p{...}` supports all Unicode General_Category abbreviations, their documented long names, and the aggregate groups `L`, `M`, `N`, `P`, `S`, `Z`, and `C`; `\P{...}` matches their complement. The generated tables target Unicode 17.0. `\w`, `\b`, and related shorthand categories use ASCII word characters. Non-capturing and named groups, lazy quantifiers, look-around, inline flags, case folding, and backreferences are not implemented.

## Development

This is a MoonBit module managed by `moon.mod`. Build it with:

```sh
moon check
```

Run the suite with `moon test`. The source is kept at the package root so the parser, AST, and NFA engine can be read together. See [DESIGN.md](DESIGN.md) for the execution model and its limits.

The Unicode category tables in [unicode_data.mbt](unicode_data.mbt) are generated from Unicode 17.0 `UnicodeData.txt`; regeneration steps are in [tools/README.md](tools/README.md). The upstream data license is included in [UNICODE-LICENSE.txt](UNICODE-LICENSE.txt).

## License

Apache-2.0. See [LICENSE](LICENSE).
