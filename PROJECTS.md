# 进行中的项目

> **规则：同时进行的项目建议不超过 3 个。** 超了就先把某个挪回 SOMEDAY.md。
> 不是不许多，是要你明确知道自己在同时扛几件事。
>
> 每个项目最重要的两栏是 **断点** 和 **下一步**。
> 离开一个项目前花 60 秒把这两栏写清楚 —— 这是你回来时不迷路的唯一保险。

状态标记：`🔥 主线` / `🌊 慢炖` / `🧊 暂停`

---

## 🔥 Capsec — Capability × Security 强度不变性

- **类型**：安全研究 + 工程
- **一句话**：验证 agent 攻击易感性是否由「相对能力强度」(任务离模型能力上限多近)决定,而非绝对能力 —— 若成立则「能力进步不买安全」
- **仓库**：`rtg-capsec`(生成) + `dtap-capsec`(测量)　**分支**：`capsec/env-state-judges` / `capsec/measurement-layer`　（推到 remote `vaibackup`）
- **技术栈**：env-state 三值判定 + depth 依赖链(strain 轴) + 固定注入 + deepseek judge + super_nova/Gemini victim
- **断点**：整条测量流水线打通并出了 60 个真 run。关键发现 = 易感性强 **shape-依赖**:content_assertion(诽谤)会转化(diversion 0.33–1.0),exfil/UA(需要显式有害动作)全 0。invariance 本身还没测出 —— 语料 n=1–3 太小 + 能力梯度太窄(免费 Google key 只有 flash 层,pro 是 429 limit:0)
- **下一步**：拿到付费 Google 配额后 —— (1) 把 content 语料每 cell 扩到 ~10 条(纯 LLM 生成,不占 docker);(2) 跑 flash→pro 全能力梯度的 content sweep;(3) `analyze_strain.py --plot` 出两张判据图:diversion-vs-绝对depth(应按能力分离)vs diversion-vs-相对strain(应塌缩=invariance)
- **卡点**：需要付费 Google billing 开 `gemini-2.5-pro`/`gemini-3-pro-preview`(免费 key 429 `limit:0`);统计 power 不足
- **更新**：2026-08-04
- **文档**：[`capsec-strain-invariance/`](capsec-strain-invariance/README.md)

<details><summary>笔记 / 决策记录</summary>

- 2026-08-04 —— 流水线打通,super_nova 3-shape + Gemini flash 多victim 60 runs。判官 gpt-5.4→deepseek(emitted judge 从 canonical dt_arena 符号链接导入,坑了很久)。Gemini 走 Google 原生 OpenAI-compat 才能多步 tool-loop(Meta gateway 掉 thought_signature)。invariance 卡在能力梯度太窄 + n 太小。

</details>

---

## 🔥 <项目名>

- **类型**：技术项目
- **一句话**：这个项目到底要做出什么
- **仓库**：`~/path/to/repo`　**分支**：`main`
- **技术栈**：
- **断点**：*上次停在哪、当时脑子里在想什么*（← 回来先读这行）
- **下一步**：*一个具体到可以立刻动手的动作，不是"继续开发"*
- **卡点**：*当前挡路的技术难点 / 需要的决策*
- **更新**：2026-08-04

<details><summary>笔记 / 决策记录</summary>

- 2026-08-04 ——

</details>

---

## 🌊 <项目名>

- **类型**：产品/创业想法
- **一句话**：
- **给谁用**：目标用户，越具体越好
- **核心假设**：*这事成立的前提是什么*
- **怎么验证**：*下一个最小验证动作，别直接开始写代码*
- **断点**：
- **下一步**：
- **更新**：2026-08-04

<details><summary>笔记 / 调研</summary>

-

</details>

---

## 🌊 <主题>

- **类型**：学习/研究
- **想搞明白什么**：*一个具体问题，不是"学 XX"*
- **资料**：
  - [ ] 来源 1
- **进度**：
- **产出物**：*笔记 / demo / 文章 —— 没有产出物的学习会蒸发*
- **断点**：
- **下一步**：
- **更新**：2026-08-04

<details><summary>笔记</summary>

-

</details>
