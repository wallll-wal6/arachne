///|
test "migration fixtures preserve common contracts and classified real differences" {
  let suites = run_demo()
  assert_eq(suites.length(), 4)
  let (common_name, common) = suites[0]
  assert_eq(common_name, "shared-ascii")
  assert_eq(common.case_count(), 5)
  assert_eq(common.runs.length(), 10)
  assert_true(common.is_compatible())
  let (syntax_name, syntax) = suites[1]
  assert_eq(syntax_name, "syntax-difference")
  assert_eq(syntax.findings.length(), 1)
  assert_eq(syntax.findings[0].case_id, "backreference-support-difference")
  assert_true(
    syntax.findings[0].kind == @arachne.FindingKind::CompileAcceptanceDiff,
  )
  assert_true(
    syntax.runs[0].outcome is @arachne.EngineOutcome::Completed(Some(_)),
  )
  assert_true(
    syntax.runs[1].outcome
    is @arachne.EngineOutcome::CompileRejected(
      "re-mbt Perl frontend rejected the pattern"
    ),
  )
  let (domain_name, domain) = suites[2]
  assert_eq(domain_name, "adapter-domain")
  assert_eq(domain.findings.length(), 2)
  assert_true(
    domain.runs[1].outcome
    is @arachne.EngineOutcome::CompileRejected(
      "adapter-domain: re-mbt Perl adapter currently accepts ASCII patterns only"
    ),
  )
  assert_true(
    domain.runs[3].outcome
    is @arachne.EngineOutcome::ExecutionFailed(
      "adapter-domain: re-mbt Perl adapter currently accepts ASCII inputs only"
    ),
  )
  assert_true(domain.findings[1].kind == @arachne.FindingKind::ExecutionDiff)
  let (unicode_name, unicode) = suites[3]
  assert_eq(unicode_name, "unicode-official-only")
  assert_eq(unicode.case_count(), 6)
  assert_eq(unicode.engine_count(), 1)
  assert_true(unicode.is_compatible())
  match unicode.runs[1].outcome {
    @arachne.EngineOutcome::Completed(Some(observation)) => {
      assert_eq(observation.start, 2)
      assert_eq(observation.end, 3)
    }
    _ => abort("supplementary prefix must retain its code-unit span")
  }
}
