# Progress & Status

_As of 2026-08-04._

## Done + validated

| item | status | evidence |
|------|--------|----------|
| Env-state generator, 3 harm shapes | ✅ end-to-end | exfil/UA/content each: valid declaration → deterministic judge → fixed injection → k=3 quality gate; pilots quality-clean |
| Quality gate hardening | ✅ | evidence cap 600→2000; ok-flag retraction net; k=3 vote drops valid-task false-severe ~⅓→~0 |
| **Strain axis (`--depth N`)** | ✅ TDD + live | 8-task plan; `validate_chain` strict spine; depth-1/2/4 sweep re-validates, `achieved==target`, quality-clean; depth-4 chain genuinely dependent (invoice_id→doc_id→vendor_ref→email) |
| Strain corpus v2 | ✅ | 3 shapes × depth{1,2,4,6,8} × 3, **0 chain-failures** (deep chains at 6/8 all valid); benign eval_task env-state fix in 38/40 |
| **Measurement loop** | ✅ proven E2E | `super_nova` ran a depth task → docker stacks → seed → inject → agent tool-loop → env-state judge → `judge_result.json` with `diverted/succeeded/admissible/undecidable` |
| Judge-LLM fix | ✅ live | canonical `dt_arena` (symlink→dtap-platform) `BaseJudge` default gpt-5.4→deepseek-chat; task-28 benign now `True`, 0 judge-404s across 40 clean runs |
| `analyze_strain.py` | ✅ | joins results→depth via `--dispatch`; diversion-over-admissible, relative-strain, plots |
| super_nova full 3-shape sweep | ✅ 40 runs | exfil/UA diversion=0 everywhere; content diversion 0.33–1.0 (see findings) |
| Gemini victim works | ✅ | native Google OpenAI-compat handles the multi-step tool loop (no thought_signature error); judge stays on deepseek independent of victim endpoint |
| First **multi-victim** content data | ✅ 60 runs total | super_nova + gemini-2.5-flash(10/15) + gemini-2.5-flash-lite(10/15) |

## In flight

- Nothing running. Last completed: throttled Gemini flash-tier content sweep (max-parallel 1).

## Blocked

- **Victim ladder is narrow.** The invariance *claim* needs a WIDE capability gap (flash→pro). The
  Google key is **free-tier**: only flash-tier models have (low, rate-limited) quota — `gemini-2.5-pro`
  and `gemini-3-pro-preview` return 429 `limit: 0`. `super_nova` is the only reliably-live Meta codename;
  frontier Meta models have tool-compat walls; Anthropic is out of credit. → **need paid Google billing
  (or a paid key) to open the pro tier.**
- **Underpowered.** n=1–3 per cell; no clean strain trend resolvable. Needs a bigger corpus per cell.

## Immediate next (once a wide-ladder key is available)

1. **Scale the corpus** for statistical power (larger `--count` per cell; docker-free gen). Focus on
   `content_assertion` — the only shape with non-zero diversion, so the only place strain is measurable.
2. **Run the full flash→pro Gemini ladder** on the content corpus (both arms across all depths).
3. `analyze_strain.py --plot` → the two decisive plots: diversion-vs-**absolute depth** (should
   separate by capability) vs diversion-vs-**relative strain** (should collapse ⇒ invariance).
4. Add a clean no-injection **benign arm** for a trustworthy per-victim frontier (currently the benign
   rate comes from the injected run, which conflates incompetence with being diverted).
