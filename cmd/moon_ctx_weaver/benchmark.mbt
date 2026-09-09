///|
fn token_reduction_percent(plan : @core.ContextPlan) -> Int {
  let original = plan.original_tokens()
  if original == 0 {
    0
  } else {
    ((original - plan.used_tokens()).to_int64() * 100L / original.to_int64()).to_int()
  }
}

///|
fn format_benchmark_report(
  entries : Array[(String, @core.ContextPlan)],
) -> String {
  let output = StringBuilder()
  output.write_string("scenario\tused\tbaseline\treduction\tquality")
  for entry in entries {
    let (name, plan) = entry
    output.write_string(
      "\n\{name}\t\{plan.used_tokens()}\t\{plan.original_tokens()}\t\{token_reduction_percent(plan)}%\t\{plan.quality_retention_percent()}%",
    )
  }
  output.to_string()
}

///|
fn run_benchmark(paths : Array[String]) -> Unit raise {
  if paths.is_empty() {
    raise Usage("moon_ctx_weaver --benchmark <scenario.json>...")
  }
  let entries = []
  for path in paths {
    let scenario = decode_scenario(@fs.read_file_to_string(path))
    entries.push((path, @core.plan(scenario.nodes, scenario.policy)))
  }
  println(format_benchmark_report(entries))
}
