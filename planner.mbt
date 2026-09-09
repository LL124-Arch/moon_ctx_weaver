///|
/// The representation chosen for one context node.
pub(all) struct SelectedContext {
  node_id : String
  kind : ContextKind
  variant : ContextVariant
  order : Int
} derive(Debug, Eq)

///|
/// A budget-feasible context selection in the nodes' source order.
pub(all) struct ContextPlan {
  selected : Array[SelectedContext]
  used : Int
  available : Int
} derive(Debug, Eq)

///|
fn cheapest_variant(node : ContextNode) -> ContextVariant {
  let mut best = node.variants[0]
  for index in 1..<node.variants.length() {
    let candidate = node.variants[index]
    if candidate.token_cost < best.token_cost ||
      (
        candidate.token_cost == best.token_cost &&
        candidate.quality > best.quality
      ) {
      best = candidate
    }
  }
  best
}

///|
/// Plan context within the usable input window.
///
/// Required nodes and their transitive dependencies are admitted as one unit.
/// Optional selection and representation upgrades are added in later passes.
pub fn plan(
  nodes : Array[ContextNode],
  policy : BudgetPolicy,
) -> ContextPlan raise PlanError {
  validate_graph(nodes)
  if policy.max_input_tokens <= 0 ||
    policy.reserved_output_tokens < 0 ||
    policy.reserved_output_tokens >= policy.max_input_tokens {
    raise InvalidBudget(
      max_input_tokens=policy.max_input_tokens,
      reserved_output_tokens=policy.reserved_output_tokens,
    )
  }
  let available = policy.available_input_tokens()
  let required = required_closure(nodes)
  let required_set : Map[String, Bool] = Map([])
  for id in required {
    required_set[id] = true
  }
  let selected = []
  let mut used = 0
  for node in nodes {
    if required_set.contains(node.id) {
      let variant = cheapest_variant(node)
      used += variant.token_cost
      selected.push({
        node_id: node.id,
        kind: node.kind,
        variant,
        order: node.order,
      })
    }
  }
  if used > available {
    raise RequiredContextExceedsBudget(
      required_tokens=used,
      available_tokens=available,
    )
  }
  { selected, used, available }
}

///|
pub fn ContextPlan::used_tokens(self : ContextPlan) -> Int {
  self.used
}

///|
pub fn ContextPlan::available_tokens(self : ContextPlan) -> Int {
  self.available
}

///|
pub fn ContextPlan::selected_variant(
  self : ContextPlan,
  node_id : String,
) -> String? {
  for item in self.selected {
    if item.node_id == node_id {
      return Some(item.variant.label)
    }
  }
  None
}

///|
pub fn ContextPlan::contains(self : ContextPlan, node_id : String) -> Bool {
  self.selected_variant(node_id) is Some(_)
}
