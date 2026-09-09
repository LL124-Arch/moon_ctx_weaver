# MoonCtxWeaver

由于 Agent 的输入往往不只是一句简单的问题，系统约束、几十个工具定义、历史消息和越来越长的工具输出会一起挤进上下文，所以窗口看起来很大，真正留给当前任务的空间却越来越少。

MoonCtxWeaver 因此把这件事看成一个普通的、可以测试的规划问题：每段上下文都有成本、价值和依赖关系，库在预算内选择合适的表示，同时说明保留或舍弃它的原因。整个过程不会偷偷调用另一个模型来做摘要，也不要求使用某个 Agent 框架。

当前仓库还在很早的阶段，因此先把数据模型、依赖检查和预算选择做扎实。现在已经可以读取一份离线场景，输出裁剪后的上下文以及逐节点的取舍说明。首版不追求覆盖所有 tokenizer，也不会把它包装成一个新的 Agent 框架。

想直接看结果，可以运行：

```bash
moon run cmd/moon_ctx_weaver --target native -- scenarios/customer_support.json
```

加上 `--format json` 会得到适合继续处理的结构化结果。仓库里还放了客服、编码和研究三类场景，因为单看一个精心挑选的例子很容易产生误判，所以可以用同一条命令一起观察预算、原始成本、压缩率和质量保留率：

```bash
moon run cmd/moon_ctx_weaver --target native -- --benchmark scenarios/customer_support.json scenarios/coding_agent.json scenarios/research_agent.json
```

这些数字来自场景中明确写出的成本和质量估计，并不是精确 tokenizer 或真实模型评测的替代品。它们的作用是让规划策略能够离线复现，后续也容易接入更可信的测量结果。

## 在项目里使用

`0.1.0` 发布到 Mooncakes 后，可以用 `moon add LL124-Arch/moon_ctx_weaver@0.1.0` 添加依赖，并在使用它的 `moon.pkg` 中导入 `LL124-Arch/moon_ctx_weaver`。目前也可以从这个仓库检出源码直接运行示例。

调用方仍然负责给出 token 成本，因为不同模型的 tokenizer 并不相同。下面的例子刻意保留这个数字，而不是让库用一个看似方便但不可验证的估算替代它：

```moonbit
let nodes = [
  @moon_ctx_weaver.message_node(
    id="request",
    kind=UserMessage,
    content="find the stale cache entry",
    token_cost=8,
    order=0,
  ),
  @moon_ctx_weaver.tool_definition_node(
    id="search",
    description="search_cache(key)",
    token_cost=12,
    order=1,
    priority=@moon_ctx_weaver.lexical_score(
      "stale cache",
      "search cache entries by key",
    ),
  ),
]
let result = @moon_ctx_weaver.plan(
  nodes,
  @moon_ctx_weaver.budget_policy(max_input_tokens=20),
)
println(@moon_ctx_weaver.render(result))
```

规划器先保证必选节点及其传递依赖完整，再以稳定的整数效用/成本比较选择可选闭包，最后利用剩余空间升级表示。因此相同输入在 native、JavaScript、WebAssembly 与 WebAssembly GC 后端上会得到一致结果，但这是一套可解释的确定性启发式，而不是全局最优证明。

项目使用 Apache-2.0 许可证。
