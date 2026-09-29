# Design notes

## Syntax and public behavior

The recursive-descent parser follows precedence directly: alternation calls concatenation, concatenation calls repetition, and repetition calls atom parsing. Capturing parentheses remain as numbered AST nodes; grouping syntax and capture metadata therefore have one source of truth. Character classes and counted repetitions are separate nodes.

`Regex::compile` parses once and stores a compiled Thompson NFA. `full_match` requires acceptance at the end of the whole input. `find` tries start positions from left to right and records the furthest accepting end for the first start that matches. Thus alternation order does not override leftmost-longest selection. `contains` tests whether `find` succeeds.

## Thompson construction

Each instruction has a state index. A literal, class, or dot consumes one Unicode scalar value; a split forks without consuming input. The `Begin` and `Finish` instructions assert absolute input boundaries, preserving the meaning of `^` and `$` even during a search. The accepting instruction is state zero. Public match spans are converted back to UTF-16 code-unit offsets for compatibility with MoonBit string slicing.

Compilation works backward from a known continuation. Concatenation connects its right fragment before its left. Alternation starts at a split leading to both branches. Star and plus wire a split back to the body; optional uses a split between its body and the continuation. Counted repetition expands into required copies, optional copies, or a star after the required copies. Empty uses the continuation directly. This construction needs no recursive matching over the AST.

## Captures

Capture groups compile to `Save` instructions surrounding their child expression. The capture-aware NFA walk carries one preferred slot vector per instruction and input boundary rather than enumerating every path. Group zero is the complete match. Numbered groups use opening-parenthesis order, unmatched optional groups are `None`, and a repeated group returns the final participating iteration. This makes captures available to replacements without changing the regular matching API.

## Lazy subset DFA

At each input boundary, an iterative epsilon closure follows split and satisfied assertion transitions. A visited-state set stops nullable cycles such as `(a?)*`. Active consuming state indices are ordered, so each epsilon-closed subset is a canonical DFA state. A transition is keyed by that subset, input scalar value, and whether the destination is the end of input; the latter preserves `$` assertions. The matcher records every accepting boundary and returns the furthest one.

The transition cache holds at most 256 edges and clears when full. It is local to each `full_match` or `find` call; `find` shares it across candidate start positions. A miss computes the transition from the NFA, so eviction never changes results. Linear cache lookup and NFA closure still bound worst-case work by the NFA state count per input step, and `find` may try every start position. Counted repetition expands the NFA, so counts above 1000 are rejected. ASCII shorthand categories are evaluated directly. Unicode General_Category properties use generated inclusive range tables and binary search; `UnicodeData.txt` 17.0 is the source, and the generator and license notice are checked in. Unicode case folding and backreferences remain outside the engine.
