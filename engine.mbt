// Copyright 2026 Arachne Authors
// Licensed under the Apache License, Version 2.0.

///|
/// Thompson NFA instructions. Assertions consume no input.
priv enum State {
  Accept
  Char(Char, Int)
  CharClass(Array[ClassItem], Bool, Int)
  Any(Int)
  Begin(Int)
  Finish(Int)
  Boundary(Bool, Int)
  Save(Int, Int)
  Split(Int, Int)
} derive(Debug, Eq)

///|
pub extend Regex with Eq::{not_equal, equal}

///|
pub extend Regex with @moonbitlang/core/debug.Debug::{to_repr}

///|
priv struct Nfa {
  states : Array[State]
  start : Int
} derive(Debug, Eq)

///|
pub extend Match with Eq::{not_equal, equal}

///|
pub extend Match with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub struct Regex {
  priv pattern : String
  priv node : Node
  priv nfa : Nfa
  priv group_count : Int
} derive(Debug, Eq)

///|
pub extend Captures with Eq::{not_equal, equal}

///|
pub extend Captures with @moonbitlang/core/debug.Debug::{to_repr}

///|
pub(all) struct Match {
  start : Int
  end : Int
} derive(Debug, Eq)

///|
pub extend RegexSet with Eq::{not_equal, equal}

///|
pub extend RegexSet with @moonbitlang/core/debug.Debug::{to_repr}

///|
/// A complete match and the numbered capture groups within it. Group zero is
/// always the complete match; groups opened by parentheses are numbered from
/// one in opening-parenthesis order.
pub(all) struct Captures {
  priv groups : Array[Match?]
} derive(Debug, Eq)

///|
pub extend RegexSetError with Eq::{not_equal, equal}

///|
pub extend RegexSetError with @moonbitlang/core/debug.Debug::{to_repr}

///|
/// A compiled collection of patterns for routing, filtering, and rule sets.
pub(all) struct RegexSet {
  priv patterns : Array[Regex]
} derive(Debug, Eq)

///|
/// Identifies which pattern failed while a set was being compiled.
pub(all) struct RegexSetError {
  pattern_index : Int
  error : RegexError
} derive(Debug, Eq)

///|
pub fn RegexSetError::to_string(self : RegexSetError) -> String {
  "pattern " + self.pattern_index.to_string() + ": " + self.error.to_string()
}

///|
/// Compiles independent patterns, returning the index and error for the first
/// pattern that is invalid or exceeds the aggregate set budget.
pub fn RegexSet::compile(
  patterns : Array[String],
) -> Result[RegexSet, RegexSetError] {
  RegexSet::compile_with_limits(patterns, CompileLimits::standard())
}

///|
/// Compiles a rule set within application-specific budgets. The first invalid
/// pattern or the pattern that crosses the aggregate state budget is reported.
pub fn RegexSet::compile_with_limits(
  patterns : Array[String],
  limits : CompileLimits,
) -> Result[RegexSet, RegexSetError] {
  match limits.validate() {
    Some(message) =>
      return Err({ pattern_index: 0, error: RegexError::new(0, message), })
    None => ()
  }
  if patterns.length() > limits.set_patterns {
    return Err({
      pattern_index: limits.set_patterns,
      error: RegexError::new(
        0,
        "regex set exceeds " +
        limits.set_patterns.to_string() +
        " patterns (configured budget)",
      ),
    })
  }
  let compiled : Array[Regex] = []
  let mut total_states = 0
  for i, pattern in patterns {
    match Regex::compile_with_limits(pattern, limits) {
      Ok(regex) => {
        if regex.nfa.states.length() > limits.set_nfa_states - total_states {
          return Err({
            pattern_index: i,
            error: RegexError::new(
              0,
              "regex set exceeds aggregate NFA states (configured limit " +
              limits.set_nfa_states.to_string() +
              ")",
            ),
          })
        }
        total_states = total_states + regex.nfa.states.length()
        compiled.push(regex)
      }
      Err(error) => return Err({ pattern_index: i, error, })
    }
  }
  Ok({ patterns: compiled, })
}

///|
pub fn RegexSet::len(self : RegexSet) -> Int {
  self.patterns.length()
}

///|
/// Tests whether any pattern in the set matches the input.
pub fn RegexSet::is_match(self : RegexSet, text : String) -> Bool {
  for pattern in self.patterns {
    if pattern.contains(text) {
      return true
    }
  }
  false
}

///|
/// Returns matching pattern indexes in their original order.
pub fn RegexSet::matching_patterns(
  self : RegexSet,
  text : String,
) -> Array[Int] {
  let matches : Array[Int] = []
  for i, pattern in self.patterns {
    if pattern.contains(text) {
      matches.push(i)
    }
  }
  matches
}

///|
/// Returns the number of entries, including group zero.
pub fn Captures::len(self : Captures) -> Int {
  self.groups.length()
}

///|
/// Returns a capture by number. Group zero is the complete match. A group
/// that did not participate, or an out-of-range index, returns `None`.
pub fn Captures::group(self : Captures, index : Int) -> Match? {
  if index < 0 || index >= self.groups.length() {
    None
  } else {
    self.groups[index]
  }
}

///|
/// Extracts a participating capture as text.
pub fn Captures::text(self : Captures, index : Int, text : String) -> String? {
  match self.group(index) {
    Some(found) => Some(found.text(text))
    None => None
  }
}

///|
/// Compiles a pattern into a reusable Regex, or returns the first error.
pub fn Regex::compile(pattern : String) -> Result[Regex, RegexError] {
  Regex::compile_with_limits(pattern, CompileLimits::standard())
}

///|
/// Compiles a pattern within application-specific budgets. Custom values may
/// lower, but never raise, the implementation ceilings.
pub fn Regex::compile_with_limits(
  pattern : String,
  limits : CompileLimits,
) -> Result[Regex, RegexError] {
  match limits.validate() {
    Some(message) => return Err(RegexError::new(0, message))
    None => ()
  }
  match parse_with_limits(pattern, limits) {
    Ok(node) =>
      if estimate_nfa_states(node) >= limits.nfa_states {
        Err(
          RegexError::new(
            0,
            "compiled expression exceeds " +
            limits.nfa_states.to_string() +
            " NFA states (configured limit)",
          ),
        )
      } else {
        Ok({
          pattern,
          node,
          nfa: compile_nfa(node),
          group_count: capture_count(node),
        })
      }
    Err(e) => Err(e)
  }
}

///|
/// Returns the number of Thompson NFA instructions, including the accept state.
pub fn Regex::nfa_state_count(self : Regex) -> Int {
  self.nfa.states.length()
}

///|
/// Returns the number of numbered capture groups, excluding group zero.
pub fn Regex::capture_group_count(self : Regex) -> Int {
  self.group_count
}

///|
let max_nfa_states = 65536

///|
let max_regex_set_patterns = 1024

///|
let max_regex_set_nfa_states = 65536

///|
fn capped_add(a : Int, b : Int) -> Int {
  if a > max_nfa_states || b > max_nfa_states || a > max_nfa_states - b {
    max_nfa_states + 1
  } else {
    a + b
  }
}

///|
fn capped_mul(a : Int, b : Int) -> Int {
  if a == 0 || b == 0 {
    0
  } else if a > max_nfa_states || b > max_nfa_states || a > max_nfa_states / b {
    max_nfa_states + 1
  } else {
    a * b
  }
}

///|
/// Estimate the Thompson instruction count without expanding repetitions.
fn estimate_nfa_states(node : Node) -> Int {
  match node {
    Empty => 0
    Start | End | WordBoundary | NotWordBoundary => 1
    Lit(_) | Class(_, _) | Dot => 1
    Concat(a, b) => capped_add(estimate_nfa_states(a), estimate_nfa_states(b))
    Alt(a, b) =>
      capped_add(capped_add(estimate_nfa_states(a), estimate_nfa_states(b)), 1)
    Capture(_, inner) => capped_add(estimate_nfa_states(inner), 2)
    Star(inner) | Plus(inner) | Optional(inner) =>
      capped_add(estimate_nfa_states(inner), 1)
    Count(inner, min, max) => {
      let body = estimate_nfa_states(inner)
      if max < 0 {
        capped_add(capped_mul(body, min), capped_add(body, 1))
      } else {
        let required = capped_mul(body, min)
        let optional = capped_mul(capped_add(body, 1), max - min)
        capped_add(required, optional)
      }
    }
  }
}

///|
pub fn Regex::pattern(self : Regex) -> String {
  self.pattern
}

///|
pub fn Regex::full_match(self : Regex, text : String) -> Bool {
  let chars = text.to_array()
  let cache : Array[DfaEdge] = []
  match match_end(self.nfa, chars, 0, cache) {
    Some(end) => end == chars.length()
    None => false
  }
}

///|
/// Finds the leftmost, longest match anywhere in text.
pub fn Regex::find(self : Regex, text : String) -> Match? {
  let chars = text.to_array()
  match find_from(self.nfa, chars, 0) {
    Some(found) => Some(to_unit_match(found, chars))
    None => None
  }
}

///|
/// Finds non-overlapping matches from left to right. Empty matches advance by
/// one input character, so patterns such as the empty expression terminate.
pub fn Regex::find_all(self : Regex, text : String) -> Array[Match] {
  let chars = text.to_array()
  let matches : Array[Match] = []
  let mut from = 0
  let mut done = false
  while !done {
    match find_from(self.nfa, chars, from) {
      Some(found) => {
        matches.push(to_unit_match(found, chars))
        if found.end > found.start {
          from = found.end
        } else if found.end < chars.length() {
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
/// Replaces the first match. `$0` inserts the entire match, `$1` inserts the
/// first capture, and `$$` inserts a literal dollar sign. An unmatched capture
/// expands to the empty string.
pub fn Regex::replace_first(
  self : Regex,
  text : String,
  replacement : String,
) -> String {
  self.replace_n(text, replacement, 1)
}

///|
/// Replaces every non-overlapping match. Empty matches advance by one
/// character and include the final input boundary once.
pub fn Regex::replace_all(
  self : Regex,
  text : String,
  replacement : String,
) -> String {
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
  let chars = text.to_array()
  let mut from = 0
  let mut copied_until = 0
  let mut count = 0
  while true {
    if limit > 0 && count == limit {
      break
    }
    match find_from(self.nfa, chars, from) {
      Some(found) => {
        write_char_range(builder, chars, copied_until, found.start)
        let captures = match
          captures_at(self.nfa, chars, found.start, self.group_count) {
          Some(captures) => captures
          None => { groups: [Some(to_unit_match(found, chars))], }
        }
        write_replacement(builder, text, replacement, captures)
        copied_until = found.end
        count = count + 1
        if found.end > found.start {
          from = found.end
        } else if found.end < chars.length() {
          from = found.end + 1
        } else {
          break
        }
      }
      None => break
    }
  }
  write_char_range(builder, chars, copied_until, chars.length())
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
  let chars = text.to_array()
  let mut from = 0
  let mut copied_until = 0
  let mut done = false
  while !done && (limit < 0 || pieces.length() < limit - 1) {
    match find_from(self.nfa, chars, from) {
      Some(found) => {
        pieces.push(char_range_string(chars, copied_until, found.start))
        copied_until = found.end
        if found.end > found.start {
          from = found.end
        } else if found.end < chars.length() {
          from = found.end + 1
        } else {
          done = true
        }
      }
      None => done = true
    }
  }
  pieces.push(char_range_string(chars, copied_until, chars.length()))
  pieces
}

///|
priv struct SearchPath {
  state : Int
  start : Int
}

///|
fn offer_search_path(
  best : Array[Int?],
  pending : Array[Int],
  state : Int,
  start : Int,
) -> Unit {
  match best[state] {
    None => {
      best[state] = Some(start)
      pending.push(state)
    }
    Some(current) =>
      if start < current {
        best[state] = Some(start)
        pending.push(state)
      }
  }
}

///|
/// Epsilon closure that keeps the earliest start reaching each NFA state.
fn search_closure(
  nfa : Nfa,
  seeds : Array[SearchPath],
  pos : Int,
  text : Array[Char],
) -> Array[Int?] {
  let best : Array[Int?] = []
  for _ in nfa.states {
    best.push(None)
  }
  let pending : Array[Int] = []
  for seed in seeds {
    offer_search_path(best, pending, seed.state, seed.start)
  }
  while pending.length() > 0 {
    let state = pending.pop().unwrap()
    let start = best[state].unwrap()
    match nfa.states[state] {
      Split(a, b) => {
        offer_search_path(best, pending, a, start)
        offer_search_path(best, pending, b, start)
      }
      Save(_, next) => offer_search_path(best, pending, next, start)
      Begin(next) =>
        if pos == 0 {
          offer_search_path(best, pending, next, start)
        }
      Finish(next) =>
        if pos == text.length() {
          offer_search_path(best, pending, next, start)
        }
      Boundary(negated, next) =>
        if word_boundary_matches(negated, pos, text) {
          offer_search_path(best, pending, next, start)
        }
      _ => ()
    }
  }
  best
}

///|
/// Find in one forward NFA pass. For a shared state and boundary, an earlier
/// start dominates every later start because both have the same future paths.
fn find_from(nfa : Nfa, text : Array[Char], from : Int) -> Match? {
  let mut pos = from
  let mut seeds : Array[SearchPath] = [{ state: nfa.start, start: from, }]
  let mut found : Match? = None
  let mut scanning = true
  while scanning {
    let active = search_closure(nfa, seeds, pos, text)
    match active[0] {
      Some(start) =>
        match found {
          None => found = Some({ start, end: pos, })
          Some(previous) =>
            if start < previous.start ||
              (start == previous.start && pos > previous.end) {
              found = Some({ start, end: pos, })
            }
        }
      None => ()
    }
    let can_extend = match found {
      None => true
      Some(match_found) => {
        let mut can_continue = false
        for state in 1..<active.length() {
          match active[state] {
            Some(start) if start <= match_found.start => can_continue = true
            _ => ()
          }
        }
        can_continue
      }
    }
    if !can_extend || pos == text.length() {
      scanning = false
    } else {
      let next_seeds : Array[SearchPath] = []
      for state in 1..<active.length() {
        match active[state] {
          Some(start) =>
            match nfa.states[state] {
              Char(c, next) =>
                if text[pos] == c {
                  next_seeds.push({ state: next, start, })
                }
              CharClass(items, negated, next) =>
                if class_matches(items, negated, text[pos].to_int()) {
                  next_seeds.push({ state: next, start, })
                }
              Any(next) => next_seeds.push({ state: next, start, })
              _ => ()
            }
          None => ()
        }
      }
      pos = pos + 1
      seeds = next_seeds
      // New starts are added only after the old starts have consumed this
      // character, so each boundary still gets an independent leftmost seed.
      seeds.push({ state: nfa.start, start: pos, })
    }
  }
  found
}

///|
fn write_replacement(
  builder : StringBuilder,
  text : String,
  replacement : String,
  captures : Captures,
) -> Unit {
  let chars = replacement.to_array()
  let mut pos = 0
  while pos < chars.length() {
    if chars[pos] == '$' && pos + 1 < chars.length() {
      if chars[pos + 1] == '$' {
        builder.write_char('$')
        pos = pos + 2
      } else if is_ascii_digit(chars[pos + 1]) {
        let mut group = 0
        let mut end = pos + 1
        while end < chars.length() && is_ascii_digit(chars[end]) {
          if group <= captures.len() {
            group = group * 10 + chars[end].to_int() - '0'.to_int()
          }
          end = end + 1
        }
        write_capture(builder, text, captures, group)
        pos = end
      } else if chars[pos + 1] == '{' {
        let mut end = pos + 2
        let mut group = 0
        let digits_start = end
        while end < chars.length() && is_ascii_digit(chars[end]) {
          if group <= captures.len() {
            group = group * 10 + chars[end].to_int() - '0'.to_int()
          }
          end = end + 1
        }
        if end > digits_start && end < chars.length() && chars[end] == '}' {
          write_capture(builder, text, captures, group)
          pos = end + 1
        } else {
          builder.write_char('$')
          pos = pos + 1
        }
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
fn unit_offset(chars : Array[Char], char_index : Int) -> Int {
  let mut units = 0
  for i in 0..<char_index {
    units = units + (if chars[i].to_int() > 0xFFFF { 2 } else { 1 })
  }
  units
}

///|
fn to_unit_match(found : Match, chars : Array[Char]) -> Match {
  {
    start: unit_offset(chars, found.start),
    end: unit_offset(chars, found.end),
  }
}

///|
fn char_range_string(chars : Array[Char], start : Int, end : Int) -> String {
  let builder = StringBuilder()
  for i in start..<end {
    builder.write_char(chars[i])
  }
  builder.to_string()
}

///|
fn write_char_range(
  builder : StringBuilder,
  chars : Array[Char],
  start : Int,
  end : Int,
) -> Unit {
  for i in start..<end {
    builder.write_char(chars[i])
  }
}

///|
fn is_ascii_digit(c : Char) -> Bool {
  c >= '0' && c <= '9'
}

///|
fn write_capture(
  builder : StringBuilder,
  text : String,
  captures : Captures,
  group : Int,
) -> Unit {
  match captures.group(group) {
    Some(found) =>
      builder.write_substring(text, found.start, found.end - found.start)
    None => ()
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
/// Returns captures for the leftmost-longest match, or `None` when no match
/// exists. Lower-numbered groups take precedence; a repeated group reports its
/// last participating iteration.
pub fn Regex::captures(self : Regex, text : String) -> Captures? {
  let chars = text.to_array()
  match find_from(self.nfa, chars, 0) {
    Some(found) => captures_at(self.nfa, chars, found.start, self.group_count)
    None => None
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
    WordBoundary => emit(states, Boundary(false, next))
    NotWordBoundary => emit(states, Boundary(true, next))
    Concat(a, b) => {
      let right = compile_to(b, next, states)
      compile_to(a, right, states)
    }
    Alt(a, b) => {
      let left = compile_to(a, next, states)
      let right = compile_to(b, next, states)
      emit(states, Split(left, right))
    }
    Capture(group, node) => {
      let end = emit(states, Save(2 * group - 1, next))
      let body = compile_to(node, end, states)
      emit(states, Save(2 * group - 2, body))
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

///|
/// A cached DFA transition between canonical epsilon-closed NFA subsets.
priv struct DfaEdge {
  from : Array[Int]
  code : Int
  at_end : Bool
  after_word : Bool
  to : Array[Int]
}

///|
fn same_subset(a : Array[Int], b : Array[Int]) -> Bool {
  if a.length() != b.length() {
    return false
  }
  for i in 0..<a.length() {
    if a[i] != b[i] {
      return false
    }
  }
  true
}

///|
fn class_matches(items : Array[ClassItem], negated : Bool, code : Int) -> Bool {
  let mut inside = false
  for item in items {
    match item {
      Single(c) => if code == c.to_int() { inside = true }
      Range(a, b) =>
        if code >= a.to_int() && code <= b.to_int() {
          inside = true
        }
      Builtin(kind, inverted) => {
        let matches = match kind {
          Digit => code >= '0'.to_int() && code <= '9'.to_int()
          Word => is_ascii_word_code(code)
          Whitespace =>
            code == ' '.to_int() ||
            code == '\t'.to_int() ||
            code == 0x0B ||
            code == '\n'.to_int() ||
            code == '\r'.to_int() ||
            code == 0x0C
        }
        if (if inverted { !matches } else { matches }) {
          inside = true
        }
      }
      Property(name, inverted) => {
        let matches = unicode_category_matches(name, code)
        if (if inverted { !matches } else { matches }) {
          inside = true
        }
      }
    }
  }
  if negated {
    !inside
  } else {
    inside
  }
}

///|
/// ASCII definition shared by `\w`, `\b`, and `\B`.
fn is_ascii_word_code(code : Int) -> Bool {
  (code >= 'a'.to_int() && code <= 'z'.to_int()) ||
  (code >= 'A'.to_int() && code <= 'Z'.to_int()) ||
  (code >= '0'.to_int() && code <= '9'.to_int()) ||
  code == '_'.to_int()
}

///|
/// Treat positions outside the text as non-word boundaries.
fn is_word_at(text : Array[Char], pos : Int) -> Bool {
  pos >= 0 && pos < text.length() && is_ascii_word_code(text[pos].to_int())
}

///|
fn word_boundary_matches(negated : Bool, pos : Int, text : Array[Char]) -> Bool {
  let boundary = is_word_at(text, pos - 1) != is_word_at(text, pos)
  if negated {
    !boundary
  } else {
    boundary
  }
}

///|
fn unicode_category_matches(category : String, code : Int) -> Bool {
  let ranges = unicode_category_ranges(category)
  let mut low = 0
  let mut high = ranges.length()
  while low < high {
    let mid = low + (high - low) / 2
    let range = ranges[mid]
    if code < range.start {
      high = mid
    } else if code > range.end {
      low = mid + 1
    } else {
      return true
    }
  }
  false
}

///|
fn capture_count(node : Node) -> Int {
  match node {
    Capture(group, inner) => max_int(group, capture_count(inner))
    Concat(a, b) | Alt(a, b) => max_int(capture_count(a), capture_count(b))
    Star(inner) | Plus(inner) | Optional(inner) => capture_count(inner)
    Count(inner, _, _) => capture_count(inner)
    _ => 0
  }
}

///|
fn max_int(a : Int, b : Int) -> Int {
  if a > b {
    a
  } else {
    b
  }
}

///|
/// Expand epsilon transitions iteratively. Visited states stop nullable loops.
fn closure(
  nfa : Nfa,
  seeds : Array[Int],
  pos : Int,
  text : Array[Char],
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
        Save(_, next) => pending.push(next)
        Begin(next) => if pos == 0 { pending.push(next) }
        Finish(next) => if pos == text.length() { pending.push(next) }
        Boundary(negated, next) =>
          if word_boundary_matches(negated, pos, text) {
            pending.push(next)
          }
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

///|
priv struct TaggedPath {
  state : Int
  slots : Array[Int?]
}

///|
fn copy_slots(slots : Array[Int?]) -> Array[Int?] {
  let copied : Array[Int?] = []
  for value in slots {
    copied.push(value)
  }
  copied
}

///|
fn capture_path_better(candidate : Array[Int?], current : Array[Int?]) -> Bool {
  let mut slot = 0
  while slot + 1 < candidate.length() {
    match (candidate[slot], current[slot]) {
      (Some(_), None) => return true
      (None, Some(_)) => return false
      (Some(a), Some(b)) if a != b => return a > b
      _ => ()
    }
    match (candidate[slot + 1], current[slot + 1]) {
      (Some(_), None) => return true
      (None, Some(_)) => return false
      (Some(a), Some(b)) if a != b => return a > b
      _ => ()
    }
    slot = slot + 2
  }
  false
}

///|
fn offer_tagged(
  best : Array[TaggedPath?],
  pending : Array[Int],
  state : Int,
  slots : Array[Int?],
) -> Unit {
  match best[state] {
    None => {
      best[state] = Some({ state, slots, })
      pending.push(state)
    }
    Some(current) =>
      if capture_path_better(slots, current.slots) {
        best[state] = Some({ state, slots, })
        pending.push(state)
      }
  }
}

///|
/// Compute capture-aware epsilon closure. For each NFA instruction, retain
/// only the preferred capture history under the documented submatch ordering.
fn tagged_closure(
  nfa : Nfa,
  seeds : Array[TaggedPath],
  pos : Int,
  text : Array[Char],
) -> Array[TaggedPath?] {
  let best : Array[TaggedPath?] = []
  for _ in nfa.states {
    best.push(None)
  }
  let pending : Array[Int] = []
  for seed in seeds {
    offer_tagged(best, pending, seed.state, seed.slots)
  }
  while pending.length() > 0 {
    let state = pending.pop().unwrap()
    match best[state] {
      Some(path) =>
        match nfa.states[state] {
          Split(a, b) => {
            offer_tagged(best, pending, a, path.slots)
            offer_tagged(best, pending, b, path.slots)
          }
          Save(slot, next) => {
            let slots = copy_slots(path.slots)
            slots[slot] = Some(pos)
            offer_tagged(best, pending, next, slots)
          }
          Begin(next) =>
            if pos == 0 {
              offer_tagged(best, pending, next, path.slots)
            }
          Finish(next) =>
            if pos == text.length() {
              offer_tagged(best, pending, next, path.slots)
            }
          Boundary(negated, next) =>
            if word_boundary_matches(negated, pos, text) {
              offer_tagged(best, pending, next, path.slots)
            }
          _ => ()
        }
      None => ()
    }
  }
  best
}

///|
fn captures_at(
  nfa : Nfa,
  text : Array[Char],
  start : Int,
  group_count : Int,
) -> Captures? {
  let slots : Array[Int?] = []
  for _ in 0..<(2 * group_count) {
    slots.push(None)
  }
  let seeds : Array[TaggedPath] = [{ state: nfa.start, slots, }]
  let mut active = tagged_closure(nfa, seeds, start, text)
  let mut pos = start
  let mut accepted : Array[Int?]? = None
  let mut accepted_end = -1
  let mut running = true
  while running {
    match active[0] {
      Some(path) => {
        let better_capture = match accepted {
          Some(previous) => capture_path_better(path.slots, previous)
          None => true
        }
        if pos > accepted_end || (pos == accepted_end && better_capture) {
          accepted = Some(copy_slots(path.slots))
          accepted_end = pos
        }
      }
      None => ()
    }
    if pos == text.length() {
      running = false
    } else {
      let next_seeds : Array[TaggedPath] = []
      for state in 0..<active.length() {
        match active[state] {
          Some(path) =>
            match nfa.states[state] {
              Char(c, next) =>
                if text[pos].to_int() == c.to_int() {
                  next_seeds.push({ state: next, slots: path.slots, })
                }
              CharClass(items, negated, next) =>
                if class_matches(items, negated, text[pos].to_int()) {
                  next_seeds.push({ state: next, slots: path.slots, })
                }
              Any(next) => next_seeds.push({ state: next, slots: path.slots, })
              _ => ()
            }
          None => ()
        }
      }
      if next_seeds.length() == 0 {
        running = false
      } else {
        pos = pos + 1
        active = tagged_closure(nfa, next_seeds, pos, text)
      }
    }
  }
  match accepted {
    Some(final_slots) => {
      let groups : Array[Match?] = [
        Some(to_unit_match({ start, end: accepted_end, }, text)),
      ]
      for group in 0..<group_count {
        let group_start = final_slots[2 * group]
        let group_end = final_slots[2 * group + 1]
        match (group_start, group_end) {
          (Some(group_start), Some(group_end)) =>
            groups.push(
              Some(to_unit_match({ start: group_start, end: group_end, }, text)),
            )
          _ => groups.push(None)
        }
      }
      Some({ groups, })
    }
    None => None
  }
}

///|
fn dfa_step(
  nfa : Nfa,
  active : Array[Int],
  text : Array[Char],
  pos : Int,
  cache : Array[DfaEdge],
) -> Array[Int] {
  let code = text[pos - 1].to_int()
  let at_end = pos == text.length()
  let after_word = is_word_at(text, pos)
  for edge in cache {
    if edge.code == code &&
      edge.at_end == at_end &&
      edge.after_word == after_word &&
      same_subset(edge.from, active) {
      return edge.to
    }
  }
  let seeds : Array[Int] = []
  for state in active {
    match nfa.states[state] {
      Char(c, next) => if code == c.to_int() { seeds.push(next) }
      CharClass(items, negated, next) =>
        if class_matches(items, negated, code) {
          seeds.push(next)
        }
      Any(next) => seeds.push(next)
      _ => ()
    }
  }
  let to = closure(nfa, seeds, pos, text)
  if cache.length() == 256 {
    cache.clear()
  }
  cache.push({ from: active, code, at_end, after_word, to, })
  to
}

///|
/// Simulate one input boundary at a time and retain the furthest acceptance.
fn match_end(
  nfa : Nfa,
  text : Array[Char],
  start : Int,
  cache : Array[DfaEdge],
) -> Int? {
  let mut active = closure(nfa, [nfa.start], start, text)
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
    active = dfa_step(nfa, active, text, pos, cache)
  }
  longest
}

///|
test "single-pass search agrees with per-start matching on small inputs" {
  let patterns = [
    "a", "a|ab", "ab|b", "a*b", "a.*b", "^a", "b$", "(a?)*", "|a", "a|", "", "[a_]",
    "\\b", "\\B", "\\w+", "\\p{L}+",
  ]
  for pattern in patterns {
    let compiled = match Regex::compile(pattern) {
      Ok(regex) => regex
      Err(_) => abort("valid test pattern should compile")
    }
    for length in 0..<=4 {
      let mut variants = 1
      for _ in 0..<length {
        variants = variants * 3
      }
      for mask in 0..<variants {
        let builder = StringBuilder()
        let mut bits = mask
        for _ in 0..<length {
          builder.write_char(
            match bits % 3 {
              0 => 'a'
              1 => '_'
              _ => '!'
            },
          )
          bits = bits / 3
        }
        let chars = builder.to_string().to_array()
        let cache : Array[DfaEdge] = []
        let mut start = 0
        let mut reference : Match? = None
        while start <= chars.length() {
          match match_end(compiled.nfa, chars, start, cache) {
            Some(end) => {
              reference = Some(to_unit_match({ start, end, }, chars))
              break
            }
            None => start = start + 1
          }
        }
        let text = char_range_string(chars, 0, chars.length())
        assert_eq(compiled.find(text), reference)
      }
    }
  }
}
