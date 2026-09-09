///|
fn run_cli(args : Array[String]) -> Unit raise {
  if args.length() >= 2 && args[1] == "--benchmark" {
    let paths = []
    for index in 2..<args.length() {
      paths.push(args[index])
    }
    run_benchmark(paths)
    return
  }
  if args.length() < 2 || args.length() > 4 {
    raise Usage(
      "moon_ctx_weaver <scenario.json> [--format text|json] | --benchmark <scenario.json>...",
    )
  }
  let path = args[1]
  let format = if args.length() == 2 {
    "text"
  } else if args.length() == 4 && args[2] == "--format" {
    args[3]
  } else {
    raise Usage(
      "moon_ctx_weaver <scenario.json> [--format text|json] | --benchmark <scenario.json>...",
    )
  }
  let scenario = decode_scenario(@fs.read_file_to_string(path))
  let plan = @core.plan(scenario.nodes, scenario.policy)
  match format {
    "text" => println(format_plan_text(plan))
    "json" => println(format_plan_json(plan))
    other => raise UnknownFormat(other)
  }
}

///|
fn main {
  try run_cli(@env.args()) catch {
    error => {
      println("moon_ctx_weaver: \{Repr(error)}")
      @sys.exit(1)
    }
  } noraise {
    _ => ()
  }
}
