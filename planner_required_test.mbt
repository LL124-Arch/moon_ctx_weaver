///|
fn planner_variant(
  label : String,
  cost : Int,
  quality : Int,
) -> @moon_ctx_weaver.ContextVariant {
  @moon_ctx_weaver.context_variant(
    label~,
    content="{label} content",
    token_cost=cost,
    quality~,
  )
}

///|
fn planner_node(
  id : String,
  variants : Array[@moon_ctx_weaver.ContextVariant],
  order : Int,
  priority? : Int = 50,
  required? : Bool = false,
  depends_on? : Array[String] = [],
) -> @moon_ctx_weaver.ContextNode {
  @moon_ctx_weaver.context_node(
    id~,
    kind=Memory,
    variants~,
    order~,
    priority~,
    required~,
    depends_on~,
  )
}

///|
test "plan rejects unusable budget envelopes" {
  try
    @moon_ctx_weaver.plan(
      [],
      @moon_ctx_weaver.budget_policy(
        max_input_tokens=100,
        reserved_output_tokens=100,
      ),
    )
  catch {
    InvalidBudget(max_input_tokens~, reserved_output_tokens~) => {
      inspect(max_input_tokens, content="100")
      inspect(reserved_output_tokens, content="100")
    }
    _ => fail("unexpected planning error")
  } noraise {
    _ => fail("expected invalid budget")
  }
}

///|
test "required closure starts from each node's cheapest representation" {
  let nodes = [
    planner_node(
      "policy",
      [planner_variant("full", 10, 100), planner_variant("compact", 4, 60)],
      0,
    ),
    planner_node(
      "result",
      [planner_variant("full", 8, 100), planner_variant("preview", 3, 50)],
      1,
      required=true,
      depends_on=["policy"],
    ),
  ]
  let result = @moon_ctx_weaver.plan(
    nodes,
    @moon_ctx_weaver.budget_policy(max_input_tokens=7),
  )
  inspect(result.used_tokens(), content="7")
  inspect(result.available_tokens(), content="7")
  debug_inspect(result.selected_variant("policy"), content="Some(\"compact\")")
  debug_inspect(result.selected_variant("result"), content="Some(\"preview\")")
  inspect(result.contains("missing"), content="false")
}

///|
test "required closure fails as one unit when it cannot fit" {
  let nodes = [
    planner_node("policy", [planner_variant("compact", 4, 60)], 0),
    planner_node(
      "result",
      [planner_variant("preview", 3, 50)],
      1,
      required=true,
      depends_on=["policy"],
    ),
  ]
  try
    @moon_ctx_weaver.plan(
      nodes,
      @moon_ctx_weaver.budget_policy(max_input_tokens=6),
    )
  catch {
    RequiredContextExceedsBudget(required_tokens~, available_tokens~) => {
      inspect(required_tokens, content="7")
      inspect(available_tokens, content="6")
    }
    _ => fail("unexpected planning error")
  } noraise {
    _ => fail("expected required context overflow")
  }
}
