///|
/// A single engine observation normalized for cross-backend comparison.
/// Offsets are zero-based MoonBit StringView code-unit offsets.
pub(all) struct MatchObservation {
  text : String
  start : Int
  end : Int
  captures : Array[String?]
} derive(Eq, Debug)

///|
/// An opaque compiled pattern supplied by an engine adapter.
pub(all) struct CompiledMatcher {
  observe : (String) -> Result[MatchObservation?, String]
}

///|
/// An engine adapter. Implement `compile` by calling the engine under test;
/// this package never parses patterns or performs matching itself.
pub(all) struct EngineAdapter {
  id : String
  compile : (String) -> Result[CompiledMatcher, String]
}

///|
/// A pattern/input pair in a portable behavior contract.
pub(all) struct ContractCase {
  id : String
  pattern : String
  input : String
  expected : ExpectedOutcome?
  expected_span : (Int, Int)?
}

///|
pub extend MatchObservation with Eq::{equal, not_equal}

///|
pub extend MatchObservation with @moonbitlang/core/debug.Debug::{to_repr}

///|
/// Optional engine-independent expectation for one contract case.
pub(all) enum ExpectedOutcome {
  ExpectedNoMatch
  ExpectedMatch(text~ : String, captures~ : Array[String?])
} derive(Eq, Debug)

///|
pub extend ExpectedOutcome with Eq::{equal, not_equal}

///|
pub extend ExpectedOutcome with @moonbitlang/core/debug.Debug::{to_repr}

///|
/// Result of running one case against one engine.
pub(all) enum EngineOutcome {
  CompileRejected(String)
  ExecutionFailed(String)
  Completed(MatchObservation?)
} derive(Eq, Debug)

///|
pub extend EngineOutcome with Eq::{equal, not_equal}

///|
pub extend EngineOutcome with @moonbitlang/core/debug.Debug::{to_repr}

///|
/// A cross-engine or expectation difference.
pub(all) struct CompatibilityFinding {
  case_id : String
  engine_id : String
  kind : FindingKind
  detail : String
}

///|
/// Difference categories emitted by a contract run.
pub(all) enum FindingKind {
  CompileAcceptanceDiff
  ExecutionDiff
  MatchPresenceDiff
  MatchedTextDiff
  MatchSpanDiff
  CaptureDiff
  ExpectationFailed
} derive(Eq, Debug)

///|
pub extend FindingKind with Eq::{equal, not_equal}

///|
pub extend FindingKind with @moonbitlang/core/debug.Debug::{to_repr}

///|
/// Output rows are stable in case order, then adapter order.
pub(all) struct EngineRun {
  case_id : String
  engine_id : String
  outcome : EngineOutcome
}

///|
/// Aggregate result from a compatibility run.
pub(all) struct CompatibilityReport {
  baseline_id : String
  case_count : Int
  engine_count : Int
  runs : Array[EngineRun]
  findings : Array[CompatibilityFinding]
}

///|
/// Invalid or ambiguous compatibility-run configuration.
pub(all) enum ContractError {
  EmptyBaseline
  NoEngines
  EmptyEngineId
  DuplicateEngine(String)
  BaselineNotFound(String)
  DuplicateCase(String)
  EmptyCaseId
  InvalidExpectedSpan(String)
} derive(Eq, Debug)

///|
pub extend ContractError with Eq::{equal, not_equal}

///|
pub extend ContractError with @moonbitlang/core/debug.Debug::{to_repr}

///|
/// Build an adapter around a real regex implementation.
pub fn EngineAdapter::new(
  id~ : String,
  compile~ : (String) -> Result[CompiledMatcher, String],
) -> EngineAdapter {
  { id, compile, }
}

///|
/// Build the observation closure returned after a backend compiles a pattern.
pub fn CompiledMatcher::new(
  observe~ : (String) -> Result[MatchObservation?, String],
) -> CompiledMatcher {
  { observe, }
}

///|
/// Construct a contract case without an expected value.
pub fn ContractCase::new(
  id~ : String,
  pattern~ : String,
  input~ : String,
) -> ContractCase {
  { id, pattern, input, expected: None, expected_span: None, }
}

///|
/// Construct a contract case with an expected non-match.
pub fn ContractCase::expect_no_match(
  id~ : String,
  pattern~ : String,
  input~ : String,
) -> ContractCase {
  {
    id,
    pattern,
    input,
    expected: Some(ExpectedOutcome::ExpectedNoMatch),
    expected_span: None,
  }
}

///|
/// Construct a contract case with expected whole-match and capture text.
pub fn ContractCase::expect_match(
  id~ : String,
  pattern~ : String,
  input~ : String,
  text~ : String,
  captures~ : Array[String?],
) -> ContractCase {
  {
    id,
    pattern,
    input,
    expected: Some(ExpectedOutcome::ExpectedMatch(text~, captures~)),
    expected_span: None,
  }
}

///|
/// Construct a contract case that also asserts the normalized whole-match
/// span. Offsets use the adapter contract's zero-based StringView code units.
pub fn ContractCase::expect_match_span(
  id~ : String,
  pattern~ : String,
  input~ : String,
  text~ : String,
  captures~ : Array[String?],
  start~ : Int,
  end~ : Int,
) -> ContractCase {
  {
    id,
    pattern,
    input,
    expected: Some(ExpectedOutcome::ExpectedMatch(text~, captures~)),
    expected_span: Some((start, end)),
  }
}

///|
/// Run a suite against every supplied adapter and compare each result with a
/// designated baseline. The caller controls adapter order and case order.
pub fn run_contracts(
  cases : Array[ContractCase],
  engines : Array[EngineAdapter],
  baseline_id : String,
) -> Result[CompatibilityReport, ContractError] {
  if baseline_id == "" {
    return Err(ContractError::EmptyBaseline)
  }
  if engines.is_empty() {
    return Err(ContractError::NoEngines)
  }
  let mut baseline_index = -1
  for i, engine in engines {
    if engine.id == "" {
      return Err(ContractError::EmptyEngineId)
    }
    for j = 0; j < i; j = j + 1 {
      if engines[j].id == engine.id {
        return Err(ContractError::DuplicateEngine(engine.id))
      }
    }
    if engine.id == baseline_id {
      baseline_index = i
    }
  }
  if baseline_index < 0 {
    return Err(ContractError::BaselineNotFound(baseline_id))
  }
  for i, case in cases {
    if case.id == "" {
      return Err(ContractError::EmptyCaseId)
    }
    if case.expected_span is Some((start, end)) &&
      (start < 0 || end < start || end > case.input.length()) {
      return Err(ContractError::InvalidExpectedSpan(case.id))
    }
    for j = 0; j < i; j = j + 1 {
      if cases[j].id == case.id {
        return Err(ContractError::DuplicateCase(case.id))
      }
    }
  }
  let runs : Array[EngineRun] = []
  let findings : Array[CompatibilityFinding] = []
  let compilation_cache : Array[CompilationCacheEntry] = []
  for case in cases {
    let case_start = runs.length()
    for engine in engines {
      let outcome = match
        compile_cached(engine, case.pattern, compilation_cache) {
        Rejected(message) => EngineOutcome::CompileRejected(message)
        Ready(matcher) =>
          match (matcher.observe)(case.input) {
            Err(message) => EngineOutcome::ExecutionFailed(message)
            Ok(observation) => EngineOutcome::Completed(observation)
          }
      }
      runs.push({ case_id: case.id, engine_id: engine.id, outcome, })
    }
    let baseline = runs[case_start + baseline_index].outcome
    for engine_index, engine in engines {
      if engine_index != baseline_index {
        let actual = runs[case_start + engine_index].outcome
        compare_outcomes(case.id, engine.id, baseline, actual, findings)
      }
      check_expectation(
        case,
        engine.id,
        runs[case_start + engine_index].outcome,
        findings,
      )
    }
  }
  Ok({
    baseline_id,
    case_count: cases.length(),
    engine_count: engines.length(),
    runs,
    findings,
  })
}

///|
/// True when no engine differs from the baseline and every golden expectation
/// passed.
pub fn CompatibilityReport::is_compatible(self : CompatibilityReport) -> Bool {
  self.findings.is_empty()
}

///|
/// Number of cases evaluated by each configured engine.
pub fn CompatibilityReport::case_count(self : CompatibilityReport) -> Int {
  self.case_count
}

///|
/// Number of configured adapters in this run.
pub fn CompatibilityReport::engine_count(self : CompatibilityReport) -> Int {
  self.engine_count
}

///|
/// Stable one-line summary intended for CI output.
pub fn CompatibilityReport::summary(self : CompatibilityReport) -> String {
  "baseline=\{self.baseline_id} cases=\{self.case_count} engines=\{self.engine_count} findings=\{self.findings.length()} compatible=\{self.is_compatible()}"
}

///|
/// Stable text form of findings, preserving case and adapter order.
pub fn CompatibilityReport::format_findings(
  self : CompatibilityReport,
) -> String {
  let mut output = ""
  for finding in self.findings {
    if output != "" {
      output = output + "\n"
    }
    output = output +
      "\{finding.case_id} [\{finding.engine_id}] \{finding_kind_name(finding.kind)}: \{finding.detail}"
  }
  output
}

///|
fn finding_kind_name(kind : FindingKind) -> String {
  match kind {
    CompileAcceptanceDiff => "compile-acceptance"
    ExecutionDiff => "execution"
    MatchPresenceDiff => "match-presence"
    MatchedTextDiff => "matched-text"
    MatchSpanDiff => "match-span"
    CaptureDiff => "captures"
    ExpectationFailed => "expectation"
  }
}

///|
/// Compare a suite using MoonBit's official `moonbitlang/regexp` package.
pub fn moonbit_regexp_adapter() -> EngineAdapter {
  EngineAdapter::new(id="moonbitlang/regexp", compile=pattern => {
    try {
      let compiled = @regexp.compile(pattern)
      Ok(
        CompiledMatcher::new(observe=input => {
          let result = compiled.execute(input)
          if !result.matched() {
            Ok(None)
          } else {
            let whole = result.get(0).unwrap().to_owned()
            let start = result.before().length()
            let captures = []
            for index = 1; index < compiled.group_count(); index = index + 1 {
              captures.push(result.get(index).map(view => view.to_owned()))
            }
            Ok(
              Some({
                text: whole,
                start,
                end: start + whole.length(),
                captures,
              }),
            )
          }
        }),
      )
    } catch {
      @regexp.RegexpError(err~, source_fragment~) =>
        Err("\{err}: \{source_fragment}")
    }
  })
}

///|
fn compare_outcomes(
  case_id : String,
  engine_id : String,
  baseline : EngineOutcome,
  actual : EngineOutcome,
  findings : Array[CompatibilityFinding],
) -> Unit {
  match (baseline, actual) {
    (CompileRejected(_), Completed(_))
    | (CompileRejected(_), ExecutionFailed(_)) =>
      push_finding(
        case_id,
        engine_id,
        FindingKind::CompileAcceptanceDiff,
        "baseline rejected the pattern; candidate compiled it",
        findings,
      )
    (Completed(_), CompileRejected(_))
    | (ExecutionFailed(_), CompileRejected(_)) =>
      push_finding(
        case_id,
        engine_id,
        FindingKind::CompileAcceptanceDiff,
        "baseline compiled the pattern; candidate rejected it",
        findings,
      )
    (ExecutionFailed(_), Completed(_)) =>
      push_finding(
        case_id,
        engine_id,
        FindingKind::ExecutionDiff,
        "baseline execution failed; candidate completed",
        findings,
      )
    (Completed(_), ExecutionFailed(_)) =>
      push_finding(
        case_id,
        engine_id,
        FindingKind::ExecutionDiff,
        "baseline completed; candidate execution failed",
        findings,
      )
    (Completed(left), Completed(right)) =>
      compare_observations(case_id, engine_id, left, right, findings)
    _ => ()
  }
}

///|
fn compare_observations(
  case_id : String,
  engine_id : String,
  baseline : MatchObservation?,
  actual : MatchObservation?,
  findings : Array[CompatibilityFinding],
) -> Unit {
  match (baseline, actual) {
    (None, Some(_)) | (Some(_), None) =>
      push_finding(
        case_id,
        engine_id,
        FindingKind::MatchPresenceDiff,
        "one engine matched and the other did not",
        findings,
      )
    (Some(left), Some(right)) => {
      if left.text != right.text {
        push_finding(
          case_id,
          engine_id,
          FindingKind::MatchedTextDiff,
          "matched text differs",
          findings,
        )
      }
      if left.start != right.start || left.end != right.end {
        push_finding(
          case_id,
          engine_id,
          FindingKind::MatchSpanDiff,
          "whole-match span differs",
          findings,
        )
      }
      if left.captures != right.captures {
        push_finding(
          case_id,
          engine_id,
          FindingKind::CaptureDiff,
          "capture values differ",
          findings,
        )
      }
    }
    (None, None) => ()
  }
}

///|
fn check_expectation(
  case : ContractCase,
  engine_id : String,
  actual : EngineOutcome,
  findings : Array[CompatibilityFinding],
) -> Unit {
  match case.expected {
    None => ()
    Some(ExpectedOutcome::ExpectedNoMatch) =>
      if actual != EngineOutcome::Completed(None) {
        push_finding(
          case.id,
          engine_id,
          FindingKind::ExpectationFailed,
          "expected no match",
          findings,
        )
      }
    Some(ExpectedOutcome::ExpectedMatch(text~, captures~)) =>
      match actual {
        Completed(Some(observation)) => {
          if observation.text != text || observation.captures != captures {
            push_finding(
              case.id,
              engine_id,
              FindingKind::ExpectationFailed,
              "match or captures differ from the contract",
              findings,
            )
          }
          if case.expected_span is Some((start, end)) &&
            (observation.start != start || observation.end != end) {
            push_finding(
              case.id,
              engine_id,
              FindingKind::ExpectationFailed,
              "match span differs from the contract",
              findings,
            )
          }
        }
        _ =>
          push_finding(
            case.id,
            engine_id,
            FindingKind::ExpectationFailed,
            "expected a match",
            findings,
          )
      }
  }
}

///|
fn push_finding(
  case_id : String,
  engine_id : String,
  kind : FindingKind,
  detail : String,
  findings : Array[CompatibilityFinding],
) -> Unit {
  findings.push({ case_id, engine_id, kind, detail, })
}

///|
priv enum CachedCompilation {
  Ready(CompiledMatcher)
  Rejected(String)
}

///|
priv struct CompilationCacheEntry {
  engine_id : String
  pattern : String
  result : CachedCompilation
}

///|
fn compile_cached(
  engine : EngineAdapter,
  pattern : String,
  cache : Array[CompilationCacheEntry],
) -> CachedCompilation {
  for entry in cache {
    if entry.engine_id == engine.id && entry.pattern == pattern {
      return entry.result
    }
  }
  let result = match (engine.compile)(pattern) {
    Ok(matcher) => CachedCompilation::Ready(matcher)
    Err(message) => CachedCompilation::Rejected(message)
  }
  cache.push({ engine_id: engine.id, pattern, result, })
  result
}
