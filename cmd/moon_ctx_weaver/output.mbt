///|
struct JsonDecision {
  node_id : String
  selected_variant : String?
  token_cost : Int
  quality : Int
  upgraded : Bool
  reason : String
} derive(ToJson)

///|
struct JsonPlan {
  available_tokens : Int
  used_tokens : Int
  original_tokens : Int
  quality_retention_percent : Int
  rendered_context : String
  decisions : Array[JsonDecision]
} derive(ToJson)

///|
fn reason_key(reason : @core.DecisionReason) -> String {
  match reason {
    Required => "required"
    RequiredDependency => "required_dependency"
    SelectedForUtility => "selected_for_utility"
    SelectedAsDependency => "selected_as_dependency"
    OmittedByBudget => "omitted_by_budget"
    OmittedByPriority => "omitted_by_priority"
  }
}

///|
fn format_plan_text(plan : @core.ContextPlan) -> String {
  "\{@core.audit_report(plan)}\n\ncontext:\n\{@core.render(plan)}"
}

///|
fn format_plan_json(plan : @core.ContextPlan) -> String {
  let decisions = [
    for decision in plan.decisions() => {
      {
        node_id: decision.node_id,
        selected_variant: decision.selected_variant,
        token_cost: decision.token_cost,
        quality: decision.quality,
        upgraded: decision.upgraded,
        reason: reason_key(decision.reason),
      }
    }
  ]
  @json.to_json({
    available_tokens: plan.available_tokens(),
    used_tokens: plan.used_tokens(),
    original_tokens: plan.original_tokens(),
    quality_retention_percent: plan.quality_retention_percent(),
    rendered_context: @core.render(plan),
    decisions,
  }).stringify(indent=2)
}
