///|
struct InputVariant {
  label : String
  content : String
  token_cost : Int
  quality : Int
} derive(FromJson)

///|
struct InputNode {
  id : String
  kind : String
  variants : Array[InputVariant]
  order : Int
  priority : Int
  required : Bool
  depends_on : Array[String]
} derive(FromJson)

///|
struct InputPolicy {
  max_input_tokens : Int
  reserved_output_tokens : Int
} derive(FromJson)

///|
struct InputScenario {
  nodes : Array[InputNode]
  policy : InputPolicy
} derive(FromJson)

///|
struct Scenario {
  nodes : Array[@core.ContextNode]
  policy : @core.BudgetPolicy
}

///|
suberror CliError {
  UnknownKind(String)
  UnknownFormat(String)
  Usage(String)
} derive(Debug)

///|
fn decode_kind(kind : String) -> @core.ContextKind raise CliError {
  match kind {
    "system_instruction" => SystemInstruction
    "developer_instruction" => DeveloperInstruction
    "user_message" => UserMessage
    "assistant_message" => AssistantMessage
    "tool_definition" => ToolDefinition
    "tool_call" => ToolCall
    "tool_result" => ToolResult
    "retrieved_context" => RetrievedContext
    "memory" => Memory
    other => raise UnknownKind(other)
  }
}

///|
fn decode_scenario(source : String) -> Scenario raise {
  let input : InputScenario = @json.from_json(@json.parse(source))
  let nodes = []
  for node in input.nodes {
    let variants = [
      for variant in node.variants => {
        @core.context_variant(
          label=variant.label,
          content=variant.content,
          token_cost=variant.token_cost,
          quality=variant.quality,
        )
      }
    ]
    nodes.push(
      @core.context_node(
        id=node.id,
        kind=decode_kind(node.kind),
        variants~,
        order=node.order,
        priority=node.priority,
        required=node.required,
        depends_on=node.depends_on,
      ),
    )
  }
  {
    nodes,
    policy: @core.budget_policy(
      max_input_tokens=input.policy.max_input_tokens,
      reserved_output_tokens=input.policy.reserved_output_tokens,
    ),
  }
}
