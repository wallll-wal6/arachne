///|
/// One fixture source for the executable and its integration regression.
pub fn run_demo() -> Array[(String, @arachne.CompatibilityReport)] {
  let official = @arachne.moonbit_regexp_adapter()
  let ascii = @arachne.rembt_ascii_perl_adapter()
  let common = [
    @arachne.ContractCase::expect_match_span(
      id="request-id",
      pattern="^req-([0-9]+)$",
      input="req-42",
      text="req-42",
      captures=[Some("42")],
      start=0,
      end=6,
    ),
    @arachne.ContractCase::expect_no_match(
      id="reject-empty-request-id",
      pattern="^req-([0-9]+)$",
      input="req-",
    ),
    @arachne.ContractCase::expect_match_span(
      id="search-with-prefix",
      pattern="user=([A-Za-z0-9_]+)",
      input="INFO user=wal6 action=login",
      text="user=wal6",
      captures=[Some("wal6")],
      start=5,
      end=14,
    ),
    @arachne.ContractCase::expect_match_span(
      id="optional-unmatched-group",
      pattern="(cat)?dog",
      input="dog",
      text="dog",
      captures=[None],
      start=0,
      end=3,
    ),
    @arachne.ContractCase::expect_match_span(
      id="empty-capture",
      pattern="^(a*)b$",
      input="b",
      text="b",
      captures=[Some("")],
      start=0,
      end=1,
    ),
    @arachne.ContractCase::expect_match_span(
      id="multiple-captures",
      pattern="^([A-Z]+)-([0-9]+)$",
      input="ORD-2048",
      text="ORD-2048",
      captures=[Some("ORD"), Some("2048")],
      start=0,
      end=8,
    ),
    @arachne.ContractCase::expect_match_span(
      id="empty-whole-match",
      pattern="^(a*)$",
      input="",
      text="",
      captures=[Some("")],
      start=0,
      end=0,
    ),
  ]
  // Probes deliberately have no shared golden expectation. Preserve the
  // existing compile-acceptance finding for the application owner's review.
  let syntax = [
    @arachne.ContractCase::new(
      id="backreference-support-difference",
      pattern="^([a-z])\\1$",
      input="aa",
    ),
  ]
  let domain = [
    @arachne.ContractCase::new(
      id="non-ascii-pattern",
      pattern="猫",
      input="猫",
    ),
    @arachne.ContractCase::new(
      id="non-ascii-input",
      pattern="(a)",
      input="🦊a",
    ),
  ]
  let unicode = [
    @arachne.ContractCase::expect_match_span(
      id="bmp-literal",
      pattern="(猫)",
      input="猫",
      text="猫",
      captures=[Some("猫")],
      start=0,
      end=1,
    ),
    @arachne.ContractCase::expect_match_span(
      id="supplementary-prefix-offset",
      pattern="(a)",
      input="🦊a",
      text="a",
      captures=[Some("a")],
      start=2,
      end=3,
    ),
    @arachne.ContractCase::expect_match_span(
      id="supplementary-literal-span",
      pattern="(🦊)",
      input="猫🦊a",
      text="🦊",
      captures=[Some("🦊")],
      start=1,
      end=3,
    ),
    @arachne.ContractCase::expect_match_span(
      id="non-ascii-uppercase-category",
      pattern="(\\p{Lu})",
      input="éΩ🦊",
      text="Ω",
      captures=[Some("Ω")],
      start=1,
      end=2,
    ),
  ]
  // This bounded generator contributes A, @, Z, [ in that order.
  for
    case in @arachne.unicode_category_cases(category="Lu", max_cases=4).unwrap() {
    unicode.push(case)
  }
  [
    (
      "shared-ascii",
      @arachne.run_contracts(common, [official, ascii], official.id).unwrap(),
    ),
    (
      "syntax-difference",
      @arachne.run_contracts(syntax, [official, ascii], official.id).unwrap(),
    ),
    (
      "adapter-domain",
      @arachne.run_contracts(domain, [official, ascii], official.id).unwrap(),
    ),
    (
      "unicode-official-only",
      @arachne.run_contracts(unicode, [official], official.id).unwrap(),
    ),
  ]
}

///|
pub fn format_text(
  suites : Array[(String, @arachne.CompatibilityReport)],
) -> String {
  let mut output = "Arachne migration demo: regexp@0.3.6 -> re-mbt@0.1.0 Perl (ASCII)"
  for suite in suites {
    let (name, report) = suite
    output += "\n[\{name}]\n\{report.summary()}"
    for run in report.runs {
      let detail = match run.outcome {
        CompileRejected(message) => "compile_rejected error=\{message}"
        ExecutionFailed(message) => "execution_failed error=\{message}"
        Completed(None) => "no_match"
        Completed(Some(observation)) =>
          "matched text=\{observation.text} span=[\{observation.start}, \{observation.end}) captures=\{@debug.to_string(observation.captures)}"
      }
      output += "\n\{run.case_id} [\{run.engine_id}] \{detail}"
    }
    let findings = report.format_findings()
    if findings != "" {
      output += "\n\{findings}"
    }
  }
  output +
  "\nFindings require owner review; normal demo exit does not approve a migration."
}
