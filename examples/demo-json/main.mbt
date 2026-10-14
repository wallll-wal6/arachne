///|
priv struct DemoSuite {
  name : String
  report : @arachne.ReportJsonV1
} derive(ToJson)

///|
priv struct DemoJson {
  demo_version : Int32
  suites : Array[DemoSuite]
} derive(ToJson)

///|
fn main {
  let output : DemoJson = {
    demo_version: 1,
    suites: @fixtures.run_demo().map(suite => {
      let (name, report) = suite
      { name, report: report.json_v1(), }
    }),
  }
  println(ToJson::to_json(output).stringify())
}
