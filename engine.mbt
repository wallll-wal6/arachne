// Copyright 2026 Arachne Authors
// Licensed under the Apache License, Version 2.0.

///|
/// Thompson NFA instructions. Assertions consume no input.
pub enum State {
  Accept
  Char(Char, Int)
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
  match match_end(self.nfa, text, 0) {
    Some(end) => end == text.length()
    None => false
  }
}

///|
/// Finds the leftmost, longest match anywhere in text.
pub fn Regex::find(self : Regex, text : String) -> Match? {
  let mut start = 0
  while start <= text.length() {
    match match_end(self.nfa, text, start) {
      Some(end) => return Some({ start, end, })
      None => ()
    }
    start = start + 1
  }
  None
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
  }
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
        _ => active.push(state)
      }
    }
  }
  active
}

///|
/// Simulate one input boundary at a time and retain the furthest acceptance.
fn match_end(nfa : Nfa, text : String, start : Int) -> Int? {
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
    let seeds : Array[Int] = []
    for state in active {
      match nfa.states[state] {
        Char(c, next) =>
          if text[pos].to_int() == c.to_int() {
            seeds.push(next)
          }
        Any(next) => seeds.push(next)
        _ => ()
      }
    }
    pos = pos + 1
    active = closure(nfa, seeds, pos, text.length())
  }
  longest
}
