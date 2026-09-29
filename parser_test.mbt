// Copyright 2026 Arachne Authors
// Licensed under the Apache License, Version 2.0.

fn expect(pattern : String) -> Node raise Error {
  match parse(pattern) {
    Ok(n) => n
    Err(_) => {
      assert_true(false)
      Empty
    }
  }
}

fn is_err(pattern : String) -> Bool {
  match parse(pattern) {
    Ok(_) => false
    Err(_) => true
  }
}

test "literals and concatenation" {
  assert_eq(expect("a"), Lit('a'))
  assert_eq(expect("ab"), Concat(Lit('a'), Lit('b')))
}

test "alternation and precedence" {
  assert_eq(expect("a|b"), Alt(Lit('a'), Lit('b')))
  assert_eq(expect("ab|c"), Alt(Concat(Lit('a'), Lit('b')), Lit('c')))
}

test "groups shape precedence" {
  assert_eq(expect("a(b|c)"), Concat(Lit('a'), Alt(Lit('b'), Lit('c'))))
}

test "quantifiers" {
  assert_eq(expect("a*"), Star(Lit('a')))
  assert_eq(expect("a+"), Plus(Lit('a')))
  assert_eq(expect("a?"), Optional(Lit('a')))
  assert_eq(expect("(a*)*"), Star(Star(Lit('a'))))
}

test "dot and escapes" {
  assert_eq(expect("."), Dot)
  assert_eq(expect("\\."), Lit('.'))
  assert_eq(expect("\\\\"), Lit('\\'))
}


test "empty pattern is the Empty node" {
  assert_eq(expect(""), Empty)
}

test "malformed patterns are rejected" {
  assert_true(is_err("a|"))
  assert_true(is_err("("))
  assert_true(is_err(")"))
  assert_true(is_err("*a"))
  assert_true(is_err("()"))
  assert_true(is_err("a\\"))
  assert_true(is_err("a**"))
}

test "errors carry the offending position" {
  match parse("a)") {
    Err(e) => assert_eq(e.pos, 1)
    Ok(_) => assert_true(false)
  }
  match parse("a|") {
    Err(e) => assert_eq(e.pos, 2)
    Ok(_) => assert_true(false)
  }
}
