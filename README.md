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

项目使用 Apache-2.0 许可证。
