// Copyright 2026 Arachne Authors
// Licensed under the Apache License, Version 2.0.

///|
/// Thompson NFA instructions. Assertions consume no input.
pub enum State {
  Accept
  Char(Char, Int)
  CharClass(Array[ClassItem], Bool, Int)
  Any(Int)
  Begin(Int)
  Finish(Int)
  Split(Int, Int)
} derive(Debug, Eq)

///|
pub struct Nfa {
  states : Array[State]
  start : Int
} derive(Debug, Eq)

///|
pub struct Regex {
  pattern : String
  node : Node
  nfa : Nfa
} derive(Debug, Eq)

///|
pub(all) struct Match {
  start : Int
  end : Int
} derive(Debug, Eq)

///|
/// Compiles a pattern into a reusable Regex, or returns the first error.
pub fn Regex::compile(pattern : String) -> Result[Regex, RegexError] {
  match parse(pattern) {
    Ok(node) => Ok({ pattern, node, nfa: compile_nfa(node), })
    Err(e) => Err(e)
  }
}

///|
pub fn Regex::pattern(self : Regex) -> String {
  self.pattern
}

///|
pub fn Regex::full_match(self : Regex, text : String) -> Bool {
  let cache : Array[DfaEdge] = []
  match match_end(self.nfa, text, 0, cache) {
    Some(end) => end == text.length()
    None => false
  }
}

///|
/// Finds the leftmost, longest match anywhere in text.
pub fn Regex::find(self : Regex, text : String) -> Match? {
  let cache : Array[DfaEdge] = []
  find_from(self.nfa, text, 0, cache)
}

///|
/// Finds non-overlapping matches from left to right. Empty matches advance by
/// one input character, so patterns such as the empty expression terminate.
pub fn Regex::find_all(self : Regex, text : String) -> Array[Match] {
  let cache : Array[DfaEdge] = []
  let matches : Array[Match] = []
  let mut from = 0
  let mut done = false
  while !done {
    match find_from(self.nfa, text, from, cache) {
      Some(found) => {
        matches.push(found)
        if found.end > found.start {
          from = found.end
        } else if found.end < text.length() {
          from = found.end + 1
        } else {
          done = true
        }
      }
      None => done = true
    }
  }
  matches
}

///|
/// Returns the text covered by this match, using the same character offsets
/// as `find` and `find_all`.
pub fn Match::text(self : Match, text : String) -> String {
  text[self.start:self.end].to_owned()
}

///|
/// Replaces the first match. `$0` inserts the entire match and `$$` inserts a
/// literal dollar sign. Until capture groups are added, other `$n` forms stay
/// literal.
pub fn Regex::replace_first(self : Regex, text : String, replacement : String) -> String {
  self.replace_n(text, replacement, 1)
}

///|
/// Replaces every non-overlapping match. Empty matches advance by one
/// character and include the final input boundary once.
pub fn Regex::replace_all(self : Regex, text : String, replacement : String) -> String {
  self.replace_n(text, replacement, -1)
}

///|
/// Replaces at most `limit` matches. A negative limit is unbounded; zero
/// returns the input unchanged.
pub fn Regex::replace_n(
  self : Regex,
  text : String,
  replacement : String,
  limit : Int,
) -> String {
  if limit == 0 {
    return text
  }
  let builder = StringBuilder()
  let cache : Array[DfaEdge] = []
  let mut from = 0
  let mut copied_until = 0
  let mut count = 0
  while true {
    if limit > 0 && count == limit {
      break
    }
    match find_from(self.nfa, text, from, cache) {
      Some(found) => {
        builder.write_substring(text, copied_until, found.start - copied_until)
        write_replacement(builder, text, replacement, found)
        copied_until = found.end
        count = count + 1
        if found.end > found.start {
          from = found.end
        } else if found.end < text.length() {
          from = found.end + 1
        } else {
          break
        }
      }
      None => break
    }
  }
  builder.write_substring(text, copied_until, text.length() - copied_until)
  builder.to_string()
}

///|
/// Splits text around non-overlapping matches, retaining empty pieces at the
/// beginning and end when the pattern matches there.
pub fn Regex::split(self : Regex, text : String) -> Array[String] {
  self.splitn(text, -1)
}

///|
/// Splits into at most `limit` pieces. A negative limit is unlimited and zero
/// returns no pieces.
pub fn Regex::splitn(self : Regex, text : String, limit : Int) -> Array[String] {
  let pieces : Array[String] = []
  if limit == 0 {
    return pieces
  }
  let cache : Array[DfaEdge] = []
  let mut from = 0
  let mut copied_until = 0
  let mut done = false
  while !done && (limit < 0 || pieces.length() < limit - 1) {
    match find_from(self.nfa, text, from, cache) {
      Some(found) => {
        pieces.push(text[copied_until:found.start].to_owned())
        copied_until = found.end
        if found.end > found.start {
          from = found.end
        } else if found.end < text.length() {
          from = found.end + 1
        } else {
          done = true
        }
      }
      None => done = true
    }
  }
  pieces.push(text[copied_until:text.length()].to_owned())
  pieces
}

///|
fn find_from(nfa : Nfa, text : String, from : Int, cache : Array[DfaEdge]) -> Match? {
  let mut start = from
  while start <= text.length() {
    match match_end(nfa, text, start, cache) {
      Some(end) => return Some({ start, end, })
      None => start = start + 1
    }
  }
  None
}

///|
fn write_replacement(
  builder : StringBuilder,
  text : String,
  replacement : String,
  found : Match,
) -> Unit {
  let chars = replacement.to_array()
  let mut pos = 0
  while pos < chars.length() {
    if chars[pos] == '$' && pos + 1 < chars.length() {
      if chars[pos + 1] == '$' {
        builder.write_char('$')
        pos = pos + 2
      } else if chars[pos + 1] == '0' {
        builder.write_substring(text, found.start, found.end - found.start)
        pos = pos + 2
      } else if chars[pos + 1] == '{' && pos + 3 < chars.length() &&
                chars[pos + 2] == '0' && chars[pos + 3] == '}' {
        builder.write_substring(text, found.start, found.end - found.start)
        pos = pos + 4
      } else {
        builder.write_char('$')
        pos = pos + 1
      }
    } else {
      builder.write_char(chars[pos])
      pos = pos + 1
    }
  }
}

///|
pub fn Regex::contains(self : Regex, text : String) -> Bool {
  match self.find(text) {
    Some(_) => true
    None => false
  }
}

///|
/// Build backwards from the accepting state, so each fragment returns its
/// entry state and its continuation is already known.
fn compile_nfa(node : Node) -> Nfa {
  let states : Array[State] = [Accept]
  let start = compile_to(node, 0, states)
  { states, start, }
}

///|
fn emit(states : Array[State], state : State) -> Int {
  let index = states.length()
  states.push(state)
  index
}

///|
fn compile_to(node : Node, next : Int, states : Array[State]) -> Int {
  match node {
    Empty => next
    Lit(c) => emit(states, Char(c, next))
    Class(items, negated) => emit(states, CharClass(items, negated, next))
    Dot => emit(states, Any(next))
    Start => emit(states, Begin(next))
    End => emit(states, Finish(next))
    Concat(a, b) => {
      let right = compile_to(b, next, states)
      compile_to(a, right, states)
    }
    Alt(a, b) => {
      let left = compile_to(a, next, states)
      let right = compile_to(b, next, states)
      emit(states, Split(left, right))
    }
    Star(a) => {
      let split = emit(states, Split(0, next))
      let body = compile_to(a, split, states)
      states[split] = Split(body, next)
      split
    }
    Plus(a) => {
      let split = emit(states, Split(0, next))
      let body = compile_to(a, split, states)
      states[split] = Split(body, next)
      body
    }
    Optional(a) => {
      let body = compile_to(a, next, states)
      emit(states, Split(body, next))
    }
    Count(a, min, max) => {
      let mut continuation = next
      if max < 0 {
        continuation = compile_to(Star(a), continuation, states)
      } else {
        let mut optional_count = max - min
        while optional_count > 0 {
          continuation = compile_to(Optional(a), continuation, states)
          optional_count = optional_count - 1
        }
      }
      let mut required_count = min
      while required_count > 0 {
        continuation = compile_to(a, continuation, states)
        required_count = required_count - 1
      }
      continuation
    }
  }
}

/// A cached DFA transition between canonical epsilon-closed NFA subsets.
priv struct DfaEdge {
  from : Array[Int]
  code : Int
  at_end : Bool
  to : Array[Int]
}

fn same_subset(a : Array[Int], b : Array[Int]) -> Bool {
  if a.length() != b.length() { return false }
  for i in 0..<a.length() {
    if a[i] != b[i] { return false }
  }
  true
}

fn class_matches(items : Array[ClassItem], negated : Bool, code : Int) -> Bool {
  let mut inside = false
  for item in items {
    match item {
      Single(c) => if code == c.to_int() { inside = true }
      Range(a, b) => if code >= a.to_int() && code <= b.to_int() { inside = true }
    }
  }
  if negated { !inside } else { inside }
}

///|
/// Expand epsilon transitions iteratively. Visited states stop nullable loops.
fn closure(
  nfa : Nfa,
  seeds : Array[Int],
  pos : Int,
  text_length : Int,
) -> Array[Int] {
  let seen : Array[Bool] = []
  for _ in nfa.states {
    seen.push(false)
  }
  let pending : Array[Int] = []
  for state in seeds {
    pending.push(state)
  }
  let active : Array[Int] = []
  while pending.length() > 0 {
    let state = pending.pop().unwrap()
    if !seen[state] {
      seen[state] = true
      match nfa.states[state] {
        Split(a, b) => {
          pending.push(a)
          pending.push(b)
        }
        Begin(next) => if pos == 0 { pending.push(next) }
        Finish(next) => if pos == text_length { pending.push(next) }
        _ => ()
      }
    }
  }
  // State-index order makes each subset a stable DFA state key.
  for i in 0..<seen.length() {
    if seen[i] {
      match nfa.states[i] {
        Accept | Char(_, _) | CharClass(_, _, _) | Any(_) => active.push(i)
        _ => ()
      }
    }
  }
  active
}

fn dfa_step(
  nfa : Nfa,
  active : Array[Int],
  code : Int,
  pos : Int,
  text_length : Int,
  cache : Array[DfaEdge],
) -> Array[Int] {
  let at_end = pos == text_length
  for edge in cache {
    if edge.code == code && edge.at_end == at_end && same_subset(edge.from, active) {
      return edge.to
    }
  }
  let seeds : Array[Int] = []
  for state in active {
    match nfa.states[state] {
      Char(c, next) => if code == c.to_int() { seeds.push(next) }
      CharClass(items, negated, next) =>
        if class_matches(items, negated, code) { seeds.push(next) }
      Any(next) => seeds.push(next)
      _ => ()
    }
  }
  let to = closure(nfa, seeds, pos, text_length)
  if cache.length() == 256 { cache.clear() }
  cache.push({ from: active, code, at_end, to, })
  to
}

///|
/// Simulate one input boundary at a time and retain the furthest acceptance.
fn match_end(nfa : Nfa, text : String, start : Int, cache : Array[DfaEdge]) -> Int? {
  let mut active = closure(nfa, [nfa.start], start, text.length())
  let mut pos = start
  let mut longest : Int? = None
  while true {
    for state in active {
      if state == 0 {
        longest = Some(pos)
      }
    }
    if pos == text.length() || active.length() == 0 {
      break
    }
    pos = pos + 1
    active = dfa_step(nfa, active, text[pos - 1].to_int(), pos, text.length(), cache)
  }
  longest
}
