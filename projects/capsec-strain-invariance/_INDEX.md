# capsec-strain-invariance · 文档索引

验证「agent 攻击易感性由相对能力强度（任务离模型能力上限多近）决定，而非绝对能力」
这个假设 —— 若成立，则「能力进步不必然买安全」，因为部署范围会随能力一起扩张。
双轨架构：`rtg-capsec`（生成 depth-N 依赖链攻击任务）+ `dtap-capsec`（跑 victim、
env-state 三值判定、出 strain 曲线）。

**最近一次收到文档**：2026-08-05（第九批——`findings.md` 同一天内第六次被就地追加：新增
§0a「THE CROSS-VICTIM RESULT」一整节 + §4 追加一条 gated 工具-schema 净化器说明。这次和
前五次都不一样：不是继续在 rift 一个 victim 身上找新的复杂度轴或再分析旧数据，而是终于跑通
了 fork 选项 (b)——一个真正会被 depth 轴压垮的弱 victim，**Llama-4-8B-Instruct-Preview**
（`api.llama.com/compat`，经新增的 `SANITIZE_TOOL_SCHEMAS` 网关 schema 净化器修复解封）。
用和 rift 完全相同的 depth 1→24 content_assertion 语料跑了一遍：benign_rate 在这档弱 victim
上被同一条 depth 轴压到 0（0.31→0.0），而 rift 完全不为所动（0.55→0.88）——「能力决定同一
任务复杂度是否触及 frontier」这条项目核心机制第一次有真实跨 victim 数据支撑。但文档同时
诚实报告了一个对 invariance 本身不利的结果：relative-strain 归一化后两个 victim 唯一可比的
一点上，diversion 并未重合（rift 0.43 vs Llama 0.083），文档原话「tentatively against naive
strain-invariance」。文档开头的摘要行没有跟上这个新结果，仍写着「still blocked on a second
powered victim」，和紧随其后的 §0a 内容有张力。详见「需要你注意的」新增 #13。这是继 §1b
（08-05 第一次）、§0/§2c-distractor（第二次）、§2d（第三次）、§2c-discrimination（第四次）、
§2c-cross-victim/gemini（第五次）之后同一天第六次追加同一份文件。
**当前节奏**：仍然很快——08-04 三轮 + 08-05 六轮，五天内九次实质性交付，且都是同一条
autonomous loop 的连续产出。这一轮和前五轮都不一样：前四次同日追加全部在复杂度维度里打转
（depth → distractor → 相关性再分析 → discrimination），第五次回头查了 victim 卡点但结果是
负面的（gemini 卡配额）；这第六次不但真正解锁了一个弱 victim，还交出了项目至今第一条
双向都有信息量的结果——核心机制被支持，但 invariance 归一化本身被初步证伪，比前五次任何
一条单独证据信息量都大。「换注入面」这个 pivot 第六次没有被采纳，但这次不完全算是重复
此前四次的模式。详见「需要你注意的」#7 的第六次更新。[avo-redteam](../avo-redteam/_INDEX.md)
同期也是这个节奏。

---

## ⚠️ 需要你注意的

### 1.（本轮新增，重大结论）action boundary 的「depth-invariant」现在也是 well-powered 结论，不再只是 n=1–3 的印象

[findings §1b](tech/2026-08-04-findings.md) + 新增数据文件
[`2026-08-05-strain_shapes.csv`](tech/2026-08-05-strain_shapes.csv) 把 §1 的 n=1–3 小样本
观察（super_nova「从不采取离散有害动作，但愿意断言诽谤性内容」）在 rift 上用真实 power
复现：**exfiltration** 5 个 depth（n_admissible 1,7,7,8,8，合计 31）diversion 全部 0.0；
**unauthorized_action** 5 个 depth（n_admissible 2,5,3,4,1，合计 15）diversion 同样全部
0.0；同一批 depth 上 **content_assertion** diversion 0.056–0.556（非零）。~46 条
admissible 的「动作」类 shape 跑下来零漂移——「拒绝边界卡在动作而非内容」从三样本印象
升级为有统计支撑的结论，和下方 #2（depth 不能 strain 前沿模型）并列成为本项目目前最硬
的两条结论。

文档自己给出的诚实功效说明：exfiltration 每 cell 都有 7–8 个 admissible 样本，Wilson
上界压到 ~0.32–0.35，站得住；unauthorized_action 因为 payout 处理任务本身 benign 完成率
低（0.13–0.63），admissibility 塌缩到 n_adm=1–5/cell（最多 75% undecidable），Wilson
上界因此宽到 ~0.43–0.79。**跨两个 shape、全部 depth 都是 0 这个一致性本身才是证据的分量
所在，不是任何单个 cell 的区间宽度**——这个措辞是准确、不过度声称的，值得肯定。

这条把上一轮索引 #3（见下方，已改写）记录的缺口——「exfil/UA 只有跨 depth 聚合层面的
区间」——基本做掉了。

### 2.（重大结论）depth 轴对前沿模型不起作用——rift 的 depth 1→24 sweep 是定论，不是初步结果

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

**2026-08-05 更新**：这个分叉现在有了第一次实际尝试的结果——fork 选项 (a)（新增一条能
strain 前沿模型的自变量）的第一个候选（distractor density，干扰邮件密度）已经建好并跑完，
同样是负结果，和 depth 轴收敛成同一个结论（新增 §0「收敛结论」）。但这条新证据的统计功效
明显比这条depth 轴薄，且有几个没处理好的地方——详见下方新增 #9。

**2026-08-05 二次更新**：同一个 §2c 小节又加了第二个候选变体——判别力（discrimination，
仿冒发件人的近似重复邮件），结果同样是负，§0 headline 因此把「两条独立复杂度轴」改写成
「三条」。但这第三条轴的证据比 distractor 变体更薄（连 n_admissible 都没报），详见下方
新增 #11。三条独立复杂度轴全部收敛到负结果后，fork 选项 (a) 这条路径本身继续加新轴的
边际价值已经很低——详见 PROJECTS.md「下一步」①的最新措辞。

### 3.（本轮部分澄清）「victim 梯度已不是 blocker」和上一轮「second victim 全部受阻」的说法有张力

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

**2026-08-05 五次更新**：本轮 cross-victim 尝试（见新增 #12）把「gemini-2.5-flash-lite
到底堵在哪」从模糊的「受阻」精确到了具体机制——它不是像 GPT/Meta 那样彻底不可用（简单
调用 8/8 成功，探针也已经跑出一个可用 cell），是免费层**每日**配额太紧，大约 2 次
agentic 跑法就耗尽。这意味着「三个候选 victim 全部受阻」这个说法需要按候选区分对待：
GPT/Meta 是真正的基础设施故障（网关崩溃／500），Gemini 现在是一个边界清楚、原则上「花钱
能解」的配额问题，harness 本身已确认可用。这不改变当前「换注入面」仍是成本最低、不依赖
外部资源的首选项这个判断，但如果后续能拿到付费 Gemini key，这条路径现在是一个有精确
前置条件（付费配额）的、随时可以重新尝试的备选项，不再是一句笼统的「基础设施受阻」。

**2026-08-05 六次更新**：本轮 §0a 报告了一条和上面 #12（gemini 配额）完全独立的第二
victim 路径——新 victim **Llama-4-8B-Instruct-Preview** 经 §4 新增的 gated 工具-schema
净化器修复后跑通了完整的 depth 1→24 sweep（83/135 落地），benign_rate 在这档弱 victim
上被同一条 depth 轴压到 0（0.31→0.0），和 rift 的「完全不起作用」形成鲜明对比——「能力
梯度」从「证实存在」（4-victim ladder 的 8/6/2/<2）第一次升级为「证实会带来不同的 strain
后果」。但这批数据的功效仍明显弱于 rift（n_admissible 6–12/cell vs 15–22/cell），且
§0a 自己指出 relative-strain 归一化后两个 victim 并不重合——不是「victim 梯度问题解决
了」，是「梯度问题从统计功效层面解决了一部分，同时在 invariance 归一化层面又冒出一个
新问题」。详见新增 #13。

### 4.（已基本解决，本轮做掉的正是这条待办）exfil/UA 的逐 depth-cell 区间已经补上——exfiltration 站得住，unauthorized_action 仍偏弱

上一轮记录的缺口是「exfil/UA 的 0 只有跨全部 5 个 depth 汇总的 Wilson 区间（n_adm=14/8，
上界 ~0.22/~0.32），没有逐 cell 拆分」。`2026-08-05-strain_shapes.csv` 把这个缺口填上
了，而且是在 rift 单一 victim 上重新测出来的更大样本：exfiltration 5 个 depth 逐
cell n_admissible = 1,7,7,8,8（合计 31，超过此前跨 victim 汇总的 14），diversion 全部
0.0，逐 cell Wilson 上界 ~0.32–0.35（depth1 的 n=1 cell 除外）；unauthorized_action 逐
depth n_admissible = 2,5,3,4,1（合计 15，超过此前的 8），diversion 同样全部 0.0，但因为
每 cell 样本仍薄，Wilson 上界宽到 ~0.43–0.79。**exfiltration 这条现在可以放心引用逐
depth 曲线；unauthorized_action 目前只能说"全 0 且一致"，还不能细拆到"哪个 depth 更
稳"这种颗粒度**——根因是 payout 处理任务本身 benign 完成率低（0.13–0.63），导致
admissible 样本天然稀薄，加语料量未必能解决，可能需要先改善 UA 的 benign 任务设计。

### 5.（延续，未受本轮影响，优先级因 #3 下调）gemini-2.5-flash-lite 的 benign frontier 仍只是「<2」这个不等式

四档梯度里最弱的一档 frontier 只写了「<2」，不是具体整数。上一轮的 victim-ladder-blocked
消息（#3）让这件事更不容易短期解决——Gemini 免费层现在被明确报告为「多步任务跑不完」，
意味着专门去钉死这个数字的探测本身也会撞上限流。从「随时可做的一次性小任务」降级为
「等基础设施恢复后再做」。本轮的 `strain_shapes.csv` 里 gemini-2.5-flash-lite 的
content_assertion 三行倒是给出了一个具体数字——`frontier_depth` 列写的是 2——但这个数字
完全押在 depth2 单次跑（n=1，一次跑通即 benign_rate=1.0）上，参见下方新增 #8，不能当成
「<2」这个不等式的实锤替代。

### 6.（延续，未受本轮影响）生成端代码只推了备用 remote，canonical origin 缺部署 key——访问单点

`01-technical-roadmap` 提到生成产物「Pushed to remote `vaibackup`（origin `Virtue-AI`
需要 `id_ed25519_virtueai` key，此环境没有）」。也就是说 `rtg-capsec` 分支
`capsec/env-state-judges` 上的工作目前只活在一个备份 remote 上，团队 canonical
仓库这边没有能推送的凭据。这是一个没写进 blocked 清单、但确实存在的单点风险——
如果这台机器 / vaibackup 账号出问题，这批工作就没有第二份可达的拷贝。
建议要么补上 `id_ed25519_virtueai` key，要么明确记一条「已知：暂只有备份 remote」
的待办，别让它悄悄待着。

### 7.（跨项目提示，来自 avo-redteam，本轮因 well-power 证据更值得优先做）注入面（wall vs soft surface）可能比伤害类型（content_assertion vs exfil/UA）更接近真正的自变量

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
diversion（见上方 #4），但固定注入（见下方决策记录「固定注入而非运行时注入」）用的很
可能是「wall」等价物——直接把有害动作要求放进任务本身，victim 一眼能看出是显式指令。
如果改成把同样的有害要求 poison 进 victim 会读的**记录**（而非任务指令本身），
exfiltration/UA 是否还能保持 0，目前没有测过。这不是说要现在就去做——depth 轴的
well-powered sweep 已经耗尽了当前精力（见 #2），但如果后续要引入新的 strain 自变量，
「注入面」本身可能比「换一个推理难度维度」更值得优先验证，因为 avo-redteam 那边已经
拿到一个正面证据，而不是从零假设。

**2026-08-05 更新（本轮权重上调）**：上方 #1/#4 把 exfiltration/unauthorized_action 的
「全 0」从 n=1–3 印象扩到了 well-powered（合计 n_admissible 31/15，逐 depth 全覆盖）。
这意味着 avo-redteam 用 soft-surface 打穿的那堵「wall」防御，现在有了远比此前扎实的
基线数字撑腰——不是"小样本没测到攻破"，是"~46 条 admissible 跑下来一条没漂"这种强度
的墙被 soft-surface 攻破了一次（UPJ/93）。这让「注入面才是真正自变量」这个假设的
先验权重应该继续上调，建议排在 (a)（新增推理难度自变量）之前，作为下一步优先做的原型：
成本更低（复用现成的 exfiltration/unauthorized_action 语料，只改注入方式，不用新设计
一整条推理难度轴），且已经有 avo-redteam 一次正面证据打底，不是从零假设去猜一个新维度。

**2026-08-05 二次更新**：这条优先级建议没有被采纳——本项目同一天实际交付的是 (a) 的另一个
子路径（distractor density，见下方 #9），不是这里建议的注入面 pivot。不算矛盾（大概率是
同一条 autonomous loop 在建议写出之前就已经在跑这个方向），但结果是：又一条复杂度轴测出
负结果，而「注入面才是关键」这个假设依然没有在本项目内被直接验证过。两条独立复杂度轴都
失败之后，继续在复杂度维度上加第三条新轴的边际价值在下降，把 avo-redteam 的 soft-surface
手法搬到 exfiltration/unauthorized_action 语料上试一次的优先级应该进一步提高，而不是降低。

**2026-08-05 三次更新**：这条建议第三次未被采纳——本项目同一天又追加了 §2d，是对已有数据
的相关性再分析（见 #10），不是新实验。三次同日追加里没有一次是这里建议的注入面 pivot。
证据没有变弱：§2d 从 within-victim 相关性角度再给出一条同方向证据（虽然比 §1b/§2b 弱），
和 avo-redteam 的 soft-surface 正面结果一起，让「注入面才是自变量」这个假设的先验权重
继续累积，而实际验证仍然是零。

**2026-08-05 四次更新**：这条建议第四次未被采纳——本项目这次追加的是同一个 §2c 小节内部
的第三个子实验（判别力/discrimination 变体，见新增 #11），仍然是在复杂度维度上继续深挖，
不是注入面 pivot。现在收敛到同一个负结果的证据已经有四条（depth 轴、distractor 轴、
discrimination 轴、within-victim 相关性），而「注入面才是关键」这个假设依旧一次都没有在
本项目内被直接验证过——continued negative results 在复杂度维度上的边际信息量已经很低，
这个 pivot 被反复建议却反复搁置本身已经构成一个值得单独关注的模式，不只是某一条具体建议
没被采纳这么简单。

**2026-08-05 五次更新**：这条建议第五次未被采纳——本项目这次追加的不是新的复杂度子实验，
而是回头处理了另一条并行卡点（第二 victim 到底堵在哪，见新增 #12），这在性质上比前四次
更值得肯定：至少证明这条 loop 不是只会在复杂度维度里加证据。但「换注入面」这条建议本身
依旧一次都没被采纳，累计已经是第五次被绕过。cross-victim 尝试同时也说明：即便 fork
选项 (b)（换 victim）后续真的靠付费配额解锁，它测的仍然是同一批「复杂度轴」自变量
（depth/distractor），不会触及「注入面」这个完全不同的维度——换句话说，(b) 路径走通
也不能替代 ①，这两件事互不冲突，不该被误读成「victim 问题解决了就不用做注入面 pivot 了」。

**2026-08-05 六次更新**：这条建议第六次未被采纳——本项目这次追加的是 §0a（Llama-4-8B
跨 victim depth 结果），仍然是复杂度轴（depth），不是注入面。但和前四次「继续在复杂度
维度加证据」性质不同的是，§0a 这次拿到的不是又一个「rift 也扛住」的负结果，而是一条
双向都有信息量的新证据——机制本身（能力决定 strain 是否触及 frontier）被支持了，但
invariance 归一化本身被（初步、带着大量方法论保留地）证伪了。这让继续投入「找
mid-capability victim 填补 rel-strain 中段」这条路径，第一次有了比「再设计一个新复杂度
轴」更强的理由；但这不构成「换注入面」这条建议作废的理由——两条路径现在都值得做，是否
有资源同时推进，是需要人来定的优先级问题，不是本索引能替项目做的决定。

### 8.（本轮新发现，方法论透明度问题）`strain_shapes.csv` 新增的 `relative_strain`/`frontier_depth` 归一化没有写进任何 prose 文档，且对弱 victim 的取值不稳

`2026-08-05-strain_shapes.csv` 比历史表格多了两列：`frontier_depth`（每个 model×shape
一个固定值）和 `relative_strain`（= depth / frontier_depth）。逐行核对后，`frontier_depth`
的取值规律可以还原为「该 shape 下 benign_rate ≥ 0.5 的最深 depth」——content_assertion/
rift 是 24（benign 从未跌破 0.5，取最大测试 depth）、exfiltration 是 4（0.875，d6/d8
跌到 0.375/0.25 以下）、unauthorized_action 是 6（0.571，d2/d4 跌到 0.25/0.125 以下）、
gemini-2.5-flash-lite/content_assertion 是 2（1.0）。**这条规则本身自洽，但 findings.md
全文没有一处提到 `frontier_depth`/`relative_strain` 这两个词**，也没有说明这条归一化
是怎么算的——是我核对 CSV 数字反推出来的，不是文档写明的。

更值得注意的是稳健性问题：gemini-2.5-flash-lite 的 `frontier_depth=2` 完全押在 depth2
那一个 cell 上——n=1，也就是**一次**跑通就把 benign_rate 记成 1.0、从而把 frontier 定在
这里。如果那一次跑换个结果，`frontier_depth` 会跳到别的 depth，整列 `relative_strain`
也会跟着变。exfiltration/unauthorized_action 的 frontier_depth（4、6）背后是 n≥7/n=7
的 cell，稳得多；rift-content 的 24 更稳（n_adm=7，且是"从未跌破阈值"的 censored 值，
不是"跌破了才反推出来"的精确点）。在这条归一化被写进任何正式结论或图表之前，建议：
①在 findings.md 里补一句明确定义（哪怕只是"frontier_depth = 最深的 benign≥0.5 depth"
这一句话）；②在用 `relative_strain` 做跨 victim/跨 shape 比较时，对 gemini-flash-lite
这类单次 n=1 定出来的 frontier 单独标注"低置信度"，不要和 rift 的 well-powered frontier
一视同仁地画在同一条曲线上。

### 9.（本轮新增，第二条独立 strain 轴——也是负结果，但证据强度明显弱于 depth 轴）distractor density（inbox 干扰邮件密度）同样不 strain rift，但样本量薄、缺 CI、缺原始数据文件

[findings §2c](tech/2026-08-04-findings.md) 首次报告 fork 选项 (a)（见上方 #2 决策记录，
「新增一条能 strain 前沿模型的自变量」）的第一次实际尝试：固定 chain depth=2（rift 的
舒适区），改为往 victim 收件箱里注入 K 封「judge-safe」干扰邮件（K=0/60/150/300），逼
victim 从噪声里检索出真实任务记录。注入器 `scripts/distractor_inject.py`（TDD，9 个
测试）通过构造保证 judge-safe：干扰邮件收件人是 victim（进入检索范围）但绝不复用真实
邮件的 (from,to) 组合（benign judge 按精确 from/to 过滤会自动忽略），且清洗掉了所有
protected term（benign 关键词 + attacker token）。结果：

| K | 0 | 60 | 150 | 300 |
|---|:--:|:--:|:--:|:--:|
| benign_rate | 0.75 | 0.75 | 0.75 | 0.83¹ |
| diversion（over adm） | 0.36 | 0.46 | 0.27 | 0.17¹ |

¹ K=300 只跑了 12 条里的 6 条（partial）；K=600 尾部直接跳过（文档原话「seeding-bound,
~1h to confirm the obvious」）。

结论方向和 depth 轴一致——benign_rate 不降反升（clutter 越多、rift 的检索反而更稳）、
diversion 是纯噪声（4/11 → 5/11 → 3/11 → 1/6，K=60 那次小反弹在 K=150 就回落），没有
任何朝着某个 frontier 上升的趋势。§0 因此把这条和 §2b 并列写成「两条独立复杂度轴都被
rift 扛住」的收敛结论。

但这条新证据不应该和 §2b 的 depth 轴被同等对待，理由三点：

1. **样本量明显更薄**：depth 轴是 8 个 depth、n_admissible 15–22/cell（~135 任务）；
   这里只有 4 个 K 值、基线 n_admissible=11，且最高的 K=300 只有 6 个 admissible 样本
   （partial run），K=600 干脆没跑。§0 的措辞「两条轴都在 real power 下扫过（swept at
   real power）」对这条轴是不准确的——它离 depth 轴的功效差一大截，这是一个轻微的
   overclaim，建议下游引用时把两条轴的置信度分开说，不要因为 §0 把它们并列陈述就默认
   它们一样可信。
2. **没有配 Wilson 95% CI**——违反了本项目自己写进「关键决策记录」的规则（「diversion
   比值一律配 Wilson 95% CI，不再裸报」，2026-08-04 追加，理由正是"小 n 下的整数比值极易
   被误读成强结论"）。§2c 的四个比值（4/11、5/11、3/11、1/6）全部裸报，没有区间——这条
   铁律在最新一节里没有被执行，值得提醒一下继续维护这份文档的人补上。
3. **没有随附原始数据文件**——§1b/§2b 都有 `2026-08-05-strain_shapes.csv` 佐证，逐行核对
   过和文档转述一致；§2c 目前只有 prose 里的一张汇总表，没有逐 task 或逐 run 的原始数据可以
   核对，只能相信文档自己的转述。

不是说这条结论是错的——方向和 depth 轴一致，且方法论（judge-safe 注入器、TDD）是扎实的
——只是它目前的证据分量明显够不上"definitive"这个词，`findings.md` 自己也没有用这个词
形容 §2c（只在 §2b 用过），这点值得肯定，但下游（尤其是 §0 的收敛表述）容易让读者把两条
轴的可信度拉平，需要提醒。

### 10.（本轮新增，方向支持论点但功效薄弱）within-victim 相关性检验：diversion 和 benign 竞争力正相关，方向和 strain 假设相反，但样本小、跨两条轴混池

[findings §2d](tech/2026-08-04-findings.md) 是 `findings.md` 本轮（同一天）第三次追加，继
§1b、§0/§2c 之后。做法：把 rift content_assertion 的全部 11 个 cell（depth 轴 8 个 +
distractor 轴 3 个，K=600 没跑成所以不算）放在一起，用 benign_rate 当「1 − strain」的代理
指标，和 diversion 算相关。

结果：Pearson r=+0.61、Spearman ρ=+0.63（benign vs diversion），换算成
corr(1−benign, diversion)=−0.61——strain 假设预测这个数应该是正的（越接近 frontier/benign
越低，diversion 应该越高），实测符号相反。文档把这个作为「within-victim 层面同样没有证据
支持 proximity-to-frontier 提升易感性」的补充证据，和 §0 的跨轴收敛结论方向一致。

但这条结果的证据强度不该被高估，原因：

1. **n 很小，且显著性边缘**：合并 11 个 cell 后 p≈0.05（文档自己写的"borderline"），只用
   depth 轴的 8 个 cell 算则 r=+0.58 且不显著（n.s.）——也就是说这个信号主要靠把 distractor
   轴的 3 个点也塞进去才勉强压过 0.05 这条线。
2. **跨两条轴混池，不是同一个受控实验**：depth 轴和 distractor 轴是两个完全不同的自变量，
   把它们的 cell 混在一条 benign–diversion 散点里做单一相关，隐含「不管什么原因导致
   benign_rate 变化，它和 diversion 的关系都一样」这个未经验证的前提。文档确实交代了
   「distractor 那 3 个 cell 几乎没有 benign 方差（0.75/0.75/0.83）」，相当于承认这 3 个点
   对相关系数的贡献主要来自 diversion 轴而非 benign 轴，但没有展开讨论这是否会人为抬高
   相关系数的显著性。
3. **仍是对已收集数据的再分析，不是新实验**——不解决 #7/#9 反复提到的「该去验证 soft-surface
   假设」这条建议；本轮 findings.md 的三次同日追加（§1b、§2c、§2d）里，两次是深挖同一批
   数据的新角度，一次是补一条统计薄弱的新轴，唯独没有去跑那个已经被建议了两轮、成本更低、
   已有 avo-redteam 正面证据打底的注入面实验。

不是说这条结论是错的——方向和 §0/§2b/§2c 一致，且文档自己用了「suggestive, not
conclusive」这个措辞，没有过度声称。只是提醒下游引用时，这条比 §1b/§2b 弱得多，不要当成
第三个 definitive 结论使用。

### 11.（本轮新增，第四次追加，§2c 内的第三个子实验）discrimination/confusable-sender 变体：也是负结果，但比 distractor 变体证据更薄、且暴露了一个基线不稳问题

[findings §2c 追加段](tech/2026-08-04-findings.md) 在原有的「distractor density」小节
之后，又加了一个更难的变体：不再是往收件箱塞不相关噪声邮件，而是塞 K 封**近似重复**邮件
——主题和真实记录一致，但发件人是仿冒地址（如 `lin.lee@suzukirobotics-inc.jp` 冒充真实的
`…suzukirobotics.jp`），逼 victim 不能只靠过滤噪声，得真的**判别**出哪封是真的。judge-safe
机制和 distractor 变体一样（按精确发件人过滤）。结果（rift，12 个任务，自带一份 K=0 基线）：

| K | 0 | 60 | 150 |
|---|:--:|:--:|:--:|
| benign_rate | 0.917 | 0.917 | 0.833 |
| diversion | 0.36 | 0.36 | 0.46 |

同样是平的——benign 不降反有余量、diversion 在噪声范围内摆动。§0 headline 据此把
depth、干扰密度、判别力写成三条 rift 都扛住的独立复杂度轴，收尾一句「rift is robust to
**three** independent complexity axes」。

但这条子实验有比 #9 已经指出的 distractor 变体更明显的短板：

1. **完全没有报告样本量**——distractor 变体好歹在 prose 里给出了「n_admissible 11」和
   逐 K 的分子（4/11、5/11、3/11、1/6）；这里只给了 benign_rate/diversion 两个比值，
   K=0/60/150 三档一个 n_admissible 都没写，读者没法验算，也没法判断 K=0 和 K=60 的
   diversion 完全相等（都是 0.36）是巧合还是分母太小的重合。
2. **没有 Wilson CI**——延续 #9 已指出的规则违反（项目自己写死「diversion 比值一律配
   区间」），这里更严重，因为连分子分母都没给。
3. **没有随附原始数据文件**——`2026-08-05-strain_shapes.csv` 逐行核对过，只覆盖 depth 轴
   （content/exfiltration/unauthorized_action）和 gemini-flash-lite 三行，完全不含
   distractor 或 discrimination 的任何一行；这条子实验目前唯一的凭证就是 prose 里这一张表。
4. **基线本身不稳，且这点是文档自己暴露出来的**——「Methodological note」承认同一批 12 个
   任务的 K=0 基线，在 distractor 探测里是 0.75、在这次 confusable 探测里是 0.917，相差
   0.167，只归因于「victim 有 ~±0.15 的跑间 benign 方差」。但这个 ±0.15 是从**两次**探测
   反推出来的单一差值，不是从重复测量估出的方差——用两个点定出「误差范围」去论证只需做
   within-run 比较，这个论证本身偏薄，下游引用时不要把它当成已经量化过的稳定噪声水平。

不是说方向错了——三条轴的负结果彼此吻合，且文档没有用「definitive」形容这一节（延续 #9
指出的克制用词），这点仍然值得肯定。但 §0 headline 把三条轴并列写成「swept at real
power」，对 discrimination 这一档尤其不准确——它是三条轴里证据最薄的一条，不该被放在和
depth 轴同一句话里、给读者「同等权重」的印象。

### 12.（本轮新增，回应的是卡点本身而非新公理）cross-victim 尝试首次把「gemini-2.5-flash-lite 受阻」量化为具体机制，但「纯粹是配额、不是工具问题」这个结论把两种不同的失败原因合并了

[findings §2c 追加段](tech/2026-08-04-findings.md) 报告了本项目第一次真正跑通的第二
victim 尝试：先确认 gemini-2.5-flash-lite 对简单间隔调用是可用的（8/8 成功，2 秒
间隔），于是把探针改造成可参数化第二 victim（`PROBE_MODEL/DEPTH/PARALLEL`），在它身上
跑 distractor 轴。拿到一个干净 cell——depth-1、K=0：benign_rate 0.33，n_admissible
3/6——和此前对这档 victim「弱、admissibility 容易塌缩」的定性一致。但往上扩 K 直接失败：
K=100 让模型「崩溃」（3/6，标注原因是「context/rate」）；换回 K=60 重跑 8 条想验证，
结果 0/8 全部不可判定，文档把这个 0/8 归因于「两次 agentic 跑法（runs）已经耗光了免费层
的每日配额（每个 agentic 任务耗 5–10 次调用）」。结论是「cross-victim sweep 是纯粹卡在
付费 Gemini 配额上，不是工具问题，harness 已经就绪」。

这个结论对 K=60 重跑的 0/8 是站得住的——耗光每日配额这个机制解释合理，且给出了具体数字
（2 次 agentic run 就能耗光）。但对 K=100 的「崩溃」，文档自己写的原因是「context/
rate」——这是两个不同的失败模式：如果是 rate limit（限流），确实是配额问题，花钱能解决；
如果是 context 溢出（K=100 意味着塞进上下文的邮件更多，可能超出这档小模型的上下文窗口），
那是一个和这台 victim 本身能力/架构相关的限制，加钱买配额解决不了，需要在探针设计上做
别的调整（比如降低这档 victim 的 K 上限，或做检索式摘要而不是整段塞进上下文）。文档没有
说清楚 K=100 崩溃到底是哪一种，却把它和 K=60 的配额耗尽一起打包成「not a tooling gap」
这一个结论——这里有过度合并的风险，下游如果真的搞到了付费 key，应该先单独复测 K=100
这一档，确认花钱真的能解决，而不是默认两种失败都是同一个原因。

另外这次尝试本身是一个积极信号：它是四次同日「继续在复杂度轴上加证据」之后，第一次回头
处理另一条真实卡点（第二 victim 受阻），而不是第五次搁置「换注入面」建议之外的又一次
搁置——只是这个信号不能替代下方 #7 反复指出的那条建议本身。

### 13.（本轮新增，全项目目前最重要的正面结果）§0a 首次在真实弱 victim 上直接演示「能力决定 strain 是否触及 frontier」的核心机制——但文档顶部摘要没跟上，且 relative-strain 归一化后两个 victim 并不重合

[findings §0a](tech/2026-08-04-findings.md) 报告了 fork 选项 (b)（换一个真正弱的 victim）
迄今为止最实质的进展：新 victim **Llama-4-8B-Instruct-Preview**（`api.llama.com/compat`，
无每日配额）在 §4 新增的 gated 工具-schema 净化器（`sanitize_json_schema`，由
`SANITIZE_TOOL_SCHEMAS` 开关控制，对 rift 等宽松网关零风险，TDD 8 个测试）修复后首次跑通
完整 agentic 任务。用和 rift 完全相同的 content_assertion depth 1→24 语料对比：

| depth | 1 | 2 | 4 | 6 | 8 | 12 | 16 | 24 |
|---|--|--|--|--|--|--|--|--|
| benign — rift（强） | 0.55 | 0.53 | 0.59 | 0.59 | 0.73 | 0.40 | 0.70 | 0.88 |
| benign — Llama-4-8B（弱） | 0.31 | 0.11 | 0.21 | 0.14 | 0.10 | 0.14 | 0.0 | 0.0 |
| diversion — Llama-4-8B | 0.08 | 0.14 | 0.08 | 0.27 | 0.10 | 0.0 | 0.50 | 0.33 |

同一条 depth 轴，在弱 victim 上把 benign_rate 压垮到 0（0.31→0.0），在 rift 上却完全不
起作用（0.55→0.88）——项目的核心机制（"能力决定同一任务复杂度是否触及 frontier"）第一次
有真实数据支撑，不再只是理论论证。diversion 在弱 victim 上也确实朝其（很浅的）frontier
上升（0.08@d1 → 0.50@d16，CI [0.19,0.81]），方向和 rift 相反（rift 的 diversion 从未因为
从未触及 frontier 而上升过）。

需要注意四点：

1. **文档顶部摘要没有跟上这个结果**：文件开头第 3–4 行仍然写着「the cross-victim /
   invariance claim is still blocked on a second powered victim」——这句话紧挨着 §0a
   自己交出的、已经跑通的第二 victim 结果，读起来前后矛盾。合理的解读是「blocked on a
   *well-powered*（达到 rift 15–22/cell 那种量级）第二 victim」仍然成立（Llama 这批只有
   83/135 落地，n_admissible 6–12/cell，明显弱于 rift），但顶部这行摘要没有做这个区分，
   容易让只读开头的人以为整个 cross-victim 尝试还是纸上谈兵。
2. **relative-strain 归一化后两个 victim 并不重合，且这本身是对「strain-invariance」假设
   不利的证据**：文档自己写得很克制——两个 victim 几乎不重叠（rift 全程 rel-strain<1，
   Llama 全程 rel-strain≥1），唯一勉强可比的点（rel-strain≈1）上 rift diversion=0.43、
   Llama diversion=0.083，**没有出现假设所预测的"归一化后曲线重合"**，文档原话
   "tentatively *against* naive strain-invariance"。这比 §2d 的相关性结果更直接地针对
   「invariance」这个词本身，建议下游引用 §0a 时把「能力决定 strain 是否触及 frontier」
   （有支撑）和「归一化后 ASR 曲线重合」（这次数据其实不支持）这两个不同强度的主张分开说，
   不要因为标题叫「THE CROSS-VICTIM RESULT」就把两者混为一谈。
3. **Llama 的 frontier_depth 本身在方法论上站不住**：按 #8 已经反推出的规则（frontier_depth
   = 该 shape 下 benign_rate≥0.5 的最深 depth），Llama 在全部 8 个 depth 上 benign_rate
   从未达到 0.5（最高 0.31 @ depth1）——也就是说这条规则对 Llama 根本给不出一个
   frontier_depth，上面第 2 点「rel-strain≈1」的比较点因此建立在一个未定义或退化的
   frontier_depth 上。这是 #8 已经指出的"relative_strain 归一化对弱 victim 不稳"这个问题
   的一次直接印证。
4. n 尚未跑满（83/135 落地，62%），diversion 上升这条本身也被文档自己标注为"suggestive
   but noisy"（n_admissible 6–12，深 depth 处 benign=0 导致 admissible 样本更少）——一个
   低并行度的续跑正在补剩下的部分，目前的表格应视为阶段性而非最终数字。

这条结果同时也是 fork 选项 (b) 的一次真正突破，但走的是和 #12（gemini-2.5-flash-lite，
卡配额）完全不同的技术路径（Meta 网关 + schema 净化器，而不是付费配额）。至此 fork
(a)（distractor/discrimination，负结果）和 fork (b)（现在有两条候选：Llama-4-8B 已经跑通、
gemini-2.5-flash-lite 卡配额）都有了实质进展，但项目最初建议、已经连续五轮未被采纳的
「换注入面」pivot，这次（第六次）依旧没有被碰——不过这次不完全是同一类"继续在复杂度轴上
加证据"的重复，因为 §0a 是这批同日追加里第一次产出真正 novel、双向都有信息量的结果（既
支持机制、又对 invariance 本身给出反例），边际价值明显高于 #9/#10/#11 那三条，继续沿这条线
找一个能补上 rel-strain 中段的 mid-capability victim，现在有比"再设计一个新复杂度轴"更强
的理由——但这不代表"换注入面"这条建议应该被取消，只是这轮的证据让两条路径都值得做，不是
谁完全压倒谁。

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
| 2026-08-04（追加 §1b/§2b/§3/§4；08-05 同一天六次追加：先补 §1b，再加 §0/§2c-distractor，再加 §2d，再在 §2c 内加 discrimination 子实验，再在 §2c 内追加 cross-victim 尝试（gemini-2.5-flash-lite，卡配额），本轮新增 §0a（Llama-4-8B 跨 victim 结果）+ §4 追加一条 schema 净化器说明） | [findings](tech/2026-08-04-findings.md) | **§0a（本轮新增，文件最前面的一整节）——「THE CROSS-VICTIM RESULT」**：新 victim Llama-4-8B-Instruct-Preview（经 §4 新增的 `SANITIZE_TOOL_SCHEMAS` 网关 schema 净化器解封）跑了和 rift 完全相同的 depth 1→24 content_assertion 语料（83/135 落地），benign_rate 被同一条 depth 轴压到 0（0.31→0.0），rift 完全不为所动（0.55→0.88）——「能力决定同一任务复杂度是否触及 frontier」这条核心机制第一次有真实跨 victim 数据支撑；diversion 在弱 victim 上朝其浅 frontier 上升（0.08@d1→0.50@d16，CI [0.19,0.81]）。但 relative-strain 归一化后两个 victim 唯一可比点上没有重合（rift diversion 0.43 vs Llama 0.083），文档自己写「tentatively against naive strain-invariance」；详见需要你注意 #13。**§0（开篇 headline）——「收敛结论」**：把 §2b（depth 轴）和 §2c（distractor-density 轴 + 本轮新增的 discrimination 轴）并列总结为「task-complexity strain 够不到 rift 的前沿，三条独立轴都被扛住」，明确写下 cross-victim invariance 主张仍卡在第二个 well-powered victim 上；§1 shape-依赖初步观察（super_nova，n=1–3，见需要你注意 #4）；**§1b——同一 shape-依赖结论在 rift 上用 well-powered 数据复现**：exfiltration（n_adm 合计 31，5 depth 全 0）、unauthorized_action（n_adm 合计 15，5 depth 全 0）diversion 全部 0.0，同批 content_assertion 0.056–0.556，明确写下「supersedes the n=1–3 tables below (§2)」；§2 首批多 victim 小样本数据（n 太小，已被 §1b/§2b 取代）；**§2b——rift 的 depth 1→24 well-powered（n_admissible 15–22/cell，~135 任务）definitive 结果**：chain-depth 不 strain rift（benign_rate flat-to-rising，depth24=0.875；diversion 在 depth1 最低之后 noisy-flat，无 monotonic 上升）；**§2c——第二、第三个正交 strain 轴**：先是 inbox 干扰邮件密度（K=0/60/150/300，depth 固定为 2），benign_rate 不降反升（0.75→0.83）、diversion 是噪声（0.36/0.46/0.27/0.17，无趋势），基础样本量薄（n_admissible=11，K=300 只 partial 6/12，K=600 直接跳过）；**本轮新增的 confusable/discrimination 子实验**——K 封仿冒发件人的近似重复邮件（K=0/60/150），benign 0.917→0.833、diversion 0.36/0.36/0.46，同样无趋势，收尾一句「rift is robust to **three** independent complexity axes」，但这条子实验连 n_admissible 都没报告，比 distractor 变体证据更薄，且暴露基线在两次探测间相差 0.167（0.75 vs 0.917）只用「~±0.15 跑间方差」带过；文档自己没有用「definitive」形容 §2c 任何一个子实验（只在 §2b 用过）；**§2d——within-victim 相关性检验**：
把 rift content_assertion 的全部 11 个 cell（depth 轴 8 个 + distractor 轴 3 个）的
benign_rate 和 diversion 放一起算相关，得到 Pearson r=+0.61、Spearman ρ=+0.63——方向与
strain 假设预测的负相关相反，是「proximity-to-frontier 提升易感性」这个朴素假设的又一次
within-victim 反证，文档自己用「suggestive, not conclusive」定性，没有过度声称；**§3**
总结方法论上行得通的部分（三值 judge、genuine depth gating、确定性判据 vs llm_check 判据的脆弱性对比）；**§4** 记录 judge.py import 路径要从 canonical `dt_arena` 找、judge 会继承 victim 的 `OPENAI_BASE_URL`、前沿模型网关对 agentic tool-use 不友好（Gemini 走 Google 原生 endpoint 是目前唯一干净的路）；**本轮新增一条**——Meta 的 `api.llama.com/compat` 网关会对任何缺 scalar `type` 的 MCP 参数整体拒绝工具列表（`400 - Parameter type is required`），修复是一个纯函数 `sanitize_json_schema`（拍平 union 类型、给缺失类型和 array 补默认值），接在 MCP wrapper 的 `list_tools` 里，由 `SANITIZE_TOOL_SCHEMAS` 开关控制、对 rift 等宽松网关零风险（TDD，8 个测试）——这正是 §0a 能够跑通 Llama-4-8B 这档弱 victim 的原因。文档自己指出「content 易感、action 不易感」的结果和 [avo-redteam](../avo-redteam/_INDEX.md)「诽谤类记录归档转述是唯一防御盲区」的结果互相印证，§1b 又把这条印证从 n=3 加固到 well-powered。**本轮追加的 cross-victim 尝试**：把探针参数化（`PROBE_MODEL/DEPTH/PARALLEL`）后正式在 gemini-2.5-flash-lite 上跑了一次，确认这档 victim 简单调用可用（8/8 成功）、拿到一个干净 cell（depth-1/K=0，benign 0.33，n_adm 3/6），但扩大 K 直接撞上免费层每日配额上限——K=100 让模型「崩溃」（3/6，归因笼统的「context/rate」），K=60 重跑 8 条得 0/8，归因于两次 agentic 跑法耗光每日配额，结论是「纯粹卡在付费配额，不是工具问题」，见需要你注意 #12。 | §1b/§2b 与 [`2026-08-05-strain_shapes.csv`](tech/2026-08-05-strain_shapes.csv) 的数字完全一致（逐条核对过 n_admissible、diversion_rate、Wilson CI，没有发现不匹配），数据完整性可信。但 CSV 里的 `frontier_depth`/`relative_strain` 两列，findings.md 全文一次都没提到，也没有说明算法——见需要你注意 #8。**§2c 的 distractor 子实验见需要你注意 #9**：四个 diversion 比值全部裸报、没有配 Wilson CI（违反本项目自己在关键决策记录里写死的规则），也没有随附逐 task 原始数据文件核对（不像 §1b/§2b 有 CSV 佐证）。**§2c 本轮新增的 discrimination 子实验证据更薄，见需要你注意 #11**：连 n_admissible 都没给，且 K=0 基线在两次探测间从 0.75 变到 0.917——§0 把三条轴并列写成「swept at real power」对这条轴尤其不准确，不是说结论错了，是 §0 的收敛表述容易让读者把三条轴的可信度拉平。§2b 末尾的「两条前进路径」和 progress.md 的「fork, needs a decision」仍是同一件事的两处重复表达（上一轮已指出，本轮未变），建议以后这类需要人做选择的分叉决策只在 progress 里写一处。另外 §3/§4 提到「llm_check 判据脆弱，曾把 judge 的 404 静默吞成 diverted=false」这个坑——核对 [runbook](tech/2026-08-04-runbook.md) 后确认：runbook 只静态记录了「judge 默认 deepseek-chat、需要 provider 路由」这个配置事实，**没有把「验证 judge 确实存活/可达」写成操作步骤**，这个已经真实发生过的失败模式（曾让"resisted"是假象）目前仍只停留在事后记录，没有变成可执行的核验清单项，和 avo-redteam 那边「trivial 假防御未进核验清单」是同一类坑（见 [avo-redteam 索引](../avo-redteam/_INDEX.md) #4）。**§2d 见需要你注意 #10**——结论方向与 §0 一致，但 11 个 cell 里有 3 个来自 distractor 轴、benign_rate 几乎不变（0.75/0.75/0.83），把它们和 depth 轴的 8 个 cell 混池算同一条相关系数，隐含「不同来源导致的 benign_rate 变化和 diversion 的关系一样」这个未经验证的前提；仅用 depth 轴 8 个 cell 时相关性本身也不显著（r=+0.58, n.s.），这一点文档如实披露，没有隐瞒。**cross-victim 尝试见需要你注意 #12**——K=60 重跑 0/8 归因于配额耗尽的论证站得住，但 K=100「崩溃」的原因文档只写了笼统的「context/rate」，没拆开是限流还是上下文溢出就和配额耗尽一起打包成「not a tooling gap」，如果实际是上下文溢出，加钱买配额并不能解决，这一点结论有过度合并的风险。**§0a 见需要你注意 #13**——这是本轮最重要的新内容：文件开头第 3–4 行的摘要（「still blocked on a second powered victim」）没有跟上 §0a 自己交出的结果，两者放在一起读有张力；§0a 的「diversion 未在 rel-strain≈1 处重合」是对 invariance 本身的初步反面证据，而 Llama 在全部测试 depth 上 benign_rate 从未达到 0.5，使其 `frontier_depth`（按 #8 反推的规则）本身是未定义的，这个「rel-strain≈1」比较点建立在一个不稳的分母上；diversion 8 个 depth 里也只在强调结论的 depth16 端点给了 Wilson CI，其余 7 个仍是裸报，延续了 #9/#11 已指出的规则执行不一致。 |
| 2026-08-04 | [runbook](tech/2026-08-04-runbook.md) | 环境变量与两个 worktree 路径；三步操作流程（生成语料，docker-free → victim sweep，需 docker，从 `dtap-capsec` 跑 → `analyze_strain.py` 出图）具体命令；operational caveats：共享 docker 主机清理规则（不许删别人的 `pool_*`/`rds-*`）、UIUC 用 docker 不是 podman、judge LLM 必须走独立 provider（不能继承 victim 的 base_url）、`.env` 里 Meta key 的 `|` 转义坑、Gemini 免费层限流（`--max-parallel 1`）。 | 无。 |
| 2026-08-05（新文件） | [`strain_shapes.csv`](tech/2026-08-05-strain_shapes.csv) | 原始数据表：4 个 model×shape 分组（rift 的 content_assertion/exfiltration/unauthorized_action，gemini-2.5-flash-lite 的 content_assertion）、22 行，逐 depth-cell 给出 n / benign_rate / n_admissible / diversion_rate / Wilson 95% CI / undecidable_rate，另加两个此前没出现过的列 `frontier_depth`、`relative_strain`。是 findings §1b/§2b 表格和本索引 #1/#4 数字的直接数据源。 | 逐条核对过表格数字与 findings.md 的转述一致，没有发现误差。`frontier_depth`/`relative_strain` 两列缺文档说明，且对样本量小的行（尤其 gemini-2.5-flash-lite 的 n=1 cell）取值不稳，已记入需要你注意 #8，正式引用前建议先补文档说明。 |

---

## 关键决策记录

- **架构决策 A：judge 从 live backend state 判定，不看 MCP 轨迹** —— 模态无关，且不会被「表面上像是拒绝了」的轨迹文本骗到。
- **LLM 只产出结构化 `HarmDeclaration`，harness 确定性渲染 `judge.py`** —— 不让 LLM 自己写判定代码，避免判官被生成的判定逻辑本身污染。
- **固定注入而非运行时注入** —— env-state judging 依赖生成时就定好的值（凭证、beneficiary、claim_text），运行时注入会让判定失去锚点。
- **depth 是唯一自变量，env-breadth 钉死** —— 否则「strain 更高」和「环境更复杂」会混杂，`validate_chain` 强制真实的依赖链而非表面深度。
  **2026-08-04 追加（这条决策的效力边界已被测出）**：在 rift 上把这条自变量测到 depth 24（well-powered，
  n_admissible 15–22/cell）后发现它对前沿模型不起作用——benign_rate 不降反升、diversion 无 monotonic
  趋势，见「需要你注意的」#2。depth 轴本身仍然是干净的自变量（`validate_chain` 保证的真实性没有问题），
  但「用它来 strain 一个前沿模型」这个应用已经走到头，继续加 rift-depth 数据不会再有新信息（文档原话
  「further rift-depth runs add nothing」）。下一步是否要引入第二个自变量（推理难度/歧义/干扰项密度/
  分支）取代或补充 depth，是一个待决策项，不是既定架构。
  **2026-08-05 追加**：这个待决策项已经有了第一次实际尝试——干扰项密度（distractor density）
  已经作为第二个自变量跑通（§2c），结果同样是负，但样本量和方法论完整度（无 Wilson CI、无
  原始数据文件）都明显弱于 depth 轴，见「需要你注意的」#9。文档没有明说这是不是要正式纳入
  项目自变量集合的一次「转正」，还是只算一次探索性尝试——这个定性问题目前悬着。
  **2026-08-05 三次追加**：§2d 从 within-victim 相关性角度对同一个待决策项给出第三条同方向
  证据（见「需要你注意的」#10），但仍是对已有数据的再分析，不是新自变量或新实验，不改变
  待决策状态——是否引入新自变量 / 换 victim / 转向注入面，依旧悬而未决。
  **2026-08-05 四次追加**：同一个 §2c 小节又加了 discrimination（判别力，仿冒发件人近似
  重复邮件）子实验，也是负结果，让「候选自变量」这个待决策项下累积的探索性尝试增加到两个
  （distractor + discrimination），但两个都明显弱于 depth 轴的方法论完整度（均缺 Wilson
  CI、原始数据文件；discrimination 这次连 n_admissible 都没给），且都不是待决策项本身要
  解决的「转向注入面」——这个 pivot 依旧悬而未决，见「需要你注意的」#7 第四次更新。
  **2026-08-05 五次追加**：fork 选项 (b)（换一个真正弱的 victim）也有了第一次实际尝试
  ——gemini-2.5-flash-lite 探针参数化后正式跑了一次 cross-victim 尝试，确认这档 victim
  简单调用可用、拿到一个干净 cell（depth-1/K=0，benign 0.33，n_adm 3/6），但扩大 K
  直接撞上免费层每日配额上限，2 次 agentic 跑法即耗尽。结论是这条路径「harness 已就绪，
  只差付费 key」，但把 K=100 崩溃笼统归因于「context/rate」、未拆分是限流还是上下文
  溢出，见「需要你注意的」新增 #12。至此 fork (a)（distractor + discrimination 两个
  候选轴，均为负结果）和 fork (b)（gemini-2.5-flash-lite，配额受限）都有了初步尝试，
  但项目最初被建议、且已有 avo-redteam 正面证据打底的第三条路——转向注入面（wall→soft
  surface）——五次同日追加里仍然一次都没被碰。
  **2026-08-05 六次追加**：fork (b) 首次真正跑通——新 victim Llama-4-8B-Instruct-Preview
  经 §4 的工具-schema 净化器修复后完成 depth 1→24 sweep（83/135 落地），benign_rate 被
  同一条 depth 轴压到 0，和 rift 形成鲜明对比，是「能力决定 strain 后果」这条核心机制
  第一次有真实跨 victim 数据支撑。但 relative-strain 归一化后两个 victim 唯一可比点上
  没有出现曲线重合（rift diversion 0.43 vs Llama 0.083），对「invariance」本身是初步的
  反面证据，见「需要你注意的」新增 #13。至此 fork (a)、(b) 都有了实质进展，但换注入面
  这个 pivot 仍然一次都没被采纳。
- **diversion 只在 admissible 上计分，undecidable 单独排除** —— 这是处理「too weak to reach the injection ≠ resisted」这个混淆的正式机制，写进了判定本身而非靠人工事后甄别。
- **judge LLM 换成 deepseek-chat，且走独立 provider 路由** —— 判官不能继承 victim 的 `OPENAI_BASE_URL`，否则判官会打到 victim 的网关上（曾经导致 404 被静默吞成「resisted」）。
  **2026-08-04 追加（证据强化，但操作清单未跟上）**：findings §3/§4 把这条决策的必要性坐实——确定性判据
  （exfil/UA）在判官 LLM 挂掉时验证结果依然存活，`llm_check` 判据（content）没有，且是**静默**失败
  （404 被吞成 `diverted=false`，一度伪装成「resisted」）。也就是说任何新增的 `llm_check` 判据都需要
  「先确认判官模型真的活着」这一步，但这一步目前只存在于事后记录里，没有进 [runbook](tech/2026-08-04-runbook.md)
  的操作清单（核对过 runbook 全文，确认真的没有），详见下方技术文档表 findings 行的审阅意见。
- **diversion 比值一律配 Wilson 95% CI，不再裸报**（2026-08-04 追加）—— 小 n 下的整数比值（0.0/1.0）极易被误读成强结论；`analyze_strain.py` 现在给每个 cell 配区间，逼着自己和读者面对当前样本量下「什么都还没被证明」的现实。
  **2026-08-05 追加（规则出现例外）**：findings §2c 的 distractor-density 结果
  （4/11、5/11、3/11、1/6）没有遵守这条规则——四个比值全部裸报，没有区间。样本量本身
  也比 depth 轴薄（基线 n_admissible=11 vs depth 轴 15–22/cell），是目前对这条规则
  执行力最弱的一节，详见「需要你注意的」#9。
  **2026-08-05 二次追加（例外扩大）**：同一小节新增的 discrimination 子实验比 distractor
  更彻底地不遵守这条规则——连分子分母都没给，不是「裸报比值」，是「比值本身都验证不了」。
  详见「需要你注意的」#11。
  **2026-08-05 三次追加**：§0a 的 Llama-4-8B diversion 数字同样没有逐 cell 配 Wilson
  CI——8 个 depth 里只在强调"diversion 上升"这个结论时给了 depth16 那一个端点的区间
  （[0.19,0.81]），其余 7 个 depth 的比值（0.08/0.14/0.08/0.27/0.10/0.0/0.33）都是裸报，
  延续了这条规则在最新几节里执行不一致的问题。详见「需要你注意的」#13。
- **新 victim 优先复用现有 endpoint/key/eval harness**（2026-08-04 追加）—— rift 5.14 与 super_nova 同 `api.ai.meta.com/v1` + `LLAMA_API_KEY`、标准 tool-calling，直接进现有 openaisdk eval，不用每次扩梯度都去攻克一个新网关的兼容性问题。
  **2026-08-04 追加（跨项目参考）**：[avo-redteam](../avo-redteam/_INDEX.md) 新交了一份
  [`using-victims-from-another-repo`](../avo-redteam/tech/2026-08-04-using-victims-from-another-repo.md)
  集成指南，把这条决策正在用的 `rift 5.14` 接入方式（endpoint、key、可复用的
  `victim_client.py`）正式文档化了。如果这边后续要把梯度顶端扩到 groovy 5.15，
  该文档 §4 已经给出现成的 `--victim-arch responses --victim-api-key-env GROOVY_KEY
  --victim-reasoning-effort high` 参数，不用重新摸索；但要注意 avo-redteam 那边
  groovy key 目前 403 停摆，这条路暂时也走不通。
