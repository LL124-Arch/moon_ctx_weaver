///|
test "lexical score normalizes case punctuation and repeated terms" {
  inspect(
    @moon_ctx_weaver.lexical_score(
      "Cache, INVALIDATION cache", "Cache invalidation prevents stale entries",
    ),
    content="88",
  )
  inspect(@moon_ctx_weaver.lexical_score("cache cache", "cache"), content="100")
}

///|
test "lexical score handles partial unicode and empty queries" {
  inspect(
    @moon_ctx_weaver.lexical_score(
      "降低 token 消耗", "通过缓存降低 token 消耗",
    ),
    content="91",
  )
  inspect(@moon_ctx_weaver.lexical_score("alpha beta", "alpha"), content="60")
  inspect(@moon_ctx_weaver.lexical_score("", "anything"), content="0")
}

///|
test "message and tool helpers retain explicit costs and dependencies" {
  let message = @moon_ctx_weaver.message_node(
    id="request",
    kind=UserMessage,
    content="please inspect the cache",
    token_cost=6,
    order=1,
  )
  let tool = @moon_ctx_weaver.tool_definition_node(
    id="search",
    description="search(query)",
    token_cost=9,
    order=2,
    priority=70,
    depends_on=["request"],
  )
  inspect(message.required, content="true")
  inspect(message.variants[0].label, content="full")
  inspect(message.variants[0].token_cost, content="6")
  debug_inspect(tool.kind, content="ToolDefinition")
  inspect(tool.priority, content="70")
  debug_inspect(tool.depends_on, content="[\"request\"]")
}
