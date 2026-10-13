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
