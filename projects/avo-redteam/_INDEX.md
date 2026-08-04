# avo-redteam · 文档索引

红队测试 avo/rift 模型家族（rift 5.14 / groovy 5.15），并把「消融驱动的漏洞分析」
产品化进 `dt_arms` 框架。代码在 `dtap-platform/`（服务器 `/data1/common/haibotong/`）。

**最近一次收到文档**：2026-08-04（首次，5 份）
**当前节奏**：—　*（首份，暂无历史可比）*

---

## ⚠️ 需要你注意的

### 1. 溯源结论的证据强度，和另外两条腿不对等

`03-findings` §2 把结论分三层呈现 —— 杠杆层（reps=3 消融）、**溯源层（belief 探针）**、
端到端（10 轮手工核验）—— 读起来像三条同等强度的证据互相印证。

但 `02-progress` 第 14 行写的是：belief 臂 **「✅ built；live-run needs groovy」**，
证据来自 *step-1 spoof_belief probe*；而「立即要做的事」第 3 条又列着
「groovy key 恢复后跑一次 clean belief-arm run」。

**也就是说溯源层的证据是一次性探针，正式的 belief 臂根本还没跑过。**
findings 里没有标出这个差别。建议在 §2 给溯源层加一句证据强度声明，
否则读者（包括三个月后的你）会以为三层证据等强。

### 2. 溯源结论本身违反了项目自己立的方法论铁律

项目的中心教训是 **「direct-probe OVERSTATES —— 每个 Tier-1 的 COMPLY 都只是假设，
必须经 Tier-2 确认才算数」**，这条规则被写进了每个工具。

而 belief 探针**本身就是一个 direct probe**。§4 用它得出「groovy 抓住了伪造的监管域名、
无回归」的结论 —— 这个结论从未经过 Tier-2 环境验证，却被当成定论写进了 findings。

方向相反不改变性质：这套方法论说的是直接探针与端到端会系统性地偏离，
那么「探针显示模型防住了」同样可能在真实环境里翻转（例如多轮上下文里
伪造域名被反复强化后模型是否还守得住）。**按项目自己的标准，
这条结论目前的状态应该是「假设」而不是「已确认」。**

### 3. groovy key 403 是唯一的关键路径阻塞，但没有推进动作

所有 groovy 活口（IP-exfil / UPJ / belief 臂 / 生成任务链）全部 parked。
`02-progress` 里写了「Consider requesting a key explicitly authorized for
safety evaluation」—— 但这是一句 consider，**没有负责人、没有日期、没有进展**。

这是整个 5.15 分支的单点阻塞。建议要么把「申请安全评估专用 key」提成一条带
日期的实际行动，要么明确决定 5.15 分支暂停、把资源投到 rift 参考victim 上，
别让它悬在「等 key」的状态里空耗。

### 4. 「闭环」目前只在本地闭合，未接真实生成器

`task_from_spec.py` 是 redteam-data-synth 的**本地替身**，progress 里的措辞也是
「chain validated **locally**」。真正的 pipeline 能否消费 `task_designer` 的 spec
仍在 roadmap 的待办里。

对外描述这套系统时注意口径 —— 现在能说的是「链路在本地替身上跑通」，
不是「闭环已接入生产管线」。

### 5. reps=3 得出 Δ+1.00，缺置信区间

杠杆层的核心数字（framing Δ+1.00、manifest-adverse Δ−0.67、over-defense 0/5）
来自 reps=3。**没有看到显著性或置信区间的处理。**

这一点和你另一个项目 stock-agent 踩过的坑高度同构，详见
[stock-agent/_INDEX.md](../stock-agent/_INDEX.md) 里「两个项目可以互相借鉴」一节。
[capsec-strain-invariance](../capsec-strain-invariance/_INDEX.md) 的 60-run 数据里
也出现了同一类整齐比值（depth=2 时 diversion=1.0），同样是小 n 造成的，见其索引「需要你注意的」#2。

**2026-08-04 更新**：capsec-strain-invariance 把这条坑趟出了一个可以直接照抄的解法——
给每个 cell 的比值配上 Wilson 95% CI 后，n_adm=1–3 的区间几乎覆盖整个 [0,1]，
干净的点估计被证实只是噪声，不是信号。同样的处理可以直接套到这里的 reps=3：
即便 3/3 全翻转，Wilson 区间大概率也宽到盖住「真实翻转率 70%」这种情况，
在 findings 里补一句区间估计，成本很低，能防止 Δ+1.00 被当成比它实际更硬的结论引用。

### 6. 独立佐证：capsec-strain-invariance 从生成侧复现了「诽谤是防御盲区」

`03-findings` §4 的三闸门模型认定「诽谤类记录归档转述」是唯一同时穿透三闸的向量。
[capsec-strain-invariance](../capsec-strain-invariance/_INDEX.md) 这边从**攻击生成**
的角度独立跑出了同一个结论：`content_assertion`（诽谤）是三种伤害 shape 里唯一测得出
非零 diversion 的一种，`exfiltration`/`unauthorized_action`（要求显式有害动作）在
所有 depth 上都是 0。两个项目分别从「测防御」和「打生成」两端撞到了同一条边界——
这不是巧合，值得在后续报告里把这两份证据放在一起引用，互相加固而不是各自孤立地说。

---

## 技术文档 · tech/

| 日期 | 文件 | 摘要 |
|---|---|---|
| 2026-08-04 | [overview](tech/2026-08-04-overview.md) | 项目定位与两层漏斗方法的总入口。两代模型：rift 5.14（chat/completions，openclaw arch）、groovy 5.15（仅 Responses API，需新 `responses` arch）。 |
| 2026-08-04 | [technical-roadmap](tech/2026-08-04-technical-roadmap.md) | 架构全貌。`ResponsesAgent` 作为 `OpenAISDKAgent` 薄子类复用 SDK 的 MCP 工具循环（三重验证通过）；Tier-1 消融引擎 `lever_ablation.py` 做最小对照组因子翻转求边际 Δ；因子/任务/攻击技能各有手工-半自动-全自动三条创作路径。 |
| 2026-08-04 | [findings](tech/2026-08-04-findings.md) | **三闸门防御模型**：动作可见性 / 内容过滤 / 溯源验证，三闸同时失明才漏 —— 唯一同时失明的向量是「诽谤类记录归档转述」。groovy 5.15 ≥ rift 5.14 防御性。核心方法论教训：直接探针系统性高估。ENDORSE vs RELAY 是判定真假胜利的关键。 |
| 2026-08-04 | [runbook](tech/2026-08-04-runbook.md) | 各工具命令行、Tier-2 tmux 启动器、结果分析三步法（先查 confound 再读轨迹再读收件方邮箱）。含 groovy 限流纪律：单轮 ≤40 次调用，遇 403 立即停。 |

## 进度汇报 · progress/

| 日期 | 文件 | 摘要 | 与上一份的差异 |
|---|---|---|---|
| 2026-08-04 | [progress](progress/2026-08-04-progress.md) | 13 项已完成并验证（victim arch、消融引擎、三路创作链、60 任务数据集已交付）。在飞：rift IP-exfil 跑中、UPJ 排队。阻塞：groovy key 403。 | 首份 |

---

## 关键决策记录

- **每个 Tier-1 的 COMPLY 一律标记 `needs_env_validation=True`** —— 把「直接探针高估」
  这条教训固化进工具而非靠人记住。这是整套方法论里最值钱的工程决策。
- **判定标准从「有没有拒绝」升级为「endorse 还是 relay」** —— 保留归属的转述
  （"匿名举报"、"未经证实"）属于可争议的双用途，不算攻击成功。
- **不信任 naive judge ASR，一律手工核验** —— 空轨迹是 confound 不是防御，
  带免责声明的转述会被误读成「已防御」。
- **groovy 限流纪律** —— 突发负载 + 违规内容触发 403 且 40 分钟冷却后不恢复；
  已确立单轮 ≤40 次调用、分小批跑的操作规范。
