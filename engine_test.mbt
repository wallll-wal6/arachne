// Copyright 2026 Arachne Authors
// Licensed under the Apache License, Version 2.0.

///|
fn regex(pattern : String) -> Regex {
  match Regex::compile(pattern) {
    Ok(r) => r
    Err(_) => abort("unexpected compile failure")
  }
}

///|
test "literal full match" {
  assert_true(regex("a").full_match("a"))
  assert_true(!regex("a").full_match("b"))
  assert_true(!regex("a").full_match("ab"))
}

///|
test "concatenation" {
  assert_true(regex("ab").full_match("ab"))
  assert_true(!regex("ab").full_match("a"))
  assert_true(!regex("ab").full_match("abc"))
}

///|
test "alternation" {
  assert_true(regex("a|b").full_match("a"))
  assert_true(regex("a|b").full_match("b"))
  assert_true(!regex("a|b").full_match("c"))
}

///|
test "star" {
  assert_true(regex("a*").full_match(""))
  assert_true(regex("a*").full_match("a"))
  assert_true(regex("a*").full_match("aaa"))
  assert_true(!regex("a*").full_match("b"))
}

///|
test "plus" {
  assert_true(!regex("a+").full_match(""))
  assert_true(regex("a+").full_match("a"))
  assert_true(regex("a+").full_match("aaa"))
}

///|
test "optional" {
  assert_true(regex("a?").full_match(""))
  assert_true(regex("a?").full_match("a"))
  assert_true(!regex("a?").full_match("aa"))
}

///|
test "dot matches any single code unit" {
  assert_true(regex(".").full_match("x"))
  assert_true(!regex(".").full_match(""))
  assert_true(!regex(".").full_match("xy"))
}

///|
test "groups and precedence" {
  assert_true(regex("(ab|cd)e").full_match("abe"))
  assert_true(regex("(ab|cd)e").full_match("cde"))
  assert_true(!regex("(ab|cd)e").full_match("abx"))
}

///|
test "nested nullable quantifiers do not loop" {
  assert_true(regex("(a?)*").full_match(""))
  assert_true(regex("(a?)*").full_match("aaa"))
  assert_true(regex("(a*)*").full_match("aaa"))
}

///|
test "empty pattern" {
  assert_true(regex("").full_match(""))
  assert_true(!regex("").full_match("a"))
}

///|
test "find returns the leftmost, longest match" {
  assert_eq(regex("a").find("ba"), Some({ start: 1, end: 2, }))
  assert_eq(regex("ab").find("xxabyy"), Some({ start: 2, end: 4, }))
  assert_eq(regex("a").find("xyz"), None)
  assert_eq(regex("a|ab").find("ab"), Some({ start: 0, end: 2, }))
  assert_eq(regex("").find("abc"), Some({ start: 0, end: 0, }))
}

///|
test "contains reports whether a match exists" {
  assert_true(regex("a").contains("ba"))
  assert_true(!regex("a").contains("xyz"))
}

///|
test "pattern accessor" {
  assert_eq(regex("abc").pattern(), "abc")
}

///|
test "anchors assert input boundaries during search" {
  assert_eq(regex("^ab").find("abxx"), Some({ start: 0, end: 2, }))
  assert_eq(regex("^ab").find("xxab"), None)
  assert_eq(regex("ab$").find("xxab"), Some({ start: 2, end: 4, }))
  assert_eq(regex("ab$").find("abxx"), None)
  assert_eq(regex("^$").find(""), Some({ start: 0, end: 0, }))
  assert_eq(regex("^$").find("x"), None)
  assert_eq(regex("$").find("ab"), Some({ start: 2, end: 2, }))
}

///|
test "escaped anchors and dot remain literals" {
  assert_true(regex("\\^\\$\\.").full_match("^$."))
  assert_eq(regex("\\$").find("a$b"), Some({ start: 1, end: 2, }))
}

///|
test "nullable loops and alternative lengths" {
  assert_eq(regex("(a?)*b").find("aaab"), Some({ start: 0, end: 4, }))
  assert_eq(regex("(a*)*").find("aa"), Some({ start: 0, end: 2, }))
  assert_eq(regex("(a?)+").find(""), Some({ start: 0, end: 0, }))
  assert_eq(regex("a|ab|abc").find("abc"), Some({ start: 0, end: 3, }))
  assert_eq(regex("a*").find("baaa"), Some({ start: 0, end: 0, }))
}

///|
test "many overlapping optional paths share active states" {
  let r = regex("a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?a?aaaaaaaaaaaaaaaaaaaa")
  assert_true(r.full_match("aaaaaaaaaaaaaaaaaaaa"))
  assert_true(!r.full_match("aaaaaaaaaaaaaaaaaaa"))
}

test "classes, negation, ranges, and literal punctuation" {
  assert_true(regex("[a-cx]+").full_match("abxc"))
  assert_true(!regex("[a-cx]+").full_match("abyd"))
  assert_true(regex("[^0-9]{2}").full_match("ab"))
  assert_true(!regex("[^0-9]{2}").full_match("a2"))
  assert_true(regex("[\\-\\]]+").full_match("-]-"))
  assert_eq(regex("[0-9]+").find("ab12cd"), Some({ start: 2, end: 4, }))
}

test "counted repetitions and anchors" {
  assert_true(regex("^(ab){2,3}$").full_match("abab"))
  assert_true(regex("^(ab){2,3}$").full_match("ababab"))
  assert_true(!regex("^(ab){2,3}$").full_match("ab"))
  assert_true(!regex("^(ab){2,3}$").full_match("abababab"))
  assert_true(regex("a{0}").full_match(""))
  assert_true(regex("a{2,}").full_match("aaaa"))
  assert_eq(regex("a{1,3}").find("aaaa"), Some({ start: 0, end: 3, }))
}

test "DFA cache handles end assertions at distinct boundaries" {
  assert_eq(regex("a*$").find("baaa"), Some({ start: 1, end: 4, }))
  assert_eq(regex("(a?)*b$").find("xaab"), Some({ start: 1, end: 4, }))
}

test "find_all returns non-overlapping leftmost matches" {
  assert_eq(
    regex("a+").find_all("baaacaa"),
    [{ start: 1, end: 4, }, { start: 5, end: 7, }],
  )
  assert_eq(
    regex("").find_all("ab"),
    [{ start: 0, end: 0, }, { start: 1, end: 1, }, { start: 2, end: 2, }],
  )
  assert_eq(regex("z").find_all("abc"), [])
}

test "matches can return their text" {
  match regex("[0-9]+").find("room 42") {
    Some(found) => assert_eq(found.text("room 42"), "42")
    None => assert_true(false)
  }
}

test "replacement handles the full match and escaped dollar" {
  let digits = regex("[0-9]+")
  assert_eq(digits.replace_all("room 12 and 4", "#$0"), "room #12 and #4")
  assert_eq(digits.replace_first("room 12 and 4", "$$0"), "room $0 and 4")
  assert_eq(digits.replace_n("a1b2", "x", 1), "axb2")
  assert_eq(digits.replace_n("a1b2", "x", 0), "a1b2")
  assert_eq(regex("z").replace_all("abc", "x"), "abc")
}

test "empty-pattern replacement visits each boundary once" {
  assert_eq(regex("").replace_all("ab", "x"), "xaxbx")
}

test "split retains empty fields and respects the piece limit" {
  let comma = regex(",")
  assert_eq(comma.split("a,,b,"), ["a", "", "b", ""])
  assert_eq(comma.splitn("a,,b,", 2), ["a", ",b,"])
  assert_eq(comma.splitn("a,b", 1), ["a,b"])
  assert_eq(comma.splitn("a,b", 0), [])
  assert_eq(regex("z").split("abc"), ["abc"])
  assert_eq(regex("").split("ab"), ["", "a", "b", ""])
  assert_eq(regex("").splitn("ab", 2), ["", "ab"])
}
