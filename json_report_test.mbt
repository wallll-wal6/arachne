///|
test "public integer APIs and JSON v1 preserve signed 32-bit boundary values" {
  let count : Int32 = 2147483647
  let offset : Int32 = count - 1
  let contract = @arachne.ContractCase::expect_match_span(
    id="boundary",
    pattern="",
    input="",
    text="",
    captures=[],
    start=offset,
    end=count,
  )
  assert_eq(contract.expected_span, Some((offset, count)))
  // Serialization accepts caller-constructed observations without executing
  // an adapter. Large offsets here test numeric encoding, not a real match.
  let report : @arachne.CompatibilityReport = {
    baseline_id: "external",
    case_count: count,
    engine_count: 1,
    runs: [
      {
        case_id: contract.id,
        engine_id: "external",
        outcome: @arachne.EngineOutcome::Completed(
          Some({ text: "", start: offset, end: count, captures: [], }),
        ),
      },
    ],
    findings: [],
  }
  let actual_count : Int32 = report.case_count()
  let actual_engines : Int32 = report.engine_count()
  assert_eq((actual_count, actual_engines), (count, 1))
  let json = report.json_v1()
  assert_eq(
    (json.schema_version, json.case_count, json.engine_count),
    (1, count, 1),
  )
  let observation : @arachne.MatchJsonV1 = {
    text: "",
    start: offset,
    end: count,
    captures: [None],
  }
  assert_eq(
    ToJson::to_json(observation),
    @json.parse(
      (
        #|{"text":"","start":2147483646,"end":2147483647,"captures":[null]}
      ),
    ),
  )
  assert_eq(@json.parse(report.format_json()), ToJson::to_json(json))
}

///|
test "JSON serialization fixes nested key order and preserves array order" {
  let report : @arachne.CompatibilityReport = {
    baseline_id: "z-baseline",
    case_count: 1,
    engine_count: 1,
    runs: [
      {
        case_id: "z-case",
        engine_id: "z-baseline",
        outcome: @arachne.EngineOutcome::Completed(
          Some({
            text: "",
            start: 0,
            end: 0,
            captures: [Some("z"), None, Some("a")],
          }),
        ),
      },
    ],
    findings: [
      {
        case_id: "z-case",
        engine_id: "absent",
        kind: @arachne.FindingKind::ExpectationFailed,
        detail: "probe",
      },
    ],
  }
  let expected =
    #|{"baseline_id":"z-baseline","case_count":1,"compatible":false,"engine_count":1,"findings":[{"actual":null,"baseline":{"error":null,"observation":{"captures":["z",null,"a"],"end":0,"start":0,"text":""},"status":"matched"},"case_id":"z-case","detail":"probe","engine_id":"absent","kind":"expectation"}],"runs":[{"case_id":"z-case","engine_id":"z-baseline","outcome":{"error":null,"observation":{"captures":["z",null,"a"],"end":0,"start":0,"text":""},"status":"matched"}}],"schema_version":1}
  assert_eq(report.format_json(), expected)
  assert_eq(report.json_v1().stringify(), expected)
  assert_eq(@json.parse(expected), ToJson::to_json(report.json_v1()))
}

///|
test "JSON round trips all control characters in identifiers errors and matches" {
  let probe = "\"\\/猫🦊\u{0000}\u{0001}\u{0002}\u{0003}\u{0004}\u{0005}\u{0006}\u{0007}\u{0008}\u{0009}\u{000A}\u{000B}\u{000C}\u{000D}\u{000E}\u{000F}\u{0010}\u{0011}\u{0012}\u{0013}\u{0014}\u{0015}\u{0016}\u{0017}\u{0018}\u{0019}\u{001A}\u{001B}\u{001C}\u{001D}\u{001E}\u{001F}\u{2028}\u{2029}"
  let baseline_id = probe + "baseline"
  let report : @arachne.CompatibilityReport = {
    baseline_id,
    case_count: 1,
    engine_count: 2,
    runs: [
      {
        case_id: probe,
        engine_id: baseline_id,
        outcome: @arachne.EngineOutcome::Completed(
          Some({
            text: probe,
            start: 0,
            end: probe.length(),
            captures: [Some(probe), None, Some("")],
          }),
        ),
      },
      {
        case_id: probe,
        engine_id: probe,
        outcome: @arachne.EngineOutcome::ExecutionFailed(probe),
      },
    ],
    findings: [
      {
        case_id: probe,
        engine_id: probe,
        kind: @arachne.FindingKind::ExecutionDiff,
        detail: probe,
      },
    ],
  }
  let encoded = report.format_json()
  let observation : Json = {
    "text": ToJson::to_json(probe),
    "start": 0,
    "end": ToJson::to_json(probe.length()),
    "captures": [ToJson::to_json(probe), null, ""],
  }
  let baseline : Json = {
    "status": "matched",
    "error": null,
    "observation": observation,
  }
  let actual : Json = {
    "status": "execution_failed",
    "error": ToJson::to_json(probe),
    "observation": null,
  }
  assert_eq(@json.parse(encoded), {
    "schema_version": 1,
    "baseline_id": ToJson::to_json(baseline_id),
    "case_count": 1,
    "engine_count": 2,
    "compatible": false,
    "runs": [
      {
        "case_id": ToJson::to_json(probe),
        "engine_id": ToJson::to_json(baseline_id),
        "outcome": baseline,
      },
      {
        "case_id": ToJson::to_json(probe),
        "engine_id": ToJson::to_json(probe),
        "outcome": actual,
      },
    ],
    "findings": [
      {
        "case_id": ToJson::to_json(probe),
        "engine_id": ToJson::to_json(probe),
        "kind": "execution",
        "detail": ToJson::to_json(probe),
        "baseline": baseline,
        "actual": actual,
      },
    ],
  })
  for iteration = 0; iteration < 3; iteration = iteration + 1 {
    assert_eq(report.format_json(), encoded)
  }
}

///|
test "JSON runner preserves every difference kind and formats without execution" {
  let mut compile_calls = 0
  let mut observe_calls = 0
  fn adapter(id : String) -> @arachne.EngineAdapter {
    @arachne.EngineAdapter::new(id~, compile=pattern => {
      compile_calls += 1
      if id == "candidate" && pattern == "compile" {
        Err("compile: \"猫\"\\\n")
      } else {
        Ok(
          @arachne.CompiledMatcher::new(observe=_input => {
            observe_calls += 1
            if id == "candidate" && pattern == "execute" {
              Err("execute: \"🦊\"\\\r\t")
            } else if id == "baseline" && pattern == "presence" {
              Ok(None)
            } else if id == "candidate" && pattern == "values" {
              Ok(
                Some({
                  text: "right",
                  start: 1,
                  end: 6,
                  captures: [Some(""), None],
                }),
              )
            } else {
              Ok(
                Some({
                  text: "left",
                  start: 0,
                  end: 4,
                  captures: [None, Some("")],
                }),
              )
            }
          }),
        )
      }
    })
  }
  let cases = [
    @arachne.ContractCase::new(id="compile", pattern="compile", input=""),
    @arachne.ContractCase::new(id="execute", pattern="execute", input=""),
    @arachne.ContractCase::new(id="presence", pattern="presence", input=""),
    @arachne.ContractCase::new(id="values", pattern="values", input=""),
    @arachne.ContractCase::expect_no_match(
      id="expected",
      pattern="expected",
      input="",
    ),
  ]
  // Candidate first also exercises context lookup with a later baseline.
  let engines = [adapter("candidate"), adapter("baseline")]
  let report = @arachne.run_contracts(cases, engines, "baseline").unwrap()
  assert_eq(compile_calls, 10)
  assert_eq(observe_calls, 9)
  let model = report.json_v1()
  assert_eq(model.findings.map(finding => finding.kind), [
    "compile-acceptance", "execution", "match-presence", "matched-text", "match-span",
    "captures", "expectation", "expectation",
  ])
  assert_eq(model.runs[0].outcome.status, "compile_rejected")
  assert_eq(model.runs[0].outcome.error, Some("compile: \"猫\"\\\n"))
  assert_eq(model.runs[2].outcome.status, "execution_failed")
  assert_eq(model.runs[2].outcome.error, Some("execute: \"🦊\"\\\r\t"))
  assert_eq(ToJson::to_json(model.runs[5].outcome), {
    "status": "no_match",
    "error": null,
    "observation": null,
  })
  for index, finding in model.findings {
    assert_eq(finding.detail, report.findings[index].detail)
    let candidate_index = if index < 3 {
      index * 2
    } else if index < 6 {
      6
    } else {
      8
    }
    assert_eq(
      ToJson::to_json(finding.baseline.unwrap()),
      ToJson::to_json(model.runs[candidate_index + 1].outcome),
    )
    let actual_index = if index == 7 { 9 } else { candidate_index }
    assert_eq(
      ToJson::to_json(finding.actual.unwrap()),
      ToJson::to_json(model.runs[actual_index].outcome),
    )
  }
  let encoded = report.format_json()
  for iteration = 0; iteration < 3; iteration = iteration + 1 {
    assert_eq(report.format_json(), encoded)
    assert_eq(model.stringify(), encoded)
  }
  assert_eq(@json.parse(encoded), ToJson::to_json(model))
  assert_eq(compile_calls, 10)
  assert_eq(observe_calls, 9)
  for iteration = 0; iteration < 3; iteration = iteration + 1 {
    let repeated = @arachne.run_contracts(cases, engines, "baseline").unwrap()
    assert_eq(repeated.format_json(), encoded)
  }
  assert_eq(compile_calls, 40)
  assert_eq(observe_calls, 36)
}

///|
test "JSON v1 has a versioned empty report shape" {
  let report = @arachne.run_contracts(
    [],
    [@arachne.moonbit_regexp_adapter()],
    "moonbitlang/regexp",
  ).unwrap()
  let model = report.json_v1()
  assert_eq(model.schema_version, 1)
  assert_eq(model.case_count, 0)
  assert_eq(model.engine_count, 1)
  assert_true(model.compatible)
  assert_eq(@json.parse(report.format_json()), {
    "schema_version": 1,
    "baseline_id": "moonbitlang/regexp",
    "case_count": 0,
    "engine_count": 1,
    "compatible": true,
    "runs": [],
    "findings": [],
  })
}

///|
test "JSON snapshot resolves a later baseline and survives source mutation" {
  let captures = [None, Some("")]
  let report : @arachne.CompatibilityReport = {
    baseline_id: "baseline",
    case_count: 1,
    engine_count: 2,
    runs: [
      {
        case_id: "span",
        engine_id: "candidate",
        outcome: @arachne.EngineOutcome::Completed(
          Some({ text: "a", start: 1, end: 2, captures, }),
        ),
      },
      {
        case_id: "span",
        engine_id: "baseline",
        outcome: @arachne.EngineOutcome::Completed(
          Some({ text: "a", start: 2, end: 3, captures, }),
        ),
      },
    ],
    findings: [
      {
        case_id: "span",
        engine_id: "candidate",
        kind: @arachne.FindingKind::MatchSpanDiff,
        detail: "offset probe",
      },
    ],
  }
  let snapshot = report.json_v1()
  let original_json = snapshot.stringify()
  assert_eq(report.format_json(), original_json)
  assert_eq(snapshot.findings[0].kind, "match-span")
  assert_eq(
    snapshot.findings[0].baseline.unwrap().observation.unwrap().start,
    2,
  )
  assert_eq(snapshot.findings[0].actual.unwrap().observation.unwrap().start, 1)
  captures[0] = Some("changed")
  report.runs.clear()
  report.findings.clear()
  assert_eq(snapshot.stringify(), original_json)
  assert_eq(snapshot.runs.length(), 2)
  assert_eq(snapshot.findings.length(), 1)
  assert_eq(snapshot.runs[0].outcome.observation.unwrap().captures, [
    None,
    Some(""),
  ])
}

///|
test "JSON compatible flag retains common failures and empty error strings" {
  fn failing_adapter(id : String) -> @arachne.EngineAdapter {
    @arachne.EngineAdapter::new(id~, compile=pattern => {
      if pattern == "compile" {
        Err("")
      } else {
        Ok(@arachne.CompiledMatcher::new(observe=_input => Err("")))
      }
    })
  }
  let report = @arachne.run_contracts(
    [
      @arachne.ContractCase::new(id="compile", pattern="compile", input=""),
      @arachne.ContractCase::new(id="execute", pattern="execute", input=""),
    ],
    [failing_adapter("baseline"), failing_adapter("candidate")],
    "baseline",
  ).unwrap()
  let model = report.json_v1()
  assert_true(model.compatible)
  assert_eq(model.findings.length(), 0)
  assert_eq(model.runs.length(), 4)
  assert_eq(ToJson::to_json(model.runs[0].outcome), {
    "status": "compile_rejected",
    "error": "",
    "observation": null,
  })
  assert_eq(ToJson::to_json(model.runs[2].outcome), {
    "status": "execution_failed",
    "error": "",
    "observation": null,
  })
  assert_eq(@json.parse(report.format_json()), ToJson::to_json(model))
}

///|
test "JSON v1 preserves real engine spans and nullable captures" {
  let report = @arachne.run_contracts(
    [
      @arachne.ContractCase::expect_match_span(
        id="optional",
        pattern="(cat)?(a)",
        input="🦊a",
        text="a",
        captures=[None, Some("a")],
        start=2,
        end=3,
      ),
    ],
    [@arachne.moonbit_regexp_adapter()],
    "moonbitlang/regexp",
  ).unwrap()
  assert_eq(@json.parse(report.format_json()), {
    "schema_version": 1,
    "baseline_id": "moonbitlang/regexp",
    "case_count": 1,
    "engine_count": 1,
    "compatible": true,
    "runs": [
      {
        "case_id": "optional",
        "engine_id": "moonbitlang/regexp",
        "outcome": {
          "status": "matched",
          "error": null,
          "observation": {
            "text": "a",
            "start": 2,
            "end": 3,
            "captures": [null, "a"],
          },
        },
      },
    ],
    "findings": [],
  })
}

///|
test "JSON v1 preserves failure strings and missing finding context as null" {
  let report : @arachne.CompatibilityReport = {
    baseline_id: "missing-baseline",
    case_count: 1,
    engine_count: 1,
    runs: [
      {
        case_id: "failure",
        engine_id: "candidate",
        outcome: @arachne.EngineOutcome::ExecutionFailed("error: \"猫\"\n"),
      },
    ],
    findings: [
      {
        case_id: "failure",
        engine_id: "candidate",
        kind: @arachne.FindingKind::ExecutionDiff,
        detail: "context probe",
      },
    ],
  }
  assert_eq(@json.parse(report.format_json()), {
    "schema_version": 1,
    "baseline_id": "missing-baseline",
    "case_count": 1,
    "engine_count": 1,
    "compatible": false,
    "runs": [
      {
        "case_id": "failure",
        "engine_id": "candidate",
        "outcome": {
          "status": "execution_failed",
          "error": "error: \"猫\"\n",
          "observation": null,
        },
      },
    ],
    "findings": [
      {
        "case_id": "failure",
        "engine_id": "candidate",
        "kind": "execution",
        "detail": "context probe",
        "baseline": null,
        "actual": {
          "status": "execution_failed",
          "error": "error: \"猫\"\n",
          "observation": null,
        },
      },
    ],
  })
}
