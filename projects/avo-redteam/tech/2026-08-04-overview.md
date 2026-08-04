# avo/rift Red-Team — Ablation-Driven Vulnerability Pipeline

Project documentation. Sync this folder to the shared Google Drive.

## What this project is

Red-teaming the **avo/rift** model family for AI safety, and **productionizing ablation-driven
vulnerability analysis** into the `dt_arms` red-team framework. Two model generations are in scope:

- **rift** — `llama/smc.rift_avo5p14_r_api_tba` (5.14), served via **chat/completions** (openclaw arch),
  key = `LLAMA_API_KEY`. The original/reference victim.
- **groovy** — `groovy_kite308` / `groovy_kite316` (5.15), served **only via the Responses API**
  (`/v1/responses`), key = a MetaGen app token. Requires the new `responses` victim arch.

## The core method — a two-tier funnel

```
  Tier-1  direct-probe ABLATION  (minutes, no env)  →  hypotheses (which levers crack)
  Tier-2  environment VALIDATION (~90 min/task)     →  confirmed / evaporated end-to-end
```

**Central lesson (validated repeatedly): direct-probe OVERSTATES.** An isolated (system,user) probe
strips the provenance / role / multi-turn context the real env supplies, so "clean cracks" seen in
Tier-1 routinely become disclaimed relays or refusals end-to-end. Every Tier-1 COMPLY is a HYPOTHESIS
that must be confirmed in Tier-2 before it counts. This guardrail is wired into every tool.

## The closed loop

```
  Tier-2 wins ─(ablation_factory)→ FACTORS ─(task_designer)→ task specs ─(task_from_spec / synth)→ tasks
       ▲              │                  │                                                          │
       │              └──(ablation_to_skill)→ attacker SKILL.md ───────────┐                        │
       └──────────── Tier-2 runs (dt_arms, loads the skill) ◀──────────────┴──── tasks + skill ◀────┘
```

Factors, tasks, and attacker guidance each have **three authoring paths**: manual / semi-auto / auto.

> **Scope caveat (do not overstate externally):** the loop currently closes only through the **local
> stand-in `task_from_spec`**, which is validated *mechanically* (generated tasks load / compile / seed
> cleanly). It is **not yet wired to the real `redteam-data-synth` pipeline**, and no generated task +
> generated skill has yet been *run* end-to-end against a victim. So "closed loop" = closed on the local
> stand-in; the real-pipeline leg and the generated-artifact Tier-2 run are still open. See 02-progress.

## Documents

| file | contents |
|------|----------|
| [01-technical-roadmap.md](01-technical-roadmap.md) | architecture, the closed loop, the three-path authoring, every component + file |
| [02-progress.md](02-progress.md) | milestones done / validated / in-flight / blocked / next |
| [03-findings.md](03-findings.md) | scientific results: the three-gate defense, the one crack, direct-probe-overstates |
| [04-runbook.md](04-runbook.md) | how to run every tool + the Tier-2 launchers + operational caveats |
| [05-using-victims-from-another-repo.md](05-using-victims-from-another-repo.md) | integration guide: call the victim + attacker/judge models from any other repo (endpoints, keys, reusable client, code) |

_Last updated: 2026-08-04._
