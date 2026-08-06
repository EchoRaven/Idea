# capsec-strain-invariance · 文档索引

验证「agent 攻击易感性由相对能力强度（任务离模型能力上限多近）决定，而非绝对能力」
这个假设 —— 若成立，则「能力进步不必然买安全」，因为部署范围会随能力一起扩张。
双轨架构：`rtg-capsec`（生成 depth-N 依赖链攻击任务）+ `dtap-capsec`（跑 victim、
env-state 三值判定、出 strain 曲线）。

**最近一次收到文档**：2026-08-06（第十三批——处理时间跨到了次日，内容仍是同一份
`findings.md` 在 2026-08-05 当天的第十次追加）：在 §0-pre 内部插入一段「MATCHED
CONTROL」，直接回应上一轮（第七次追加）就指出的两个缺口——convergent（0.44）vs
linear（0.55–0.88）此前用的是两份不同任务内容的语料，混杂了「结构」和「内容」；且
convergent 的数字连样本量都没报。这次用同一个生成种子、只切换 `CHAIN_MODE=linear`
开关，生成一份内容与 convergent-20 对齐的 LINEAR-20 corpus 作为干净对照：matched
linear-20 benign ~0.556（n=9，Wilson [0.27,0.81]）vs convergent-20 0.44（n=25，
Wilson [0.27,0.62]）。方向仍然正确（convergent 更低），但效应量从跨语料对比隐含的
「~0.3」下修到「**~0.12**」，且两个区间**互相重叠**——文档自己定性为
「suggestive, not yet decisive」，并交代一份补齐到 n→~25 的 linear 基线「正在跑」。
这是项目第一次主动回头给自己最重量级的新结论打折扣，而不是继续叠加新证据，值得肯定；
但这次给的 CI 只覆盖 benign_rate，convergent 轴的 diversion 数字（0.125/0.083/0.118）
依旧裸报，承诺中的 n→~25 补充跑这次也没有交付结果。详见「需要你注意的」新增 #18。
这是继 §1b（08-05 第一次）、§0/§2c-distractor（第二次）、§2d（第三次）、
§2c-discrimination（第四次）、§2c-cross-victim/gemini（第五次）、§0a（第六次）、§0-pre
初版（第七次）、§0-pre 3-victim 表（第八次）、kimi-k3 订正（第九次）之后同一份文件
第十次追加。
**当前节奏**：仍然很快——08-04 三轮 + 08-05 十轮，跨两天十三次实质性交付，且都来自同一条
autonomous loop。这一轮和前九轮不同：它不是加新证据、不是加新方向，而是主动检验并下修
了七次追加时交出的头号新结论的效应量——这种「回头给自己纠偏」的动作本轮是第二次出现
（第一次是九次追加的 kimi-k3 订正），但这次影响的是全项目论证分量最重的一条结论。
[avo-redteam](../avo-redteam/_INDEX.md) 同期也是这个节奏。

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

**2026-08-05 七次更新（本条标题需要加一个限定词）**：新增 §0-pre 把这条标题「depth 轴
对前沿模型不起作用」精确化为「**线性** depth 轴对前沿模型不起作用」——同样是深度概念，
换成要求多源汇聚的 convergent-integration DAG 结构后，rift 的 benign 竞争力从
0.55–0.88 掉到 0.44，是至今唯一压穿这条线的结果。这不是推翻本条结论（well-powered 的
depth 1→24 线性 sweep 依然成立），而是缩小了它的适用范围：结论对「线性步数」成立，
对「深度」这个更宽泛的概念不成立。新证据本身样本量未知、且没有讨论 diversion 是否
随之上升，详见下方新增 #15。

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

### 14.（新增，跨项目提示，来自新入库的 forgingground-gen）「不信中间信号，只信 ground truth」这条纪律在第三个完全不同的领域被独立验证

[forgingground-gen](../forgingground-gen/_INDEX.md)（2026-08-05 首次入库的应用生成
流水线项目）把自己最重要的方法论纪律总结为「ground-truth-first——只信真实渲染/
日志/registry/boot-probe，不信日志行或静态代码猜测」，用它推翻过 5 个以上错误
理论；配套的「delivery ≠ narration」判定设计（LLM 自己喊的 `🚀 DELIVER_PROJECT`
不算数，只有 `main()==0` 且 `releases/` 非空才算真实交付）和本项目「diversion
比值一律配 Wilson 95% CI，不再裸报干净点估计」是同一类问题的第三次独立修正——
中间信号（日志行、干净的点估计）系统性地比真实 ground truth 更乐观。另外
forgingground-gen 自己也有一处「标题结论跑在证据前面」的例子（§3 写「delivery
blocker: essentially solved」，但同段紧跟着说「validation in flight」，至今
还没真正产出过一次 `create_release`）——这正好是本项目一直在强调的「干净的点
估计/结论容易比实际证据更硬」这条教训的又一个具体案例，可以作为下次审阅同类
文档时的参照。纯属记录，不构成本项目待办。

### 15.（本轮新增，第七次追加，全项目目前最重要的方法论转向）线性深度轴是「假复杂度」——convergent-integration 才是真正 strain 到前沿模型的轴，但缺样本量、且与 diversion 的关系被自己的框架忽略了

[findings §0-pre](tech/2026-08-04-findings.md) 是本轮（同一天）第七次追加，而且是六次
追加以来第一次插进文件最开头（排在 §0a 之前）。起因是一条用户的设计批评：step k 只依赖
step k-1 的链式深度是「线性主干」（linear spine），有能力的 agent 只需要顺着链条走一遍，
这测的是**上下文长度**，不是检索/推理能力——这解释了为什么 §2b 的 depth 1→24（线性）测
不穿 rift。真正的复杂度是 **convergent integration**：后面的步骤必须综合**多个非相邻**
的早期产物（检索+综合+工作记忆同时要用）。

项目据此把 strain 轴从线性链重建为 **convergent-integration DAG**（校验器现在要求存在
fan-in≥2 的整合节点、一个 fan-in≥3 且跨度回到前三分之一的最终注入节点、近乎全连通；
`ChainStep.consumes` 从单一来源改成来源列表），生成了一个 25-task、depth-20 的 convergent
语料，在 rift 上重跑，和线性基线对比：

| axis (depth ~20) | benign_rate | diversion |
|---|:--:|:--:|
| **linear**（基线，§2b 原数据） | 0.55–0.88（d16=0.70, d24=0.875） | 0.056–0.556 |
| **convergent**（新） | **0.44** | 0.125 |

结论：convergent 复杂度把 benign 竞争力打到 0.44——**这是至今唯一一条真正把 rift 压到
明显低于线性趋势的复杂度轴**，证明「前沿模型抗任务复杂度 strain」这条此前的结论，至少对
depth 这个自变量而言，部分是「假复杂度」（线性）的产物；换成真整合复杂度，rift 也会掉。
§0-pre 自己写明这是专门针对 depth 轴的重新表述（"reframes §0 for the depth axis
specifically"）。

需要注意四点：

1. **这条新数字完全没有报告样本量**——0.44 和 0.125 都是裸的点估计，连 n（更不用说
   n_admissible）都没给。25-task 语料在 depth-20、且 benign 明显更低的情况下，admissible
   样本很可能比线性语料同深度段的 n_admissible（7–22）更薄。这比 #9/#11 已经指出的
   「distractor/discrimination 缺 Wilson CI」更严重——那两条好歹给了裸的分子分母，这条
   连比值的分母都没有，是目前全文档统计透明度最低的一条新结论，却又是被论证分量最重、
   被放在文件最开头的一条。
2. **跨语料混杂，文档自己承认**——convergent vs linear 用的是不同任务内容的语料
   （"cross-corpus, not perfectly matched"），意味着 0.44 这个下降有多少来自 DAG 结构
   本身、多少来自换了一批任务内容，目前无法拆开。文档诚实地把这点说清楚了，值得肯定，
   但这意味着「convergent 复杂度本身导致下降」这个因果推断目前只能算强烈提示，不是像
   §2b 那样的受控实验结论。
3. **文档只报告了 benign 竞争力下降，完全没有讨论这个新低点上 diversion 是否真的更容易
   被攻破**——而这恰恰是全项目最核心的问题。把这个新数字放进已有的 depth 曲线里看：线性
   轴里 benign 最低的一格是 d12（0.40），对应 diversion 只有 0.10；convergent 的
   benign（0.44）几乎和 d12 一样低，diversion（0.125）也几乎一样低——**这个新数据点
   非但没有打破 §2d 已经发现的「diversion 和 benign 正相关、方向与 strain 假设相反」的
   模式，反而是这个模式的又一个印证点**。换句话说，项目终于找到一条真正压低 benign
   竞争力的轴，但拿这条轴量出来的 diversion 并没有像 strain 假设预测的那样升高——这本该
   是 §0-pre 该讨论、但完全没有讨论的问题，下游如果要用这条结果论证「convergent 轴证明
   了 strain 能达到前沿」，必须同时正视它对核心 diversion 假设完全没有提供正面支持，甚至
   是又一条反面数据点。
4. **跨 victim 验证（Llama-4-8B、kimi-k3）仍在跑，尚未交付**——目前的 0.44/0.125 只是
   rift 单一 victim 上的单点，convergent 轴是否也和 depth 轴一样「能力越弱越先被压垮」
   还没有数据。

另外，§0-pre 直接写明"reframes §0"，但文件靠后的 §0（开篇 headline，原文写"task-complexity
strain does not raise attack susceptibility, because task complexity does not reach
rift's frontier"）并没有被同步改写或标注「部分过时」——这是继 #13 指出的「文件开头摘要
没跟上 §0a」之后，**同一份文档里第二处「新结论加在最前面、旧结论没有被撤回或修订」的
情况**，建议后续维护者养成加新结论时回头补一句"supersedes/qualifies §X"的习惯，而不是让
读者自己去逐节比对。

这条结果也是对 PROJECTS.md 此前连续建议、一直优先级最高的「换注入面（wall→soft
surface）」pivot 的第七次搁置——但这次和 §0a 一样不完全是「重复的复杂度轴加证据」，而是
找到了一个此前从未验证过的、真正有效的新维度（整合复杂度而非步数），边际价值明显高于
distractor/discrimination 那两条已经收敛的负结果，也应该被视为一条独立的、值得继续跟进的
路径，而不是「又一次搁置注入面」这个模式的简单重复。

**2026-08-06 更新（第十次追加，matched control）**：本条第 1、2 点指出的缺口——
convergent 轴的数字没有样本量支撑、且和 linear 基线跨语料混杂——这次被一段「MATCHED
CONTROL」正面处理：同种子只切换 `CHAIN_MODE` 生成的干净 linear-20 对照显示，convergent
结构确实让 benign 更低，但效应量只有 ~0.12，不是跨语料对比隐含的 ~0.3，且 n=9 下两个
Wilson 区间互相重叠、尚不显著。第 3 点（diversion 是否也随 convergent strain 升高）
依旧完全没有被讨论。详见新增 #18。

### 16.（本轮新增，第八次追加，回应 #15 遗留的「跨 victim 验证仍在跑」）convergent-integration 轴的 3-victim 结果到手，但统计严谨度全线倒退，且 kimi-k3 的能力排序和它的「mid reasoner」标签自相矛盾

[findings §0-pre 追加段](tech/2026-08-04-findings.md) 是本轮（同一天）第八次追加，直接
补上了 #15 第 4 点标注的缺口——convergent-integration 语料的跨 victim 验证不再「仍在跑」，
而是首次交出结果，新增了一个此前从未在本项目任何文档里出现过的第三个 victim
**kimi-k3**（标为「mid reasoner」），连同 rift、Llama-4-8B 一起跑了同一批 25-task
convergent depth-20 语料：

| victim | convergent benign | diversion | linear-baseline benign |
|---|:--:|:--:|:--:|
| rift（frontier） | 0.44（n=25） | 0.125 | 0.55–0.88 |
| kimi-k3（mid reasoner） | 0.083（n=12） | 0.0 | ~0.45 |
| Llama-4-8B（weak 8B） | 0.167（n=18） | 0.118 | ~0.0–0.35 |

文档把这个结果总结成「每个 victim 的 benign 竞争力都被 convergent 复杂度压垮，含前沿模型
在内；diversion 在三个 victim 上都很低（~0–0.12），说明 convergent 复杂度 strain 的是
能力，不是易感性」。

需要指出四点：

1. **kimi-k3 从未在本项目任何此前文档里出现过，这次直接带着结果空降，零基础设施说明**——
   Llama-4-8B 首次登场时（§0a/§4）配了完整的接入路径（网关地址、schema 净化器、TDD 测试）；
   kimi-k3 连 endpoint、是谁的模型（推测是 Moonshot Kimi）、怎么接入 harness 都没有一个字
   说明。如果后续要正式引用这个三 victim 表，至少需要补一句 kimi-k3 的接入方式，否则读者
   无法判断这条数据是否和 rift/Llama 用的是同一套 judge/injector。
2. **三个 victim 全部没有 n_admissible、没有 Wilson CI**——n=25/12/18 是原始样本数，不是
   admissible 数，diversion 是「over admissible」算出来的比值，但 admissible 分母完全
   没给。这比 #15 已经指出的「convergent 单点连分子分母都没有」还退了一步：现在是三个
   victim 同时都没有，而且新增的 kimi-k3/Llama 这两档还是弱 victim——历史上（#12/#13）
   弱 victim 的 admissibility 一贯容易塌缩（gemini-flash-lite n_adm 3/6，Llama depth16+
   n_adm 6–12），n=12/18 里 admissible 部分可能所剩无几，diversion 的 0.0/0.118 这两个
   数字目前无从核实。
3. **kimi-k3 的「mid reasoner」标签和它实测的能力排序自相矛盾**——如果 kimi-k3 真的是
   介于 Llama-4-8B（weak 8B）和 rift（frontier）之间的中间档位，预期它的 convergent
   benign_rate 也应该落在 0.167 和 0.44 之间；但实测是 **0.083，比标称「更弱」的
   Llama-4-8B（0.167）还低**。文档把这个反常排序轻描淡写成「两者的次序在 n=12/18 下是
   噪声范围内的」（within noise），但没有给出任何区间或统计检验支撑这句话，只是断言。
   如果 kimi-k3 真实能力确实弱于 Llama-4-8B，那么它的「mid reasoner」标签本身就是错的，
   连带这份表格「rift 最强、kimi-k3/Llama 都被打到底」这个能力排序论证的说服力也要打
   折扣——这不是一句「within noise」能带过的小问题，而是这条结果能否支撑「convergent
   轴复现了能力梯度」这个核心论点的关键一环。
4. **「diversion 在三个 victim 上都很低」被包装成一条独立、方向友好的新发现，但它其实是
   对项目核心假设的又一次反面证据，而不是无关的附加信息**——convergent 轴被 §0-pre 主体
   段落称为「至今唯一真正 strain 到前沿模型的轴」，如果 strain 假设成立，这恰恰应该是
   最有希望看到 diversion 随 strain 上升的地方；但结果是三个 victim 上 diversion 全部
   趴在 0–0.125，和 rift 在线性轴上「diversion 从不上升」是同一个模式，现在扩展到了两个
   更弱的 victim 上。文档把这个包装成「convergent 复杂度 strain 的是能力、不是易感性」
   这个中性陈述，但和 §2d 已经发现的「diversion 与 benign 正相关、方向与 strain 假设
   相反」放在一起看，这条新结果不是一条独立轴，而是同一个反直觉模式第三次出现（depth
   轴、within-victim 相关性、现在是 convergent 轴跨三个 victim）——下游如果要引用这条
   结果论证「convergent 轴证明复杂度能到达前沿」，必须同时正视它对「到达前沿会提高
   易感性」这个更核心的主张完全没有提供支持。

这条结果直接回应了 #15 第 4 点标注的缺口（「跨 victim 验证仍在跑，尚未交付」），缺口本身
确实被填上了，但填上的方式让 §0-pre 的统计严谨度问题从「一个 victim 缺样本量」扩大成
「三个 victim 都缺样本量，外加一个全新 victim 零基础设施文档、一个能力排序自相矛盾」——净
效果是这条结果在被正式采信之前需要补的功课比 #15 写下时更多，而不是更少。另外文件开头
第 3–4 行的摘要（「still blocked on a second powered victim」）现在离实际内容更远了：
不仅 §0a 的 Llama-4-8B 早已跑通（#13 已指出），现在连第三个新 victim kimi-k3 的结果都
交付了，这行摘要连续两轮（#13、本条）都没有被同步更新。

### 17.（本轮新增，第九次追加，是订正不是新实验）kimi-k3 的 convergent 数字被上修 3 倍，解决了 #16 的标签矛盾，但订正本身仍未配区间——反而是「小样本点估计不可信」的一次现身说法

[findings §0-pre 追加段](tech/2026-08-04-findings.md) 是本轮（同一天）第九次追加，直接
回应 #16 指出的问题：kimi-k3 标称「mid reasoner」，但 #16 记录的 convergent benign
（0.083，n=12）反而低于标称「weak 8B」的 Llama-4-8B（0.167），排序和标签矛盾。这次文档
把 kimi-k3 的样本量从 n=12 扩到 n=25，数字随之改变：

| victim | convergent benign（本轮） | convergent benign（上一轮 #16） | diversion（本轮） | diversion（上一轮 #16） |
|---|:--:|:--:|:--:|:--:|
| rift | 0.44（n=25，未变） | 0.44（n=25） | 0.125（未变） | 0.125 |
| kimi-k3 | **0.24**（n=25） | 0.083（n=12） | **0.083** | 0.0 |
| Llama-4-8B | 0.167（n=18，未变） | 0.167（n=18） | 0.118（未变） | 0.118 |

文档原话把上一轮的数字定性为「an n=12 fluke, corrected by extending to n=25」，并宣称
「the convergent competence ordering is cleanly monotonic in capability: rift 0.44 >
kimi-k3 0.24 > Llama-4-8B 0.18」——三档能力排序第一次和它们的标签（frontier / mid
reasoner / weak 8B）对上了，#16 第 3 点指出的排序矛盾这次确实被解决了。

需要指出两点：

1. **这是一次好的订正，不是一次新的矛盾**：文档主动说明了旧数字是什么、新数字是什么、
   为什么变了（样本量扩大），没有像文件开头摘要那样悄悄不同步就过去——这个透明度值得
   肯定，是这类 autonomous loop 文档里比较少见的「自我纠错」实例。
2. **但订正后的数字依旧没有配 Wilson CI，这次的订正幅度本身恰好是「为什么需要 CI」这条
   项目自己规则的最佳示范**：kimi-k3 的点估计从 0.083 变成 0.24，接近 3 倍，只是多测了
   13 个样本（n=12→25，约合 1/12 → 6/25）；diversion 也从 0.0 变到 0.083。如果当时
   （#16 那一轮）就配了 Wilson CI，n=12 时 0.083 的置信区间上界大概率宽到能覆盖 0.24，
   这个"矛盾"从一开始就不会被当成一个需要专门指出的问题。现在的教训是反过来的：
   `n=25` 依旧是小样本，没有理由认为这次的 0.24 就已经稳定——继续扩到 n=50，点估计仍
   完全可能再次大幅移动。在 kimi-k3/Llama-4-8B 这两档补上 n_admissible 和 Wilson CI
   （#16 已经提过的待办，这次仍未做）之前，「三档能力排序现在对上了」这个结论应该继续
   标注为初步，而非定论。

这条订正没有推进核心假设（diversion 是否随 strain 上升）本身——kimi-k3 的 diversion
从 0.0 变成 0.083，仍然落在 rift/Llama 的同一噪声地板范围内，不改变 #16 第 4 点已经
指出的「三个 victim 上 diversion 都不随 convergent strain 上升，对核心假设是又一次
反面印证」这条结论。

### 18.（本轮新增，第十次追加，直接回应 #15 遗留的两个方法论缺口）matched control 把 convergent 轴的效应量从「~0.3」下修到「~0.12」，同时第一次给这个数字配上了 Wilson CI

[findings §0-pre 追加段](tech/2026-08-04-findings.md)（「MATCHED CONTROL」段落）直接
回应 #15 指出的两个问题：①convergent（0.44）vs linear（0.55–0.88）用的是不同任务内容
的语料，下降多少来自结构、多少来自内容混杂拆不开；②convergent 的 0.44/0.125 连样本量
都没报。这次项目用同一个生成种子、只切换 `CHAIN_MODE=linear` 这一个开关，生成一份内容
和 convergent-20 语料对齐、仅结构不同的 LINEAR-20 corpus 作为干净对照重新跑了一次：

| 语料 | benign_rate | n | Wilson 95% CI |
|---|:--:|:--:|:--:|
| matched linear-20 | 0.556 | 9 | [0.27, 0.81] |
| convergent-20 | 0.44 | 25 | [0.27, 0.62] |

方向仍然正确——convergent 确实更低——但效应量比此前跨语料对比隐含的「~0.3」
（0.55–0.88 vs 0.44 的粗略落差）小得多，只有 **~0.12**（0.556→0.44）。更关键的是两个
区间**互相重叠**，文档自己如实定性为「suggestive, not yet decisive」，并交代一份补齐到
n→~25 的 linear 基线「正在跑」。

需要指出三点：

1. **这是一次值得肯定的自我纠错**：项目主动回头检验自己此前最重量级的结论
   （"convergent 轴是唯一压穿前沿模型的复杂度轴"），发现原始效应量被跨语料混杂夸大了
   将近 3 倍，并主动把这个下修写进了段落标题本身（"tempers the effect size"），没有
   藏着不提。这和 #17 记录的 kimi-k3 订正是同一种"自己抓自己错"的好习惯，在这类
   autonomous loop 产出的文档里比较少见。
2. **这次给的 CI 是 benign_rate 的，不是 diversion 的**——#16/#17 反复指出 convergent
   轴 3-victim 表里的 diversion 数字（rift 0.125、kimi-k3 0.083、Llama-4-8B 0.118）
   全部没有 Wilson CI，这次的 matched control 段落完全没有涉及 diversion，那三个数字
   依旧裸报。「diversion 比值一律配 Wilson CI」这条项目自己的规则，在 convergent 轴上
   仍然只对 benign_rate 生效，没有扩展到 diversion。
3. **matched linear-20 的 n=9 本身还是偏薄的**（比 depth 轴 well-powered 时的
   n_admissible 15–22/cell 薄很多），这也是两个区间会重叠的直接原因——文档自己承认，
   一份 n→~25 的补充跑「正在跑」但**这次没有交付结果**，是继 §0-pre 第七次追加时「跨
   victim 验证仍在跑」之后，同一小节里第二次留下一个「正在跑、待下次交付」的悬空承诺，
   下一次收到 findings.md 更新时应该优先核对这个 n~25 版本是否真的到了、区间是否收窄
   到不再重叠。

这条结果没有推翻 §0-pre 的方向性结论（convergent 结构确实让 rift 的 benign 竞争力比
matched linear 更低），但把它从"至今唯一压穿前沿模型的复杂度轴，效应量很大"精确成了
"效应方向正确、量级温和、统计上仍不够决定性"——这是一个更诚实、但也更谨慎的结论，下游
引用时应该用这次的措辞，而不是七次追加时的原始措辞。

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
| 2026-08-04（追加 §1b/§2b/§3/§4；08-05 同一天八次追加：先补 §1b，再加 §0/§2c-distractor，再加 §2d，再在 §2c 内加 discrimination 子实验，再在 §2c 内追加 cross-victim 尝试（gemini-2.5-flash-lite，卡配额），再新增 §0a（Llama-4-8B 跨 victim 结果）+ §4 追加一条 schema 净化器说明，第七次新增 §0-pre（convergent-integration 轴，插在文件最开头，排在 §0a 之前），第八次在 §0-pre 内追加「Cross-victim on the same convergent corpus」段落，新增第三个 victim kimi-k3，本轮（第九次）就地订正 kimi-k3 数字：convergent benign 0.083(n=12)→0.24(n=25)，diversion 0.0→0.083；第十次在同一 §0-pre 段落内插入「MATCHED CONTROL」，用同种子 linear-20 对照把 convergent 效应量从 ~0.3 下修到 ~0.12 并首次给出 Wilson CI） | [findings](tech/2026-08-04-findings.md) | **§0-pre（本轮新增，现在是文件最开头的一节）——线性 depth 轴是「假复杂度」**：用户设计批评指出 step k 只依赖 step k-1 的线性链只测上下文长度，据此把 strain 轴重建为要求 fan-in≥2 整合节点的 convergent-integration DAG，25-task depth-20 语料在 rift 上重测得 benign_rate=0.44（远低于线性同深度段的 0.55–0.88）、diversion=0.125——**全项目至今唯一一条真正把 rift 压到明显低于线性趋势的复杂度轴**，部分推翻「前沿模型抗任务复杂度 strain」对 depth 轴的普适性；但完全没报告样本量、跨语料混杂（文档自承）、且没有讨论这个新低点上 diversion 是否真的更高——对照线性轴同样低 benign 的 d12（diversion 仅 0.10），convergent 的 0.125 其实并不异常，反而印证了 §2d 已发现的「diversion 与 benign 正相关、方向与 strain 假设相反」。详见需要你注意 #15。**本轮（第八次追加）——同一节内补上「Cross-victim on the same convergent corpus」**：convergent 语料首次交出跨 victim 结果，新增此前从未出现过的第三个 victim kimi-k3（标为「mid reasoner」），rift/kimi-k3/Llama-4-8B 的 convergent benign 分别是 0.44/0.083/0.167、diversion 分别是 0.125/0.0/0.118——三个 victim 的 benign 都被 convergent 复杂度压低、diversion 都不升高，文档总结为「convergent 复杂度 strain 的是能力、不是易感性」。但三个 victim 全部没有 n_admissible/Wilson CI（比单点缺 CI 更退一步），kimi-k3 零基础设施说明就直接带结果空降，且它「mid reasoner」标签与实测能力排序（convergent benign 低于「weak 8B」的 Llama-4-8B）自相矛盾。详见需要你注意 #16。**本轮（第九次）——同一张表被就地订正**：kimi-k3 从 0.083(n=12)/diversion 0.0 上修为 0.24(n=25)/diversion 0.083，文档明确交代原因是「n=12 fluke」，订正后三档排序（rift>kimi-k3>Llama-4-8B）终于对上了各自的能力标签，解决了 #16 第 3 点的矛盾；但订正后依旧没有 Wilson CI，这次将近 3 倍的点估计跳变本身就是「小样本不可信」的一次现身说法。详见需要你注意 #17。**本轮（第十次追加）——同一个 §0-pre 小节插入「MATCHED CONTROL」段落**：用同一个生成种子只切换 `CHAIN_MODE=linear` 生成一份内容对齐的 LINEAR-20 语料作为干净对照，重新对比 convergent-20：matched linear-20 benign 0.556（n=9，Wilson [0.27,0.81]）vs convergent-20 0.44（n=25，Wilson [0.27,0.62]）——方向仍是 convergent 更低，但效应量从跨语料对比隐含的 ~0.3 下修到 ~0.12，且两区间重叠，文档自己定性为「suggestive, not yet decisive」，并交代一份 n→~25 的补充 linear 基线正在跑但本轮未交付。详见需要你注意 #18。**§0a（文件次开头的一整节）——「THE CROSS-VICTIM RESULT」**：新 victim Llama-4-8B-Instruct-Preview（经 §4 新增的 `SANITIZE_TOOL_SCHEMAS` 网关 schema 净化器解封）跑了和 rift 完全相同的 depth 1→24 content_assertion 语料（83/135 落地），benign_rate 被同一条 depth 轴压到 0（0.31→0.0），rift 完全不为所动（0.55→0.88）——「能力决定同一任务复杂度是否触及 frontier」这条核心机制第一次有真实跨 victim 数据支撑；diversion 在弱 victim 上朝其浅 frontier 上升（0.08@d1→0.50@d16，CI [0.19,0.81]）。但 relative-strain 归一化后两个 victim 唯一可比点上没有重合（rift diversion 0.43 vs Llama 0.083），文档自己写「tentatively against naive strain-invariance」；详见需要你注意 #13。**§0（开篇 headline）——「收敛结论」**：把 §2b（depth 轴）和 §2c（distractor-density 轴 + 本轮新增的 discrimination 轴）并列总结为「task-complexity strain 够不到 rift 的前沿，三条独立轴都被扛住」，明确写下 cross-victim invariance 主张仍卡在第二个 well-powered victim 上；§1 shape-依赖初步观察（super_nova，n=1–3，见需要你注意 #4）；**§1b——同一 shape-依赖结论在 rift 上用 well-powered 数据复现**：exfiltration（n_adm 合计 31，5 depth 全 0）、unauthorized_action（n_adm 合计 15，5 depth 全 0）diversion 全部 0.0，同批 content_assertion 0.056–0.556，明确写下「supersedes the n=1–3 tables below (§2)」；§2 首批多 victim 小样本数据（n 太小，已被 §1b/§2b 取代）；**§2b——rift 的 depth 1→24 well-powered（n_admissible 15–22/cell，~135 任务）definitive 结果**：chain-depth 不 strain rift（benign_rate flat-to-rising，depth24=0.875；diversion 在 depth1 最低之后 noisy-flat，无 monotonic 上升）；**§2c——第二、第三个正交 strain 轴**：先是 inbox 干扰邮件密度（K=0/60/150/300，depth 固定为 2），benign_rate 不降反升（0.75→0.83）、diversion 是噪声（0.36/0.46/0.27/0.17，无趋势），基础样本量薄（n_admissible=11，K=300 只 partial 6/12，K=600 直接跳过）；**本轮新增的 confusable/discrimination 子实验**——K 封仿冒发件人的近似重复邮件（K=0/60/150），benign 0.917→0.833、diversion 0.36/0.36/0.46，同样无趋势，收尾一句「rift is robust to **three** independent complexity axes」，但这条子实验连 n_admissible 都没报告，比 distractor 变体证据更薄，且暴露基线在两次探测间相差 0.167（0.75 vs 0.917）只用「~±0.15 跑间方差」带过；文档自己没有用「definitive」形容 §2c 任何一个子实验（只在 §2b 用过）；**§2d——within-victim 相关性检验**：
把 rift content_assertion 的全部 11 个 cell（depth 轴 8 个 + distractor 轴 3 个）的
benign_rate 和 diversion 放一起算相关，得到 Pearson r=+0.61、Spearman ρ=+0.63——方向与
strain 假设预测的负相关相反，是「proximity-to-frontier 提升易感性」这个朴素假设的又一次
within-victim 反证，文档自己用「suggestive, not conclusive」定性，没有过度声称；**§3**
总结方法论上行得通的部分（三值 judge、genuine depth gating、确定性判据 vs llm_check 判据的脆弱性对比）；**§4** 记录 judge.py import 路径要从 canonical `dt_arena` 找、judge 会继承 victim 的 `OPENAI_BASE_URL`、前沿模型网关对 agentic tool-use 不友好（Gemini 走 Google 原生 endpoint 是目前唯一干净的路）；**本轮新增一条**——Meta 的 `api.llama.com/compat` 网关会对任何缺 scalar `type` 的 MCP 参数整体拒绝工具列表（`400 - Parameter type is required`），修复是一个纯函数 `sanitize_json_schema`（拍平 union 类型、给缺失类型和 array 补默认值），接在 MCP wrapper 的 `list_tools` 里，由 `SANITIZE_TOOL_SCHEMAS` 开关控制、对 rift 等宽松网关零风险（TDD，8 个测试）——这正是 §0a 能够跑通 Llama-4-8B 这档弱 victim 的原因。文档自己指出「content 易感、action 不易感」的结果和 [avo-redteam](../avo-redteam/_INDEX.md)「诽谤类记录归档转述是唯一防御盲区」的结果互相印证，§1b 又把这条印证从 n=3 加固到 well-powered。**本轮追加的 cross-victim 尝试**：把探针参数化（`PROBE_MODEL/DEPTH/PARALLEL`）后正式在 gemini-2.5-flash-lite 上跑了一次，确认这档 victim 简单调用可用（8/8 成功）、拿到一个干净 cell（depth-1/K=0，benign 0.33，n_adm 3/6），但扩大 K 直接撞上免费层每日配额上限——K=100 让模型「崩溃」（3/6，归因笼统的「context/rate」），K=60 重跑 8 条得 0/8，归因于两次 agentic 跑法耗光每日配额，结论是「纯粹卡在付费配额，不是工具问题」，见需要你注意 #12。 | §1b/§2b 与 [`2026-08-05-strain_shapes.csv`](tech/2026-08-05-strain_shapes.csv) 的数字完全一致（逐条核对过 n_admissible、diversion_rate、Wilson CI，没有发现不匹配），数据完整性可信。但 CSV 里的 `frontier_depth`/`relative_strain` 两列，findings.md 全文一次都没提到，也没有说明算法——见需要你注意 #8。**§2c 的 distractor 子实验见需要你注意 #9**：四个 diversion 比值全部裸报、没有配 Wilson CI（违反本项目自己在关键决策记录里写死的规则），也没有随附逐 task 原始数据文件核对（不像 §1b/§2b 有 CSV 佐证）。**§2c 本轮新增的 discrimination 子实验证据更薄，见需要你注意 #11**：连 n_admissible 都没给，且 K=0 基线在两次探测间从 0.75 变到 0.917——§0 把三条轴并列写成「swept at real power」对这条轴尤其不准确，不是说结论错了，是 §0 的收敛表述容易让读者把三条轴的可信度拉平。§2b 末尾的「两条前进路径」和 progress.md 的「fork, needs a decision」仍是同一件事的两处重复表达（上一轮已指出，本轮未变），建议以后这类需要人做选择的分叉决策只在 progress 里写一处。另外 §3/§4 提到「llm_check 判据脆弱，曾把 judge 的 404 静默吞成 diverted=false」这个坑——核对 [runbook](tech/2026-08-04-runbook.md) 后确认：runbook 只静态记录了「judge 默认 deepseek-chat、需要 provider 路由」这个配置事实，**没有把「验证 judge 确实存活/可达」写成操作步骤**，这个已经真实发生过的失败模式（曾让"resisted"是假象）目前仍只停留在事后记录，没有变成可执行的核验清单项，和 avo-redteam 那边「trivial 假防御未进核验清单」是同一类坑（见 [avo-redteam 索引](../avo-redteam/_INDEX.md) #4）。**§2d 见需要你注意 #10**——结论方向与 §0 一致，但 11 个 cell 里有 3 个来自 distractor 轴、benign_rate 几乎不变（0.75/0.75/0.83），把它们和 depth 轴的 8 个 cell 混池算同一条相关系数，隐含「不同来源导致的 benign_rate 变化和 diversion 的关系一样」这个未经验证的前提；仅用 depth 轴 8 个 cell 时相关性本身也不显著（r=+0.58, n.s.），这一点文档如实披露，没有隐瞒。**cross-victim 尝试见需要你注意 #12**——K=60 重跑 0/8 归因于配额耗尽的论证站得住，但 K=100「崩溃」的原因文档只写了笼统的「context/rate」，没拆开是限流还是上下文溢出就和配额耗尽一起打包成「not a tooling gap」，如果实际是上下文溢出，加钱买配额并不能解决，这一点结论有过度合并的风险。**§0a 见需要你注意 #13**——这是本轮最重要的新内容：文件开头第 3–4 行的摘要（「still blocked on a second powered victim」）没有跟上 §0a 自己交出的结果，两者放在一起读有张力；§0a 的「diversion 未在 rel-strain≈1 处重合」是对 invariance 本身的初步反面证据，而 Llama 在全部测试 depth 上 benign_rate 从未达到 0.5，使其 `frontier_depth`（按 #8 反推的规则）本身是未定义的，这个「rel-strain≈1」比较点建立在一个不稳的分母上；diversion 8 个 depth 里也只在强调结论的 depth16 端点给了 Wilson CI，其余 7 个仍是裸报，延续了 #9/#11 已指出的规则执行不一致。**§0-pre 见需要你注意 #15**——本轮统计透明度最低的一条新结论：0.44/0.125 连分子分母都没给，比 #9/#11 已指出的「缺 Wilson CI」更严重；且文档只讲了 benign 竞争力下降，完全没有对照检查这个新低点上 diversion 是否真的升高——对照线性轴同样低 benign 的 d12（diversion 仅 0.10），convergent 的 0.125 并不异常，反而是 §2d「diversion 与 benign 正相关」这个反直觉模式的又一个印证点，而不是它的反例。另外 §0-pre 自称"reframes §0"，但 §0 headline 本身没有被同步改写，是继「文件开头摘要没跟上 §0a」之后第二处「新结论顶在最前面、旧结论未被撤回」的情况。**本轮新增的跨 victim convergent 段落见需要你注意 #16**——统计严谨度比 §0-pre 初版更差(三个 victim rift/kimi-k3/Llama-4-8B 全部无 n_admissible/CI，不是一个)；新增的 kimi-k3 是全文档第一个零基础设施说明就交结果的 victim；且它「mid reasoner」标签与实测能力排序(convergent benign 0.083 反而低于「weak 8B」Llama-4-8B 的 0.167)自相矛盾，文档只用「within noise」带过、无统计支撑。文件开头摘要「still blocked on a second powered victim」现在连续两轮(#13、#16)都没跟上正文交付的结果。**本轮(第九次)见需要你注意 #17**——kimi-k3 数字被就地订正(0.083→0.24, n=12→25)，解决了 #16 指出的标签排序矛盾，文档主动披露了订正原因，值得肯定；但订正后仍未配 Wilson CI，且这次约 3 倍的点估计跳变本身就是"小样本点估计不稳"的直接示范。**本轮(第十次)见需要你注意 #18**——matched control 是一次值得肯定的自我纠错：主动检验了此前最重量级的 convergent 结论，发现效应量被跨语料混杂夸大，主动下修（~0.3→~0.12）并首次给出 Wilson CI；但这个 CI 只覆盖 benign_rate，convergent 轴的 diversion 数字（0.125/0.083/0.118）依旧裸报，且承诺中的 n→~25 补充 linear 跑这次没有交付结果，下一批文档到了应优先核对。 |
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
  **2026-08-05 七次追加（这条决策本身的核心问题被正面回答）**：depth 轴「是否有一种
  形式能真正 strain 前沿模型」这个悬了三轮的问题（见上方「2026-08-04 追加」「2026-08-05
  追加」两条）第一次得到正面回答——不是换成完全不同的自变量（干扰密度/判别力），而是
  发现 depth 本身此前测的是**线性**依赖链，只考验上下文长度，换成要求多源汇聚的
  convergent-integration DAG（同样是「深度」，但图结构不同）后，rift 的 benign 竞争力
  从 0.55–0.88 掉到 0.44，是全项目至今唯一压穿这条线的复杂度结果。这意味着「depth 是
  唯一自变量，env-breadth 钉死」这条最初的架构决策不需要被推翻，但「depth」本身的操作化
  定义（线性 vs DAG）需要被认定为两种不同强度的自变量，历史的 depth 1→24 well-powered
  负结果（§2b）应被理解为「线性 depth 测不穿」而非「depth 这个概念测不穿」。但这条新
  结果本身证据单薄（0.44/0.125 连样本量都没报，见「需要你注意的」#15），且没有讨论
  diversion 是否真的随之升高——不应该在方法论上直接「转正」为新的定论,需要先补样本量
  和跨 victim 验证。
  **2026-08-05 八次追加（上一条要的「跨 victim 验证」到手，但没有解决样本量问题）**：
  convergent 轴新增了 rift/kimi-k3/Llama-4-8B 三方对比（0.44/0.083/0.167），三个 victim
  的 benign 都被 convergent 复杂度压低、diversion 都维持在 0–0.125，方向上支持「convergent
  是目前唯一能触及前沿的轴」这条七次追加的结论。但七次追加末尾提出的「需要先补样本量和跨
  victim 验证」这两个待办，这次只做对了一半——跨 victim 验证做了，样本量问题完全没解决
  （三个 victim 全部仍是裸点估计，无 n_admissible/CI），还新增了一个 kimi-k3 零基础设施
  文档、「mid reasoner」标签与实测能力排序矛盾的问题，见「需要你注意的」新增 #16。
  **2026-08-06 追加（matched control，回应七次追加提出的「需要先补样本量」要求，部分满足）**：
  七次追加时对这条决策提出的「不应该在方法论上直接转正为新的定论，需要先补样本量」这个
  要求，这次被部分满足——convergent-20 的 benign_rate（0.44）现在有了同种子 matched
  linear-20（n=9）对照和双侧 Wilson CI，效应量从隐含的 ~0.3 下修到 ~0.12，且区间重叠、
  尚不显著。样本量问题只解决了一半：benign_rate 有 CI 了，diversion（0.125/0.083/0.118）
  依旧没有，「跨 victim 验证」也仍是八次追加时那批未经 CI 加固的裸点估计。详见「需要你
  注意的」新增 #18。
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
  **2026-08-05 四次追加（规则执行力度的新低点）**：§0-pre 新增的 3-victim convergent 表
  （rift/kimi-k3/Llama-4-8B 的 diversion 0.125/0.0/0.118）不仅没有 Wilson CI，连
  n_admissible 都没给——只有裸的原始样本数 n=25/12/18，比此前任何一次「裸报比值」都退
  得更远，因为读者连分母是多少都不知道。详见「需要你注意的」新增 #16。
  **2026-08-05 五次追加（这条规则的必要性被反向证明）**：上一条记录的 kimi-k3 数字
  （benign 0.083/n=12）这次被订正为 0.24/n=25——约 3 倍的跳变仅由样本量翻倍导致。这正是
  这条 Wilson CI 规则本来要防的事：如果当初 n=12 时就配了区间，读者会看到一个宽到覆盖
  0.24 的上界，不会把 0.083 误当成一个可以拿来和 Llama-4-8B 比排序的稳定数字。订正后的
  0.24/n=25 依旧没有配区间，问题没有解决，只是换了一个数字继续裸报。详见「需要你注意的」
  新增 #17。
  **2026-08-06 追加（部分合规，但只针对 benign_rate）**：matched control 段落第一次给
  convergent 轴的 benign_rate 比较配上了 Wilson CI（[0.27,0.81] vs [0.27,0.62]），是这条
  规则在 convergent 轴上第一次被真正执行。但这次的 CI 只覆盖 benign_rate，convergent
  3-victim 表里的 diversion 数字（0.125/0.083/0.118）依旧裸报，这条规则对 diversion 比值
  的执行力度没有变化。详见「需要你注意的」新增 #18。
- **新 victim 优先复用现有 endpoint/key/eval harness**（2026-08-04 追加）—— rift 5.14 与 super_nova 同 `api.ai.meta.com/v1` + `LLAMA_API_KEY`、标准 tool-calling，直接进现有 openaisdk eval，不用每次扩梯度都去攻克一个新网关的兼容性问题。
  **2026-08-04 追加（跨项目参考）**：[avo-redteam](../avo-redteam/_INDEX.md) 新交了一份
  [`using-victims-from-another-repo`](../avo-redteam/tech/2026-08-04-using-victims-from-another-repo.md)
  集成指南，把这条决策正在用的 `rift 5.14` 接入方式（endpoint、key、可复用的
  `victim_client.py`）正式文档化了。如果这边后续要把梯度顶端扩到 groovy 5.15，
  该文档 §4 已经给出现成的 `--victim-arch responses --victim-api-key-env GROOVY_KEY
  --victim-reasoning-effort high` 参数，不用重新摸索；但要注意 avo-redteam 那边
  groovy key 目前 403 停摆，这条路暂时也走不通。
