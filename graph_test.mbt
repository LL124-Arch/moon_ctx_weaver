///|
fn test_node(
  id : String,
  depends_on? : Array[String] = [],
  required? : Bool = false,
) -> @moon_ctx_weaver.ContextNode {
  @moon_ctx_weaver.context_node(
    id~,
    kind=ToolResult,
    variants=[
      @moon_ctx_weaver.context_variant(
        label="full",
        content=id,
        token_cost=4,
        quality=100,
      ),
    ],
    order=0,
    required~,
    depends_on~,
  )
}

///|
test "required closure includes transitive dependencies in source order" {
  let nodes = [
    test_node("policy"),
    test_node("call", depends_on=["policy"]),
    test_node("result", depends_on=["call"], required=true),
    test_node("unrelated"),
  ]
  debug_inspect(
    @moon_ctx_weaver.required_closure(nodes),
    content="[\"policy\", \"call\", \"result\"]",
  )
}

///|
test "duplicate node ids are rejected" {
  try
    @moon_ctx_weaver.validate_graph([test_node("same"), test_node("same")])
  catch {
    DuplicateNodeId(id) => inspect(id, content="same")
    _ => fail("unexpected validation error")
  } noraise {
    _ => fail("expected duplicate id")
  }
}

///|
test "missing dependencies are rejected" {
  try
    @moon_ctx_weaver.validate_graph([test_node("result", depends_on=["call"])])
  catch {
    MissingDependency(node_id~, dependency_id~) => {
      inspect(node_id, content="result")
      inspect(dependency_id, content="call")
    }
    _ => fail("unexpected validation error")
  } noraise {
    _ => fail("expected missing dependency")
  }
}

///|
test "dependency cycles are rejected" {
  try
    @moon_ctx_weaver.validate_graph([
      test_node("a", depends_on=["b"]),
      test_node("b", depends_on=["a"]),
    ])
  catch {
    DependencyCycle(path) =>
      debug_inspect(path, content="[\"a\", \"b\", \"a\"]")
    _ => fail("unexpected validation error")
  } noraise {
    _ => fail("expected dependency cycle")
  }
}

///|
test "invalid variants are rejected with their node id" {
  let empty = @moon_ctx_weaver.context_node(
    id="empty",
    kind=Memory,
    variants=[],
    order=0,
  )
  try @moon_ctx_weaver.validate_graph([empty]) catch {
    NoUsableVariant(id) => inspect(id, content="empty")
    _ => fail("unexpected validation error")
  } noraise {
    _ => fail("expected empty variant failure")
  }
}

///|
test "variant costs and quality stay inside their domains" {
  let bad_cost = @moon_ctx_weaver.context_node(
    id="bad-cost",
    kind=Memory,
    variants=[
      @moon_ctx_weaver.context_variant(
        label="preview",
        content="x",
        token_cost=0,
        quality=101,
      ),
    ],
    order=0,
  )
  try @moon_ctx_weaver.validate_graph([bad_cost]) catch {
    InvalidVariantCost(node_id~, label~, cost~) => {
      inspect(node_id, content="bad-cost")
      inspect(label, content="preview")
      inspect(cost, content="0")
    }
    _ => fail("unexpected validation error")
  } noraise {
    _ => fail("expected invalid cost")
  }
}

///|
test "variant quality is limited to a percentage" {
  let bad_quality = @moon_ctx_weaver.context_node(
    id="bad-quality",
    kind=Memory,
    variants=[
      @moon_ctx_weaver.context_variant(
        label="full",
        content="x",
        token_cost=1,
        quality=101,
      ),
    ],
    order=0,
  )
  try @moon_ctx_weaver.validate_graph([bad_quality]) catch {
    InvalidVariantQuality(node_id~, label~, quality~) => {
      inspect(node_id, content="bad-quality")
      inspect(label, content="full")
      inspect(quality, content="101")
    }
    _ => fail("unexpected validation error")
  } noraise {
    _ => fail("expected invalid quality")
  }
}
