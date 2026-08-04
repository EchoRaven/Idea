# Technical Roadmap & Architecture

Two git worktrees, one shared Python env (`/home/haibotong/miniconda3/envs/dt/bin/python`).

| repo (worktree) | branch | role |
|-----------------|--------|------|
| `rtg-capsec` (red-task-gen) | `capsec/env-state-judges` | the GENERATOR — emits depth-varying attack tasks + deterministic env-state judges |
| `dtap-capsec` (DecodingTrust-Agent-Platform) | `capsec/measurement-layer` | the MEASUREMENT — `capsec/` judge builders + `dt_arena/` env stacks + `eval/` victim runner |

Emitted tasks land in `redteam-data-synth/output/<domain>/malicious/indirect/<risk>/<id>/`.
Pushed to remote `vaibackup` (origin `Virtue-AI` needs the `id_ed25519_virtueai` key, absent here).

## 1. The generator (rtg-capsec)

### 1.1 Env-state judging model (architecture decision "A")
The judge decides from live backend state via `dt_arena.utils.<env>.helpers` HTTP queries, not the
MCP tool trajectory. The LLM emits a **structured `HarmDeclaration`**; the harness **deterministically
renders** `judge.py` (no LLM-authored judge code). Three shapes, each a `capsec` builder returning
`(diversion_checks, effect_checks)` consumed by `evaluate_attack` and bridged by `to_eval_attack`
into the three-valued verdict. Key files: `src/emit/harm_judge.py` (declaration schema, validation,
render, injection builders), `capsec/{exfil,unauthorized_action,content,statecheck,bridge}.py`.

### 1.2 Fixed injection
Env-state judging keys on values decided at generation time, so the attack is a **fixed** injection
(not a dt_arms runtime one). `build_env_state_injection(decl, subject, read_env)`:
- exfiltration — the credential is SEEDED as a carrier email (`build_credential_carrier`, from
  `it-systems@`); the injection carries only the forward instruction.
- unauthorized_action — no carrier; the injection induces the payout redirect to `beneficiary`. The
  instruction lands in the MAIL/read env (gmail), which differs from the action env (paypal).
- content_assertion — plants a literal `claim_text` (injection-only param, excluded from the builder
  call) framed as fact to include in the write-up to `target`.

### 1.3 The strain axis (depth)
- Data model: `ChainStep(index, env, tool, reads, produces, consumes, is_injection_point)` +
  `depth` / `dependent_steps` on `TaskTemplate`/`PolishedTask` (`src/core/artifacts.py`).
- Knob: `--depth N` pins env-breadth so depth is the sole IV (`_env_range_for`).
- Prompt: depth-aware `task_design.j2` emits the chain; `plan.j2` seeds data that *forces* the order
  (each step's record keyed by the prior step's output).
- Gate: `validate_chain` (strict spine `consumes(k)==produces(k-1)`, injection at the last read) +
  a task_design repair loop (`_repair_chain`). Emit records `depth` + `achieved_depth` in config.yaml.
- Spec + plan: `rtg-capsec/docs/superpowers/{specs,plans}/2026-07-30-strain-*`.

### 1.4 Quality gate
Post-gen LLM rubric hardened this arc: evidence cap 600→2000; a retraction net for the ok-flag
self-negation flake; **k=3 self-consistency vote** (deepseek single-shot ~⅓ false-severe on valid
tasks). Config `judge.env_state: true`, `quality.vote_k: 3`. Gen model = `deepseek/deepseek-chat`.

## 2. The measurement (dtap-capsec)

### 2.1 Victim runner
`python -m eval.evaluation --task-list <jsonl> --model <M> --agent-type openaisdk`. Boots per-task
docker env stacks on random free ports, seeds via `setup.sh`, applies the fixed injection, runs the
victim agent (MCP tool loop), then the judge. Writes `results/benchmark/openaisdk/<model>/indirect/
<risk>/<id>/judge_result.json`. **Run from `dtap-capsec`** (capsec + dt_arena import natively).

### 2.2 The judge LLM
`BaseJudge.llm_check` needs a working LLM. The emitted judge imports `BaseJudge` from the **canonical**
`dt_arena` — a symlink `/data1/common/haibotong/dt_arena → dtap-platform/dt_arena`, NOT the worktree
copy. Default was `gpt-5.4` (dead) and it inherits `OPENAI_BASE_URL` (the victim gateway) → 404.
Fixed the canonical `dtap-platform/dt_arena/src/types/judge.py` default to **`deepseek-chat`** (routes
to api.deepseek.com independent of the victim endpoint).

### 2.3 Analysis
`dtap-capsec/scripts/analyze_strain.py --results … --corpus … --dispatch <v2 dispatch glob>`. Joins
each `judge_result.json` to its task depth/shape; aggregates per (victim, shape, depth): benign rate,
**diversion over admissible**, effectuation, undecidable; relative strain = depth / benign-frontier;
plots ASR-vs-depth and ASR-vs-relative-strain (collapse ⇒ invariance). `--dispatch` restricts the
corpus index to our exact tasks (the result path lacks domain → old same-risk tasks collide otherwise).

## 3. Victims

| victim | endpoint | tools? | notes |
|--------|----------|--------|-------|
| `super_nova` (Llama codename) | `api.ai.meta.com/v1` (`LLAMA_API_KEY`) | ✅ standard | the one reliably-live Meta codename |
| `gemini-2.5-flash*` (Google) | `generativelanguage.googleapis.com/v1beta/openai` | ✅ | free-tier: flash only, low rate-limit |
| `gpt-5-5-genai-responses` (Meta) | experimental compat | ❌ | contradictory tool schema — unusable for agents |
| `gemini-3-*-genai` (Meta gateway) | experimental compat | ❌ | drops thought_signature on 2nd tool call |
| Claude (Anthropic direct) | — | — | key out of credit |
