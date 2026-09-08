///|
test "context values keep caller intent" {
  let full = @moon_ctx_weaver.context_variant(
    label="full",
    content="weather forecast schema",
    token_cost=24,
    quality=100,
  )
  let compact = @moon_ctx_weaver.context_variant(
    label="compact",
    content="weather schema",
    token_cost=8,
    quality=70,
  )
  let node = @moon_ctx_weaver.context_node(
    id="tool.weather",
    kind=ToolDefinition,
    variants=[full, compact],
    order=3,
    priority=80,
    required=true,
    depends_on=["policy.tools"],
  )
  debug_inspect(
    node,
    content=(
      #|{
      #|  id: "tool.weather",
      #|  kind: ToolDefinition,
      #|  variants: [
      #|    {
      #|      label: "full",
      #|      content: "weather forecast schema",
      #|      token_cost: 24,
      #|      quality: 100,
      #|    },
      #|    {
      #|      label: "compact",
      #|      content: "weather schema",
      #|      token_cost: 8,
      #|      quality: 70,
      #|    },
      #|  ],
      #|  order: 3,
      #|  priority: 80,
      #|  required: true,
      #|  depends_on: ["policy.tools"],
      #|}

    ),
  )
}

///|
test "budget reserves output space" {
  let budget = @moon_ctx_weaver.budget_policy(
    max_input_tokens=4096,
    reserved_output_tokens=1024,
  )
  inspect(budget.available_input_tokens(), content="3072")
}
