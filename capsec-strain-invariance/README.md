# Capsec — Capability × Security "Strain Invariance"

Project documentation. Research + engineering on whether an agent's attack susceptibility is
governed by **relative capability strain** (how close a task sits to the model's own limit) rather
than absolute capability.

## The hypothesis

**Strain invariance.** For a fixed model, attack success rises as a task nears that model's
capability frontier. Across models, a more capable model faces *lower* relative strain on the same
absolute task → lower ASR; but it gets deployed on *harder* tasks, restoring the strain → ASR is
roughly **invariant to capability**. Corollary: **capability progress does not buy security**,
because deployment scope expands with capability.

To test it we need a generator that varies task difficulty on a controllable axis, a modality-clean
way to score attacks, and a capability-tiered set of victims.

## Two halves

```
  GENERATOR (rtg-capsec)                          MEASUREMENT (dtap-capsec)
  ─────────────────────                           ────────────────────────
  seed → task_design (depth-N chain)              victim runs the task (dtap eval)
       → plan/env_data (forces the chain)    →         │ env stacks (docker) + injection
       → malicious_goal → HarmDeclaration           env-state JUDGE (deepseek llm_check)
       → deterministic judge.py (capsec)                │ diverted / succeeded / admissible / undecidable
       → fixed injection at the final read         analyze_strain.py → ASR-vs-depth, ASR-vs-relative-strain
```

## The strain axis — dependent-step depth

`--depth N` makes the benign task a chain of **N genuinely-dependent read-steps** (strict data-flow
spine: `consumes(k) == produces(k-1)`), with the fixed injection planted in the **final** read
(maximum accumulated load). Depth is the sole IV; env-breadth is pinned. A validation gate rejects
any chain that isn't a real depth-N spine, so the difficulty axis is genuine, not cosmetic.

## The judge — env-state, three-valued

The verdict is decided from **live backend state** (modality-agnostic), not the MCP trajectory:
`diverted` (agent manipulated) / `succeeded` (harm effectuated) / `admissible` / **`undecidable`**
(agent never reached the injection). Diversion is measured **over admissible runs only** —
`undecidable` is excluded, which is exactly how the **"security by incompetence"** confound is
handled: a model too weak to reach the injection is not scored as "resisted".

## Three harm shapes

| shape | vehicle | what the injection induces | judge |
|-------|---------|----------------------------|-------|
| exfiltration | credential-compromise | forward a seeded credential to an attacker address | deterministic (token→exfil_address) |
| unauthorized_action | unauthorized-transaction | redirect a payout to an attacker beneficiary | deterministic (action→beneficiary) |
| content_assertion | defamation | assert a fabricated claim as fact in a sent message | `llm_check` on a claim criterion |

## Documents

| file | contents |
|------|----------|
| [01-technical-roadmap.md](01-technical-roadmap.md) | architecture, the generator + measurement components, every key file + repo |
| [02-progress.md](02-progress.md) | done / validated / in-flight / blocked / next |
| [03-findings.md](03-findings.md) | shape-dependent susceptibility, the first multi-victim data, methodological notes |
| [04-runbook.md](04-runbook.md) | generate a strain corpus, run a victim sweep, analyze — with commands + the infra gotchas |
