///|
fn main {
  let official = @arachne.moonbit_regexp_adapter()
  let reference = @arachne.reference_ascii_adapter()
  let report = @arachne.run_contracts(
    [
      @arachne.ContractCase::expect_match(
        id="request-id",
        pattern="^req-[0-9]+$",
        input="req-42",
        text="req-42",
        captures=[],
      ),
      @arachne.ContractCase::expect_match(
        id="service-token",
        pattern="[A-Za-z0-9_]+@[A-Za-z0-9_]+",
        input="owner: moonbit_1@runtime",
        text="moonbit_1@runtime",
        captures=[],
      ),
    ],
    [official, reference],
    official.id,
  ).unwrap()
  println(report.summary())
  if !report.is_compatible() {
    println(report.format_findings())
    abort("reference engine sample differs from the official backend")
  }
}
