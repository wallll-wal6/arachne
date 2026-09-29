# Design notes

## Syntax and public behavior

The recursive-descent parser follows precedence directly: alternation calls concatenation, concatenation calls repetition, and repetition calls atom parsing. Capturing parentheses remain as numbered AST nodes; grouping syntax and capture metadata therefore have one source of truth. Character classes and counted repetitions are separate nodes.

`Regex::compile` parses once and stores a compiled Thompson NFA. `full_match` requires acceptance at the end of the whole input. `find` runs one forward NFA search, tagging active paths with their start offsets. When paths reach the same instruction at the same boundary, the earlier start dominates later starts because their possible continuations are identical. The engine retains the furthest accepting end for the earliest successful start, preserving leftmost-longest selection independently of alternation order. `contains` tests whether `find` succeeds.

## Thompson construction

Each instruction has a state index. A literal, class, or dot consumes one Unicode scalar value; a split forks without consuming input. The `Begin` and `Finish` instructions assert absolute input boundaries, preserving the meaning of `^` and `$` even during a search. `Boundary` checks whether the ASCII word status changes across an input position. The accepting instruction is state zero. Public match spans are converted back to UTF-16 code-unit offsets for compatibility with MoonBit string slicing.

Compilation works backward from a known continuation. Concatenation connects its right fragment before its left. Alternation starts at a split leading to both branches. Star and plus wire a split back to the body; optional uses a split between its body and the continuation. Counted repetition expands into required copies, optional copies, or a star after the required copies. Empty uses the continuation directly. This construction needs no recursive matching over the AST.

## Captures

Capture groups compile to `Save` instructions surrounding their child expression. The capture-aware NFA walk carries one preferred slot vector per instruction and input boundary rather than enumerating every path. Group zero is the complete match. Numbered groups use opening-parenthesis order, unmatched optional groups are `None`, and a repeated group returns the final participating iteration. This makes captures available to replacements without changing the regular matching API.

## Lazy subset DFA

At each input boundary, an iterative epsilon closure follows split and satisfied assertion transitions. A visited-state set stops nullable cycles such as `(a?)*`. Active consuming state indices are ordered, so each epsilon-closed subset is a canonical DFA state. A transition is keyed by that subset, input scalar value, end-of-input status, and the destination's ASCII word status; these context values preserve `$`, `\b`, and `\B` assertions. The matcher records every accepting boundary and returns the furthest one.

The transition cache holds at most 256 edges and clears when full. It is local to each `full_match` call; search uses the tagged NFA pass above. A cache miss computes the transition from the NFA, so eviction never changes results. Search work is bounded by input length times NFA state count instead of restarting the matcher at every input position. Patterns are limited to 1024 scalars, 128 nested groups, and 256 captures. Compilation estimates Thompson instruction count before expanding repetitions and rejects patterns above 65,536 states; a set allows at most 1024 patterns and the same aggregate state budget. These bounds prevent integer-overflow and expansion-based memory exhaustion. ASCII shorthand categories are evaluated directly. Unicode General_Category properties use generated inclusive range tables and binary search; `UnicodeData.txt` 17.0 is the source, and the generator and license notice are checked in. Unicode case folding and backreferences remain outside the engine.
