///|
let sample_scenario : String =
  #|{
  #|  "policy": { "max_input_tokens": 5, "reserved_output_tokens": 0 },
  #|  "nodes": [
  #|    {
  #|      "id": "policy",
  #|      "kind": "system_instruction",
  #|      "order": 0,
  #|      "priority": 100,
  #|      "required": true,
  #|      "depends_on": [],
  #|      "variants": [
  #|        { "label": "full", "content": "full policy", "token_cost": 8, "quality": 100 },
  #|        { "label": "preview", "content": "policy preview", "token_cost": 2, "quality": 60 }
  #|      ]
  #|    },
  #|    {
  #|      "id": "tool",
  #|      "kind": "tool_definition",
  #|      "order": 1,
  #|      "priority": 60,
  #|      "required": false,
  #|      "depends_on": ["policy"],
  #|      "variants": [
  #|        { "label": "compact", "content": "tool compact", "token_cost": 3, "quality": 80 }
  #|      ]
  #|    }
  #|  ]
  #|}

///|
test "scenario JSON becomes planner inputs" {
  let scenario = decode_scenario(sample_scenario)
  inspect(scenario.nodes.length(), content="2")
  inspect(scenario.policy.max_input_tokens, content="5")
  debug_inspect(scenario.nodes[0].kind, content="SystemInstruction")
  inspect(scenario.nodes[1].depends_on[0], content="policy")
}

///|
test "CLI formatters expose both text and structured output" {
  let scenario = decode_scenario(sample_scenario)
  let plan = @core.plan(scenario.nodes, scenario.policy)
  inspect(
    format_plan_text(plan),
    content=(
      #|budget: 5/5 tokens
      #|baseline: 11 tokens
      #|quality retained: 77%
      #|policy: preview, 2 tokens, required
      #|tool: compact, 3 tokens, selected for utility
      #|
      #|context:
      #|policy preview
      #|
      #|tool compact
    ),
  )
  json_inspect(@json.parse(format_plan_json(plan)), content={
    "available_tokens": 5,
    "used_tokens": 5,
    "original_tokens": 11,
    "quality_retention_percent": 77,
    "rendered_context": "policy preview\n\ntool compact",
    "decisions": [
      {
        "node_id": "policy",
        "selected_variant": "preview",
        "token_cost": 2,
        "quality": 60,
        "upgraded": false,
        "reason": "required",
      },
      {
        "node_id": "tool",
        "selected_variant": "compact",
        "token_cost": 3,
        "quality": 80,
        "upgraded": false,
        "reason": "selected_for_utility",
      },
    ],
  })
}
