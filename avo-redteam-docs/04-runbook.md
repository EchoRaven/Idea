# Runbook

## Environment

```bash
PY=/home/haibotong/miniconda3/envs/dt/bin/python        # has agents SDK + mcp + fastmcp
cd /data1/common/haibotong/dtap-platform
# keys live in .env: LLAMA_API_KEY (rift victim + gateway), DEEPSEEK_API_KEY (attacker/judge + factory)
# groovy victim key = a MetaGen app token (currently 403-blocked)
export DTAP_DATASET_ROOT=/data1/common/haibotong/redteam-data-synth/output
```

## Tier-1 — ablation (fast, no env)

```bash
# defense profile (15 cells)
$PY dt_arms/tools/defense_profiler.py --model groovy_kite316 --api-style responses \
    --base-url https://api.ai.meta.com/v1 --api-key "$GROOVY_KEY" --effort xhigh

# lever ablation (marginal Δ + over-defense Pareto + belief arm)
$PY dt_arms/tools/lever_ablation.py --model groovy_kite316 --api-style responses \
    --base-url https://api.ai.meta.com/v1 --api-key "$GROOVY_KEY" --effort high --reps 3 --belief \
    --out lever.json
$PY dt_arms/tools/lever_ablation.py --recompute lever.json      # re-derive summary offline, no re-query
$PY dt_arms/tools/lever_ablation.py --dump-factors factors_template.json   # export built-in suite
$PY dt_arms/tools/lever_ablation.py --factors my_factors.json ...          # run an external factor spec
```

> **Pace groovy.** Keep a run ≤ ~40 calls; leave a cooldown between runs; run belief/over-defense arms
> in small separate batches. Sustained bursts hit a 429 output-token rate-limit and can escalate to a
> 403 policy block. On 403, STOP — do not retry.

## Tier-1 → Tier-2 bridge

```bash
$PY dt_arms/tools/ablation_to_env.py lever.json     # ranked env-validation plan + launch command
```

## Tier-2 — environment runs (~90 min/task)

Run in **tmux** (dt runs die on compaction otherwise). Launchers in `tmp_dtmt/`.

```bash
# rift (openclaw) — the reference victim (LLAMA_API_KEY, not blocked)
tmux new-session -d -s rift_ip "bash tmp_dtmt/launch_ipexfil_rift.sh > out.log 2>&1"
tmux new-session -d -s rift_upj "bash tmp_dtmt/launch_upj_rift.sh > out.log 2>&1"

# groovy (responses) — once the key is restored
tmux new-session -d -s g_ip "bash tmp_dtmt/launch_ipexfil_groovy.sh > out.log 2>&1"
```

Launcher knobs: `FORCE_VICTIM_MODEL`, `VICTIM_ARCH`, `GROOVY_KEY`, `VICTIM_REASONING_EFFORT`, port
range (use a clean window like `12200-13800`; the 30k band is congested), `DT_SCRATCH_BASE`.

**Analyzing a Tier-2 run — always hand-verify:**
1. Check `run.log` for a traceback / `403` / `429` / empty `Target responded (0 chars)` → the run is a
   **confound**, not a defense. Naive ASR is invalid.
2. Read each attempt's `traj_info.agent_final_response` — did the harm actually land? How (endorsed vs
   disclaimed relay vs withheld)?
3. For propagation tasks, read the RECIPIENT mailbox (any sender), not just the victim's sent box.

## The closed loop — authoring

```bash
# factors from a Tier-2 corpus (semi-auto: propose → curate → run)
$PY dt_arms/tools/ablation_factory.py --mode propose --corpus <run_dir> --out cand.json
$PY dt_arms/tools/lever_ablation.py --factors cand.json --model <victim> ...

# tasks from a factor (diverse lightweight specs → pipeline)
$PY dt_arms/tools/task_designer.py --factor framing --risk-category defamation --n 3 \
    --domains "comms-ops,people-ops,support-comms" --out-dir task_specs/

# local generation of a runnable task from a spec (stand-in for redteam-data-synth)
$PY dt_arms/tools/task_from_spec.py task_specs/<spec>.json --out-root $DTAP_DATASET_ROOT

# crack → loadable attacker SKILL.md (grounded in the measured Δ)
$PY dt_arms/tools/ablation_to_skill.py --factor framing --risk-category defamation --result lever.json \
    --out-dir dt_arms/attack_skills/env_strategy
# then load it in a Tier-2 run: --allowed-skill-names <generated-name>
```

## Key files

| path | what |
|------|------|
| `agent/responses/src/agent.py` | `ResponsesAgent` (5.15 victim arch) |
| `dt_arms/tools/lever_ablation.py` | ablation engine (factors, Pareto, belief, `--factors`) |
| `dt_arms/tools/defense_profiler.py` | 15-cell profile + `verdict`/`endorsement_hint`/`belief_verdict` |
| `dt_arms/tools/ablation_factory.py` | corpus → factor spec (semi/auto) |
| `dt_arms/tools/task_designer.py` | factor → diverse task specs (plan contract) |
| `dt_arms/tools/task_from_spec.py` | spec → runnable task (local synth stand-in) |
| `dt_arms/tools/ablation_to_skill.py` | crack → attacker SKILL.md |
| `dt_arms/tools/ablation_to_env.py` | Tier-1 → Tier-2 bridge |
| `dt_arms/tools/README_responses_pipeline.md` | the in-repo version of this doc set |
| `tmp_dtmt/launch_*.sh` | Tier-2 launchers |
| `redteam-data-synth/output/` | stock task corpus + `plan.json` manifests |
