# Arachne

A small regular-expression engine written in pure MoonBit. It parses a pattern into an AST and evaluates that tree against input text. The first milestone focuses on a compact, inspectable core before adding automaton compilation.

## Current syntax

| Pattern form | Meaning |
| --- | --- |
| `a` | Literal character |
| `.` | Any single character |
| `ab` | Concatenation |
| `a|b` | Alternation |
| `(ab)` | Grouping |
| `a*`, `a+`, `a?` | Zero-or-more, one-or-more, optional |
| `^`, `$` | Beginning and end of the input |
| `\.` | Escaped literal metacharacter |

Character classes, counted repetitions, capture groups, and backreferences are not implemented yet. Matching currently walks the AST and is intended for learning and small patterns; this milestone does not promise a linear-time bound for adversarial expressions.

## Use

Add the module to a MoonBit project, then compile and run:

```moon
match @arachne.Regex::compile("^(ab|cd)+$") {
  Ok(regex) => regex.full_match("abcd")
  Err(_) => false
}
```

The public API provides `Regex::compile`, `Regex::full_match`, `Regex::find`, `Regex::contains`, and `Regex::pattern`. `parse` is also public when callers need the syntax tree directly.

## Development

This is a MoonBit module managed by `moon.mod`. Build it with:

```sh
moon check
```

The source is kept at the package root so the parser, AST, and evaluator can be read together. See [DESIGN.md](DESIGN.md) for the current execution model and the next implementation boundary.

## License

Apache-2.0. See [LICENSE](LICENSE).
