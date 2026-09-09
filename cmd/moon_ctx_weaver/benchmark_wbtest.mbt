///|
test "offline scenarios stay inside benchmark quality bounds" {
  let entries = []
  for name in ["customer_support", "coding_agent", "research_agent"] {
    let source = @fs.read_file_to_string("scenarios/\{name}.json")
    let scenario = decode_scenario(source)
    let plan = @core.plan(scenario.nodes, scenario.policy)
    let reduction = token_reduction_percent(plan)
    assert_true(plan.used_tokens() <= plan.available_tokens())
    assert_true(reduction >= 35 && reduction <= 60)
    assert_true(plan.quality_retention_percent() >= 85)
    entries.push((name, plan))
  }
  inspect(
    format_benchmark_report(entries),
    content=(
      #|scenario	used	baseline	reduction	quality
      #|customer_support	360	640	43%	89%
      #|coding_agent	420	800	47%	89%
      #|research_agent	450	850	47%	91%
    ),
  )
}
