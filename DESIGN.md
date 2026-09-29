# Design notes

## Syntax and public behavior

The recursive-descent parser follows precedence directly: alternation calls concatenation, concatenation calls repetition, and repetition calls atom parsing. Parentheses shape the AST but do not become nodes. The new AST nodes represent character classes and counted repetition. Existing public entry points and anchor behavior are unchanged.

`Regex::compile` parses once and stores a compiled Thompson NFA. `full_match` requires acceptance at the end of the whole input. `find` tries start positions from left to right and records the furthest accepting end for the first start that matches. Thus alternation order does not override leftmost-longest selection. `contains` tests whether `find` succeeds.

## Thompson construction

Each instruction has a state index. A literal, class, or dot consumes one input code unit; a split forks without consuming input. The `Begin` and `Finish` instructions assert absolute input boundaries, preserving the meaning of `^` and `$` even during a search. The accepting instruction is state zero.

Compilation works backward from a known continuation. Concatenation connects its right fragment before its left. Alternation starts at a split leading to both branches. Star and plus wire a split back to the body; optional uses a split between its body and the continuation. Counted repetition expands into required copies, optional copies, or a star after the required copies. Empty uses the continuation directly. This construction needs no recursive matching over the AST.

## Lazy subset DFA

At each input boundary, an iterative epsilon closure follows split and satisfied assertion transitions. A visited-state set stops nullable cycles such as `(a?)*`. Active consuming state indices are ordered, so each epsilon-closed subset is a canonical DFA state. A transition is keyed by that subset, input code unit, and whether the destination is the end of input; the latter preserves `$` assertions. The matcher records every accepting boundary and returns the furthest one.

The transition cache holds at most 256 edges and clears when full. It is local to each `full_match` or `find` call; `find` shares it across candidate start positions. A miss computes the transition from the NFA, so eviction never changes results. Linear cache lookup and NFA closure still bound worst-case work by the NFA state count per input step, and `find` may try every start position. Counted repetition expands the NFA, so counts above 1000 are rejected. Captures, backreferences, Unicode properties, and case folding remain outside the engine.
