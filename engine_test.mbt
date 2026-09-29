// Copyright 2026 Arachne Authors
// Licensed under the Apache License, Version 2.0.

fn regex(pattern : String) -> Regex raise Error {
  match Regex::compile(pattern) {
    Ok(r) => r
    Err(_) => {
      assert_true(false)
      { pattern: "", node: Empty }
    }
  }
}

test "literal full match" {
  assert_true(regex("a").full_match("a"))
  assert_true(!regex("a").full_match("b"))
  assert_true(!regex("a").full_match("ab"))
}

test "concatenation" {
  assert_true(regex("ab").full_match("ab"))
  assert_true(!regex("ab").full_match("a"))
  assert_true(!regex("ab").full_match("abc"))
}

test "alternation" {
  assert_true(regex("a|b").full_match("a"))
  assert_true(regex("a|b").full_match("b"))
  assert_true(!regex("a|b").full_match("c"))
}

test "star" {
  assert_true(regex("a*").full_match(""))
  assert_true(regex("a*").full_match("a"))
  assert_true(regex("a*").full_match("aaa"))
  assert_true(!regex("a*").full_match("b"))
}

test "plus" {
  assert_true(!regex("a+").full_match(""))
  assert_true(regex("a+").full_match("a"))
  assert_true(regex("a+").full_match("aaa"))
}

test "optional" {
  assert_true(regex("a?").full_match(""))
  assert_true(regex("a?").full_match("a"))
  assert_true(!regex("a?").full_match("aa"))
}

test "dot matches any single code unit" {
  assert_true(regex(".").full_match("x"))
  assert_true(!regex(".").full_match(""))
  assert_true(!regex(".").full_match("xy"))
}


test "groups and precedence" {
  assert_true(regex("(ab|cd)e").full_match("abe"))
  assert_true(regex("(ab|cd)e").full_match("cde"))
  assert_true(!regex("(ab|cd)e").full_match("abx"))
}

test "nested nullable quantifiers do not loop" {
  assert_true(regex("(a?)*").full_match(""))
  assert_true(regex("(a?)*").full_match("aaa"))
  assert_true(regex("(a*)*").full_match("aaa"))
}

test "empty pattern" {
  assert_true(regex("").full_match(""))
  assert_true(!regex("").full_match("a"))
}

test "find returns the leftmost, longest match" {
  assert_eq(regex("a").find("ba"), Some({ start: 1, end: 2 }))
  assert_eq(regex("ab").find("xxabyy"), Some({ start: 2, end: 4 }))
  assert_eq(regex("a").find("xyz"), None)
  assert_eq(regex("a|ab").find("ab"), Some({ start: 0, end: 2 }))
  assert_eq(regex("").find("abc"), Some({ start: 0, end: 0 }))
}

test "contains reports whether a match exists" {
  assert_true(regex("a").contains("ba"))
  assert_true(!regex("a").contains("xyz"))
}

test "pattern accessor" {
  assert_eq(regex("abc").pattern(), "abc")
}
