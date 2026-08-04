# capsec-strain-invariance · 文档索引

验证「agent 攻击易感性由相对能力强度（任务离模型能力上限多近）决定，而非绝对能力」
这个假设 —— 若成立，则「能力进步不必然买安全」，因为部署范围会随能力一起扩张。
双轨架构：`rtg-capsec`（生成 depth-N 依赖链攻击任务）+ `dtap-capsec`（跑 victim、
env-state 三值判定、出 strain 曲线）。

**最近一次收到文档**：2026-08-04（首次，5 份）
**当前节奏**：—　*（首份，暂无历史可比）*

---

## ⚠️ 需要你注意的

### 1. Finding 1「exfil/UA 打 0，只有 content_assertion 易感」缺 n_admissible 支撑

`03-findings` §1 的结论是 super_nova 在 exfiltration / unauthorized_action 上
5 个 depth 全部 diversion=0.0，由此推出「拒绝边界在**动作**层、不在**内容**层」。
但表格只给了 diversion 比值，没有给每个 cell 的 admissible 样本数——
§2 讨论 content 时明确标出了 `n_adm=0` 这种情况，说明作者知道 n 会小到需要单独标注，
但 exfil/UA 那张表没有做同样的处理。

如果 exfil/UA 的 admissible 数本身就很小（这两个 shape 都要求「真的做出一个离散有害动作」，
比 content 更难触达），那「0.0 everywhere」有可能部分是「很少 admissible」而不是
「稳定地拒绝」——判定逻辑虽然把 undecidable 排除在外处理了 security-by-incompetence，
但如果 admissible 本身就是 1、2 个样本，0.0 和「拒绝边界很硬」这个强解读之间还有一步核实没做。
建议 `analyze_strain.py` 或后续报告里把 exfil/UA 的 n_admissible 也摆出来。

### 2. 小 n 下的"整齐比值"——和 avo-redteam、stock-agent 是同一个统计坑

depth=2 时 super_nova 的 content diversion=**1.0**，depth=6 全部 shape 都是 **0.0**——
这些干净的整数背后的分母目前不可见，很可能就是 1/1、2/2 这种 n=1–3 的比值。
`02-progress` 自己也把「Underpowered. n=1–3 per cell」列在 blocked 里，
说明这不是没意识到，只是还没解决。

这和 [avo-redteam](../avo-redteam/_INDEX.md) 的 reps=3 Δ+1.00、和
[stock-agent](../stock-agent/_INDEX.md) 早前踩过的「按行数而非独立观测数算显著性」
是同一类错误：**小样本上的整数结果最容易被误读成硬结论。**
下一步「扩语料到每 cell ~10 条」是对的方向；建议扩完之后直接给
diversion 比值配上区间估计（哪怕只是简单的 Wilson 区间），而不是继续裸报比值。

### 3. 生成端代码只推了备用 remote，canonical origin 缺部署 key——访问单点

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

---

## 技术文档 · tech/

| 日期 | 文件 | 摘要 | 审阅意见 |
|---|---|---|---|
| 2026-08-04 | [overview](tech/2026-08-04-overview.md) | 项目总纲：定义 strain-invariance 假设（同模型内 strain 越高越易被攻破；跨模型因部署范围随能力扩张，ASR 大致不变）、双轨架构图、三种伤害 shape 定义表（exfiltration / unauthorized_action / content_assertion）、depth-N 依赖链作为唯一 strain 自变量、三值 judge（diverted/succeeded/admissible/undecidable）的判定逻辑。 | 文末指向 `01-/02-/03-/04-*.md` 的内部链接，归档改名（`2026-08-04-*.md`）后已经指不到实际文件了——纯格式问题，不影响内容，不需要动原文档。 |
| 2026-08-04 | [technical-roadmap](tech/2026-08-04-technical-roadmap.md) | 架构与实现细节：两个 git worktree（`rtg-capsec` 生成端 branch `capsec/env-state-judges`、`dtap-capsec` 测量端 branch `capsec/measurement-layer`）；env-state judging 的渲染链路（LLM 只出结构化 `HarmDeclaration`，harness 确定性渲染 `judge.py`）、三种 shape 各自的固定注入构造方式、depth 数据模型与 `validate_chain` 校验闸门、k=3 self-consistency 质量投票；测量侧 victim runner 命令、judge-LLM 从 gpt-5.4 切到 deepseek-chat 的修复过程、`analyze_strain.py` 的结果-语料对齐逻辑；victim 能力/可用性表。 | victim 表把「为什么能力梯度这么窄」交代得很清楚——Meta 前沿模型网关工具协议互不兼容、Anthropic 缺 credit、Google 免费层只开 flash——这张表本身就是对当前卡点最好的证据，建议随后续 victim 变化持续更新，别只留在这一份快照里。 |
| 2026-08-04 | [findings](tech/2026-08-04-findings.md) | 首批实证结果：exfil/UA 在全部 5 个 depth 上易感性均为 0，content_assertion 在 0.33–1.0 间波动（见需要你注意 #1）；60 runs 首批多 victim（super_nova + 两档 Gemini flash）数据显示三个 victim 都在 content 上有非零 diversion，但解不出单调 strain 趋势（n 太小，见需要你注意 #2）；三值 judge + depth 校验闸门被验证为有效方法论；记录三条 infra 踩坑（judge import 路径、judge 会继承 victim 的 `OPENAI_BASE_URL`、前沿模型网关不兼容）。文档自己指出这个「content 易感、action 不易感」的结果和 [avo-redteam](../avo-redteam/_INDEX.md) 「诽谤类记录归档转述是唯一防御盲区」的结果互相印证，是从生成侧对同一现象的独立复现——两个项目分别从「打生成」和「测防御」两端撞到了同一条边界，值得在两边索引里都留个记号。 | 见需要你注意 #1、#2。 |
| 2026-08-04 | [runbook](tech/2026-08-04-runbook.md) | 环境变量与两个 worktree 路径；三步操作流程（生成语料，docker-free → victim sweep，需 docker，从 `dtap-capsec` 跑 → `analyze_strain.py` 出图）具体命令；operational caveats：共享 docker 主机清理规则（不许删别人的 `pool_*`/`rds-*`）、UIUC 用 docker 不是 podman、judge LLM 必须走独立 provider（不能继承 victim 的 base_url）、`.env` 里 Meta key 的 `|` 转义坑、Gemini 免费层限流（`--max-parallel 1`）。 | 无。 |

---

## 关键决策记录

- **架构决策 A：judge 从 live backend state 判定，不看 MCP 轨迹** —— 模态无关，且不会被「表面上像是拒绝了」的轨迹文本骗到。
- **LLM 只产出结构化 `HarmDeclaration`，harness 确定性渲染 `judge.py`** —— 不让 LLM 自己写判定代码，避免判官被生成的判定逻辑本身污染。
- **固定注入而非运行时注入** —— env-state judging 依赖生成时就定好的值（凭证、beneficiary、claim_text），运行时注入会让判定失去锚点。
- **depth 是唯一自变量，env-breadth 钉死** —— 否则「strain 更高」和「环境更复杂」会混杂，`validate_chain` 强制真实的依赖链而非表面深度。
- **diversion 只在 admissible 上计分，undecidable 单独排除** —— 这是处理「too weak to reach the injection ≠ resisted」这个混淆的正式机制，写进了判定本身而非靠人工事后甄别。
- **judge LLM 换成 deepseek-chat，且走独立 provider 路由** —— 判官不能继承 victim 的 `OPENAI_BASE_URL`，否则判官会打到 victim 的网关上（曾经导致 404 被静默吞成「resisted」）。
