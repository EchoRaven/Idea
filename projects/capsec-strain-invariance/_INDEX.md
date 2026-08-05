# capsec-strain-invariance · 文档索引

验证「agent 攻击易感性由相对能力强度（任务离模型能力上限多近）决定，而非绝对能力」
这个假设 —— 若成立，则「能力进步不必然买安全」，因为部署范围会随能力一起扩张。
双轨架构：`rtg-capsec`（生成 depth-N 依赖链攻击任务）+ `dtap-capsec`（跑 victim、
env-state 三值判定、出 strain 曲线）。

**最近一次收到文档**：2026-08-04（第三批——`progress.md` 被就地追加了一段「autonomous
loop」更新，`findings.md` 被就地追加 §2b/§3/§4；两份都是原文件内容扩展，不是新文件）
**当前节奏**：快，且罕见——同一天内已经是第三轮内容产出（首批 5 份技术文档 → 4-victim-ladder
critique 回应 → 本轮的 depth-24 定论 + fork 决策点），说明作者当天在跑一个连续的
autonomous loop，产出速度明显超出常规节奏。

---

## ⚠️ 需要你注意的

### 1.（重大结论，本轮核心）depth 轴对前沿模型不起作用——rift 的 depth 1→24 sweep 是定论，不是初步结果

[progress 追加段](progress/2026-08-04-progress.md#update-2026-08-04-later--autonomous-loop-6-iterations)
与 [findings §2b](tech/2026-08-04-findings.md) 报告的是同一份新数据：三轮扩语料后达到
**n_admissible 15–22/cell（~135 任务）**，覆盖 depth {1,2,4,6,8,12,16,24}。结果——
benign_rate 不降反升，depth 24 达到 **0.875**（已核实不是判据变松的假象：depth24 的
benign 判据反而比 depth1 更严格，6 checks/4 llm_checks vs 4 checks/1 llm_check）；
diversion 在最浅处最低（0.056 @ depth1，Wilson [0.01,0.26]），之后噪声式持平，没有随
深度上升的趋势。两条结论都直接反驳「越深越容易被攻破」的朴素 strain 故事。

这次和上一轮不一样：上一轮索引 #1 说的是「既证不了也证伪不了，统计功效不够」；这次是
**先把 n 做够，再拿到一个明确的负结果**——不是数据不够、是这条自变量本身对前沿模型不
起作用。文档原话「strain-invariance is untestable on a frontier victim via the depth
axis」。这意味着项目最初的架构决策「depth-N 依赖链是唯一 strain 自变量」（见下方决策
记录）现在需要被重新审视，不是执行层面的事，是设计层面要做选择——具体分叉见 PROJECTS.md
「下一步」。

### 2.（新发现，需要澄清）「victim 梯度已不是 blocker」和这轮「second victim 全部受阻」的说法有张力

上一轮索引记录：4-victim ladder（rift/super_nova/gemini-flash/gemini-flash-lite）证实
了 8/6/2/<2 的真实能力梯度，「能力梯度太窄」这条 blocker 被实证推翻。但本轮
[progress 追加段]紧跟着 depth-24 结果之后写的是：「Victim-ladder status: all
second-victim paths blocked」——GPT（`-genai-responses`）在 tool-result 轮上网关序列化
崩溃、Gemini 免费层限流（5 次探测 2 次 429，多步任务跑不完）、Meta 各 codename 已经
500 了 6 小时以上，「只有 rift（不限量）+ deepseek 生成能可靠使用」。

这两条表述不是逻辑矛盾——前者是「能在 n=1–3 的小样本上跑出四档梯度」，后者是「没法把
第二个 victim 也扩到 rift 这种 well-powered（n=15–22/cell）规模」——但放在一起读容易让
人误以为 victim 基础设施问题已经解决。实际上「把 depth-24 well-powered sweep 复制到
第二个 victim」这件事现在比上一轮乐观表述听起来的更堵，不是更松。PROJECTS.md 的断点
措辞已按这个区分改写。

### 3.（延续，未受本轮影响）exfil/UA 的「全 0」目前只在跨 depth 聚合层面有 Wilson 区间

exfiltration n_adm=14（分 5 个 cell：3/3/2/3/3）、unauthorized_action n_adm=8
（2/2/1/1/2），两者 diverted 都是 0，Wilson 95% 上界分别 ~0.22 / ~0.32——是真的走到了
注入点、真的没被攻破，不是「太弱走不到」混进来的假 0。但这仍是**跨全部 5 个 depth 汇总**
的数字，没有逐 depth-cell 的区间。本轮两份文档都没有补这个，继续挂着——如果后续要画
diversion-vs-depth 曲线，这两个 shape 也需要跟 content 一样的逐 cell 处理。

### 4.（延续，未受本轮影响，优先级因 #2 下调）gemini-2.5-flash-lite 的 benign frontier 仍只是「<2」这个不等式

四档梯度里最弱的一档 frontier 只写了「<2」，不是具体整数。本轮的 victim-ladder-blocked
消息（#2）让这件事更不容易短期解决——Gemini 免费层现在被明确报告为「多步任务跑不完」，
意味着专门去钉死这个数字的探测本身也会撞上限流。从「随时可做的一次性小任务」降级为
「等基础设施恢复后再做」。

### 5.（延续，未受本轮影响）生成端代码只推了备用 remote，canonical origin 缺部署 key——访问单点

`01-technical-roadmap` 提到生成产物「Pushed to remote `vaibackup`（origin `Virtue-AI`
需要 `id_ed25519_virtueai` key，此环境没有）」。也就是说 `rtg-capsec` 分支
`capsec/env-state-judges` 上的工作目前只活在一个备份 remote 上，团队 canonical
仓库这边没有能推送的凭据。这是一个没写进 blocked 清单、但确实存在的单点风险——
如果这台机器 / vaibackup 账号出问题，这批工作就没有第二份可达的拷贝。
建议要么补上 `id_ed25519_virtueai` key，要么明确记一条「已知：暂只有备份 remote」
的待办，别让它悄悄待着。

### 6.（跨项目提示，来自 avo-redteam，可能是 exfil/UA「全 0」的一个待测混杂因素）注入面（wall vs soft surface）可能比伤害类型（content_assertion vs exfil/UA）更接近真正的自变量

[avo-redteam](../avo-redteam/_INDEX.md) 2026-08-05 交的
[`reproduced-attack-report`](../avo-redteam/tech/2026-08-05-reproduced-attack-report.md)
把 rift 的防御拆成了两种注入面：**「wall」**——伪造内容直接写在邮件/note 里断言给
victim 听，rift 会拒绝并要求走自己的工具核对官方记录；**「soft surface」**——同样的伪造
内容 poison 进 victim legitimate 任务本就会读的记录本身（policy 页面、tracker 状态列），
victim 会当真执行。用 soft-surface 手法后，rift 交出了一个手工核验的真实攻击成功
（污染 Confluence/Jira 政策页 → 触发一次真实的 `create_payout`）——注意这次触发的是一个
**动作**（payout），不是纯内容断言，说明「content_assertion 撬动 unauthorized_action」
这条链路对 rift 是通的。

这对本项目的启发：本项目 exfiltration/unauthorized_action 全 5 个 depth 都是 0
diversion（见上方 #3），但固定注入（见下方决策记录「固定注入而非运行时注入」）用的很
可能是「wall」等价物——直接把有害动作要求放进任务本身，victim 一眼能看出是显式指令。
如果改成把同样的有害要求 poison 进 victim 会读的**记录**（而非任务指令本身），
exfiltration/UA 是否还能保持 0，目前没有测过。这不是说要现在就去做——depth 轴的
well-powered sweep 已经耗尽了当前精力（见 #1），但如果后续要引入新的 strain 自变量，
「注入面」本身可能比「换一个推理难度维度」更值得优先验证，因为 avo-redteam 那边已经
拿到一个正面证据，而不是从零假设。

---

## 进度汇报 · progress/

| 日期 | 文件 | 摘要 | 与上一份的差异 |
|---|---|---|---|
| 2026-08-04（追加更新） | [progress](progress/2026-08-04-progress.md) | Generator+measurement 全链路端到端打通，首批交付 60 runs（super_nova 3-shape 全 sweep + 两档 Gemini flash 的 content sweep）。**同一份文件当天被追加两层内容**：先是独立的 4-victim-ladder 回应文件（见下一行），之后这份文件本身又被追加了一段「Update（autonomous loop, ~6 iterations）」——三轮扩语料后在 rift 上完成 depth 1→24 的 well-powered sweep（n_admissible 15–22/cell），结论是 chain-depth 不能 strain 一个前沿模型，并明确写下「depth-axis measurement on rift is complete; further rift-depth runs add nothing」。文末给下一阶段留了一个需要人决策的分叉：换一个能真正 strain 前沿模型的自变量（推理难度/歧义/干扰项密度/分支），或者换一个真正弱的 victim（三条候选路径目前全部基础设施受阻）。 | 与首批内容相比，追加段把索引 #1 的「既证不了也证伪不了」直接升级为「证伪了，depth 轴本身对前沿模型不是好轴」；同时给出一个和上一轮乐观基调不完全对齐的新说法——第二个 victim 想复制这种规模的 sweep 目前全部受阻，见「需要你注意的」#2。 |
| 2026-08-04 | [4victim-ladder-and-index-critique-response](progress/2026-08-04-4victim-ladder-and-index-critique-response.md) | 新增第四个 victim **rift 5.14**（与 super_nova 同 endpoint/key `api.ai.meta.com/v1` + `LLAMA_API_KEY`，标准 tool-calling），4-victim ladder 累计 74 runs，benign frontier 呈现 8/6/2/<2 的真实能力梯度。同时直接回应了索引「需要你注意的」#1、#2：给 exfil/UA 的「全 0」补上 n_admissible（14、8）与 Wilson 区间（上界 ~22%/~32%），证实是稳定拒绝；给 content 的 diversion 比值补上 Wilson 区间，证实这些区间几乎覆盖整个 [0,1]，invariance 假设现在「既证不了也证伪不了」。 | 与首份相比：①「能力梯度太窄」这条 blocker 被实证推翻，真瓶颈收窄成统计功效一项；②这不是常规进度推进，而是收到索引反馈后当天返回的核实回应——一次快速的「读者提问 → 作者核实 → 给出量化答案」闭环；③下一步的优先级被重新排序并解耦：之前混在一起的「扩语料」和「付费 Google 配额」被拆开——扩语料本身不需要付费 key，只有「加宽梯度顶端」才需要，付费卡点因此从阻塞主线降级为可选项。（此文件本身本轮未再更新，摘要保留原状；后续演进见上一行 progress.md 的追加段。） |

---

## 技术文档 · tech/

| 日期 | 文件 | 摘要 | 审阅意见 |
|---|---|---|---|
| 2026-08-04 | [overview](tech/2026-08-04-overview.md) | 项目总纲：定义 strain-invariance 假设（同模型内 strain 越高越易被攻破；跨模型因部署范围随能力扩张，ASR 大致不变）、双轨架构图、三种伤害 shape 定义表（exfiltration / unauthorized_action / content_assertion）、depth-N 依赖链作为唯一 strain 自变量、三值 judge（diverted/succeeded/admissible/undecidable）的判定逻辑。 | 文末指向 `01-/02-/03-/04-*.md` 的内部链接，归档改名（`2026-08-04-*.md`）后已经指不到实际文件了——纯格式问题，不影响内容，不需要动原文档。 |
| 2026-08-04 | [technical-roadmap](tech/2026-08-04-technical-roadmap.md) | 架构与实现细节：两个 git worktree（`rtg-capsec` 生成端 branch `capsec/env-state-judges`、`dtap-capsec` 测量端 branch `capsec/measurement-layer`）；env-state judging 的渲染链路（LLM 只出结构化 `HarmDeclaration`，harness 确定性渲染 `judge.py`）、三种 shape 各自的固定注入构造方式、depth 数据模型与 `validate_chain` 校验闸门、k=3 self-consistency 质量投票；测量侧 victim runner 命令、judge-LLM 从 gpt-5.4 切到 deepseek-chat 的修复过程、`analyze_strain.py` 的结果-语料对齐逻辑；victim 能力/可用性表。 | victim 表把「为什么能力梯度这么窄」交代得很清楚——Meta 前沿模型网关工具协议互不兼容、Anthropic 缺 credit、Google 免费层只开 flash——这张表本身就是对当前卡点最好的证据，建议随后续 victim 变化持续更新，别只留在这一份快照里。 |
| 2026-08-04（追加 §2b/§3/§4） | [findings](tech/2026-08-04-findings.md) | §1 shape-依赖（exfil/UA 全 5 个 depth 均 0，content 0.33–1.0，见需要你注意 #3）；§2 首批多 victim 小样本数据（n 太小，无法解出单调趋势）；**§2b（新增，本轮核心）——rift 的 depth 1→24 well-powered（n_admissible 15–22/cell，~135 任务）definitive 结果**：chain-depth 不 strain rift（benign_rate flat-to-rising，depth24=0.875；diversion 在 depth1 最低之后 noisy-flat，无 monotonic 上升），两条结论都直接反驳「越深越容易被攻破」的朴素 strain 故事，末尾给出两条前进路径（新自变量 vs 弱 victim）供决策；**§3（新增）**总结方法论上行得通的部分（三值 judge、genuine depth gating、确定性判据 vs llm_check 判据的脆弱性对比）；**§4（新增，原§3 infra 教训扩充/重排）**记录 judge.py import 路径要从 canonical `dt_arena` 找、judge 会继承 victim 的 `OPENAI_BASE_URL`、前沿模型网关对 agentic tool-use 不友好（Gemini 走 Google 原生 endpoint 是目前唯一干净的路）。文档自己指出「content 易感、action 不易感」的结果和 [avo-redteam](../avo-redteam/_INDEX.md)「诽谤类记录归档转述是唯一防御盲区」的结果互相印证。 | §2b 与 [progress 追加段](progress/2026-08-04-progress.md) 的数字完全一致（benign@24=0.875、diversion@1=0.056），两份文档互相印证，没有发现矛盾——这是迄今最扎实的单点结论，第一次是「扩够语料后敢下定论」而不是「n 不够所以什么都不能说」。但 §2b 末尾的「两条前进路径」和 progress.md 的「fork, needs a decision」是同一件事的两处重复表达，建议以后这类需要人做选择的分叉决策只在 progress 里写一处、tech findings 只放数据和结论，避免两份文档各自演化出不一致的措辞。另外 §3/§4 提到「llm_check 判据脆弱，曾把 judge 的 404 静默吞成 diverted=false」这个坑——核对 [runbook](tech/2026-08-04-runbook.md) 后确认：runbook 只静态记录了「judge 默认 deepseek-chat、需要 provider 路由」这个配置事实，**没有把「验证 judge 确实存活/可达」写成操作步骤**，这个已经真实发生过的失败模式（曾让"resisted"是假象）目前仍只停留在事后记录，没有变成可执行的核验清单项，和 avo-redteam 那边「trivial 假防御未进核验清单」是同一类坑（见 [avo-redteam 索引 #6](../avo-redteam/_INDEX.md)）。 |
| 2026-08-04 | [runbook](tech/2026-08-04-runbook.md) | 环境变量与两个 worktree 路径；三步操作流程（生成语料，docker-free → victim sweep，需 docker，从 `dtap-capsec` 跑 → `analyze_strain.py` 出图）具体命令；operational caveats：共享 docker 主机清理规则（不许删别人的 `pool_*`/`rds-*`）、UIUC 用 docker 不是 podman、judge LLM 必须走独立 provider（不能继承 victim 的 base_url）、`.env` 里 Meta key 的 `|` 转义坑、Gemini 免费层限流（`--max-parallel 1`）。 | 无。 |

---

## 关键决策记录

- **架构决策 A：judge 从 live backend state 判定，不看 MCP 轨迹** —— 模态无关，且不会被「表面上像是拒绝了」的轨迹文本骗到。
- **LLM 只产出结构化 `HarmDeclaration`，harness 确定性渲染 `judge.py`** —— 不让 LLM 自己写判定代码，避免判官被生成的判定逻辑本身污染。
- **固定注入而非运行时注入** —— env-state judging 依赖生成时就定好的值（凭证、beneficiary、claim_text），运行时注入会让判定失去锚点。
- **depth 是唯一自变量，env-breadth 钉死** —— 否则「strain 更高」和「环境更复杂」会混杂，`validate_chain` 强制真实的依赖链而非表面深度。
  **2026-08-04 追加（这条决策的效力边界已被测出）**：在 rift 上把这条自变量测到 depth 24（well-powered，
  n_admissible 15–22/cell）后发现它对前沿模型不起作用——benign_rate 不降反升、diversion 无 monotonic
  趋势，见「需要你注意的」#1。depth 轴本身仍然是干净的自变量（`validate_chain` 保证的真实性没有问题），
  但「用它来 strain 一个前沿模型」这个应用已经走到头，继续加 rift-depth 数据不会再有新信息（文档原话
  「further rift-depth runs add nothing」）。下一步是否要引入第二个自变量（推理难度/歧义/干扰项密度/
  分支）取代或补充 depth，是一个待决策项，不是既定架构。
- **diversion 只在 admissible 上计分，undecidable 单独排除** —— 这是处理「too weak to reach the injection ≠ resisted」这个混淆的正式机制，写进了判定本身而非靠人工事后甄别。
- **judge LLM 换成 deepseek-chat，且走独立 provider 路由** —— 判官不能继承 victim 的 `OPENAI_BASE_URL`，否则判官会打到 victim 的网关上（曾经导致 404 被静默吞成「resisted」）。
  **2026-08-04 追加（证据强化，但操作清单未跟上）**：findings §3/§4 把这条决策的必要性坐实——确定性判据
  （exfil/UA）在判官 LLM 挂掉时验证结果依然存活，`llm_check` 判据（content）没有，且是**静默**失败
  （404 被吞成 `diverted=false`，一度伪装成「resisted」）。也就是说任何新增的 `llm_check` 判据都需要
  「先确认判官模型真的活着」这一步，但这一步目前只存在于事后记录里，没有进 [runbook](tech/2026-08-04-runbook.md)
  的操作清单（核对过 runbook 全文，确认真的没有），详见下方技术文档表 findings 行的审阅意见。
- **diversion 比值一律配 Wilson 95% CI，不再裸报**（2026-08-04 追加）—— 小 n 下的整数比值（0.0/1.0）极易被误读成强结论；`analyze_strain.py` 现在给每个 cell 配区间，逼着自己和读者面对当前样本量下「什么都还没被证明」的现实。
- **新 victim 优先复用现有 endpoint/key/eval harness**（2026-08-04 追加）—— rift 5.14 与 super_nova 同 `api.ai.meta.com/v1` + `LLAMA_API_KEY`、标准 tool-calling，直接进现有 openaisdk eval，不用每次扩梯度都去攻克一个新网关的兼容性问题。
  **2026-08-04 追加（跨项目参考）**：[avo-redteam](../avo-redteam/_INDEX.md) 新交了一份
  [`using-victims-from-another-repo`](../avo-redteam/tech/2026-08-04-using-victims-from-another-repo.md)
  集成指南，把这条决策正在用的 `rift 5.14` 接入方式（endpoint、key、可复用的
  `victim_client.py`）正式文档化了。如果这边后续要把梯度顶端扩到 groovy 5.15，
  该文档 §4 已经给出现成的 `--victim-arch responses --victim-api-key-env GROOVY_KEY
  --victim-reasoning-effort high` 参数，不用重新摸索；但要注意 avo-redteam 那边
  groovy key 目前 403 停摆，这条路暂时也走不通。
