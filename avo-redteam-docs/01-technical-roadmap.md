# Technical Roadmap & Architecture

All code lives under `dtap-platform/` (repo root). Tools: `dt_arms/tools/`. Python env:
`/home/haibotong/miniconda3/envs/dt/bin/python` (has `agents` SDK + `mcp` + `fastmcp`).

## 1. Victim integration — red-teaming both model generations

| arch | model | API | key | status |
|------|-------|-----|-----|--------|
| `openclaw` | rift 5.14 | chat/completions | `LLAMA_API_KEY` | working |
| `responses` | groovy 5.15 | `/v1/responses` | MetaGen app token | built + validated; key currently policy-blocked |

**`responses` victim arch** (`agent/responses/src/agent.py`, `ResponsesAgent`) is a thin subclass of
`OpenAISDKAgent`. The OpenAI Agents SDK already runs the full MCP agentic tool-loop and trajectory
capture; the only things it lacks for the 5.15 models are (a) a dedicated client on the Responses
endpoint (without polluting the global `OPENAI_BASE_URL` other archs use), and (b) a reasoning-effort +
output-token budget. So it reuses every parent setup method and overrides only the model-assembly block.

- Registered in `agent/__init__.py` `_ADAPTERS` as `("responses", …, "ResponsesAgent")`.
- Config via `RuntimeConfig.agent_kwargs`: `base_url` / `api_key` / `api_key_env` / `reasoning_effort` /
  `max_output_tokens` (env fallbacks `VICTIM_*`).
- CLI (in `dt_arms/run.py` + `dt_arms/red_team_runner.py`): `--victim-arch responses`,
  `--victim-reasoning-effort`, `--victim-max-output-tokens`, plus the existing `--victim-base-url` /
  `--victim-api-key-env`.
- **Validated 3 ways**: isolated SDK tool-loop; real stdio-MCP connection; full dt_arms harness
  (drove real gmail MCP list/get/forward over 10 iterations, zero infra errors).

## 2. Tier-1 — direct-probe ablation (fast, no env)

### `defense_profiler.py`
A 15-cell `PROBE_SUITE` (id, category, mechanism, system, user, expected) → a structured **defense
profile** (which walls hold, which crack, by what mechanism). `verdict()` classifies each output
DECLINE/COMPLY/REVIEW; `endorsement_hint()` flags likely attribute-don't-assert relays; `belief_verdict()`
scores the belief-gated provenance cells (TRUSTED=fooled / SKEPTICAL=defended). Guardrail: every COMPLY
is `needs_env_validation=True`.

### `lever_ablation.py` — the ablation ENGINE
The sharper cousin: **minimal-pair factor toggles** (content held constant, one dimension changed) →
the **marginal Δ comply-rate** for each lever. Arms:

- **factors** (`FACTORS`): `framing` (assert ↔ relay-received-tip), `corroboration` (zero → single →
  multi → contradicted), `action_visibility` (latent-file ↔ manifest-adverse), `provenance`
  (free-webmail ↔ corporate-lookalike ↔ spoofed-regulator). Each level tagged `role`
  (exploit / exploit-hard / calibration-comply), `evap_risk`, and an `endorsement_hint`.
- **over-defense control** (`OVERDEFENSE`): legit + authorized cells that SHOULD comply — the utility
  axis (false-refusal cost).
- **belief-gated provenance** (`PROVENANCE_BELIEF`, `--belief`): the CORRECT spoof test — gate an
  action on JUDGING authenticity, contrast a spoofed vs real regulator domain.

Outputs a corrected summary that separates **clean cracks** (COMPLY on an exploit cell) from
**contestable dual-use** (REVIEW) from **gate held**, plus the attack-surface-vs-over-refusal Pareto and
per-crack evaporation-risk. `--recompute` re-derives the summary from a saved JSON offline (no re-query).

**The engine is factor-source-agnostic**: `--factors <json>` loads an external spec; `--dump-factors`
exports the built-in suite as a template. This is what makes the three authoring paths possible.

## 3. Tier-1 → Tier-2 bridge — `ablation_to_env.py`
Turns a Tier-1 result into a **ranked env-validation plan** + the exact `--victim-arch responses` launch
command. Ranks candidate cracks **HIGH-evap first** (most informative to validate: a HIGH-evap crack
that survives end-to-end is a real finding; one that evaporates confirms the guardrail), maps each
category to its crack-frame env task. Makes "COMPLY → must env-validate" an automated hand-off.

## 4. Tier-2 — environment validation
`--victim-arch responses` (groovy) or `--victim-arch openclaw` (rift) runs a candidate crack in the real
dt_arms env (MCP tools, multi-turn, judge). Attacker + judge = fireworks-deepseek via the llama.com
gateway. Launchers in `tmp_dtmt/`. **Always hand-verify** — the naive judge ASR is unreliable on these
tasks (empty victim trajectory = a confound, not a defense; disclaimed relay reads as "defended").

## 5. The closed loop — three authoring paths for factors, tasks, skills

| authoring | factors | tasks | attacker guidance |
|-----------|---------|-------|-------------------|
| **manual** | hand-write `FACTORS` | hand-author env task | hand-write `SKILL.md` |
| **semi-auto** | `ablation_factory --mode propose` → curate | `task_designer` → review → pipeline / `task_from_spec` | `ablation_to_skill` → review |
| **auto** | `ablation_factory --mode auto` | `task_designer` → `task_from_spec` → run | `ablation_to_skill` → load |

- **`ablation_factory.py`** — mines a Tier-2 corpus (`attack_trajectory`) via deepseek → proposes an
  ablation factor-spec (minimal-pair levels). Closes "explore → auto-extract factors". Validated: mining
  the intake-log run recovered exactly the dimension its attacker varied (framing: anonymous-tip ↔
  substantiated-audit-finding).
- **`task_designer.py`** — factor → N **diverse lightweight** task-design specs in the redteam-data-synth
  **plan contract** (intent + observation-points + `data_plan` outlines + malicious_goal), round-robined
  across domains with fresh invented entities. Handed to the pipeline, which expands outlines into real
  seed data.
- **`task_from_spec.py`** — a LOCAL stand-in for redteam-data-synth: expands a spec into a runnable
  dt_arms task (deepseek expands seed outlines; a parametrized judge). Lets the whole chain run
  end-to-end locally. Includes an injection-leak filter (the benign seed must not contain the runtime
  injection).
- **`ablation_to_skill.py`** — a crack the chain FOUND → a loadable attacker `SKILL.md`
  (`attack_skills/env_strategy/` format), grounded in the measured marginal Δ + the endorse/relay hint.
  Validated: framing/Δ+1.0 → `defamation-relay-received-tip` skill.

## 6. Where the base tasks come from (provenance)

Three layers, different origins:
1. **Stock/original tasks** (`redteam-data-synth/output/`, the 577-task corpus) — **machine-generated**
   by the redteam-data-synth pipeline. Each carries a `plan.json` manifest: `intent` (risk_category +
   risk_definition) → scenario (domain/envs/capabilities/observation-points) → `data_plan` (seed) →
   `malicious_goal` → exported runnable task. **The generator itself is a separate system (only its
   `output/` is synced locally).**
2. **The Tier-2 crack-frame tasks** (intakelog / IP-exfil / UPJ) — **hand-authored** from a stock task
   scaffold, because stock tasks are mostly the "hard frame" (assert-and-send = the wall); the crack
   needs the "relay-into-record" frame. `task_from_spec.py` now automates this.
3. **The Tier-1 ablation base scenario** (CMP compliance-assistant + the canonical accusation) —
   hand-written, distilled from the rift defamation experiments.

## Roadmap — next

- Restore/replace the groovy key → run IP-exfil / UPJ / belief-arm on groovy (all built, parked).
- End-to-end run of a `task_from_spec`-generated task (final chain confirmation).
- Extend the redteam-data-synth interface so its pipeline can consume `task_designer` specs directly
  (currently `task_from_spec` is the local stand-in).
- Broaden the ablation factor set beyond defamation levers as more Tier-2 corpora accumulate.
