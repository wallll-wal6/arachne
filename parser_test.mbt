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

test "character classes and ranges parse" {
  assert_eq(expect("[a-cx]"), Class([Range('a', 'c'), Single('x')], false))
  assert_eq(expect("[^0-9]"), Class([Range('0', '9')], true))
  assert_eq(expect("[\\-\\]]"), Class([Single('-'), Single(']')], false))
  assert_eq(expect("[a-cx]").to_pattern(), "[a-cx]")
}

test "counted repetitions parse" {
  assert_eq(expect("a{2}"), Count(Lit('a'), 2, 2))
  assert_eq(expect("(ab){1,3}"), Count(Concat(Lit('a'), Lit('b')), 1, 3))
  assert_eq(expect("a{2,}"), Count(Lit('a'), 2, -1))
  assert_eq(expect("a{0}"), Count(Lit('a'), 0, 0))
  assert_eq(expect("a{2,}").to_pattern(), "a{2,}")
}

test "malformed classes and counts are rejected" {
  assert_true(is_err("[]"))
  assert_true(is_err("[^]"))
  assert_true(is_err("[z-a]"))
  assert_true(is_err("[abc"))
  assert_true(is_err("a{2"))
  assert_true(is_err("a{2,1}"))
  assert_true(is_err("a{2,x}"))
  assert_true(is_err("a{1001}"))
}
