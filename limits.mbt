// Copyright 2026 Arachne Authors
// Licensed under the Apache License, Version 2.0.

///|
/// Resource budgets used while parsing and compiling patterns.
///
/// The standard values are also the implementation hard ceilings. Applications
/// may lower each value to fit a smaller configuration or tenant budget.
pub struct CompileLimits {
  priv pattern_scalars : Int
  priv nesting_depth : Int
  priv capture_groups : Int
  priv repetition : Int
  priv nfa_states : Int
  priv set_patterns : Int
  priv set_nfa_states : Int
} derive(Eq, Debug)

///|
pub extend CompileLimits with Eq::{not_equal, equal}

///|
pub extend CompileLimits with @moonbitlang/core/debug.Debug::{to_repr}

///|
/// Returns the documented maximum budgets supported by this implementation.
pub fn CompileLimits::standard() -> CompileLimits {
  {
    pattern_scalars: max_pattern_length,
    nesting_depth: max_group_depth,
    capture_groups: max_capture_groups,
    repetition: max_repetition,
    nfa_states: max_nfa_states,
    set_patterns: max_regex_set_patterns,
    set_nfa_states: max_regex_set_nfa_states,
  }
}

///|
/// Sets a pattern-length budget, measured in Unicode scalars. Values outside
/// the supported range are rejected when the policy is used.
pub fn CompileLimits::with_max_pattern_scalars(
  self : CompileLimits,
  value : Int,
) -> CompileLimits {
  { ..self, pattern_scalars: value, }
}

///|
/// Sets a nesting-depth budget. Values outside the supported range are rejected
/// when the policy is used.
pub fn CompileLimits::with_max_nesting_depth(
  self : CompileLimits,
  value : Int,
) -> CompileLimits {
  { ..self, nesting_depth: value, }
}

///|
/// Sets a capture-group budget. Values outside the supported range are rejected
/// when the policy is used.
pub fn CompileLimits::with_max_capture_groups(
  self : CompileLimits,
  value : Int,
) -> CompileLimits {
  { ..self, capture_groups: value, }
}

///|
/// Sets a counted-repetition budget. Values outside the supported range are
/// rejected when the policy is used.
pub fn CompileLimits::with_max_repetition(
  self : CompileLimits,
  value : Int,
) -> CompileLimits {
  { ..self, repetition: value, }
}

///|
/// Sets a per-pattern NFA-state budget. Values outside the supported range are
/// rejected when the policy is used.
pub fn CompileLimits::with_max_nfa_states(
  self : CompileLimits,
  value : Int,
) -> CompileLimits {
  { ..self, nfa_states: value, }
}

///|
/// Sets a pattern-count budget for one RegexSet. Values outside the supported
/// range are rejected when the policy is used.
pub fn CompileLimits::with_max_set_patterns(
  self : CompileLimits,
  value : Int,
) -> CompileLimits {
  { ..self, set_patterns: value, }
}

///|
/// Sets an aggregate NFA-state budget for one RegexSet. Values outside the
/// supported range are rejected when the policy is used.
pub fn CompileLimits::with_max_set_nfa_states(
  self : CompileLimits,
  value : Int,
) -> CompileLimits {
  { ..self, set_nfa_states: value, }
}

///|
fn CompileLimits::validate(self : CompileLimits) -> String? {
  if self.pattern_scalars < 0 || self.pattern_scalars > max_pattern_length {
    Some("pattern scalar limit must be between 0 and 1024")
  } else if self.nesting_depth < 0 || self.nesting_depth > max_group_depth {
    Some("nesting depth limit must be between 0 and 128")
  } else if self.capture_groups < 0 || self.capture_groups > max_capture_groups {
    Some("capture group limit must be between 0 and 256")
  } else if self.repetition < 0 || self.repetition > max_repetition {
    Some("repetition limit must be between 0 and 1000")
  } else if self.nfa_states < 0 || self.nfa_states > max_nfa_states {
    Some("NFA state limit must be between 0 and 65536")
  } else if self.set_patterns < 0 || self.set_patterns > max_regex_set_patterns {
    Some("RegexSet pattern limit must be between 0 and 1024")
  } else if self.set_nfa_states < 0 ||
    self.set_nfa_states > max_regex_set_nfa_states {
    Some("RegexSet state limit must be between 0 and 65536")
  } else {
    None
  }
}
