# 进行中的项目

> **规则：同时进行的项目建议不超过 3 个。** 超了就先把某个挪回 SOMEDAY.md。
> 不是不许多，是要你明确知道自己在同时扛几件事。
>
> 每个项目最重要的两栏是 **断点** 和 **下一步**。
> 离开一个项目前花 60 秒把这两栏写清楚 —— 这是你回来时不迷路的唯一保险。

状态标记：`🔥 主线` / `🌊 慢炖` / `🧊 暂停`

---

## 🔥 capsec — Capability × Security 强度不变性

- **类型**：安全研究 + 工程
- **一句话**：验证 agent 攻击易感性是否由「相对能力强度」(任务离模型能力上限多近)决定,而非绝对能力 —— 若成立则「能力进步不买安全」
- **仓库**：`rtg-capsec`(生成) + `dtap-capsec`(测量)　**分支**：`capsec/env-state-judges` / `capsec/measurement-layer`　（推到 remote `vaibackup`）
- **技术栈**：env-state 三值判定 + depth 依赖链(strain 轴) + 固定注入 + deepseek judge + super_nova/Gemini victim
- **断点**：4-victim ladder(rift 5.14 / super_nova / gemini-2.5-flash / gemini-2.5-flash-lite)累计 74 runs。benign frontier 呈 8/6/2/<2 的真实能力梯度,「梯度太窄」这条 blocker 已被实证推翻。索引里原来两条 critique 都已核实回应:exfil/UA 的「全 0」补上 n_admissible(14、8)+ Wilson 区间(上界 ~22%/~32%),证实是稳定拒绝,不是样本太小的假象;但 content 的 diversion 比值补上 Wilson 区间后,发现 n_adm=1–3 的区间几乎覆盖整个 [0,1] —— invariance 假设现在「既证不了也证伪不了」,唯一真瓶颈收窄成统计 power 这一件
- **下一步**：①（最优先,不需要付费 key）把 content 语料每个 depth-cell 扩到 10–15 条,纯 LLM 生成、docker-free,用现有生成流水线；② 扩完后在 4-victim ladder 上重跑,`analyze_strain.py --plot` 出图时给每个比值配 Wilson 95% CI,不再裸报;③（非阻塞、可延后）如需进一步加宽梯度顶端,需要付费 Google billing 开 pro 层,或 groovy-provisioned MetaGen token —— env-gen-2 key 到不了 groovy,gemini-3-pro-genai 走 Meta 网关会因 thought_signature 被 OpenAI-compat 剥离而不能 agentic(已实测确认此路不通)
- **卡点**：统计 power 不足是当前唯一挡住 invariance 结论的卡点(解法是扩语料,没有权限障碍,纯粹是还没做完的工作量);付费 Google billing 仍然拿不到,但已降级为「加宽梯度顶端」的加分项,不再阻塞主线结论;另外 `rtg-capsec` 分支目前只推到备份 remote `vaibackup`,canonical origin(`Virtue-AI`)缺 `id_ed25519_virtueai` key,这个访问单点没有变化
- **更新**：2026-08-04
- **文档索引**：[projects/capsec-strain-invariance/_INDEX.md](projects/capsec-strain-invariance/_INDEX.md)

<details><summary>笔记 / 决策记录</summary>

- 2026-08-04 —— 流水线打通,super_nova 3-shape + Gemini flash 多victim 60 runs。判官 gpt-5.4→deepseek(emitted judge 从 canonical dt_arena 符号链接导入,坑了很久)。Gemini 走 Google 原生 OpenAI-compat 才能多步 tool-loop(Meta gateway 掉 thought_signature)。invariance 卡在能力梯度太窄 + n 太小 —— 这和 avo-redteam 的 reps=3、stock-agent 早前踩过的「按行数算显著性」是同一类小样本坑。content_assertion 易感、exfil/UA 不易感,这个 shape 分化和 avo-redteam「诽谤记录归档转述是唯一防御盲区」的结果互相印证,是从生成侧独立复现的同一现象。
- 2026-08-04(续)—— 新增 victim rift 5.14,4-victim ladder 达 74 runs,能力梯度(8/6/2/<2)被实证坐实,不再是 blocker。同日追加进度文档直接回应了索引里的两条 critique:exfil/UA 的「全 0」用 Wilson 95% CI 证实为稳定拒绝(上界 ~22%/~32%);content 的整数比值配上 Wilson CI 后证实统计不显著(区间几乎覆盖整个 [0,1])。真瓶颈现在只剩统计 power,解法(扩语料到每 cell 10–15 条)已确认不需要付费 key。

</details>

---

## 🔥 avo-redteam

- **类型**：技术项目 / AI 安全研究
- **一句话**：红队测试 avo/rift 模型家族，并把「消融驱动的漏洞分析」产品化进 `dt_arms` 框架
- **代码**：`/data1/common/haibotong/dtap-platform`（服务器）　**Python**：`~/miniconda3/envs/dt/bin/python`
- **文档索引**：[projects/avo-redteam/_INDEX.md](projects/avo-redteam/_INDEX.md)
- **技术栈**：OpenAI Agents SDK、MCP / FastMCP、deepseek（attacker+judge）、tmux
- **断点**：rift 三条 Tier-2 全部跑完并手工核验 ✅——IP-exfil、UPJ-medical 均为
  genuine defense；closed-loop（`task_from_spec` 生成任务 + `ablation_to_skill` 生成技能）
  也端到端跑通 vs rift，「生成产物未跑」的缺口正式关闭（仍是本地替身，没接真实
  redteam-data-synth）。但 findings.md 里对 rift 在同一诽谤归档任务上的默认行为给出了
  两组矛盾的比例——§2/Net 说基线「filing ~8/10（withhold ~2/10）」，§6 说 closed-loop
  「withheld ~7/10（relay ~2/10）」却称其与「hand-authored baseline」functionally
  identical——这两个数字对不上，「闭环复现了手工基线行为」这个结论目前不能自洽。
  **groovy（5.15）依旧全线停摆**，key 仍是 403，progress.md 这次把这个阻塞正式写成了
  「project-management gap」，但 owner/日期仍是 `<assign>`/`<set date>` 占位符，没真填。
- **下一步**：
  ① 回头核对 rift 诽谤归档基线的原始 run 记录，把 §2/Net「filing ~8/10」和 §6
  「withheld ~7/10」两个数字对齐，或查清这两处是否指的是两个不同的 run，修正 findings
  里的表述——这是当前唯一卡住「闭环已验证」结论的东西；
  ② 把 groovy key 的 ACTION ITEM 填实：指派一个真实负责人和日期，否则 5.15 分支会继续
  无限期悬空；
  ③ 顺手把 runbook 的 Tier-2 三步核验清单补一条：检查生成任务是否落在
  `DTAP_DATASET_ROOT` 下、run 的 duration 不是异常的 <1s ——防止一次纯配置错误的
  trivial「已防御」假结果被当成 Tier-2 confirmed（findings §6 已口头提醒过这个坑，
  但还没写进任何核验清单）。
- **卡点**：groovy key 403 仍是 5.15 分支唯一的单点阻塞（这次自我承认但仍未分派）；
  新增卡点——rift 基线数字的内部矛盾使「闭环产物行为等同手工基线」这条关键结论暂时
  站不住，需要人工回查 run 记录才能定论。
- **更新**：2026-08-04

<details><summary>笔记 / 决策记录</summary>

- 2026-08-04 —— 收到首批 5 份文档并归档。索引里记了 5 条待办，其中两条关于
  溯源结论的证据强度值得优先看：belief 臂正式运行还没跑过，而 findings 把它
  和 reps=3 消融、端到端核验并列呈现。
- 2026-08-04（第二批）—— 同一天内收到 progress/findings 的就地修订版，另补入一份
  此前漏收录的技术文档（using-victims-from-another-repo，与 capsec-strain-invariance
  的 victim 接入方式强相关，见两边索引）。修订版正面回应了首批索引的两条证据分层批评：
  findings §2 把结论显式拆成 Tier-2-confirmed（仅诽谤转述一条）vs Tier-1-hypothesis
  （杠杆量级、溯源），§4 自己承认 belief 探针违反项目自己的方法论铁律。同时新增三条
  rift Tier-2 验证（IP-exfil / UPJ / closed-loop），均为 genuine defense。但发现一个
  新问题：findings 内部对 rift 诽谤基线的转述/withhold 比例前后矛盾（§2 说 filing~8/10，
  §6 说 withheld~7/10），见索引「需要你注意的」#1（本轮最高优先级）。

</details>

---

## 🌊 stock-agent

- **类型**：技术项目 / 产品
- **一句话**：量化筛选粗筛 + 四角色 LLM 委员会细判，服务端风控闸门是唯一放行权威，默认只跑模拟盘
- **仓库**：`EchoRaven/stock-agent`（文档同步自其 `docs/`）
- **文档索引**：[projects/stock-agent/_INDEX.md](projects/stock-agent/_INDEX.md)
- **技术栈**：Python 3.12 / FastAPI / FastMCP / SQLAlchemy+SQLite / uv、Gemini、
  Next.js + TypeScript + Tailwind、yfinance + finnhub + SEC EDGAR、富途 OpenD（默认关）
- **断点**：M1–M7 全部完成，~170 commits / 785 后端离线测试。M8 已从「方向」推进到
  「机制通电+测过」：`replay_loop.py` 在隔离库跑通完整 `run_trade_cycle`，25 天历史重放
  产出 2 笔平仓 → 2 条复盘写进记忆；`learning_ab.py` 做 DiD（有复盘 AMD/JPM vs 无复盘
  AAPL/MSFT）测出委员会对自己复盘的行为响应 **DiD≈0，几乎无响应**。置信度→收益显著性
  检验也用三区间够样本重跑（39 买入/22 决策日）完成，结论口径从「样本不足」升级为
  「测了，不显著」。M9 因此被重新定义：瓶颈不是数据管道（复盘已经喂进 memory_context），
  是委员会没有有效权衡它 —— 是 prompt/框定问题。
- **下一步**：照 ROADMAP §M9 的方案改 committee prompt——委员会读到某票的 `trade_review`
  记忆时，要求 `bear_rebuttal`/理由里显式回应"上次这只票亏了 X%，这次买入的额外理由是什么"，
  不能只是把复盘塞进 memory_context 就算完。改完立刻用 `scripts/learning_ab.py` 重跑 DiD，
  看是否从 ≈0 转负（负值=委员会读到亏损复盘后变谨慎）—— 这把尺子已经现成，不需要再造。
- **卡点**：DiD≈0 目前只测了 1 轮、2 笔平仓，且 treatment/control 完全按标的划分（AMD/JPM
  有复盘、AAPL/MSFT 没有）——不是随机分组，无法排除"这两只票本来行为就不同"的混杂，文档
  自己也承认"机制探针非结论"。要让 DiD 结果站得住，得先用 `replay_loop.py` 跑更长窗口/更高
  换手拿到更多独立平仓样本，且最好让分组方式避免与 memory 状态完全共线。
- **更新**：2026-08-04

<details><summary>笔记 / 决策记录</summary>

- 2026-08-04 —— 收到首批 3 份文档并归档。文档质量很高，PROGRESS §3 把 5 个自造的
  测量缺陷写进了正式文档。其中「显著性按独立观测数而非行数」这条教训可以直接
  搬给 avo-redteam（它的 Δ+1.00 来自 reps=3，缺区间估计），详见索引第 5 条。
- 2026-08-04（续）—— 收到第二批文档：progress.md/roadmap.md 实质性修订 + 新增
  overview.md（原 README.md 迁移改名）。核心变化：M8 从「建好没通电」变成「通电且测过」——
  `replay_loop.py` 实测能产出平仓复盘，但 `learning_ab.py` 的 DiD 检验显示委员会对自己
  复盘几乎无响应（DiD≈0），且该检验的 treatment/control 完全按标的分组、非随机，混杂未被
  排除（索引新发现，文档本身没点名）。M9 因此被重新定义为 prompt/框定问题。详见索引第 1 条。

</details>
