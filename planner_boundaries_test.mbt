///|
fn boundary_variant(
  cost : Int,
  quality : Int,
) -> @moon_ctx_weaver.ContextVariant {
  @moon_ctx_weaver.context_variant(
    label="compact",
    content="compact context",
    token_cost=cost,
    quality~,
  )
}

///|
fn boundary_node(
  id : String,
  cost : Int,
  quality : Int,
  order : Int,
  priority? : Int = 50,
  depends_on? : Array[String] = [],
) -> @moon_ctx_weaver.ContextNode {
  @moon_ctx_weaver.context_node(
    id~,
    kind=RetrievedContext,
    variants=[boundary_variant(cost, quality)],
    order~,
    priority~,
    depends_on~,
  )
}

///|
test "an optional closure is never partially admitted" {
  let nodes = [
    boundary_node("schema", 2, 20, 0, priority=0),
    boundary_node("tool", 4, 90, 1, priority=100, depends_on=["schema"]),
    boundary_node("fallback", 5, 60, 2, priority=40),
  ]
  let result = @moon_ctx_weaver.plan(
    nodes,
    @moon_ctx_weaver.budget_policy(max_input_tokens=5),
  )
  inspect(result.contains("schema"), content="false")
  inspect(result.contains("tool"), content="false")
  inspect(result.contains("fallback"), content="true")
  inspect(result.used_tokens(), content="5")
}

///|
test "equal utility candidates retain source order" {
  let nodes = [
    boundary_node("earlier", 3, 60, 0, priority=50),
    boundary_node("later", 3, 60, 1, priority=50),
  ]
  let result = @moon_ctx_weaver.plan(
    nodes,
    @moon_ctx_weaver.budget_policy(max_input_tokens=3),
  )
  inspect(result.contains("earlier"), content="true")
  inspect(result.contains("later"), content="false")
}

///|
test "shared dependencies are charged only once" {
  let nodes = [
    boundary_node("shared", 1, 20, 0, priority=0),
    boundary_node("first", 2, 60, 1, depends_on=["shared"]),
    boundary_node("second", 2, 60, 2, depends_on=["shared"]),
  ]
  let result = @moon_ctx_weaver.plan(
    nodes,
    @moon_ctx_weaver.budget_policy(max_input_tokens=5),
  )
  inspect(result.contains("shared"), content="true")
  inspect(result.contains("first"), content="true")
  inspect(result.contains("second"), content="true")
  inspect(result.used_tokens(), content="5")
}
