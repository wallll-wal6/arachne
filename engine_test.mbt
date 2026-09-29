// Copyright 2026 Arachne Authors
// Licensed under the Apache License, Version 2.0.

///|
fn regex(pattern : String) -> @arachne.Regex {
  match @arachne.Regex::compile(pattern) {
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
test "dot matches any single Unicode scalar" {
  assert_true(regex(".").full_match("x"))
  assert_true(!regex(".").full_match(""))
  assert_true(!regex(".").full_match("xy"))
}

///|
test "shorthand classes support practical field filtering" {
  assert_true(regex("\\d+").full_match("2048"))
  assert_true(!regex("\\d+").full_match("20x8"))
  assert_true(regex("[\\w.-]+").full_match("moon.log-2"))
  assert_true(!regex("\\W+").full_match("abc_12"))
  assert_true(
    regex("\\s+").full_match(" \t\n" + (0x0B).to_char().unwrap().to_string()),
  )
  assert_true(regex("[^\\d]+").full_match("room-x"))
  assert_eq(
    regex("\\d+").find("机房 42 号").map(fn(m) { m.text("机房 42 号") }),
    Some("42"),
  )
}

///|
test "word boundaries follow the ASCII word category" {
  let whole_word = regex("\\bcat\\b")
  assert_true(whole_word.full_match("cat"))
  assert_eq(whole_word.find("a cat!"), Some({ start: 2, end: 5, }))
  assert_eq(whole_word.find("scatter"), None)
  assert_true(regex("\\Bcat\\B").contains("scatter"))
  assert_eq(regex("\\b").find_all("ab cd"), [
    { start: 0, end: 0, },
    { start: 2, end: 2, },
    { start: 3, end: 3, },
    { start: 5, end: 5, },
  ])
  assert_eq(regex("\\b").replace_all("ab cd", "|"), "|ab| |cd|")
  assert_true(!regex("\\b猫\\b").contains("猫"))
  assert_true(regex("a*\\b.").full_match("aa!"))
}

///|
test "matching advances by Unicode scalar and reports UTF-16 offsets" {
  let cat = regex("🐈")
  assert_true(cat.full_match("🐈"))
  assert_true(regex(".").full_match("🐈"))
  assert_eq(cat.find("x🐈y"), Some({ start: 1, end: 3, }))
  assert_eq(regex("🐈+").replace_all("🐈🐈!", "cat"), "cat!")
  assert_eq(regex("🐈").split("a🐈b"), ["a", "b"])
}

///|
test "Unicode general categories match multilingual text" {
  assert_true(regex("[\\p{L}\\p{M}]+").full_match("東京বাংলা"))
  assert_true(regex("\\p{Lu}\\p{Ll}+").full_match("Moon"))
  assert_true(regex("\\p{N}+").full_match("١٢Ⅳ"))
  assert_true(regex("[\\p{L}\\p{N}_]+").full_match("東京_42"))
  assert_true(!regex("\\p{L}+").full_match("42"))
  assert_true(regex("\\P{L}+").full_match("42!"))
  assert_eq(
    regex("\\p{L}+").find("v2東京:ok").map(fn(m) { m.text("v2東京:ok") }),
    Some("v"),
  )
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
test "single-pass search preserves leftmost-longest behavior with live starts" {
  assert_eq(regex("ab|a").find("xaba"), Some({ start: 1, end: 3, }))
  assert_eq(regex("a.*z|b").find("abb"), Some({ start: 1, end: 2, }))
  assert_eq(regex("^a").find_all("aa"), [{ start: 0, end: 1, }])
  assert_eq(regex("$").find_all("ab"), [{ start: 2, end: 2, }])
  let input = "a".repeat(5000) + "z"
  assert_eq(regex(".*z").find(input), Some({ start: 0, end: 5001, }))
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

///|
test "classes, negation, ranges, and literal punctuation" {
  assert_true(regex("[a-cx]+").full_match("abxc"))
  assert_true(!regex("[a-cx]+").full_match("abyd"))
  assert_true(regex("[^0-9]{2}").full_match("ab"))
  assert_true(!regex("[^0-9]{2}").full_match("a2"))
  assert_true(regex("[\\-\\]]+").full_match("-]-"))
  assert_eq(regex("[0-9]+").find("ab12cd"), Some({ start: 2, end: 4, }))
}

///|
test "counted repetitions and anchors" {
  assert_true(regex("^(ab){2,3}$").full_match("abab"))
  assert_true(regex("^(ab){2,3}$").full_match("ababab"))
  assert_true(!regex("^(ab){2,3}$").full_match("ab"))
  assert_true(!regex("^(ab){2,3}$").full_match("abababab"))
  assert_true(regex("a{0}").full_match(""))
  assert_true(regex("a{2,}").full_match("aaaa"))
  assert_eq(regex("a{1,3}").find("aaaa"), Some({ start: 0, end: 3, }))
}

///|
test "DFA cache handles end assertions at distinct boundaries" {
  assert_eq(regex("a*$").find("baaa"), Some({ start: 1, end: 4, }))
  assert_eq(regex("(a?)*b$").find("xaab"), Some({ start: 1, end: 4, }))
}

///|
test "find_all returns non-overlapping leftmost matches" {
  assert_eq(regex("a+").find_all("baaacaa"), [
    { start: 1, end: 4, },
    { start: 5, end: 7, },
  ])
  assert_eq(regex("").find_all("ab"), [
    { start: 0, end: 0, },
    { start: 1, end: 1, },
    { start: 2, end: 2, },
  ])
  assert_eq(regex("z").find_all("abc"), [])
}

///|
test "matches can return their text" {
  match regex("[0-9]+").find("room 42") {
    Some(found) => assert_eq(found.text("room 42"), "42")
    None => assert_true(false)
  }
}

///|
test "replacement handles the full match and escaped dollar" {
  let digits = regex("[0-9]+")
  assert_eq(digits.replace_all("room 12 and 4", "#$0"), "room #12 and #4")
  assert_eq(digits.replace_first("room 12 and 4", "$$0"), "room $0 and 4")
  assert_eq(digits.replace_n("a1b2", "x", 1), "axb2")
  assert_eq(digits.replace_n("a1b2", "x", 0), "a1b2")
  assert_eq(regex("z").replace_all("abc", "x"), "abc")
}

///|
test "empty-pattern replacement visits each boundary once" {
  assert_eq(regex("").replace_all("ab", "x"), "xaxbx")
}

///|
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

///|
test "captures expose numbered groups and the complete match" {
  let found = match regex("([a-z]+)-([0-9]+)").captures("id=moon-42;") {
    Some(captures) => captures
    None => abort("expected a capture result")
  }
  assert_eq(found.len(), 3)
  assert_eq(found.text(0, "id=moon-42;"), Some("moon-42"))
  assert_eq(found.text(1, "id=moon-42;"), Some("moon"))
  assert_eq(found.text(2, "id=moon-42;"), Some("42"))
  assert_eq(found.group(3), None)
}

///|
test "empty capturing groups record an empty span" {
  let found = match regex("()").captures("") {
    Some(captures) => captures
    None => abort("expected the empty pattern to match")
  }
  assert_eq(found.group(0), Some({ start: 0, end: 0, }))
  assert_eq(found.group(1), Some({ start: 0, end: 0, }))
}

///|
test "unmatched optional captures are represented as none" {
  let found = match regex("(a)?b").captures("b") {
    Some(captures) => captures
    None => abort("expected a capture result")
  }
  assert_eq(found.text(0, "b"), Some("b"))
  assert_eq(found.group(1), None)
}

///|
test "captures honor leftmost-longest matching and repeated groups" {
  let found = match regex("((a|ab)+)").captures("abab") {
    Some(captures) => captures
    None => abort("expected a capture result")
  }
  assert_eq(found.text(0, "abab"), Some("abab"))
  assert_eq(found.text(1, "abab"), Some("abab"))
  assert_eq(found.text(2, "abab"), Some("ab"))
  assert_eq(regex("(a)").captures("bbb"), None)
}

///|
test "replacement expands numeric captures and leaves missing captures empty" {
  let pair = regex("([a-z]+), ([a-z]+)")
  assert_eq(pair.replace_all("doe, jane", "$2 $1"), "jane doe")
  assert_eq(regex("(a)?b").replace_first("b", "<$1>"), "<>")
  assert_eq(pair.replace_first("doe, jane", "${2}, ${1}"), "jane, doe")
  assert_eq(pair.replace_first("doe, jane", "$$$2"), "$jane")
}

///|
test "regex sets report every matching rule by stable index" {
  let set = match
    @arachne.RegexSet::compile(["^INFO", "error", "warn", "error [0-9]+"]) {
    Ok(set) => set
    Err(_) => abort("valid patterns should compile")
  }
  assert_eq(set.len(), 4)
  assert_true(set.is_match("error 503"))
  assert_eq(set.matching_patterns("error 503"), [1, 3])
  assert_eq(set.matching_patterns("INFO ready"), [0])
  assert_eq(set.matching_patterns("debug"), [])
}

///|
test "regex set compilation identifies the invalid pattern" {
  match @arachne.RegexSet::compile(["ready", "a{2"]) {
    Ok(_) => assert_true(false)
    Err(error) => {
      assert_eq(error.pattern_index, 1)
      assert_true(error.to_string().contains("pattern 1"))
    }
  }
}

///|
test "regex sets enforce pattern and aggregate state limits" {
  let too_many_patterns : Array[String] = []
  for _ in 0..<1025 {
    too_many_patterns.push("")
  }
  match @arachne.RegexSet::compile(too_many_patterns) {
    Ok(_) => assert_true(false)
    Err(error) => {
      assert_eq(error.pattern_index, 1024)
      assert_true(error.to_string().contains("1024 patterns"))
    }
  }

  let too_many_states : Array[String] = []
  for _ in 0..<66 {
    too_many_states.push("a{1000}")
  }
  match @arachne.RegexSet::compile(too_many_states) {
    Ok(_) => assert_true(false)
    Err(error) => {
      assert_eq(error.pattern_index, 65)
      assert_true(error.to_string().contains("aggregate NFA states"))
    }
  }
}

///|
test "compile rejects nested repetitions that exceed the NFA budget" {
  match @arachne.Regex::compile("(a{1000}){1000}") {
    Ok(_) => assert_true(false)
    Err(error) => assert_true(error.to_string().contains("65536 NFA states"))
  }
  assert_true(regex("a{1000}").full_match("a".repeat(1000)))
}
