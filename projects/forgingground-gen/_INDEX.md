# forgingground-gen · 文档索引

> 本文件由 Claude 维护。每次处理新文档后更新。
> 你只需要读这一页，就知道这个项目所有文档说了什么。

一次性 LLM-agent 流水线：把产品 *contract* 项目式生成为完整可运行的
**FastAPI + Postgres + React(Vite)** 全栈应用，由 orchestrator/design-analyst/
前后端工程师/verifier/浏览器测试用户等多个 agent 在 podman + podman-compose 上
协同完成。当前目标是让单次运行**同时**满足「真实交付」（`main()==0` 且
`releases/` 非空）与「视觉保真度」（vs 参考截图均值 ≥0.65，当前目标应用是
Netflix web clone）两个门槛，且每个修复都要能推广到所有环境/应用，不只是这一个
目标应用。方法论纪律是 **ground-truth-first**——只信真实渲染/日志/registry/
boot-probe，不信日志行或静态代码猜测；这条纪律已经推翻过 5 个以上的错误理论。

**最近一次收到文档**：2026-08-05（首次入库——项目状态总览文档 `forgingground-gen.md`，
一次性涵盖项目定位、当前状态(r85 交付门转绿)、6 项已发布修复(#505/#506/#507/#508/
#509/#510/#512)、方法论与路线图。这份文档不是拆分投递的 tech/progress 两类文档，
而是单个文件直接放在 `projects/forgingground-gen.md`，不在 `sync/sources.conf`
配置的自动拉取管线里——原因见下方「需要你注意的」#3：agent 在生成运行的那台机器上
被 GitHub 出网 403 挡住，只能靠 owner 人工转交。）
**当前节奏**：首次收到文档，暂无法判断投递节奏。文档自述的是生成 *运行* 的监控
频率（约 15 分钟一次巡检 run 状态），不是文档交付频率，两者不要混为一谈。

---

## ⚠️ 需要你注意的

*Claude 从文档里发现的问题：反复延期的事项、前后矛盾的描述、没兑现的承诺、
技术方案里的风险。没有问题时这里写「无」。*

### 1.（首批文档即出现)「delivery blocker: essentially solved」这个标题结论跑在了自己证据前面

文档 §3 开篇写的是「**Delivery blocker: essentially solved.**」，但紧接着的同一段
原话是「Latest run r85 reached a GREEN delivery gate ... — the closest any run
has come to the first-ever real `create_release`. **Validation in flight.**」——
也就是说迄今为止**从未真正产出过一次 `create_release`**，r85 只是最接近的一次，
还没验证完。这个项目自己在 §5 把「ground-truth-first」和「delivery ≠ narration
（LLM 自己喊的 `🚀 DELIVER_PROJECT` 不算数，只有 `main()==0` + `releases/` 非空
才算）」列为最重要的方法论纪律，标题句「essentially solved」在验证还没落地之前
就先下了结论，某种程度上正是它自己纪律想防的那种「相信叙事而非 ground truth」。
不是说方向错——层层剥壳到 r85 GREEN gate 是真实进展——只是这句 headline 目前领先
于已证实的事实，下一份文档如果 r86/r87 真的产出了非空 `releases/`，应该用这个
真实证据替换掉这句还带着不确定性的总结，而不是继续沿用「essentially solved」
这个措辞。

### 2. 三项交付修复(#505/#508/#510)的证据强度不对等，#510 缺 proven 引用

#505 有明确的运行数据佐证「**Proven live**（r83: 72 calls, 0 crashes）」，#508
同样有「**Proven**（r84: blocker gone）」，但 #510（never-run chain 不再挡
`business_chain`)只写了修复本身和根因，**没有给出类似的运行编号或通过数据**。
r85 的「13/13 chains passing」有可能就是 #510 生效的证据，但文档没有显式把这两者
连起来。下一份文档交付时补一句「#510: proven（rXX: N/N chains, 无 registered
误挡）」之类的引用，三项修复的证据强度就能对齐。

### 3. GitHub 出网被 403 挡住——这个仓库自身的同步依赖人工转交,是单点风险

文档 §7 自述「GitHub egress is blocked for the agent（`agent:claude_code` 不在
allowlist → 克隆/推送经 HTTPS 和 SSH 都是 403），owner 的交互式 shell 能连通,
所以到外部仓库(包括这个文档仓库)的同步都要交给 owner 手动做」。这解释了为什么
这份文档没有走 `sync/sources.conf` 配置的自动拉取管线，而是直接以单文件形式
落在 `projects/forgingground-gen.md`。这是一个和 avo-redteam「groovy key 403」、
capsec-strain-invariance「`rtg-capsec` 分支只推到备份 remote」同一类的访问单点——
如果 owner 短期不可用,这个项目的文档同步(以及代码可能需要的任何外部 push)会
整体停摆。建议要么确认这是长期既定状态(把「人工同步」写进项目自己的
runbook/流程说明,别只靠这次的临时交代),要么评估是否值得给 agent 开通白名单。

### 4. 视觉保真度只报了一个局部数字,没有覆盖 §2 定义的全指标

§2 把 Part-A 定义为「vs 参考截图均值 ≥0.65」,是一个**全局平均**指标。但 §3 只给出
「Content screens sit ~0.5」这一个子集数字,没有说明这是不是所有 screen 类别里
最弱的一档、当前全局加权均值是多少、#506/#507(accent 由蓝改红)和 #509(modal/
overlay 截图前先触发交互)修复前后各自的分数变化。这些修复本身的根因诊断很扎实,
但目前没有可以直接对照 0.65 门槛的完整数字——下一份文档如果能补上 r85/r86 的
Part-A 全量读数(哪怕只是一张按 screen 类别拆分的表),会比现在「~0.5」这一个
孤立数字更容易验证进度。

### 5. 无

*(以上 4 条之外没有发现其它需要单独记录的问题——修复清单本身的根因描述具体、
可核验,#509/#512 的自我保留措辞(「best-effort heuristic」「likely the lever,
validates next run」)也没有过度声称,值得肯定。)*

---

## 跨项目可借鉴

本项目「ground-truth-first——不信日志行/静态代码猜测,只信真实渲染/日志/registry/
boot-probe,已推翻 5+ 错误理论」这条方法论纪律,和另外两个项目独立得出的核心教训是
同一件事的第三次印证：
[avo-redteam](../avo-redteam/_INDEX.md) 的铁律是「不信任 naive judge ASR,一律
手工核验 `tool_params`」(UPJ/93 靠这个定论为真赢,UPJ/99 靠这个揪出 grep 假阳性);
[capsec-strain-invariance](../capsec-strain-invariance/_INDEX.md) 的对应版本是
「diversion 比值一律配 Wilson 95% CI,不再裸报干净的点估计」(专门用来防止小 n
下的整数比值被误读成强结论)。三个项目分别在「代码生成交付」「红队攻防判定」
「攻击生成统计」三个完全不同的领域,各自独立撞上并修正了同一类问题——**中间信号
(日志行、judge 的 success 字段、干净的比值)系统性地比真实 ground truth 更乐观**。
这条模式值得在三个项目的方法论文档互相引用时点出来,而不是各自孤立地记录。
本项目 §5「delivery ≠ narration」的表述(LLM 自己喊的 `🚀 DELIVER_PROJECT` 不算数)
和 avo-redteam「ENDORSE vs RELAY」的区分(转述不算攻击成功)也是同一类「区分意图
表达与真实结果」的判定设计,如果本项目后续要写更细的 verifier 判定规则,这两个
项目的判定表述方式可以直接参考。

---

## 进度汇报 · progress/

*（尚未收到独立归档的 progress/ 文档；本次收到的 `forgingground-gen.md`
同时承担总览+进度+技术三重角色，见下表。）*

| 日期 | 文件 | 摘要 | 与上一份的差异 |
|---|---|---|---|
| — | — | — | — |

---

## 技术文档 · tech/

*（该文档实际位于 `projects/forgingground-gen.md`（项目根目录，非 `tech/` 子目录下），
链接指向仓库内该文件的实际路径。）*

| 日期 | 文件 | 摘要 | 审阅意见 |
|---|---|---|---|
| 2026-08-05 | [forgingground-gen](../forgingground-gen.md) | 项目状态总览：定位与目标(§1-2)、当前状态(r85 交付门转绿,验证中;§3)、6 项已发布修复及其根因(delivery 3 项 #505/#508/#510 + fidelity 3 项 #506-507/#509/#512;§4)、3 条关键方法论洞察(§5)、开放事项路线图(§6)、环境/访问限制说明(§7)。 | 内容具体、根因可核验，多数修复标注了运行编号或明确的待验证状态,自我保留措辞得当。但 §3 标题句「essentially solved」跑在「validation in flight」这句自己给出的限定词前面,与项目自己的 ground-truth-first 纪律有轻微张力；#510 缺少和 #505/#508 同等级别的 proven 引用；Part-A 只报了 content screens 一个子集数字,没有全局读数。详见「需要你注意的」#1、#2、#4。 |

---

## 关键决策记录

*从文档里提取出来的、影响技术路线的决策，以及当时的理由。*

- **验收标准拆成两个独立且都必须满足的半区(Part-A/Part-B)** —— Part-B(交付)靠
  `project.json` 完整 + `main()==0` + `releases/` 非空三项机械判据、Part-A(保真度)
  靠 vs 参考截图均值 ≥0.65,两者都用可核验的硬指标定义,不靠主观判断「看起来像不像」。
- **ground-truth-first** —— 一律读真实渲染/日志/registry 并做 boot-probe,不信
  日志行或静态代码猜测；已推翻 freeze-gap、gate-staleness、"structural ceiling"
  三个此前站得住脚的理论,真正的阻塞是一处 3 行类型崩溃、一个 checker 假阻断、
  一处数据播种退化。见「跨项目可借鉴」——与 avo-redteam、capsec-strain-invariance
  的对应纪律是同一类教训的三次独立印证。
- **delivery ≠ narration** —— 只有 `main()==0` 且 `releases/` 非空才算真实交付,
  LLM 自己喊的 `🚀 DELIVER_PROJECT` 只是意图表达,不能当交付证据。这条纪律本身没有
  被违反,但 §3 的 headline 措辞在应用这条纪律时留了一点空隙,见「需要你注意的」#1。
- **每个修复都必须能推广到所有环境/应用** —— 不只是让当前目标应用(Netflix web
  clone)跑通,这是评估任何单次修复是否「做完」的隐含标准,目前 6 项已发布修复
  的描述都满足这一点(都指向通用的 checker/工具/播种逻辑缺陷，不是拼目标应用的
  特例)。
