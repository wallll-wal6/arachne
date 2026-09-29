// Copyright 2026 Arachne Authors
// Licensed under the Apache License, Version 2.0.

/// The matching engine.
///
/// Matching is modelled as a function that, given a position in the input,
/// returns every position at which the pattern can finish. That is the same
/// idea as NFA simulation: a set of reachable positions, one per possible
/// end. Keeping it on the AST first makes the engine small and lets a
/// compiled NFA (and later a DFA) slot in later without changing the public
/// API.

pub(all) struct Regex {
  pattern : String
  node : Node
} derive(Debug, Eq)

pub(all) struct Match {
  start : Int
  end : Int
} derive(Debug, Eq)

/// Compiles a pattern into a reusable `Regex`, or returns the first error.
pub fn Regex::compile(pattern : String) -> Result[Regex, RegexError] {
  match parse(pattern) {
    Ok(node) => Ok({ pattern, node })
    Err(e) => Err(e)
  }
}

/// Returns the original pattern this `Regex` was compiled from.
pub fn Regex::pattern(self : Regex) -> String {
  self.pattern
}

/// Whether the whole `text` matches the pattern from beginning to end.
pub fn Regex::full_match(self : Regex, text : String) -> Bool {
  contains(match_here(self.node, text, 0), text.length())
}

/// Finds the leftmost, longest match anywhere in `text`.
pub fn Regex::find(self : Regex, text : String) -> Option[Match] {
  let mut start = 0
  while start <= text.length() {
    let ends = match_here(self.node, text, start)
    if ends.length() > 0 {
      let mut longest = ends[0]
      let mut i = 1
      while i < ends.length() {
        if ends[i] > longest {
          longest = ends[i]
        }
        i = i + 1
      }
      return Some({ start, end: longest })
    }
    start = start + 1
  }
  None
}

/// Whether the pattern matches somewhere in `text`.
pub fn Regex::contains(self : Regex, text : String) -> Bool {
  match self.find(text) {
    Some(_) => true
    None => false
  }
}

/// Returns every position where `node` can finish matching `text` starting
/// from `pos`.
fn match_here(node : Node, text : String, pos : Int) -> Array[Int] {
  match node {
    Empty => [pos]
    Dot =>
      if pos < text.length() {
        [pos + 1]
      } else {
        []
      }
    Start => if pos == 0 { [pos] } else { [] }
    End => if pos == text.length() { [pos] } else { [] }
    Lit(c) =>
      if pos < text.length() && text[pos].to_int() == c.to_int() {
        [pos + 1]
      } else {
        []
      }
    Concat(a, b) => {
      let result : Array[Int] = []
      for e in match_here(a, text, pos) {
        for f in match_here(b, text, e) {
          push_unique(result, f)
        }
      }
      result
    }
    Alt(a, b) => {
      let result : Array[Int] = []
      for e in match_here(a, text, pos) {
        push_unique(result, e)
      }
      for e in match_here(b, text, pos) {
        push_unique(result, e)
      }
      result
    }
    Star(a) => match_star(a, text, pos, [])
    Plus(a) => {
      let result : Array[Int] = []
      for e in match_here(a, text, pos) {
        for f in match_star(a, text, e, []) {
          push_unique(result, f)
        }
      }
      result
    }
    Optional(a) => {
      let result : Array[Int] = [pos]
      for e in match_here(a, text, pos) {
        push_unique(result, e)
      }
      result
    }
  }
}

/// Collects every position reachable by repeating `a` zero or more times.
/// The `e != pos` guard stops the recursion when `a` can match the empty
/// string, which would otherwise loop forever.
fn match_star(a : Node, text : String, pos : Int, acc : Array[Int]) -> Array[Int] {
  push_unique(acc, pos)
  for e in match_here(a, text, pos) {
    if e != pos {
      let _ = match_star(a, text, e, acc)
    }
  }
  acc
}

/// Appends `x` to `arr` unless it is already present.
fn push_unique(arr : Array[Int], x : Int) -> Unit {
  let mut i = 0
  let mut found = false
  while i < arr.length() {
    if arr[i] == x {
      found = true
      break
    }
    i = i + 1
  }
  if !found {
    arr.push(x)
  }
}

/// Whether `x` occurs in `arr`.
fn contains(arr : Array[Int], x : Int) -> Bool {
  let mut i = 0
  while i < arr.length() {
    if arr[i] == x {
      return true
    }
    i = i + 1
  }
  false
}
