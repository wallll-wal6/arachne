// Copyright 2026 Arachne Authors
// Licensed under the Apache License, Version 2.0.

/// A compile-time error for an invalid pattern. `pos` counts Unicode scalar
/// values from the start of the pattern.
pub(all) struct RegexError {
  pos : Int
  msg : String
} derive(Debug, Eq)

pub fn RegexError::new(pos : Int, msg : String) -> RegexError {
  { pos, msg }
}

/// Renders a human-readable, one-line description of the error.
pub fn RegexError::to_string(self : RegexError) -> String {
  "error at position " + self.pos.to_string() + ": " + self.msg
}
