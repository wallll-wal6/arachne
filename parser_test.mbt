// Copyright 2026 Arachne Authors
// Licensed under the Apache License, Version 2.0.

///|
fn expect(pattern : String) -> @arachne.Node raise Error {
  match @arachne.parse(pattern) {
    Ok(n) => n
    Err(_) => {
      assert_true(false)
      @arachne.Empty
    }
  }
}

///|
fn is_err(pattern : String) -> Bool {
  match @arachne.parse(pattern) {
    Ok(_) => false
    Err(_) => true
  }
}

///|
test "literals and concatenation" {
  assert_eq(expect("a"), @arachne.Lit('a'))
  assert_eq(expect("ab"), @arachne.Concat(@arachne.Lit('a'), @arachne.Lit('b')))
}

///|
test "alternation and precedence" {
  assert_eq(expect("a|b"), @arachne.Alt(@arachne.Lit('a'), @arachne.Lit('b')))
  assert_eq(
    expect("ab|c"),
    @arachne.Alt(
      @arachne.Concat(@arachne.Lit('a'), @arachne.Lit('b')),
      @arachne.Lit('c'),
    ),
  )
}

///|
test "groups shape precedence" {
  assert_eq(
    expect("a(b|c)"),
    @arachne.Concat(
      @arachne.Lit('a'),
      @arachne.Capture(1, @arachne.Alt(@arachne.Lit('b'), @arachne.Lit('c'))),
    ),
  )
}

///|
test "quantifiers" {
  assert_eq(expect("a*"), @arachne.Star(@arachne.Lit('a')))
  assert_eq(expect("a+"), @arachne.Plus(@arachne.Lit('a')))
  assert_eq(expect("a?"), @arachne.Optional(@arachne.Lit('a')))
  assert_eq(
    expect("(a*)*"),
    @arachne.Star(@arachne.Capture(1, @arachne.Star(@arachne.Lit('a')))),
  )
}

///|
test "dot and escapes" {
  assert_eq(expect("."), @arachne.Dot)
  assert_eq(expect("\\."), @arachne.Lit('.'))
  assert_eq(expect("\\\\"), @arachne.Lit('\\'))
}

///|
test "empty pattern is the Empty node" {
  assert_eq(expect(""), @arachne.Empty)
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
  assert_eq(expect("()"), @arachne.Capture(1, @arachne.Empty))
  assert_eq(expect("|a"), @arachne.Alt(@arachne.Empty, @arachne.Lit('a')))
  assert_eq(expect("a|"), @arachne.Alt(@arachne.Lit('a'), @arachne.Empty))
  assert_eq(expect("|"), @arachne.Alt(@arachne.Empty, @arachne.Empty))
}

///|
test "errors carry the offending position" {
  match @arachne.parse("a)") {
    Err(e) => assert_eq(e.pos, 1)
    Ok(_) => assert_true(false)
  }
  match @arachne.parse("a{2") {
    Err(e) => assert_eq(e.pos, 3)
    Ok(_) => assert_true(false)
  }
}

///|
test "common character shorthands and control escapes" {
  assert_eq(
    expect("\\d"),
    @arachne.Class([@arachne.Builtin(@arachne.Digit, false)], false),
  )
  assert_eq(
    expect("\\W"),
    @arachne.Class([@arachne.Builtin(@arachne.Word, true)], false),
  )
  assert_eq(
    expect("[a-z\\d]"),
    @arachne.Class(
      [@arachne.Range('a', 'z'), @arachne.Builtin(@arachne.Digit, false)],
      false,
    ),
  )
  assert_eq(
    expect("\\n\\t\\r"),
    @arachne.Concat(
      @arachne.Concat(@arachne.Lit('\n'), @arachne.Lit('\t')),
      @arachne.Lit('\r'),
    ),
  )
  assert_eq(expect("\\v"), @arachne.Lit((0x0B).to_char().unwrap()))
  assert_eq(expect("[\\n\\v]").to_pattern(), "[\\n\\v]")
  assert_eq(
    expect("[\\s\\D]"),
    @arachne.Class(
      [
        @arachne.Builtin(@arachne.Whitespace, false),
        @arachne.Builtin(@arachne.Digit, true),
      ],
      false,
    ),
  )
  assert_eq(expect("\\n").to_pattern(), "\\n")
  assert_true(is_err("[\\d-a]"))
}

///|
test "word boundary assertions and class backspace escape parse" {
  assert_eq(expect("\\b"), @arachne.WordBoundary)
  assert_eq(expect("\\B"), @arachne.NotWordBoundary)
  assert_eq(
    expect("[\\b]"),
    @arachne.Class([@arachne.Single((0x08).to_char().unwrap())], false),
  )
  assert_eq(expect("[\\b]").to_pattern(), "[\\b]")
}

///|
test "parser advances over Unicode scalar values" {
  assert_eq(expect("🐈"), @arachne.Lit('🐈'))
  assert_eq(
    expect("a🐈b"),
    @arachne.Concat(
      @arachne.Concat(@arachne.Lit('a'), @arachne.Lit('🐈')),
      @arachne.Lit('b'),
    ),
  )
}

///|
test "Unicode general category properties and normalize aliases" {
  assert_eq(
    expect("\\p{L}"),
    @arachne.Class([@arachne.Property("L", false)], false),
  )
  assert_eq(
    expect("\\P{Decimal_Number}"),
    @arachne.Class([@arachne.Property("Nd", true)], false),
  )
  assert_eq(expect("[\\p{Letter}\\p{N}]").to_pattern(), "[\\p{L}\\p{N}]")
  assert_true(is_err("\\p{Bogus}"))
  assert_true(is_err("\\pL"))
  assert_true(is_err("[\\p{L}-z]"))
}

///|
test "character classes and ranges" {
  assert_eq(
    expect("[a-cx]"),
    @arachne.Class([@arachne.Range('a', 'c'), @arachne.Single('x')], false),
  )
  assert_eq(expect("[^0-9]"), @arachne.Class([@arachne.Range('0', '9')], true))
  assert_eq(
    expect("[\\-\\]]"),
    @arachne.Class([@arachne.Single('-'), @arachne.Single(']')], false),
  )
  assert_eq(expect("[a-cx]").to_pattern(), "[a-cx]")
}

///|
test "counted repetitions" {
  assert_eq(expect("a{2}"), @arachne.Count(@arachne.Lit('a'), 2, 2))
  assert_eq(
    expect("(ab){1,3}"),
    @arachne.Count(
      @arachne.Capture(1, @arachne.Concat(@arachne.Lit('a'), @arachne.Lit('b'))),
      1,
      3,
    ),
  )
  assert_eq(expect("a{2,}"), @arachne.Count(@arachne.Lit('a'), 2, -1))
  assert_eq(expect("a{0}"), @arachne.Count(@arachne.Lit('a'), 0, 0))
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
  assert_eq(expect("a{1000}"), @arachne.Count(@arachne.Lit('a'), 1000, 1000))
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
