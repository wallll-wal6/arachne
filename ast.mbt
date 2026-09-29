// Copyright 2026 Arachne Authors
// Licensed under the Apache License, Version 2.0.

/// The parsed form of a regular expression.
///
/// The parser lowers a pattern string into this tree; the engine walks it.
/// Ten nodes cover the grammar: the empty pattern, single
/// characters, the any-dot, two boundary anchors, concatenation, alternation,
/// and the three postfix quantifiers. Parentheses never become a node — they only shape
/// precedence while parsing, so they are discarded once a subtree is built.
pub(all) enum Node {
  Empty
  Lit(Char)
  Dot
  Start
  End
  Concat(Node, Node)
  Alt(Node, Node)
  Star(Node)
  Plus(Node)
  Optional(Node)
} derive(Debug, Eq)

/// Renders a single character into a string.
fn char_to_string(c : Char) -> String {
  c.to_string()
}

/// Reports whether a character has special meaning in the regex grammar and
/// must be escaped when rendered back into a pattern string.
fn is_metachar(c : Char) -> Bool {
    c == '.' ||
    c == '^' ||
    c == '$' ||
    c == '*' ||
    c == '+' ||
    c == '?' ||
    c == '|' ||
    c == '(' ||
    c == ')' ||
    c == '\\'
}

/// Renders a literal character, escaping it when the grammar would otherwise
/// read it as an operator.
fn escaped_literal(c : Char) -> String {
  if is_metachar(c) {
    "\\" + char_to_string(c)
  } else {
    char_to_string(c)
  }
}

/// Wraps a sub-pattern in parentheses when it is not a single atom, so the
/// rendered string stays unambiguous.
fn wrapped(node : Node) -> String {
  match node {
    Lit(_) => node.to_pattern()
    Dot => node.to_pattern()
    Start => node.to_pattern()
    End => node.to_pattern()
    Empty => node.to_pattern()
    Alt(_, _) => node.to_pattern()
    _ => "(" + node.to_pattern() + ")"
  }
}

/// Renders the pattern back into a canonical, unambiguous string.
/// Useful for debugging and for round-trip tests in the suite.
pub fn Node::to_pattern(self : Node) -> String {
  match self {
    Empty => ""
    Dot => "."
    Start => "^"
    End => "$"
    Lit(c) => escaped_literal(c)
    Concat(a, b) => a.to_pattern() + b.to_pattern()
    Alt(a, b) => "(" + a.to_pattern() + "|" + b.to_pattern() + ")"
    Star(a) => wrapped(a) + "*"
    Plus(a) => wrapped(a) + "+"
    Optional(a) => wrapped(a) + "?"
  }
}
