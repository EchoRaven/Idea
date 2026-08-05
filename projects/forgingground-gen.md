# forgingground-gen · One-Shot App-Generation Pipeline

> Project owner: haibotong (+ claude_code agent)
> Status: **Active** · Last updated: 2026-08-05
> Repo (code): `/home/haibotong/forgingground-gen` (this box is code-only — generation runs happen here)

---

## 1. What this project is

**forgingground-gen** turns a product *contract* into a complete, runnable full-stack app —
deterministically-projected **FastAPI + Postgres + React (Vite)**, orchestrated by a team of
LLM agents (orchestrator, design-analyst, frontend/backend engineers, verifier, browser
test-user squad) running on podman + podman-compose.

My work on it is a **pipeline-hardening effort**: make it reliably **one-shot** generate a
*complete, bug-free* app whose *UI is near-identical to the reference design* — with **no
human intervention**, and with every fix **generalizing to all environments/apps**, not just
one target (current target: a Netflix web clone).

## 2. Objective (the bar)

A single run must satisfy **both**:

| Half | Definition (operationalized) |
|------|------------------------------|
| **Part-B — Delivery** | `project.json` complete · `[main-exit] main() returned 0` · non-empty `releases/` (a real `create_release`, not the LLM's `🚀 DELIVER_PROJECT` narration) |
| **Part-A — Fidelity** | Visual-fidelity avg **≥ 0.65** vs the reference screenshots |

**Discipline that governs the work:** *ground-truth-first* — read the actual render / log /
registry / generated code and boot-probe the app, never trust a log line or static code guess.
This method has overturned **5+ wrong theories** and is the single biggest reason progress is
now real.

## 3. Current status (2026-08-05)

- **Delivery blocker: essentially solved.** The true first-delivery blockers were found and
  fixed (see §4). Latest run **r85** reached a **GREEN delivery gate** (0 blockers, 15/15
  endpoints, 12/12 ui_flow, 13/13 chains passing, visual passed) — the closest any run has come
  to the first-ever real `create_release`. Validation in flight.
- **Fidelity: on the path to 0.65.** Content screens sit ~0.5; the dominant lever (identical
  repeated poster on every card) was root-caused and fixed (#512) — validates next run.
- **Run trajectory** (each run peeled one blocker layer): r79 build-wedge → r80 stale checklist
  → r81 browser-gate false-block → r82 `deliver_project` crash → r83 `bare_authed_fetch`
  false-block → r84 never-run-chain gate → **r85 green gate (delivery imminent)**.

## 4. Shipped fixes (all ground-truth-rooted, unit-tested, generalizable)

### Part-B — Delivery
| # | Fix | Root cause (from ground truth) |
|---|-----|--------------------------------|
| **#505** | `deliver_project` coerces a string `checklist` → dict | The tool crashed on a JSON-string checklist (`'str' has no .get`) on *every* deliver attempt → no release though the app was fully deliverable. **Proven live** (r83: 72 calls, 0 crashes). |
| **#508** | `bare_authed_fetch` excuses ES6 shorthand `{ headers }` | The checker false-blocked a *correct* app that attaches auth via `fetch(url, { headers })` → `main()=1`. **Proven** (r84: blocker gone). |
| **#510** | Never-run (`registered`) chains don't block `business_chain` (with a ≥1-passing guard) | The verifier re-authored chains at the deliver tail that never ran → `business_chain_failing` forever → milestone never cleared → `main()=1`. |

### Part-A — Fidelity
| # | Fix | Root cause |
|---|-----|-----------|
| **#506 / #507** | Accent resolves to the vivid brand color across both the inline and Tailwind-token paths | Every CTA rendered **blue**, not brand-red — the analyst mis-recorded a link-blue as `accent`. |
| **#509** | Visual capture drives modal/overlay interactions before screenshotting | Overlay screens (rate_dialog, account_menu, card_hover) scored a floor because route-capture never opens the modal. *(Best-effort heuristic + safe fallback; a fully-robust version needs the design-analyst to record explicit per-overlay triggers.)* |
| **#512** | Distribute distinct real staged posters/backdrops over degenerate catalog seed rows | All 30 titles shared **one** repeated crop image → every rail looked like placeholders, while 60 real posters sat unused. Likely **the** lever from ~0.52 → 0.65 on content screens. |

## 5. Key insights

1. **Ground-truth-first beats theorizing** — reading the real render/log/registry overturned
   the freeze-gap (R1), gate-staleness (R2), and "structural ceiling" theories; the real
   blockers were a 3-line type crash, a checker false-block, and a data-seeding degeneracy.
2. **The deliver tail is a layered onion** — each fix exposes the next-innermost blocker. #505
   → #508 → #510 each removed one wall; the current innermost is deliver-tail *convergence*.
3. **Delivery ≠ narration** — the LLM's `🚀 DELIVER_PROJECT` is intent; only `main()==0` +
   non-empty `releases/` is real. This distinction caught several false "delivered" reports.

## 6. Roadmap / open levers

- **[in flight] r85 → first real delivery** — validate #505/#508/#510 end-to-end; measure Part-A.
- **[next] #512 validation (r86)** — confirm the varied real poster wall lifts content-screen fidelity toward 0.65.
- **[open] #511 — checklist "record-the-truth"** — if `verification_checklist_not_ready` recurs (stale `build:*`=failure despite a passing api_smoke run), directly re-record build success rather than the current reset-and-hope re-run.
- **[deep] task#47 — deliver-tail convergence / token efficiency** — the squad over-files, tasks oscillate, `deliver_project` retry-churns; make the tail converge cleanly instead of grinding to a bounded escape.
- **[deep] Part-A structural** — per-screen layout/copy/imagery beyond palette + posters (landing poster-mosaic, section copy, header chrome).

## 7. Environment notes

- This host is **code-only**; generation runs are launched here and monitored ~15-min cadence.
- **GitHub egress is blocked for the agent** (`agent:claude_code` not allowlisted → 403 on
  clone/push over HTTPS *and* SSH); the owner's interactive shell can reach it, so syncs to
  external repos (like this one) are handed off to the owner.
- Providers: vertex proxy `:8790`, relay `:19080`. Base images pulled via the internal VMVM
  mirror with the proxy unset.
