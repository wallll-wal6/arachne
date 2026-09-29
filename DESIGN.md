# Design notes

## Syntax and public behavior

The recursive-descent parser follows precedence directly: alternation calls concatenation, concatenation calls repetition, and repetition calls atom parsing. Parentheses shape the AST but do not become nodes. The syntax and parse errors remain those of the first milestone.

`Regex::compile` parses once and stores a compiled Thompson NFA. `full_match` requires acceptance at the end of the whole input. `find` tries start positions from left to right and records the furthest accepting end for the first start that matches. Thus alternation order does not override leftmost-longest selection. `contains` tests whether `find` succeeds.

## Thompson construction

Each instruction has a state index. A literal or dot consumes one input code unit; a split forks without consuming input. The `Begin` and `Finish` instructions assert absolute input boundaries, preserving the meaning of `^` and `$` even during a search. The accepting instruction is state zero.

Compilation works backward from a known continuation. Concatenation connects its right fragment before its left. Alternation starts at a split leading to both branches. Star and plus wire a split back to the body; optional uses a split between its body and the continuation. Empty uses the continuation directly. This construction needs no recursive matching over the AST.

## State-set simulation

At each input boundary, an iterative epsilon closure follows split and satisfied assertion transitions. A visited-state set stops nullable cycles such as `(a?)*`. The simulator advances all active consuming states together for each code unit, then takes another closure. It records every accepting boundary and returns the furthest one.

For a fixed start position, simulation uses space proportional to the number of NFA states and time proportional to the input length times the state count. `find` tries each possible start in order, so a search may take quadratic time in input length times state count. There is no DFA cache. Character classes, counted repetitions, captures, and backreferences are outside this stage.
