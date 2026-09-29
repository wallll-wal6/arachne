// Copyright 2026 Arachne Authors
// Licensed under the Apache License, Version 2.0.

/// A hand-written recursive-descent parser for the regex grammar.
///
/// Grammar, from loosest to tightest precedence:
///   alternation   := concatenation ( '|' concatenation )*
///   concatenation := repetition+
///   repetition    := atom ( '*' | '+' | '?' | count )?
///   count         := '{' digits ( ',' digits? )? '}'
///   atom          := '.' | '^' | '$' | class | '\' <any> | literal | '(' alternation ')'
///
/// The grammar is small enough that no separate lexer is needed; the parser
/// advances over Unicode scalar values in the pattern.

priv struct Parser {
  src : Array[Char]
  mut pos : Int
  mut groups : Int
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
  let p = { src: pattern.to_array(), pos: 0, groups: 0 }
  match p.parse_alternation() {
    Ok(node) => {
      if p.pos != p.src.length() {
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
  } else if c == '{'.to_int() && self.pos + 1 < self.src.length() &&
            self.src[self.pos + 1] >= '0' && self.src[self.pos + 1] <= '9' {
    self.parse_count(atom)
  } else {
    Ok(atom)
  }
}

/// Counts are capped to keep Thompson expansion bounded.
fn Parser::parse_number(self : Parser) -> Result[Int, RegexError] {
  let mut value = 0
  let start = self.pos
  while self.peek() >= '0'.to_int() && self.peek() <= '9'.to_int() {
    value = value * 10 + self.peek() - '0'.to_int()
    if value > 1000 {
      return Err(RegexError::new(start, "repetition count exceeds 1000"))
    }
    self.advance()
  }
  if self.pos == start {
    Err(RegexError::new(start, "expected repetition count"))
  } else {
    Ok(value)
  }
}

fn Parser::parse_count(self : Parser, atom : Node) -> Result[Node, RegexError] {
  self.advance()
  let min = match self.parse_number() {
    Ok(n) => n
    Err(e) => return Err(e)
  }
  let mut max = min
  if self.peek() == ','.to_int() {
    self.advance()
    if self.peek() == '}'.to_int() {
      max = -1
    } else {
      max = match self.parse_number() {
        Ok(n) => n
        Err(e) => return Err(e)
      }
    }
  }
  if self.peek() != '}'.to_int() {
    return Err(RegexError::new(self.pos, "unclosed repetition"))
  }
  self.advance()
  if max >= 0 && max < min {
    Err(RegexError::new(self.pos, "repetition upper bound is below lower bound"))
  } else {
    Ok(Count(atom, min, max))
  }
}

fn shorthand(code : Int) -> ClassItem? {
  match code {
    100 => Some(Builtin(Digit, false))
    68 => Some(Builtin(Digit, true))
    119 => Some(Builtin(Word, false))
    87 => Some(Builtin(Word, true))
    115 => Some(Builtin(Whitespace, false))
    83 => Some(Builtin(Whitespace, true))
    _ => None
  }
}

fn escaped_char(code : Int) -> Char {
  match code {
    110 => '\n'
    114 => '\r'
    116 => '\t'
    _ => int_to_char(code)
  }
}

fn normalize_property_name(name : String) -> String? {
  match name {
    "L" | "Letter" => Some("L")
    "Lu" | "Uppercase_Letter" => Some("Lu")
    "Ll" | "Lowercase_Letter" => Some("Ll")
    "Lt" | "Titlecase_Letter" => Some("Lt")
    "Lm" | "Modifier_Letter" => Some("Lm")
    "Lo" | "Other_Letter" => Some("Lo")
    "M" | "Mark" => Some("M")
    "Mn" | "Nonspacing_Mark" => Some("Mn")
    "Mc" | "Spacing_Mark" => Some("Mc")
    "Me" | "Enclosing_Mark" => Some("Me")
    "N" | "Number" => Some("N")
    "Nd" | "Decimal_Number" => Some("Nd")
    "Nl" | "Letter_Number" => Some("Nl")
    "No" | "Other_Number" => Some("No")
    "P" | "Punctuation" => Some("P")
    "Pc" | "Connector_Punctuation" => Some("Pc")
    "Pd" | "Dash_Punctuation" => Some("Pd")
    "Ps" | "Open_Punctuation" => Some("Ps")
    "Pe" | "Close_Punctuation" => Some("Pe")
    "Pi" | "Initial_Punctuation" => Some("Pi")
    "Pf" | "Final_Punctuation" => Some("Pf")
    "Po" | "Other_Punctuation" => Some("Po")
    "S" | "Symbol" => Some("S")
    "Sm" | "Math_Symbol" => Some("Sm")
    "Sc" | "Currency_Symbol" => Some("Sc")
    "Sk" | "Modifier_Symbol" => Some("Sk")
    "So" | "Other_Symbol" => Some("So")
    "Z" | "Separator" => Some("Z")
    "Zs" | "Space_Separator" => Some("Zs")
    "Zl" | "Line_Separator" => Some("Zl")
    "Zp" | "Paragraph_Separator" => Some("Zp")
    "C" | "Other" => Some("C")
    "Cc" | "Control" => Some("Cc")
    "Cf" | "Format" => Some("Cf")
    "Cs" | "Surrogate" => Some("Cs")
    "Co" | "Private_Use" => Some("Co")
    "Cn" | "Unassigned" => Some("Cn")
    _ => None
  }
}

fn Parser::parse_property(self : Parser, negated : Bool) -> Result[ClassItem, RegexError] {
  if self.peek() != '{'.to_int() {
    return Err(RegexError::new(self.pos, "expected '{' after Unicode property escape"))
  }
  self.advance()
  let start = self.pos
  let name = StringBuilder()
  while self.peek() >= 0 && self.peek() != '}'.to_int() {
    name.write_char(int_to_char(self.peek()))
    self.advance()
  }
  if self.peek() != '}'.to_int() {
    return Err(RegexError::new(start, "unclosed Unicode property"))
  }
  self.advance()
  match normalize_property_name(name.to_string()) {
    Some(property) => Ok(Property(property, negated))
    None => Err(RegexError::new(start, "unknown Unicode general category"))
  }
}

fn Parser::class_atom(self : Parser) -> Result[ClassItem, RegexError] {
  if self.peek() == '\\'.to_int() {
    self.advance()
    if self.peek() < 0 {
      return Err(RegexError::new(self.pos, "trailing backslash in class"))
    }
    let escaped = self.peek()
    self.advance()
    if escaped == 'p'.to_int() || escaped == 'P'.to_int() {
      return self.parse_property(escaped == 'P'.to_int())
    }
    match shorthand(escaped) {
      Some(item) => return Ok(item)
      None => return Ok(Single(escaped_char(escaped)))
    }
  }
  let c = int_to_char(self.peek())
  self.advance()
  Ok(Single(c))
}

fn Parser::parse_class(self : Parser) -> Result[Node, RegexError] {
  self.advance()
  let negated = self.peek() == '^'.to_int()
  if negated { self.advance() }
  let items : Array[ClassItem] = []
  while self.peek() >= 0 && self.peek() != ']'.to_int() {
    let first = match self.class_atom() {
      Ok(c) => c
      Err(e) => return Err(e)
    }
    if self.peek() == '-'.to_int() && self.pos + 1 < self.src.length() &&
       self.src[self.pos + 1] != ']' {
      let first_char = match first {
        Single(c) => c
        _ => return Err(RegexError::new(self.pos, "character category cannot start a range"))
      }
      self.advance()
      let last = match self.class_atom() {
        Ok(c) => c
        Err(e) => return Err(e)
      }
      let last_char = match last {
        Single(c) => c
        _ => return Err(RegexError::new(self.pos, "character category cannot end a range"))
      }
      if first_char.to_int() > last_char.to_int() {
        return Err(RegexError::new(self.pos, "descending character range"))
      }
      items.push(Range(first_char, last_char))
    } else {
      items.push(first)
    }
  }
  if self.peek() != ']'.to_int() {
    return Err(RegexError::new(self.pos, "unclosed character class"))
  }
  if items.length() == 0 {
    return Err(RegexError::new(self.pos, "empty character class"))
  }
  self.advance()
  Ok(Class(items, negated))
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
  if c == '['.to_int() {
    return self.parse_class()
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
    match shorthand(escaped) {
      _ if escaped == 'p'.to_int() || escaped == 'P'.to_int() => {
        let property = match self.parse_property(escaped == 'P'.to_int()) {
          Ok(item) => item
          Err(error) => return Err(error)
        }
        return Ok(Class([property], false))
      }
      Some(item) => return Ok(Class([item], false))
      None => return Ok(Lit(escaped_char(escaped)))
    }
  }
  if c == '('.to_int() {
    self.advance()
    if self.peek() == ')'.to_int() {
      return Err(RegexError::new(self.pos, "empty group"))
    }
    self.groups = self.groups + 1
    let group = self.groups
    let inner = match self.parse_alternation() {
      Ok(n) => n
      Err(e) => return Err(e)
    }
    if self.peek() != ')'.to_int() {
      return Err(RegexError::new(self.pos, "unclosed group"))
    }
    self.advance()
    return Ok(Capture(group, inner))
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
