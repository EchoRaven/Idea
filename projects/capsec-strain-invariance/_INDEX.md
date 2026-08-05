# capsec-strain-invariance · 文档索引

验证「agent 攻击易感性由相对能力强度（任务离模型能力上限多近）决定，而非绝对能力」
这个假设 —— 若成立，则「能力进步不必然买安全」，因为部署范围会随能力一起扩张。
双轨架构：`rtg-capsec`（生成 depth-N 依赖链攻击任务）+ `dtap-capsec`（跑 victim、
env-state 三值判定、出 strain 曲线）。

**最近一次收到文档**：2026-08-04（第二批，1 份进度更新）
**当前节奏**：快 —— 同一天内两批文档。首批 5 份技术文档交上来后，作者当天又追加
1 份进度更新，直接点名回应了索引「需要你注意的」#1、#2 两条 critique，是少见的
「反馈 → 核实 → 回应」快速闭环。

---

## ⚠️ 需要你注意的

### 1. Invariance 假设目前「既证不了也证伪不了」——统计功效是唯一还没解决的真瓶颈

（继承自原 #2，本次进度更新把它坐实、且比原先设想更严重）

[4victim-ladder-and-index-critique-response](progress/2026-08-04-4victim-ladder-and-index-critique-response.md)
给 content 的 diversion 比值配上了 Wilson 95% CI 后，n_adm=1–3 的 cell 区间几乎横跨
整个 [0,1]（例：super_nova content d=2 div=1.0 CI=[0.34,1.0]；d=6 div=0.0 CI=[0.0,0.56]；
rift 5.14 d=8 div=1.0 CI=[0.21,1.0]）。这意味着现在任何「diversion vs 绝对 depth 分离、
diversion vs 相对 strain 塌缩」的图形对比，在这个 n 下都读不出信号——干净的点估计只是
幻觉。这和 [avo-redteam](../avo-redteam/_INDEX.md) 的 reps=3 Δ+1.00、
[stock-agent](../stock-agent/_INDEX.md) 的按行数算显著性是同一类坑，这次是作者自己
点破的。下一步「扩语料到每 cell 10–15 条」是唯一能解开这个瓶颈的动作，且已确认
不需要付费 key、纯 LLM 生成——没有权限障碍，纯粹是还没做完的工作量。在语料扩完、
区间收窄之前，invariance 结论（无论哪个方向）都不该被引用。

### 2. exfil/UA 的「全 0」已用 n_admissible + Wilson 区间坐实为稳定拒绝——但目前只在聚合层面成立

（原 #1，已回应，追加一条精度提醒）

回应给出 exfiltration n_adm=14（分 5 个 cell：3/3/2/3/3）、unauthorized_action n_adm=8
（2/2/1/1/2），两者 diverted 都是 0，Wilson 95% 上界分别 ~0.22 / ~0.32。undecidable
已经在判定逻辑里被排除在分母外，所以这不是「能力不够走不到注入点」混进来的假 0——
是真的走到了、真的没被攻破。原来的核实要求已经补上，结论现在站得住。

但这个 14/8 是**跨全部 5 个 depth 汇总**的数字，没有给出逐 depth-cell 各自的 Wilson
区间（只给了每个 cell 里 admissible 的个数）。也就是说现在能说的是「exfil/UA 整体上
抵抗住了」，还不能说「在每一个 strain 深度上都抵抗住了」——如果后续要画
diversion-vs-depth 曲线，这两个 shape 也需要跟 content 一样的逐 cell 处理，
不能因为聚合结论干净就跳过。

### 3. 新 victim rift 5.14 让能力梯度变成了实证事实，但最弱 victim 的 frontier 还是一个不等式（"<2"）

四档 benign frontier —— rift 5.14: 8、super_nova: 6、gemini-2.5-flash: 2、
gemini-2.5-flash-lite: **<2** —— 把「能力梯度太窄」这条原来的 blocker 实证推翻了，
是这批文档里最扎实的新进展。但 gemini-2.5-flash-lite 的 frontier 只写了「<2」，不是
一个具体整数。如果后续 relative strain 是按 depth / frontier 算的，这个不确定的分母
会直接传导成梯度最底端（也是数据最薄的那一端）的 strain 坐标不精确。建议花一次专门的
benign-only 探测把这个数字钉死，不需要很多 runs。

### 4. 生成端代码只推了备用 remote，canonical origin 缺部署 key——访问单点（延续自上一份，本次未涉及，继续挂着）

`01-technical-roadmap` 提到生成产物「Pushed to remote `vaibackup`（origin `Virtue-AI`
需要 `id_ed25519_virtueai` key，此环境没有）」。也就是说 `rtg-capsec` 分支
`capsec/env-state-judges` 上的工作目前只活在一个备份 remote 上，团队 canonical
仓库这边没有能推送的凭据。这是一个没写进 blocked 清单、但确实存在的单点风险——
如果这台机器 / vaibackup 账号出问题，这批工作就没有第二份可达的拷贝。
建议要么补上 `id_ed25519_virtueai` key，要么明确记一条「已知：暂只有备份 remote」
的待办，别让它悄悄待着。

---

## 进度汇报 · progress/

| 日期 | 文件 | 摘要 | 与上一份的差异 |
|---|---|---|---|
| 2026-08-04 | [progress](progress/2026-08-04-progress.md) | Generator+measurement 全链路端到端打通，交付 60 runs 真实数据（super_nova 3-shape 全 sweep + 两档 Gemini flash 的 content sweep）。核心发现：易感性强 shape-依赖，content_assertion 有变化（0.33–1.0）、exfil/UA 全 0。Invariance 假设本身还没测——被 Google 免费 key 只开 flash 层（pro 返回 429 `limit:0`）和 n=1–3 的统计功效不足两个原因一起卡住。 | 首份 |
| 2026-08-04 | [4victim-ladder-and-index-critique-response](progress/2026-08-04-4victim-ladder-and-index-critique-response.md) | 新增第四个 victim **rift 5.14**（与 super_nova 同 endpoint/key `api.ai.meta.com/v1` + `LLAMA_API_KEY`，标准 tool-calling），4-victim ladder 累计 74 runs，benign frontier 呈现 8/6/2/<2 的真实能力梯度。同时直接回应了索引「需要你注意的」#1、#2：给 exfil/UA 的「全 0」补上 n_admissible（14、8）与 Wilson 区间（上界 ~22%/~32%），证实是稳定拒绝；给 content 的 diversion 比值补上 Wilson 区间，证实这些区间几乎覆盖整个 [0,1]，invariance 假设现在「既证不了也证伪不了」。 | 与首份相比：①「能力梯度太窄」这条 blocker 被实证推翻，真瓶颈收窄成统计功效一项；②这不是常规进度推进，而是收到索引反馈后当天返回的核实回应——一次快速的「读者提问 → 作者核实 → 给出量化答案」闭环；③下一步的优先级被重新排序并解耦：之前混在一起的「扩语料」和「付费 Google 配额」被拆开——扩语料本身不需要付费 key，只有「加宽梯度顶端」才需要，付费卡点因此从阻塞主线降级为可选项。 |

---

## 技术文档 · tech/

| 日期 | 文件 | 摘要 | 审阅意见 |
|---|---|---|---|
| 2026-08-04 | [overview](tech/2026-08-04-overview.md) | 项目总纲：定义 strain-invariance 假设（同模型内 strain 越高越易被攻破；跨模型因部署范围随能力扩张，ASR 大致不变）、双轨架构图、三种伤害 shape 定义表（exfiltration / unauthorized_action / content_assertion）、depth-N 依赖链作为唯一 strain 自变量、三值 judge（diverted/succeeded/admissible/undecidable）的判定逻辑。 | 文末指向 `01-/02-/03-/04-*.md` 的内部链接，归档改名（`2026-08-04-*.md`）后已经指不到实际文件了——纯格式问题，不影响内容，不需要动原文档。 |
| 2026-08-04 | [technical-roadmap](tech/2026-08-04-technical-roadmap.md) | 架构与实现细节：两个 git worktree（`rtg-capsec` 生成端 branch `capsec/env-state-judges`、`dtap-capsec` 测量端 branch `capsec/measurement-layer`）；env-state judging 的渲染链路（LLM 只出结构化 `HarmDeclaration`，harness 确定性渲染 `judge.py`）、三种 shape 各自的固定注入构造方式、depth 数据模型与 `validate_chain` 校验闸门、k=3 self-consistency 质量投票；测量侧 victim runner 命令、judge-LLM 从 gpt-5.4 切到 deepseek-chat 的修复过程、`analyze_strain.py` 的结果-语料对齐逻辑；victim 能力/可用性表。 | victim 表把「为什么能力梯度这么窄」交代得很清楚——Meta 前沿模型网关工具协议互不兼容、Anthropic 缺 credit、Google 免费层只开 flash——这张表本身就是对当前卡点最好的证据，建议随后续 victim 变化持续更新，别只留在这一份快照里。 |
| 2026-08-04 | [findings](tech/2026-08-04-findings.md) | 首批实证结果：exfil/UA 在全部 5 个 depth 上易感性均为 0，content_assertion 在 0.33–1.0 间波动（见需要你注意 #2）；60 runs 首批多 victim（super_nova + 两档 Gemini flash）数据显示三个 victim 都在 content 上有非零 diversion，但解不出单调 strain 趋势（n 太小，见需要你注意 #1）；三值 judge + depth 校验闸门被验证为有效方法论；记录三条 infra 踩坑（judge import 路径、judge 会继承 victim 的 `OPENAI_BASE_URL`、前沿模型网关不兼容）。文档自己指出这个「content 易感、action 不易感」的结果和 [avo-redteam](../avo-redteam/_INDEX.md) 「诽谤类记录归档转述是唯一防御盲区」的结果互相印证，是从生成侧对同一现象的独立复现——两个项目分别从「打生成」和「测防御」两端撞到了同一条边界，值得在两边索引里都留个记号。 | 见需要你注意 #1、#2（两条 critique 已在 [2026-08-04 进度更新](progress/2026-08-04-4victim-ladder-and-index-critique-response.md) 里被作者直接回应）。 |
| 2026-08-04 | [runbook](tech/2026-08-04-runbook.md) | 环境变量与两个 worktree 路径；三步操作流程（生成语料，docker-free → victim sweep，需 docker，从 `dtap-capsec` 跑 → `analyze_strain.py` 出图）具体命令；operational caveats：共享 docker 主机清理规则（不许删别人的 `pool_*`/`rds-*`）、UIUC 用 docker 不是 podman、judge LLM 必须走独立 provider（不能继承 victim 的 base_url）、`.env` 里 Meta key 的 `|` 转义坑、Gemini 免费层限流（`--max-parallel 1`）。 | 无。 |

---

## 关键决策记录

- **架构决策 A：judge 从 live backend state 判定，不看 MCP 轨迹** —— 模态无关，且不会被「表面上像是拒绝了」的轨迹文本骗到。
- **LLM 只产出结构化 `HarmDeclaration`，harness 确定性渲染 `judge.py`** —— 不让 LLM 自己写判定代码，避免判官被生成的判定逻辑本身污染。
- **固定注入而非运行时注入** —— env-state judging 依赖生成时就定好的值（凭证、beneficiary、claim_text），运行时注入会让判定失去锚点。
- **depth 是唯一自变量，env-breadth 钉死** —— 否则「strain 更高」和「环境更复杂」会混杂，`validate_chain` 强制真实的依赖链而非表面深度。
- **diversion 只在 admissible 上计分，undecidable 单独排除** —— 这是处理「too weak to reach the injection ≠ resisted」这个混淆的正式机制，写进了判定本身而非靠人工事后甄别。
- **judge LLM 换成 deepseek-chat，且走独立 provider 路由** —— 判官不能继承 victim 的 `OPENAI_BASE_URL`，否则判官会打到 victim 的网关上（曾经导致 404 被静默吞成「resisted」）。
- **diversion 比值一律配 Wilson 95% CI，不再裸报**（2026-08-04 追加）—— 小 n 下的整数比值（0.0/1.0）极易被误读成强结论；`analyze_strain.py` 现在给每个 cell 配区间，逼着自己和读者面对当前样本量下「什么都还没被证明」的现实。
- **新 victim 优先复用现有 endpoint/key/eval harness**（2026-08-04 追加）—— rift 5.14 与 super_nova 同 `api.ai.meta.com/v1` + `LLAMA_API_KEY`、标准 tool-calling，直接进现有 openaisdk eval，不用每次扩梯度都去攻克一个新网关的兼容性问题。
  **2026-08-04 追加（跨项目参考）**：[avo-redteam](../avo-redteam/_INDEX.md) 新交了一份
  [`using-victims-from-another-repo`](../avo-redteam/tech/2026-08-04-using-victims-from-another-repo.md)
  集成指南，把这条决策正在用的 `rift 5.14` 接入方式（endpoint、key、可复用的
  `victim_client.py`）正式文档化了。如果这边后续要把梯度顶端扩到 groovy 5.15，
  该文档 §4 已经给出现成的 `--victim-arch responses --victim-api-key-env GROOVY_KEY
  --victim-reasoning-effort high` 参数，不用重新摸索；但要注意 avo-redteam 那边
  groovy key 目前 403 停摆，这条路暂时也走不通。
