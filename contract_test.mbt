///|
test "MoonBit regexp adapter preserves match and capture observations" {
  let adapter = moonbit_regexp_adapter()
  let report = match
    run_contracts(
      [
        ContractCase::expect_match(
          id="repeat-capture",
          pattern="(ab)+",
          input="zzabab!",
          text="abab",
          captures=[Some("ab")],
        ),
      ],
      [adapter],
      "moonbitlang/regexp",
    ) {
    Ok(report) => report
    Err(_) => abort("valid one-engine contract should run")
  }
  assert_eq(report.runs.length(), 1)
  assert_true(report.findings.is_empty())
  match report.runs[0].outcome {
    EngineOutcome::Completed(Some(observation)) => {
      assert_eq(observation.start, 2)
      assert_eq(observation.end, 6)
      assert_eq(observation.captures, [Some("ab")])
    }
    _ => abort("the official engine should produce a match")
  }
}

///|
test "golden contract detects a Unicode match-span regression" {
  let report = match
    run_contracts(
      [
        ContractCase::expect_match_span(
          id="supplementary-prefix-offset",
          pattern="(a)",
          input="🦊a",
          text="a",
          captures=[Some("a")],
          start=2,
          end=3,
        ),
      ],
      [moonbit_regexp_adapter()],
      "moonbitlang/regexp",
    ) {
    Ok(report) => report
    Err(_) => abort("valid span contract should run")
  }
  assert_true(report.is_compatible())
  match report.runs[0].outcome {
    EngineOutcome::Completed(Some(observation)) => {
      assert_eq(observation.start, 2)
      assert_eq(observation.end, 3)
    }
    _ => abort("the official engine should produce a match")
  }
}

///|
test "span expectations fail when an adapter reports a different offset" {
  let wrong_span = EngineAdapter::new(id="wrong-span", compile=_pattern => {
    Ok(
      CompiledMatcher::new(observe=_input => {
        Ok(Some({ text: "a", start: 0, end: 1, captures: [], }))
      }),
    )
  })
  let report = match
    run_contracts(
      [
        ContractCase::expect_match_span(
          id="span-contract",
          pattern="a",
          input="ba",
          text="a",
          captures=[],
          start=1,
          end=2,
        ),
      ],
      [wrong_span],
      "wrong-span",
    ) {
    Ok(report) => report
    Err(_) => abort("valid span expectation should run")
  }
  assert_eq(report.findings.length(), 1)
  assert_eq(report.findings[0].detail, "match span differs from the contract")
}

///|
test "contract runner rejects invalid expected spans before invoking adapters" {
  let compile_count = [0]
  let adapter = EngineAdapter::new(id="counted", compile=_pattern => {
    compile_count[0] = compile_count[0] + 1
    Ok(CompiledMatcher::new(observe=_input => Ok(None)))
  })
  let invalid = ContractCase::expect_match_span(
    id="outside-input",
    pattern="a",
    input="a",
    text="a",
    captures=[],
    start=0,
    end=2,
  )
  assert_true(
    run_contracts([invalid], [adapter], "counted")
    is Err(ContractError::InvalidExpectedSpan("outside-input")),
  )
  assert_eq(compile_count[0], 0)
}

///|
test "contract runner detects cross-engine behavior drift" {
  let reference = moonbit_regexp_adapter()
  let alternate = EngineAdapter::new(id="fixture-engine", compile=_pattern => {
    Ok(
      CompiledMatcher::new(observe=_input => {
        Ok(Some({ text: "a", start: 0, end: 1, captures: [], }))
      }),
    )
  })
  let report = match
    run_contracts(
      [ContractCase::new(id="greedy-search", pattern="a+", input="baaa")],
      [reference, alternate],
      "moonbitlang/regexp",
    ) {
    Ok(report) => report
    Err(_) => abort("valid two-engine contract should run")
  }
  assert_eq(report.runs.length(), 2)
  assert_eq(report.findings.length(), 2)
  assert_true(report.findings[0].kind == FindingKind::MatchedTextDiff)
  assert_true(report.findings[1].kind == FindingKind::MatchSpanDiff)
}

///|
test "contract runner detects capture differences and exposes stable reports" {
  let baseline = EngineAdapter::new(id="capture-base", compile=_pattern => {
    Ok(
      CompiledMatcher::new(observe=_input => {
        Ok(Some({ text: "ab", start: 0, end: 2, captures: [Some("a")], }))
      }),
    )
  })
  let candidate = EngineAdapter::new(id="capture-candidate", compile=_pattern => {
    Ok(
      CompiledMatcher::new(observe=_input => {
        Ok(Some({ text: "ab", start: 0, end: 2, captures: [Some("b")], }))
      }),
    )
  })
  let report = match
    run_contracts(
      [ContractCase::new(id="capture", pattern="(a)(b)", input="ab")],
      [baseline, candidate],
      "capture-base",
    ) {
    Ok(report) => report
    Err(_) => abort("valid capture contract should run")
  }
  assert_true(!report.is_compatible())
  assert_eq(
    report.summary(),
    "baseline=capture-base cases=1 engines=2 findings=1 compatible=false",
  )
  assert_true(report.format_findings().contains("capture-candidate"))
  assert_true(report.findings[0].kind == FindingKind::CaptureDiff)
}

///|
test "contract runner distinguishes compile acceptance from execution drift" {
  let rejects_all = EngineAdapter::new(id="rejecting-engine", compile=_pattern => {
    Err("unsupported syntax")
  })
  let accepts = EngineAdapter::new(id="accepting-engine", compile=_pattern => {
    Ok(CompiledMatcher::new(observe=_input => Ok(None)))
  })
  let report = match
    run_contracts(
      [ContractCase::new(id="invalid-here", pattern="(", input="x")],
      [rejects_all, accepts],
      "rejecting-engine",
    ) {
    Ok(report) => report
    Err(_) => abort("valid adapter configuration should run")
  }
  assert_eq(report.findings.length(), 1)
  assert_true(report.findings[0].kind == FindingKind::CompileAcceptanceDiff)
}

///|
test "contract runner rejects duplicate case identifiers" {
  let adapter = moonbit_regexp_adapter()
  let result = run_contracts(
    [
      ContractCase::new(id="same", pattern="a", input="a"),
      ContractCase::new(id="same", pattern="b", input="b"),
    ],
    [adapter],
    "moonbitlang/regexp",
  )
  assert_true(result is Err(ContractError::DuplicateCase("same")))
}

///|
test "contract runner validates baseline selection" {
  let result = run_contracts([], [moonbit_regexp_adapter()], "missing")
  assert_true(result is Err(ContractError::BaselineNotFound("missing")))
}

///|
test "contract runner rejects empty adapter and duplicate engine identifiers" {
  assert_true(run_contracts([], [], "base") is Err(ContractError::NoEngines))
  assert_true(
    run_contracts([], [moonbit_regexp_adapter()], "")
    is Err(ContractError::EmptyBaseline),
  )
  let duplicate = moonbit_regexp_adapter()
  assert_true(
    run_contracts([], [duplicate, duplicate], "moonbitlang/regexp")
    is Err(ContractError::DuplicateEngine("moonbitlang/regexp")),
  )
}

///|
test "contract runner reports rejected syntax through the adapter boundary" {
  let report = match
    run_contracts(
      [ContractCase::new(id="unclosed", pattern="(", input="x")],
      [moonbit_regexp_adapter()],
      "moonbitlang/regexp",
    ) {
    Ok(report) => report
    Err(_) => abort("valid engine configuration should run")
  }
  assert_true(report.runs[0].outcome is EngineOutcome::CompileRejected(_))
}

///|
test "contract runner compiles a repeated pattern only once per engine" {
  let compile_count = [0]
  let counted = EngineAdapter::new(id="counted", compile=_pattern => {
    compile_count[0] = compile_count[0] + 1
    Ok(
      CompiledMatcher::new(observe=input => {
        Ok(Some({ text: input, start: 0, end: input.length(), captures: [], }))
      }),
    )
  })
  let report = match
    run_contracts(
      [
        ContractCase::new(id="first", pattern="x+", input="xx"),
        ContractCase::new(id="second", pattern="x+", input="xxx"),
      ],
      [counted],
      "counted",
    ) {
    Ok(report) => report
    Err(_) => abort("valid repeated-pattern suite should run")
  }
  assert_eq(report.case_count(), 2)
  assert_eq(report.engine_count(), 1)
  assert_eq(compile_count[0], 1)
}

///|
test "golden expectations are checked for every engine" {
  let adapter = moonbit_regexp_adapter()
  let report = match
    run_contracts(
      [ContractCase::expect_no_match(id="no-hit", pattern="^x+$", input="abc")],
      [adapter],
      "moonbitlang/regexp",
    ) {
    Ok(report) => report
    Err(_) => abort("valid contract should run")
  }
  assert_true(report.findings.is_empty())
}

///|
test "golden expectation reports an engine that returns the wrong result" {
  let wrong = EngineAdapter::new(id="wrong-engine", compile=_pattern => {
    Ok(CompiledMatcher::new(observe=_input => Ok(None)))
  })
  let report = match
    run_contracts(
      [
        ContractCase::expect_match(
          id="must-match",
          pattern="a",
          input="a",
          text="a",
          captures=[],
        ),
      ],
      [wrong],
      "wrong-engine",
    ) {
    Ok(report) => report
    Err(_) => abort("valid golden contract should run")
  }
  assert_eq(report.findings.length(), 1)
  assert_true(report.findings[0].kind == FindingKind::ExpectationFailed)
}

///|
test "Unicode corpus emits positive and adjacent negative scalar samples" {
  let cases = match unicode_category_cases(category="Lu", max_cases=2) {
    Ok(cases) => cases
    Err(_) => abort("Lu has valid scalar samples")
  }
  assert_eq(cases.length(), 2)
  assert_eq(cases[0].pattern, "^\\p{Lu}$")
  assert_eq(cases[0].input, "A")
  assert_true(
    match cases[0].expected {
      Some(ExpectedOutcome::ExpectedMatch(text~, captures~)) =>
        text == "A" && captures.is_empty()
      _ => false
    },
  )
  assert_eq(cases[1].input, "@")
  assert_true(cases[1].expected is Some(ExpectedOutcome::ExpectedNoMatch))
  let report = match
    run_contracts(cases, [moonbit_regexp_adapter()], "moonbitlang/regexp") {
    Ok(report) => report
    Err(_) => abort("valid Unicode boundary cases should run")
  }
  assert_true(report.is_compatible())
}

///|
test "Unicode corpus rejects unknown, empty, and non-scalar categories" {
  assert_true(
    unicode_category_cases(category="Unknown", max_cases=4)
    is Err(UnicodeCorpusError::UnknownCategory("Unknown")),
  )
  assert_true(
    unicode_category_cases(category="Lu", max_cases=0)
    is Err(UnicodeCorpusError::InvalidCaseLimit),
  )
  let surrogate_cases = match
    unicode_category_cases(category="Cs", max_cases=4) {
    Ok(cases) => cases
    Err(_) => abort("Cs boundaries still provide valid neighboring scalars")
  }
  assert_eq(surrogate_cases.length(), 2)
  for case in surrogate_cases {
    assert_true(case.expected is Some(ExpectedOutcome::ExpectedNoMatch))
  }
}
