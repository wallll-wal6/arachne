///|
test "migration fixtures preserve common contracts and classified real differences" {
  let suites = run_demo()
  assert_eq(suites.length(), 4)
  let (common_name, common) = suites[0]
  assert_eq(common_name, "shared-ascii")
  assert_eq(common.case_count(), 7)
  assert_eq(common.runs.length(), 14)
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
  assert_eq(unicode.case_count(), 8)
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

///|
test "both real backends distinguish empty matches and preserve capture order" {
  let (_, common) = run_demo()[0]
  for index in [10, 11] {
    assert_eq(common.runs[index].case_id, "multiple-captures")
    match common.runs[index].outcome {
      @arachne.EngineOutcome::Completed(Some(observation)) => {
        assert_eq(observation.text, "ORD-2048")
        assert_eq(observation.captures, [Some("ORD"), Some("2048")])
        assert_eq((observation.start, observation.end), (0, 8))
      }
      _ => abort("both real backends must preserve the two capture values")
    }
  }
  for index in [12, 13] {
    assert_eq(common.runs[index].case_id, "empty-whole-match")
    match common.runs[index].outcome {
      @arachne.EngineOutcome::Completed(Some(observation)) => {
        assert_eq(observation.text, "")
        assert_eq(observation.captures, [Some("")])
        assert_eq((observation.start, observation.end), (0, 0))
      }
      _ => abort("an empty whole match must not become no_match")
    }
  }
}

///|
test "official Unicode fixtures match supplementary text and non-ASCII Lu" {
  let (_, unicode) = run_demo()[3]
  assert_eq(unicode.runs[2].case_id, "supplementary-literal-span")
  match unicode.runs[2].outcome {
    @arachne.EngineOutcome::Completed(Some(observation)) => {
      assert_eq(observation.text, "🦊")
      assert_eq(observation.captures, [Some("🦊")])
      assert_eq((observation.start, observation.end), (1, 3))
    }
    _ => abort("the supplementary literal must occupy two UTF-16 code units")
  }
  assert_eq(unicode.runs[3].case_id, "non-ascii-uppercase-category")
  match unicode.runs[3].outcome {
    @arachne.EngineOutcome::Completed(Some(observation)) => {
      assert_eq(observation.text, "Ω")
      assert_eq(observation.captures, [Some("Ω")])
      assert_eq((observation.start, observation.end), (1, 2))
    }
    _ => abort("the category search must skip é and match Greek capital omega")
  }
}
