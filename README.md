# Arachne

A small regular-expression engine written in pure MoonBit. It parses a pattern into an AST, compiles the tree into a Thompson NFA, and matches with a bounded lazy DFA cache of NFA state subsets.

## Current syntax

| Pattern form | Meaning |
| --- | --- |
| `a` | Literal character |
| `.` | Any single character |
| `ab` | Concatenation |
| `a|b` | Alternation |
| `(ab)` | Grouping |
| `a*`, `a+`, `a?` | Zero-or-more, one-or-more, optional |
| `[abc]`, `[a-z]`, `[^0-9]` | Character class, inclusive range, negated class |
| `a{2}`, `a{2,}`, `a{2,4}` | Exact, lower-bounded, bounded repetition |
| `^`, `$` | Beginning and end of the input |
| `\.` | Escaped literal metacharacter |

Inside a class, `\` escapes the next character; escape `]`, `-`, `^`, or `\` to use them literally. A `-` at the end of a class is literal. Empty classes and descending ranges are errors. Repetition counts are limited to 1000 and the upper bound must be at least the lower bound. Capture groups and backreferences are not implemented.

## Use

Add the module to a MoonBit project, then compile and run:

```moon
match @arachne.Regex::compile("^(ab|cd)+$") {
  Ok(regex) => regex.full_match("abcd")
  Err(_) => false
}
```

The public API provides `Regex::compile`, `Regex::full_match`, `Regex::find`, `Regex::contains`, and `Regex::pattern`. `parse` is also public when callers need the syntax tree directly.

`find` returns the leftmost match and, at that start position, the longest possible end position. Empty matches are valid. `^` and `$` assert the boundaries of the entire input, including when searching with `find`; escape them to match literal characters. Matching advances over MoonBit string code units, as in the first milestone. Character classes and ranges compare those code units; they do not implement Unicode properties or case folding.

## Development

This is a MoonBit module managed by `moon.mod`. Build it with:

```sh
moon check
```

Run the suite with `moon test`. The source is kept at the package root so the parser, AST, and NFA engine can be read together. See [DESIGN.md](DESIGN.md) for the execution model and its limits.

## License

Apache-2.0. See [LICENSE](LICENSE).
