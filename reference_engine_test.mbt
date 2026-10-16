///|
test "reference NFA parses precedence classes escapes and repetition" {
  let engine = @arachne.reference_ascii_adapter()
  let report = @arachne.run_contracts(
    [
      @arachne.ContractCase::expect_match_span(
        id="alternation-and-greedy-repeat",
        pattern="^(ab|a)+[0-9]?$",
        input="aba2",
        text="aba2",
        captures=[],
        start=0,
        end=4,
      ),
      @arachne.ContractCase::expect_match(
        id="negated-class-and-search",
        pattern="[^a-c]+",
        input="abc--x!",
        text="--x!",
        captures=[],
      ),
      @arachne.ContractCase::expect_match(
        id="digit-escape",
        pattern="\\d+",
        input="id-2048-end",
        text="2048",
        captures=[],
      ),
      @arachne.ContractCase::expect_no_match(
        id="end-anchor",
        pattern="^cat$",
        input="cats",
      ),
    ],
    [engine],
    "arachne/reference-nfa (ASCII)",
  ).unwrap()
  assert_eq(
    report.runs[0].outcome,
    @arachne.EngineOutcome::Completed(
      Some({ text: "aba2", start: 0, end: 4, captures: [], }),
    ),
  )
  assert_eq(report.runs[3].outcome, @arachne.EngineOutcome::Completed(None))
  assert_eq(report.format_findings(), "")
  match report.runs[2].outcome {
    @arachne.EngineOutcome::Completed(Some(observation)) => {
      assert_eq(observation.start, 3)
      assert_eq(observation.end, 7)
    }
    _ => abort("the digit escape should match its longest run")
  }
}

///|
test "reference NFA returns leftmost-longest and empty matches" {
  let engine = @arachne.reference_ascii_adapter()
  let report = @arachne.run_contracts(
    [
      @arachne.ContractCase::expect_match(
        id="leftmost-longest-alternative",
        pattern="a|ab",
        input="zab",
        text="ab",
        captures=[],
      ),
      @arachne.ContractCase::expect_match_span(
        id="empty-pattern",
        pattern="",
        input="abc",
        text="",
        captures=[],
        start=0,
        end=0,
      ),
    ],
    [engine],
    "arachne/reference-nfa (ASCII)",
  ).unwrap()
  assert_true(report.is_compatible())
}

///|
test "reference NFA rejects unsupported syntax instead of misreading it" {
  let engine = @arachne.reference_ascii_adapter()
  let invalid_patterns = ["(", "[a-", "a**", "(?=a)", "\\1", "\\p{L}"]
  for pattern in invalid_patterns {
    let report = @arachne.run_contracts(
      [@arachne.ContractCase::new(id=pattern, pattern~, input="a")],
      [engine],
      "arachne/reference-nfa (ASCII)",
    ).unwrap()
    match report.runs[0].outcome {
      @arachne.EngineOutcome::CompileRejected(message) =>
        assert_true(message != "")
      _ => abort("unsupported patterns must be rejected at compile time")
    }
  }
}

///|
test "reference NFA exposes its ASCII and capture boundaries" {
  let engine = @arachne.reference_ascii_adapter()
  let report = @arachne.run_contracts(
    [@arachne.ContractCase::new(id="non-ascii-input", pattern="a", input="猫")],
    [engine],
    "arachne/reference-nfa (ASCII)",
  ).unwrap()
  match report.runs[0].outcome {
    @arachne.EngineOutcome::ExecutionFailed(message) =>
      assert_true(message.contains("ASCII"))
    _ => abort("non-ASCII input must be refused explicitly")
  }
  match (engine.compile)("(a)") {
    Err(message) => abort(message)
    Ok(matcher) =>
      match (matcher.observe)("a") {
        Err(message) => abort(message)
        Ok(Some(observation)) => assert_true(observation.captures.is_empty())
        _ => abort("a structural group should still match its contents")
      }
  }
}

///|
test "reference NFA handles a long anchored near miss without backtracking" {
  let input = String::make(4096, 'a') + "!"
  let report = @arachne.run_contracts(
    [
      @arachne.ContractCase::expect_no_match(
        id="nested-repetition-near-miss",
        pattern="^(a+)+$",
        input~,
      ),
    ],
    [@arachne.reference_ascii_adapter()],
    "arachne/reference-nfa (ASCII)",
  ).unwrap()
  assert_true(report.is_compatible())
}

///|
test "reference NFA agrees with the official engine on selected regular cases" {
  let report = @arachne.run_contracts(
    [
      @arachne.ContractCase::expect_match(
        id="request-id",
        pattern="^req-[0-9]+$",
        input="req-42",
        text="req-42",
        captures=[],
      ),
      @arachne.ContractCase::expect_match(
        id="email-like-token",
        pattern="[A-Za-z0-9_]+@[A-Za-z0-9_]+",
        input="contact: dev_1@moonbit",
        text="dev_1@moonbit",
        captures=[],
      ),
    ],
    [@arachne.moonbit_regexp_adapter(), @arachne.reference_ascii_adapter()],
    "moonbitlang/regexp",
  ).unwrap()
  assert_true(report.is_compatible())
}
