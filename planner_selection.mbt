///|
fn cheapest_variant_position(node : ContextNode) -> Int {
  let mut best = 0
  for index in 1..<node.variants.length() {
    let candidate = node.variants[index]
    let current = node.variants[best]
    if candidate.token_cost < current.token_cost ||
      (
        candidate.token_cost == current.token_cost &&
        candidate.quality > current.quality
      ) {
      best = index
    }
  }
  best
}

///|
fn collect_unselected_closure(
  id : String,
  indexed : Map[String, ContextNode],
  selected : Map[String, Int],
  closure : Map[String, Bool],
) -> Unit {
  if selected.contains(id) || closure.contains(id) {
    return
  }
  closure[id] = true
  for dependency in indexed[id].depends_on {
    collect_unselected_closure(dependency, indexed, selected, closure)
  }
}

///|
fn closure_cost(nodes : Array[ContextNode], closure : Map[String, Bool]) -> Int {
  let mut cost = 0
  for node in nodes {
    if closure.contains(node.id) {
      cost += node.variants[cheapest_variant_position(node)].token_cost
    }
  }
  cost
}

///|
fn ratio_is_better(
  utility : Int64,
  cost : Int,
  best_utility : Int64,
  best_cost : Int,
) -> Bool {
  utility * best_cost.to_int64() > best_utility * cost.to_int64()
}

///|
fn select_optional_nodes(
  nodes : Array[ContextNode],
  indexed : Map[String, ContextNode],
  selected : Map[String, Int],
  used : Ref[Int],
  available : Int,
) -> Unit {
  while true {
    let mut best_id : String? = None
    let mut best_cost = 0
    let mut best_utility = 0L
    for node in nodes {
      if !selected.contains(node.id) && node.priority > 0 {
        let closure : Map[String, Bool] = Map([])
        collect_unselected_closure(node.id, indexed, selected, closure)
        let cost = closure_cost(nodes, closure)
        if used.val + cost <= available {
          let variant = node.variants[cheapest_variant_position(node)]
          let utility = node.priority.to_int64() * variant.quality.to_int64()
          if best_id is None ||
            ratio_is_better(utility, cost, best_utility, best_cost) {
            best_id = Some(node.id)
            best_cost = cost
            best_utility = utility
          }
        }
      }
    }
    match best_id {
      None => break
      Some(id) => {
        let closure : Map[String, Bool] = Map([])
        collect_unselected_closure(id, indexed, selected, closure)
        for node in nodes {
          if closure.contains(node.id) {
            selected[node.id] = cheapest_variant_position(node)
          }
        }
        used.val += best_cost
      }
    }
  }
}

///|
fn upgrade_selected_nodes(
  nodes : Array[ContextNode],
  selected : Map[String, Int],
  used : Ref[Int],
  available : Int,
) -> Unit {
  while true {
    let mut best_node : String? = None
    let mut best_variant = 0
    let mut best_cost = 0
    let mut best_quality = 0
    for node in nodes {
      match selected.get(node.id) {
        None => ()
        Some(current_index) => {
          let current = node.variants[current_index]
          for index, candidate in node.variants {
            let added_cost = candidate.token_cost - current.token_cost
            let added_quality = candidate.quality - current.quality
            if added_cost >= 0 &&
              added_quality > 0 &&
              used.val + added_cost <= available {
              let is_better = if best_node is None {
                true
              } else if added_cost == 0 {
                best_cost != 0 || added_quality > best_quality
              } else if best_cost == 0 {
                false
              } else {
                ratio_is_better(
                  added_quality.to_int64(),
                  added_cost,
                  best_quality.to_int64(),
                  best_cost,
                )
              }
              if is_better {
                best_node = Some(node.id)
                best_variant = index
                best_cost = added_cost
                best_quality = added_quality
              }
            }
          }
        }
      }
    }
    match best_node {
      None => break
      Some(id) => {
        selected[id] = best_variant
        used.val += best_cost
      }
    }
  }
}
