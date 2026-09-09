///|
fn golden_plan(path : String) -> @core.ContextPlan raise {
  let scenario = decode_scenario(@fs.read_file_to_string(path))
  @core.plan(scenario.nodes, scenario.policy)
}

///|
test "benchmark output matches its checked-in golden" {
  let entries = [
    (
      "scenarios/customer_support.json",
      golden_plan("scenarios/customer_support.json"),
    ),
    ("scenarios/coding_agent.json", golden_plan("scenarios/coding_agent.json")),
    (
      "scenarios/research_agent.json",
      golden_plan("scenarios/research_agent.json"),
    ),
  ]
  let expected = @fs.read_file_to_string("golden/benchmark.tsv")
    .trim()
    .to_owned()
  assert_eq(format_benchmark_report(entries), expected)
}

///|
test "structured plan matches its checked-in golden" {
  let expected = @fs.read_file_to_string("golden/customer_support.plan.json")
    .trim()
    .to_owned()
  assert_eq(
    format_plan_json(golden_plan("scenarios/customer_support.json")),
    expected,
  )
}
