///|
/// Why a node was kept or omitted by the planner.
pub(all) enum DecisionReason {
  Required
  RequiredDependency
  SelectedForUtility
  SelectedAsDependency
  OmittedByBudget
  OmittedByPriority
} derive(Debug, Eq)

///|
/// The auditable outcome for one input node.
pub(all) struct NodeDecision {
  node_id : String
  selected_variant : String?
  token_cost : Int
  quality : Int
  upgraded : Bool
  reason : DecisionReason
} derive(Debug, Eq)

///|
fn fullest_variant_position(node : ContextNode) -> Int {
  let mut best = 0
  for index in 1..<node.variants.length() {
    let candidate = node.variants[index]
    let current = node.variants[best]
    if candidate.quality > current.quality ||
      (
        candidate.quality == current.quality &&
        candidate.token_cost > current.token_cost
      ) {
      best = index
    }
  }
  best
}

///|
fn build_plan_details(
  nodes : Array[ContextNode],
  required_set : Map[String, Bool],
  selected : Map[String, Int],
) -> (Int, Int, Int, Array[NodeDecision]) {
  let mut original = 0
  let mut retained_quality = 0
  let mut original_quality = 0
  let decisions = []
  for node in nodes {
    let fullest = node.variants[fullest_variant_position(node)]
    original += fullest.token_cost
    original_quality += fullest.quality
    match selected.get(node.id) {
      Some(index) => {
        let variant = node.variants[index]
        retained_quality += variant.quality
        let reason = if node.required {
          Required
        } else if required_set.contains(node.id) {
          RequiredDependency
        } else if node.priority > 0 {
          SelectedForUtility
        } else {
          SelectedAsDependency
        }
        decisions.push({
          node_id: node.id,
          selected_variant: Some(variant.label),
          token_cost: variant.token_cost,
          quality: variant.quality,
          upgraded: index != cheapest_variant_position(node),
          reason,
        })
      }
      None =>
        decisions.push({
          node_id: node.id,
          selected_variant: None,
          token_cost: 0,
          quality: 0,
          upgraded: false,
          reason: if node.priority <= 0 {
            OmittedByPriority
          } else {
            OmittedByBudget
          },
        })
    }
  }
  (original, retained_quality, original_quality, decisions)
}

///|
fn ordered_selection(plan : ContextPlan) -> Array[SelectedContext] {
  let ordered = plan.selected.copy()
  for index in 1..<ordered.length() {
    let mut cursor = index
    while cursor > 0 && ordered[cursor - 1].order > ordered[cursor].order {
      ordered.swap(cursor - 1, cursor)
      cursor -= 1
    }
  }
  ordered
}

///|
/// Render selected content in semantic order, separated by blank lines.
pub fn render(plan : ContextPlan) -> String {
  let output = StringBuilder()
  for index, item in ordered_selection(plan) {
    if index > 0 {
      output.write_string("\n\n")
    }
    output.write_string(item.variant.content)
  }
  output.to_string()
}

///|
fn reason_text(reason : DecisionReason) -> String {
  match reason {
    Required => "required"
    RequiredDependency => "required dependency"
    SelectedForUtility => "selected for utility"
    SelectedAsDependency => "selected dependency"
    OmittedByBudget => "omitted by budget"
    OmittedByPriority => "omitted by priority"
  }
}

///|
/// Produce a compact, deterministic text report of the planning decision.
pub fn audit_report(plan : ContextPlan) -> String {
  let output = StringBuilder()
  output.write_string("budget: \{plan.used}/\{plan.available} tokens")
  output.write_string("\nbaseline: \{plan.original} tokens")
  output.write_string(
    "\nquality retained: \{plan.quality_retention_percent()}%",
  )
  for decision in plan.node_decisions {
    output.write_string("\n\{decision.node_id}: ")
    match decision.selected_variant {
      Some(label) =>
        output.write_string(
          "\{label}, \{decision.token_cost} tokens, \{reason_text(decision.reason)}",
        )
      None => output.write_string(reason_text(decision.reason))
    }
  }
  output.to_string()
}
