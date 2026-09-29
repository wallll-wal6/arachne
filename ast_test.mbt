// Copyright 2026 Arachne Authors
// Licensed under the Apache License, Version 2.0.

///|
fn render(pattern : String) -> String raise Error {
  match parse(pattern) {
    Ok(n) => n.to_pattern()
    Err(_) => {
      assert_true(false)
      ""
    }
  }
}

///|
test "renders literals and dots" {
  assert_eq(render("a"), "a")
  assert_eq(render("ab"), "ab")
  assert_eq(render("."), ".")
  assert_eq(render("\\."), "\\.")
}

///|
test "renders alternation and quantifiers" {
  assert_eq(render("a|b"), "(a|b)")
  assert_eq(render("a*"), "a*")
  assert_eq(render("a+"), "a+")
  assert_eq(render("a?"), "a?")
}

///|
test "renders groups with correct wrapping" {
  assert_eq(render("(ab)*"), "(ab)*")
  assert_eq(render("(a|b)c"), "(a|b)c")
  assert_eq(render("(a*)*"), "(a*)*")
}

///|
test "round-trips a few patterns" {
  assert_eq(render(render("(ab|cd)*")), "(ab|cd)*")
  assert_eq(render(render("a(b|c)d")), "a(b|c)d")
}
