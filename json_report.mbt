///|
/// Version 1 of the machine-readable report. Independent of debug enum output.
pub(all) struct ReportJsonV1 {
  schema_version : Int
  baseline_id : String
  case_count : Int
  engine_count : Int
  compatible : Bool
  runs : Array[EngineRunJsonV1]
  findings : Array[FindingJsonV1]
} derive(ToJson)

///|
pub(all) struct EngineRunJsonV1 {
  case_id : String
  engine_id : String
  outcome : EngineOutcomeJsonV1
} derive(ToJson)

///|
/// Status is compile_rejected, execution_failed, no_match, or matched.
/// Error and observation are always present on the wire, using null when absent.
pub(all) struct EngineOutcomeJsonV1 {
  status : String
  error : String?
  observation : MatchJsonV1?
}

///|
/// Captures exclude group zero; null means an unmatched capture.
/// Spans remain zero-based, end-exclusive StringView code-unit offsets.
pub(all) struct MatchJsonV1 {
  text : String
  start : Int
  end : Int
  captures : Array[String?]
}

///|
/// Baseline and actual preserve the observations behind a finding.
/// Null means the corresponding run is absent from a caller-constructed report.
pub(all) struct FindingJsonV1 {
  case_id : String
  engine_id : String
  kind : String
  detail : String
  baseline : EngineOutcomeJsonV1?
  actual : EngineOutcomeJsonV1?
}

///|
// Option's generic ToJson encoding is not the report wire format. Construct
// nullable slots explicitly to retain null keys and scalar capture strings.
pub impl ToJson for EngineOutcomeJsonV1 with fn to_json(self) {
  {
    "status": self.status.to_json(),
    "error": match self.error {
      None => null
      Some(message) => message.to_json()
    },
    "observation": match self.observation {
      None => null
      Some(observation) => ToJson::to_json(observation)
    },
  }
}

///|
pub impl ToJson for MatchJsonV1 with fn to_json(self) {
  {
    "text": self.text.to_json(),
    "start": self.start.to_json(),
    "end": self.end.to_json(),
    "captures": self.captures
    .map(capture => {
      match capture {
        None => null
        Some(text) => text.to_json()
      }
    })
    .to_json(),
  }
}

///|
pub impl ToJson for FindingJsonV1 with fn to_json(self) {
  {
    "case_id": self.case_id.to_json(),
    "engine_id": self.engine_id.to_json(),
    "kind": self.kind.to_json(),
    "detail": self.detail.to_json(),
    "baseline": match self.baseline {
      None => null
      Some(outcome) => ToJson::to_json(outcome)
    },
    "actual": match self.actual {
      None => null
      Some(outcome) => ToJson::to_json(outcome)
    },
  }
}

///|
/// Take a v1 snapshot without compiling patterns or calling adapters.
pub fn CompatibilityReport::json_v1(self : CompatibilityReport) -> ReportJsonV1 {
  let runs = self.runs.map(run => EngineRunJsonV1::{
    case_id: run.case_id,
    engine_id: run.engine_id,
    outcome: outcome_json_v1(run.outcome),
  })
  let findings = self.findings.map(finding => FindingJsonV1::{
    case_id: finding.case_id,
    engine_id: finding.engine_id,
    kind: finding_kind_name(finding.kind),
    detail: finding.detail,
    baseline: find_json_outcome(runs, finding.case_id, self.baseline_id),
    actual: find_json_outcome(runs, finding.case_id, finding.engine_id),
  })
  {
    schema_version: 1,
    baseline_id: self.baseline_id,
    case_count: self.case_count,
    engine_count: self.engine_count,
    compatible: self.is_compatible(),
    runs,
    findings,
  }
}

///|
/// Serialize a compatibility report using the version 1 wire schema.
pub fn CompatibilityReport::format_json(self : CompatibilityReport) -> String {
  self.json_v1().stringify()
}

///|
pub fn ReportJsonV1::stringify(self : ReportJsonV1) -> String {
  ToJson::to_json(self).stringify()
}

///|
fn outcome_json_v1(outcome : EngineOutcome) -> EngineOutcomeJsonV1 {
  match outcome {
    CompileRejected(message) =>
      { status: "compile_rejected", error: Some(message), observation: None, }
    ExecutionFailed(message) =>
      { status: "execution_failed", error: Some(message), observation: None, }
    Completed(None) => { status: "no_match", error: None, observation: None, }
    Completed(Some(observation)) =>
      {
        status: "matched",
        error: None,
        observation: Some({
          text: observation.text,
          start: observation.start,
          end: observation.end,
          captures: observation.captures.copy(),
        }),
      }
  }
}

///|
fn find_json_outcome(
  runs : Array[EngineRunJsonV1],
  case_id : String,
  engine_id : String,
) -> EngineOutcomeJsonV1? {
  for run in runs {
    if run.case_id == case_id && run.engine_id == engine_id {
      return Some(run.outcome)
    }
  }
  None
}
