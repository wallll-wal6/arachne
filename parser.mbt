// Copyright 2026 Arachne Authors
// Licensed under the Apache License, Version 2.0.

/// A hand-written recursive-descent parser for the regex grammar.
///
/// Grammar, from loosest to tightest precedence:
///   alternation   := concatenation ( '|' concatenation )*
///   concatenation := repetition+
///   repetition    := atom ( '*' | '+' | '?' )?
///   atom          := '.' | '^' | '$' | '\' <any> | literal | '(' alternation ')'
///
/// The grammar is small enough that no separate lexer is needed; the parser
/// reads code units straight from the pattern string.

priv struct Parser {
  src : String
  mut pos : Int
}

/// Converts a code point back into a `Char`, substituting `?` for values
/// that are not valid scalar values (which should not occur in practice).
fn int_to_char(code : Int) -> Char {
  match code.to_char() {
    Some(c) => c
    None => '?'
  }
}

/// Parses a pattern into an AST, or returns the first error encountered.
pub fn parse(pattern : String) -> Result[Node, RegexError] {
  if pattern.length() == 0 {
    return Ok(Empty)
  }
  let p = { src: pattern, pos: 0 }
  match p.parse_alternation() {
    Ok(node) => {
      if p.pos != pattern.length() {
        Err(RegexError::new(p.pos, "unexpected ')' or trailing character"))
      } else {
        Ok(node)
      }
    }
    Err(e) => Err(e)
  }
}

/// Returns the code point at the cursor, or -1 at the end of input.
fn Parser::peek(self : Parser) -> Int {
  if self.pos < self.src.length() {
    self.src[self.pos].to_int()
  } else {
    -1
  }
}

fn Parser::advance(self : Parser) -> Unit {
  self.pos = self.pos + 1
}

/// Whether the next character can begin an atom, which excludes the end of
/// input, ')' and '|'.
fn Parser::can_start_atom(self : Parser) -> Bool {
  let c = self.peek()
  c >= 0 && c != ')'.to_int() && c != '|'.to_int()
}

fn Parser::parse_alternation(self : Parser) -> Result[Node, RegexError] {
  let first = match self.parse_concatenation() {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  let mut left = first
  while self.peek() == '|'.to_int() {
    self.advance()
    let right = match self.parse_concatenation() {
      Ok(n) => n
      Err(e) => return Err(e)
    }
    left = Alt(left, right)
  }
  Ok(left)
}

fn Parser::parse_concatenation(self : Parser) -> Result[Node, RegexError] {
  let first = match self.parse_repetition() {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  let mut left = first
  while self.can_start_atom() {
    let right = match self.parse_repetition() {
      Ok(n) => n
      Err(e) => return Err(e)
    }
    left = Concat(left, right)
  }
  Ok(left)
}

fn Parser::parse_repetition(self : Parser) -> Result[Node, RegexError] {
  let atom = match self.parse_atom() {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  let c = self.peek()
  if c == '*'.to_int() {
    self.advance()
    Ok(Star(atom))
  } else if c == '+'.to_int() {
    self.advance()
    Ok(Plus(atom))
  } else if c == '?'.to_int() {
    self.advance()
    Ok(Optional(atom))
  } else {
    Ok(atom)
  }
}

fn Parser::parse_atom(self : Parser) -> Result[Node, RegexError] {
  let c = self.peek()
  if c < 0 {
    return Err(RegexError::new(self.pos, "unexpected end of pattern"))
  }
  if c == '.'.to_int() {
    self.advance()
    return Ok(Dot)
  }
  if c == '^'.to_int() {
    self.advance()
    return Ok(Start)
  }
  if c == '$'.to_int() {
    self.advance()
    return Ok(End)
  }
  if c == '\\'.to_int() {
    self.advance()
    let escaped = self.peek()
    if escaped < 0 {
      return Err(RegexError::new(self.pos, "trailing backslash"))
    }
    self.advance()
    return Ok(Lit(int_to_char(escaped)))
  }
  if c == '('.to_int() {
    self.advance()
    if self.peek() == ')'.to_int() {
      return Err(RegexError::new(self.pos, "empty group"))
    }
    let inner = match self.parse_alternation() {
      Ok(n) => n
      Err(e) => return Err(e)
    }
    if self.peek() != ')'.to_int() {
      return Err(RegexError::new(self.pos, "unclosed group"))
    }
    self.advance()
    return Ok(inner)
  }
  if c == ')'.to_int() {
    return Err(RegexError::new(self.pos, "unmatched ')'"))
  }
  if c == '|'.to_int() || c == '*'.to_int() || c == '+'.to_int() || c == '?'.to_int() {
    return Err(RegexError::new(self.pos, "quantifier or alternation with no operand"))
  }
  self.advance()
  Ok(Lit(int_to_char(c)))
}
