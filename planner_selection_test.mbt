///|
fn selection_variant(
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
fn selection_node(
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
test "optional candidates bring their dependency closure" {
  let nodes = [
    selection_node(
      "schema",
      [selection_variant("preview", 2, 30)],
      0,
      priority=0,
    ),
    selection_node(
      "tool",
      [selection_variant("compact", 3, 80)],
      1,
      priority=80,
      depends_on=["schema"],
    ),
    selection_node(
      "memory",
      [selection_variant("compact", 4, 70)],
      2,
      priority=50,
    ),
  ]
  let result = @moon_ctx_weaver.plan(
    nodes,
    @moon_ctx_weaver.budget_policy(max_input_tokens=5),
  )
  inspect(result.used_tokens(), content="5")
  inspect(result.contains("schema"), content="true")
  inspect(result.contains("tool"), content="true")
  inspect(result.contains("memory"), content="false")
}

///|
test "unused budget upgrades a selected representation" {
  let nodes = [
    selection_node(
      "system",
      [
        selection_variant("full", 7, 100),
        selection_variant("preview", 2, 40),
        selection_variant("compact", 4, 75),
      ],
      0,
      required=true,
    ),
  ]
  let result = @moon_ctx_weaver.plan(
    nodes,
    @moon_ctx_weaver.budget_policy(max_input_tokens=4),
  )
  inspect(result.used_tokens(), content="4")
  debug_inspect(result.selected_variant("system"), content="Some(\"compact\")")
}
