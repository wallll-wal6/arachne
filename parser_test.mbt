// Copyright 2026 Arachne Authors
// Licensed under the Apache License, Version 2.0.

///|
fn expect(pattern : String) -> Node raise Error {
  match parse(pattern) {
    Ok(n) => n
    Err(_) => {
      assert_true(false)
      Empty
    }
  }
}

///|
fn is_err(pattern : String) -> Bool {
  match parse(pattern) {
    Ok(_) => false
    Err(_) => true
  }
}

///|
test "literals and concatenation" {
  assert_eq(expect("a"), Lit('a'))
  assert_eq(expect("ab"), Concat(Lit('a'), Lit('b')))
}

///|
test "alternation and precedence" {
  assert_eq(expect("a|b"), Alt(Lit('a'), Lit('b')))
  assert_eq(expect("ab|c"), Alt(Concat(Lit('a'), Lit('b')), Lit('c')))
}

///|
test "groups shape precedence" {
  assert_eq(
    expect("a(b|c)"),
    Concat(Lit('a'), Capture(1, Alt(Lit('b'), Lit('c')))),
  )
}

///|
test "quantifiers" {
  assert_eq(expect("a*"), Star(Lit('a')))
  assert_eq(expect("a+"), Plus(Lit('a')))
  assert_eq(expect("a?"), Optional(Lit('a')))
  assert_eq(expect("(a*)*"), Star(Capture(1, Star(Lit('a')))))
}

///|
test "dot and escapes" {
  assert_eq(expect("."), Dot)
  assert_eq(expect("\\."), Lit('.'))
  assert_eq(expect("\\\\"), Lit('\\'))
}

///|
test "empty pattern is the Empty node" {
  assert_eq(expect(""), Empty)
}

///|
test "malformed patterns are rejected" {
  assert_true(is_err("("))
  assert_true(is_err(")"))
  assert_true(is_err("*a"))
  assert_true(is_err("a\\"))
  assert_true(is_err("a**"))
}

///|
test "empty groups and alternation branches are valid" {
  assert_eq(expect("()"), Capture(1, Empty))
  assert_eq(expect("|a"), Alt(Empty, Lit('a')))
  assert_eq(expect("a|"), Alt(Lit('a'), Empty))
  assert_eq(expect("|"), Alt(Empty, Empty))
}

///|
test "errors carry the offending position" {
  match parse("a)") {
    Err(e) => assert_eq(e.pos, 1)
    Ok(_) => assert_true(false)
  }
  match parse("a{2") {
    Err(e) => assert_eq(e.pos, 3)
    Ok(_) => assert_true(false)
  }
}

///|
test "common character shorthands and control escapes" {
  assert_eq(expect("\\d"), Class([Builtin(Digit, false)], false))
  assert_eq(expect("\\W"), Class([Builtin(Word, true)], false))
  assert_eq(
    expect("[a-z\\d]"),
    Class([Range('a', 'z'), Builtin(Digit, false)], false),
  )
  assert_eq(
    expect("\\n\\t\\r"),
    Concat(Concat(Lit('\n'), Lit('\t')), Lit('\r')),
  )
  assert_eq(expect("\\v"), Lit((0x0B).to_char().unwrap()))
  assert_eq(expect("[\\n\\v]").to_pattern(), "[\\n\\v]")
  assert_eq(
    expect("[\\s\\D]"),
    Class([Builtin(Whitespace, false), Builtin(Digit, true)], false),
  )
  assert_eq(expect("\\n").to_pattern(), "\\n")
  assert_true(is_err("[\\d-a]"))
}

///|
test "word boundary assertions and class backspace escape parse" {
  assert_eq(expect("\\b"), WordBoundary)
  assert_eq(expect("\\B"), NotWordBoundary)
  assert_eq(expect("[\\b]"), Class([Single((0x08).to_char().unwrap())], false))
  assert_eq(expect("[\\b]").to_pattern(), "[\\b]")
}

///|
test "parser advances over Unicode scalar values" {
  assert_eq(expect("🐈"), Lit('🐈'))
  assert_eq(expect("a🐈b"), Concat(Concat(Lit('a'), Lit('🐈')), Lit('b')))
}

///|
test "Unicode general category properties parse and normalize aliases" {
  assert_eq(expect("\\p{L}"), Class([Property("L", false)], false))
  assert_eq(expect("\\P{Decimal_Number}"), Class([Property("Nd", true)], false))
  assert_eq(expect("[\\p{Letter}\\p{N}]").to_pattern(), "[\\p{L}\\p{N}]")
  assert_true(is_err("\\p{Bogus}"))
  assert_true(is_err("\\pL"))
  assert_true(is_err("[\\p{L}-z]"))
}

///|
test "character classes and ranges parse" {
  assert_eq(expect("[a-cx]"), Class([Range('a', 'c'), Single('x')], false))
  assert_eq(expect("[^0-9]"), Class([Range('0', '9')], true))
  assert_eq(expect("[\\-\\]]"), Class([Single('-'), Single(']')], false))
  assert_eq(expect("[a-cx]").to_pattern(), "[a-cx]")
}

///|
test "counted repetitions parse" {
  assert_eq(expect("a{2}"), Count(Lit('a'), 2, 2))
  assert_eq(
    expect("(ab){1,3}"),
    Count(Capture(1, Concat(Lit('a'), Lit('b'))), 1, 3),
  )
  assert_eq(expect("a{2,}"), Count(Lit('a'), 2, -1))
  assert_eq(expect("a{0}"), Count(Lit('a'), 0, 0))
  assert_eq(expect("a{2,}").to_pattern(), "a{2,}")
}

///|
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

///|
test "count parsing rejects integers before they can overflow" {
  assert_true(is_err("a{999999999999999999999999999999999999999999999999}"))
  assert_true(is_err("a{1001}"))
  assert_eq(expect("a{1000}"), Count(Lit('a'), 1000, 1000))
}

///|
test "parser limits pattern length, nesting, and capture count" {
  let long = StringBuilder()
  for _ in 0..<1025 {
    long.write_char('a')
  }
  assert_true(is_err(long.to_string()))

  let nested = StringBuilder()
  for _ in 0..<129 {
    nested.write_char('(')
  }
  nested.write_char('a')
  for _ in 0..<129 {
    nested.write_char(')')
  }
  assert_true(is_err(nested.to_string()))

  let many_groups = StringBuilder()
  for _ in 0..<257 {
    many_groups.write_string("(a)")
  }
  assert_true(is_err(many_groups.to_string()))
}
