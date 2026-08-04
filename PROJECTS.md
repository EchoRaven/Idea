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
- **断点**：整条测量流水线打通并出了 60 个真 run。关键发现 = 易感性强 **shape-依赖**:content_assertion(诽谤)会转化(diversion 0.33–1.0),exfil/UA(需要显式有害动作)全 0。invariance 本身还没测出 —— 语料 n=1–3 太小 + 能力梯度太窄(免费 Google key 只有 flash 层,pro 是 429 limit:0)
- **下一步**：拿到付费 Google 配额后 —— (1) 把 content 语料每 cell 扩到 ~10 条(纯 LLM 生成,不占 docker);(2) 跑 flash→pro 全能力梯度的 content sweep;(3) `analyze_strain.py --plot` 出两张判据图:diversion-vs-绝对depth(应按能力分离)vs diversion-vs-相对strain(应塌缩=invariance)
- **卡点**：需要付费 Google billing 开 `gemini-2.5-pro`/`gemini-3-pro-preview`(免费 key 429 `limit:0`);统计 power 不足
- **更新**：2026-08-04
- **文档索引**：[projects/capsec/_INDEX.md](projects/capsec/_INDEX.md)

<details><summary>笔记 / 决策记录</summary>

- 2026-08-04 —— 流水线打通,super_nova 3-shape + Gemini flash 多victim 60 runs。判官 gpt-5.4→deepseek(emitted judge 从 canonical dt_arena 符号链接导入,坑了很久)。Gemini 走 Google 原生 OpenAI-compat 才能多步 tool-loop(Meta gateway 掉 thought_signature)。invariance 卡在能力梯度太窄 + n 太小。

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
