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
  original : Int
  retained_quality : Int
  original_quality : Int
  node_decisions : Array[NodeDecision]
} derive(Debug, Eq)

///|
/// Plan context within the usable input window.
///
/// Required nodes and their transitive dependencies are admitted as one unit.
/// Optional closures and representation upgrades use stable utility/cost passes.
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
  let selected_indices : Map[String, Int] = Map([])
  let used = Ref(0)
  for node in nodes {
    if required_set.contains(node.id) {
      let index = cheapest_variant_position(node)
      selected_indices[node.id] = index
      used.val += node.variants[index].token_cost
    }
  }
  if used.val > available {
    raise RequiredContextExceedsBudget(
      required_tokens=used.val,
      available_tokens=available,
    )
  }
  let indexed : Map[String, ContextNode] = Map([])
  for node in nodes {
    indexed[node.id] = node
  }
  select_optional_nodes(nodes, indexed, selected_indices, used, available)
  upgrade_selected_nodes(nodes, selected_indices, used, available)
  let selected = []
  for node in nodes {
    match selected_indices.get(node.id) {
      None => ()
      Some(index) =>
        selected.push({
          node_id: node.id,
          kind: node.kind,
          variant: node.variants[index],
          order: node.order,
        })
    }
  }
  let (original, retained_quality, original_quality, node_decisions) = build_plan_details(
    nodes, required_set, selected_indices,
  )
  {
    selected,
    used: used.val,
    available,
    original,
    retained_quality,
    original_quality,
    node_decisions,
  }
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

///|
/// Token cost of keeping every node at its highest-quality representation.
pub fn ContextPlan::original_tokens(self : ContextPlan) -> Int {
  self.original
}

///|
/// Retained quality as an integer percentage of the uncropped context.
pub fn ContextPlan::quality_retention_percent(self : ContextPlan) -> Int {
  if self.original_quality == 0 {
    100
  } else {
    (self.retained_quality.to_int64() * 100L / self.original_quality.to_int64()).to_int()
  }
}

///|
/// One decision for every input node, in source order.
pub fn ContextPlan::decisions(self : ContextPlan) -> Array[NodeDecision] {
  self.node_decisions.copy()
}
