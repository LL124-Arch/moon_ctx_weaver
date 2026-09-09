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
  { selected, used: used.val, available }
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
