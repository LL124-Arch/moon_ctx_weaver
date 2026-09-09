///|
fn output_variant(
  label : String,
  content : String,
  cost : Int,
  quality : Int,
) -> @moon_ctx_weaver.ContextVariant {
  @moon_ctx_weaver.context_variant(label~, content~, token_cost=cost, quality~)
}

///|
fn output_node(
  id : String,
  content : String,
  order : Int,
) -> @moon_ctx_weaver.ContextNode {
  @moon_ctx_weaver.context_node(
    id~,
    kind=UserMessage,
    variants=[output_variant("full", content, 1, 100)],
    order~,
    required=true,
  )
}

///|
test "render restores semantic order and keeps equal positions stable" {
  let plan = @moon_ctx_weaver.plan(
    [
      output_node("late", "third", 20),
      output_node("first", "first", 10),
      output_node("second", "second", 10),
    ],
    @moon_ctx_weaver.budget_policy(max_input_tokens=3),
  )
  inspect(
    @moon_ctx_weaver.render(plan),
    content=(
      #|first
      #|
      #|second
      #|
      #|third
    ),
  )
}

///|
test "plan reports baseline cost quality retention and node decisions" {
  let nodes = [
    @moon_ctx_weaver.context_node(
      id="policy",
      kind=SystemInstruction,
      variants=[
        output_variant("full", "full policy", 10, 100),
        output_variant("preview", "policy preview", 4, 60),
      ],
      order=0,
      required=true,
    ),
    @moon_ctx_weaver.context_node(
      id="memory",
      kind=Memory,
      variants=[
        output_variant("full", "full memory", 8, 100),
        output_variant("compact", "memory compact", 3, 70),
      ],
      order=1,
      priority=50,
    ),
  ]
  let plan = @moon_ctx_weaver.plan(
    nodes,
    @moon_ctx_weaver.budget_policy(max_input_tokens=7),
  )
  inspect(plan.original_tokens(), content="18")
  inspect(plan.quality_retention_percent(), content="65")
  debug_inspect(
    plan.decisions(),
    content=(
      #|[
      #|  {
      #|    node_id: "policy",
      #|    selected_variant: Some("preview"),
      #|    token_cost: 4,
      #|    quality: 60,
      #|    upgraded: false,
      #|    reason: Required,
      #|  },
      #|  {
      #|    node_id: "memory",
      #|    selected_variant: Some("compact"),
      #|    token_cost: 3,
      #|    quality: 70,
      #|    upgraded: false,
      #|    reason: SelectedForUtility,
      #|  },
      #|]
    ),
  )
  inspect(
    @moon_ctx_weaver.audit_report(plan),
    content=(
      #|budget: 7/7 tokens
      #|baseline: 18 tokens
      #|quality retained: 65%
      #|policy: preview, 4 tokens, required
      #|memory: compact, 3 tokens, selected for utility
    ),
  )
}
