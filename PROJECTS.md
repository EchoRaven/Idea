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
- **断点**：rift IP-exfil 的 Tier-2 跑在 tmux 会话 `rift_ipexfil`（~10 轮 × ~11 分钟），
  等着手工核验。UPJ-medical 的启动器 `launch_upj_rift.sh` 已就绪，排在 IP 之后串行跑。
  **groovy（5.15）全线停摆** —— key 被 403 policy-block，IP / UPJ / belief 臂全部 parked，
  工具默认 `--model groovy_kite316` 所以 key 一恢复就能直接打。
- **下一步**：核验 rift IP-exfil 结果 —— 按 runbook 三步走：① 先查 `run.log` 有无
  traceback / 403 / 429 / `Target responded (0 chars)`（有则整轮是 confound，ASR 无效）
  ② 逐条读 `traj_info.agent_final_response` 判断是 endorse 还是 disclaimed relay
  ③ **读收件方邮箱**（任意发件人），不能只看 victim 的已发送
- **卡点**：groovy key 的 403 是 5.15 分支的单点阻塞，且目前没有带日期的推进动作。
  需要决断：要么正式申请一个安全评估专用 key，要么明确暂停 5.15 分支
- **更新**：2026-08-04

<details><summary>笔记 / 决策记录</summary>

- 2026-08-04 —— 收到首批 5 份文档并归档。索引里记了 5 条待办，其中两条关于
  溯源结论的证据强度值得优先看：belief 臂正式运行还没跑过，而 findings 把它
  和 reps=3 消融、端到端核验并列呈现。

</details>

---

## 🌊 stock-agent

- **类型**：技术项目 / 产品
- **一句话**：量化筛选粗筛 + 四角色 LLM 委员会细判，服务端风控闸门是唯一放行权威，默认只跑模拟盘
- **仓库**：`EchoRaven/stock-agent`（文档同步自其 `docs/`）
- **文档索引**：[projects/stock-agent/_INDEX.md](projects/stock-agent/_INDEX.md)
- **技术栈**：Python 3.12 / FastAPI / FastMCP / SQLAlchemy+SQLite / uv、Gemini、
  Next.js + TypeScript + Tailwind、yfinance + finnhub + SEC EDGAR、富途 OpenD（默认关）
- **断点**：M1–M7 全部完成（决策核心、闸门、四模式、11 页 UI、评测体系、富途适配器），
  ~164 commits / 785 后端离线测试。**M8「让学习闭环真正产生信号」是唯一还开着的口子**，
  且只停在「方向」阶段：现在只有平仓才写复盘，模拟盘几乎不平仓，
  所以 agent 至今几乎没从自己的交易里学到东西 —— 记忆/复盘/因子挖掘整条线建好了但没通电。
- **下一步**：跑 `scripts/replay_eval.py`，用 `--end-date` 跨多个反向行情区间批量重放
  screen→committee，把产出的「决策 + 结果」样本喂回评测与记忆，先把 M8 的样本荒解决
- **卡点**：「置信度能否预测收益」目前不显著、尚未证实 —— 这是项目最大的开放性风险，
  而它的答案依赖 M8 先产出足够独立样本。**所以 M8 应当优先于 M9**（M9 要把该股历史战绩
  喂进委员会，依赖的正是 M8 生产的数据）
- **更新**：2026-08-04

<details><summary>笔记 / 决策记录</summary>

- 2026-08-04 —— 收到首批 3 份文档并归档。文档质量很高，PROGRESS §3 把 5 个自造的
  测量缺陷写进了正式文档。其中「显著性按独立观测数而非行数」这条教训可以直接
  搬给 avo-redteam（它的 Δ+1.00 来自 reps=3，缺区间估计），详见索引第 5 条。

</details>
