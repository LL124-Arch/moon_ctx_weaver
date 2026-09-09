///|
/// The role a context node plays in an agent request.
pub(all) enum ContextKind {
  SystemInstruction
  DeveloperInstruction
  UserMessage
  AssistantMessage
  ToolDefinition
  ToolCall
  ToolResult
  RetrievedContext
  Memory
} derive(Debug, Eq)

///|
/// One usable representation of a context node.
pub(all) struct ContextVariant {
  label : String
  content : String
  token_cost : Int
  quality : Int
} derive(Debug, Eq)

///|
/// Build one representation. Costs and quality are validated with the graph.
pub fn context_variant(
  label~ : String,
  content~ : String,
  token_cost~ : Int,
  quality~ : Int,
) -> ContextVariant {
  { label, content, token_cost, quality }
}

///|
/// A selectable unit of agent context and its prerequisites.
pub(all) struct ContextNode {
  id : String
  kind : ContextKind
  variants : Array[ContextVariant]
  order : Int
  priority : Int
  required : Bool
  depends_on : Array[String]
} derive(Debug, Eq)

///|
/// Build a context node. Optional values keep small callers concise.
pub fn context_node(
  id~ : String,
  kind~ : ContextKind,
  variants~ : Array[ContextVariant],
  order~ : Int,
  priority? : Int = 0,
  required? : Bool = false,
  depends_on? : Array[String] = [],
) -> ContextNode {
  { id, kind, variants, order, priority, required, depends_on }
}

///|
/// Input-window limits used by the planner.
pub(all) struct BudgetPolicy {
  max_input_tokens : Int
  reserved_output_tokens : Int
} derive(Debug, Eq)

///|
/// Build a budget policy, reserving no output space unless requested.
pub fn budget_policy(
  max_input_tokens~ : Int,
  reserved_output_tokens? : Int = 0,
) -> BudgetPolicy {
  { max_input_tokens, reserved_output_tokens }
}

///|
/// Space that may be occupied by selected context.
pub fn BudgetPolicy::available_input_tokens(self : BudgetPolicy) -> Int {
  self.max_input_tokens - self.reserved_output_tokens
}

///|
/// Build a common message node with one full-fidelity representation.
pub fn message_node(
  id~ : String,
  kind~ : ContextKind,
  content~ : String,
  token_cost~ : Int,
  order~ : Int,
  priority? : Int = 100,
  required? : Bool = true,
  depends_on? : Array[String] = [],
) -> ContextNode {
  context_node(
    id~,
    kind~,
    variants=[context_variant(label="full", content~, token_cost~, quality=100)],
    order~,
    priority~,
    required~,
    depends_on~,
  )
}

///|
/// Build a common tool-definition node with one full representation.
pub fn tool_definition_node(
  id~ : String,
  description~ : String,
  token_cost~ : Int,
  order~ : Int,
  priority? : Int = 50,
  required? : Bool = false,
  depends_on? : Array[String] = [],
) -> ContextNode {
  context_node(
    id~,
    kind=ToolDefinition,
    variants=[
      context_variant(
        label="full",
        content=description,
        token_cost~,
        quality=100,
      ),
    ],
    order~,
    priority~,
    required~,
    depends_on~,
  )
}
