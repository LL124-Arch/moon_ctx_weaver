///|
/// Structural failures found before budget planning starts.
pub(all) suberror PlanError {
  DuplicateNodeId(String)
  MissingDependency(node_id~ : String, dependency_id~ : String)
  DependencyCycle(Array[String])
  NoUsableVariant(String)
  InvalidVariantCost(node_id~ : String, label~ : String, cost~ : Int)
  InvalidVariantQuality(node_id~ : String, label~ : String, quality~ : Int)
} derive(Debug, Eq)

///|
fn index_nodes(
  nodes : Array[ContextNode],
) -> Map[String, ContextNode] raise PlanError {
  let indexed : Map[String, ContextNode] = Map([])
  for node in nodes {
    if indexed.contains(node.id) {
      raise DuplicateNodeId(node.id)
    }
    indexed[node.id] = node
  }
  indexed
}

///|
fn validate_variants(node : ContextNode) -> Unit raise PlanError {
  if node.variants.is_empty() {
    raise NoUsableVariant(node.id)
  }
  for variant in node.variants {
    if variant.token_cost <= 0 {
      raise InvalidVariantCost(
        node_id=node.id,
        label=variant.label,
        cost=variant.token_cost,
      )
    }
    if variant.quality < 0 || variant.quality > 100 {
      raise InvalidVariantQuality(
        node_id=node.id,
        label=variant.label,
        quality=variant.quality,
      )
    }
  }
}

///|
fn cycle_from(path : Array[String], repeated : String) -> Array[String] {
  let start = path.search_by(id => id == repeated).unwrap_or(0)
  let cycle = []
  for index in start..<path.length() {
    cycle.push(path[index])
  }
  cycle.push(repeated)
  cycle
}

///|
fn visit_node(
  id : String,
  indexed : Map[String, ContextNode],
  states : Map[String, Int],
  path : Array[String],
) -> Unit raise PlanError {
  match states.get(id) {
    Some(1) => raise DependencyCycle(cycle_from(path, id))
    Some(2) => ()
    _ => {
      states[id] = 1
      path.push(id)
      let node = indexed[id]
      for dependency in node.depends_on {
        visit_node(dependency, indexed, states, path)
      }
      ignore(path.pop())
      states[id] = 2
    }
  }
}

///|
/// Validate node identity, representations, dependencies, and acyclicity.
pub fn validate_graph(nodes : Array[ContextNode]) -> Unit raise PlanError {
  let indexed = index_nodes(nodes)
  for node in nodes {
    validate_variants(node)
    for dependency in node.depends_on {
      if !indexed.contains(dependency) {
        raise MissingDependency(node_id=node.id, dependency_id=dependency)
      }
    }
  }
  let states : Map[String, Int] = Map([])
  let path : Array[String] = []
  for node in nodes {
    visit_node(node.id, indexed, states, path)
  }
}

///|
fn include_dependencies(
  id : String,
  indexed : Map[String, ContextNode],
  included : Map[String, Bool],
) -> Unit {
  if included.contains(id) {
    return
  }
  included[id] = true
  for dependency in indexed[id].depends_on {
    include_dependencies(dependency, indexed, included)
  }
}

///|
/// Return required nodes and all transitive prerequisites in source order.
pub fn required_closure(
  nodes : Array[ContextNode],
) -> Array[String] raise PlanError {
  validate_graph(nodes)
  let indexed = index_nodes(nodes)
  let included : Map[String, Bool] = Map([])
  for node in nodes {
    if node.required {
      include_dependencies(node.id, indexed, included)
    }
  }
  [
    for node in nodes if included.contains(node.id) => node.id
  ]
}
