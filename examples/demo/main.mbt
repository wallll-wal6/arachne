///|
fn main {
  let cases = [
    @arachne.ContractCase::expect_match(
      id="request-id",
      pattern="^req-([0-9]+)$",
      input="req-42",
      text="req-42",
      captures=[Some("42")],
    ),
    @arachne.ContractCase::new(
      id="backreference-support-difference",
      pattern="^([a-z])\\1$",
      input="aa",
    ),
  ]
  let engines = [
    @arachne.moonbit_regexp_adapter(),
    @arachne.rembt_ascii_perl_adapter(),
  ]
  match @arachne.run_contracts(cases, engines, "moonbitlang/regexp") {
    Ok(report) => {
      println(report.summary())
      let findings = report.format_findings()
      if findings != "" {
        println(findings)
      }
      println(
        "Findings are behavior differences for review, not automatic failures.",
      )
    }
    Err(_) => println("invalid demo contract configuration")
  }
}
