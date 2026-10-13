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
