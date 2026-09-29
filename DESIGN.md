# Design notes

## First milestone: make the grammar inspectable

The parser is a hand-written recursive-descent parser. Its functions follow precedence directly: alternation calls concatenation, concatenation calls repetition, and repetition calls atom parsing. Parentheses control precedence but do not need a node of their own.

The AST evaluator is deliberately the first execution model. It keeps the public `Regex` API independent from the eventual automaton and makes pattern semantics visible in a small amount of code. Its cost can grow quickly when alternatives and repetitions combine, so it is not the final performance model.

Anchors are represented as AST nodes and checked against the input boundaries during evaluation. Escaping them keeps `^` and `$` available as literals. This keeps the syntax rule explicit instead of adding special cases to `find`.

## Next boundary

The next engine step is to compile the existing AST into a Thompson NFA and simulate sets of active states. That replaces recursive path enumeration while preserving the parser and public matching API. Character classes and counted repetitions can then be added with parser-level tests and explicit semantics before considering DFA caching or backreferences.
