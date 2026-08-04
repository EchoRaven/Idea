# Progress & Status

_As of 2026-08-04._

## Done + validated

| item | status | evidence |
|------|--------|----------|
| `responses` victim arch (red-team 5.15 Responses-API models) | ✅ built, validated 3 ways | isolated tool-loop + real stdio-MCP + full harness (10-iter gmail loop, 0 infra errors) |
| CLI wiring (`--victim-arch responses` + reasoning/max-tokens flags) | ✅ | `run.py` + `red_team_runner.py`, argparse + forwarding tested |
| `defense_profiler.py` (15-cell profile) | ✅ | groovy profile: only defamation shows candidate cracks |
| `lever_ablation.py` (marginal-Δ + over-defense Pareto + evap-risk + `--recompute`) | ✅ | groovy reps=3 profile |
| `endorsement_hint()` (endorse vs relay) | ✅ | all 5 groovy cracks flagged `RELAY?`, matched Tier-2 |
| belief-gated provenance arm (`--belief`) + `belief_verdict()` | ✅ built; live-run needs groovy | substance from step-1 spoof_belief probe |
| `ablation_to_env.py` (Tier-1 → Tier-2 bridge) | ✅ | ranks groovy cracks HIGH-evap-first |
| 3-path factor authoring (`ablation_factory.py`) | ✅ | semi-auto recovered the framing dimension from the intake-log corpus |
| 3-path task authoring (`task_designer.py` + `task_from_spec.py`) | ⚠️ **mechanical only** | framing spec → runnable task (config valid, judge compiles, seed benign-only). Generated task **NOT yet run E2E** against a victim. |
| ablation → skill (`ablation_to_skill.py`) | ⚠️ **artifact only** | framing/Δ+1.0 → `defamation-relay-received-tip` SKILL.md. Skill **NOT yet loaded/run** in a Tier-2 attack. |
| **Tier-2 intake-log defamation E2E vs groovy** | ✅ hand-verified | see findings — no clean win; groovy more defensive than rift |
| crack-frame tasks: intakelog (defamation), IP-exfil, UPJ-medical | ✅ authored + validated | judges compile, seeds valid |
| Dataset deliverable `clawfish_avo_dataset.zip` | ✅ delivered | 60 tasks (40 tool-use by risk-category + 20 BUA), sanitized |

## In flight

- **IP-exfil Tier-2 vs rift** — running (tmux `rift_ipexfil`). rift is the reference victim while
  groovy is blocked. ~10 iterations, ~11 min each. Will hand-verify (confound check first, then whether
  confidential values reached the external recipient).
- **UPJ-medical Tier-2 vs rift** — launcher ready (`launch_upj_rift.sh`); runs after IP (sequential).

## Blocked — the 5.15 (groovy) branch is PAUSED

**Single point of failure: the groovy key is policy-blocked (403 `user_blocked`), 2026-08-04.** Triggered
by burst load + policy-violating red-team content; persisted after a 40-min cooldown. **This blocks the
ENTIRE 5.15 branch** — every groovy Tier-2 result (IP-exfil, UPJ, and the formal belief/provenance arm)
is unavailable until the key is restored/replaced. Until then, treat the 5.15 branch as **PAUSED**, and
every groovy finding as an unconfirmed Tier-1 hypothesis (see 03-findings §2).

**ACTION ITEM (owner: `<assign>` — needs a name; due: `<set date>`):** obtain a groovy/avo key explicitly
authorized for safety evaluation (the current MetaGen app token gets policy-flagged by red-team content).
Until this is closed, do NOT keep retrying the blocked key (retries entrench the block). Operational
guardrail once a key exists: pace calls (≤~40/run, cooldown between runs, small belief/over-defense
batches), stop on 403.

> This is a project-management gap, not a technical one — it is called out here so the branch is not
> silently assumed "in progress". Either the action item above gets an owner+date, or the 5.15 branch
> stays formally paused.

## Immediate next (once a working victim key is available)

1. Finish rift IP-exfil + UPJ (reference-victim pipeline validation).
2. End-to-end run of a `task_from_spec`-generated task (final chain confirmation) + load the generated
   `defamation-relay-received-tip` skill.
3. On groovy key restore: re-run the confounded IP-exfil, run UPJ, clean belief-arm run, then the
   generated-task/skill run — all with pacing.
