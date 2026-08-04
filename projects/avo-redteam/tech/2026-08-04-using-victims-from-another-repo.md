# Using the victim models (and attacker/judge models) from another repo

A self-contained integration guide: how any other project can call the avo/rift victim models and the
attacker/judge models. **No secrets here** — only env-var names; put the real keys in that repo's own
`.env` (and keep this + the keys private: these are internal models).

## 1. The models and their roles

| model | role | API style | endpoint | key (env var) | status |
|-------|------|-----------|----------|---------------|--------|
| `smc.rift_avo5p14_r_api_tba` (rift 5.14) | **victim** | chat/completions | `https://api.ai.meta.com/v1/chat/completions` | `LLAMA_API_KEY` | working |
| `groovy_kite316` / `groovy_kite308` (5.15) | **victim** | **Responses** | `https://api.ai.meta.com/v1/responses` | MetaGen app token (`LLM\|...`) | **403 policy-blocked (2026-08-04)** |
| `fireworks-deepseek-v4-pro` (deepseek) | attacker / judge | chat/completions | `https://api.llama.com/experimental/compat/openai/v1` | gateway `LLAMA_API_KEY` | working |
| `deepseek-chat` (deepseek direct) | attacker / judge / tooling | chat/completions | `https://api.deepseek.com` | `DEEPSEEK_API_KEY` | working |

Notes:
- The two victims live on the **same host** (`api.ai.meta.com`) but need **different API styles** and
  **different keys**. rift = chat/completions + `LLAMA_API_KEY`; groovy = Responses API + a MetaGen app
  token. Don't cross them (groovy on chat/completions returns "Invalid model name").
- The victims are **heavy reasoners** — allow a large `max_tokens`/`max_output_tokens` (≥6000) or they
  truncate into reasoning-only with empty content.
- **Pace groovy**: sustained bursts hit a 429 output-token rate-limit and can escalate to a 403 policy
  block. Keep runs small, cool down between them, stop on 403.

## 2. The reusable client (recommended)

The simplest path: copy **`dt_arms/tools/victim_client.py`** (~80 lines, stdlib only) into your repo. It
exposes ONE `query(system, user)` for both API styles, so your code is victim-agnostic:

```python
from victim_client import VictimClient, VictimConfig

# rift (chat/completions)
rift = VictimClient(VictimConfig(
    model="smc.rift_avo5p14_r_api_tba", api_style="chat",
    base_url="https://api.ai.meta.com/v1", api_key=os.environ["LLAMA_API_KEY"],
    max_output_tokens=6500))
print(rift.query("You are a helpful assistant.", "Say hi."))

# groovy (Responses API)
groovy = VictimClient(VictimConfig(
    model="groovy_kite316", api_style="responses",
    base_url="https://api.ai.meta.com/v1", api_key=os.environ["GROOVY_KEY"],
    reasoning_effort="high", max_output_tokens=6500))
print(groovy.query("You are a helpful assistant.", "Say hi."))
```

It handles retries, reasoning-effort, and pulling the final text out of each API's response shape.

## 3. Raw HTTP (if you don't want the client)

**rift — chat/completions:**
```python
import json, urllib.request, os
body = {"model": "smc.rift_avo5p14_r_api_tba",
        "messages": [{"role":"system","content": SYS}, {"role":"user","content": USER}],
        "max_tokens": 6500}
req = urllib.request.Request("https://api.ai.meta.com/v1/chat/completions",
        data=json.dumps(body).encode(),
        headers={"Authorization": f"Bearer {os.environ['LLAMA_API_KEY']}", "Content-Type":"application/json"})
j = json.load(urllib.request.urlopen(req, timeout=200))
m = j["choices"][0]["message"]
text = (m.get("content") or "").strip() or ("[reasoning-only] " + (m.get("reasoning_content") or ""))
```

**groovy — Responses API:**
```python
body = {"model": "groovy_kite316", "instructions": SYS, "input": USER,
        "reasoning": {"effort": "high"}, "max_output_tokens": 6500}
req = urllib.request.Request("https://api.ai.meta.com/v1/responses",
        data=json.dumps(body).encode(),
        headers={"Authorization": f"Bearer {os.environ['GROOVY_KEY']}", "Content-Type":"application/json"})
j = json.load(urllib.request.urlopen(req, timeout=200))
text = next(p["text"] for o in j["output"] if o.get("type")=="message"
            for p in o["content"] if p.get("type") in ("output_text","text"))
```

**deepseek (attacker/judge) — OpenAI-compatible chat/completions:**
```python
# direct:
body = {"model":"deepseek-chat","messages":[{"role":"system","content":SYS},{"role":"user","content":USER}],"max_tokens":4000}
url, key = "https://api.deepseek.com/chat/completions", os.environ["DEEPSEEK_API_KEY"]
# OR via the llama.com gateway: model "fireworks-deepseek-v4-pro",
#    url "https://api.llama.com/experimental/compat/openai/v1/chat/completions", key = gateway LLAMA_API_KEY
```

## 4. If the other repo runs agentic MCP tasks (dt_arms-style)

If it needs the victim to run a **tool-loop in an environment** (not just a single call), it can use the
dt_arms victim-agent architecture:
- rift → `--victim-arch openclaw --victim-model llama/smc.rift_avo5p14_r_api_tba` (note the `llama/`
  litellm prefix here; the raw API model name drops it).
- groovy → `--victim-arch responses --victim-model groovy_kite316 --victim-base-url https://api.ai.meta.com/v1
  --victim-api-key-env GROOVY_KEY --victim-reasoning-effort high --victim-max-output-tokens 6500`.

The `responses` arch is `agent/responses/src/agent.py` (`ResponsesAgent`, a thin subclass of the OpenAI
Agents SDK agent). Copy `agent/responses/` + register it in that repo's agent registry, or just reuse
`victim_client.py` for non-agentic calls.

## 5. Keys — where they come from

Put these in the other repo's `.env` (never commit real values):

```
LLAMA_API_KEY=...        # rift victim (chat/completions) AND the deepseek gateway
GROOVY_KEY=...           # MetaGen app token for groovy Responses API  (LLM|<appid>|<secret>)
DEEPSEEK_API_KEY=...     # deepseek direct (attacker/judge/tooling)
```

Get them from the same place this project's `.env` holds them. The MetaGen groovy token is the one that
gets policy-flagged by red-team content — for sustained safety-eval use, request a key explicitly
authorized for evaluation.

## 6. Gotchas (learned the hard way)

- **Empty response ≠ refusal.** If a victim call returns empty/short, it usually errored (429/403) or
  truncated (reasoner ran out of output budget) — check the HTTP status and raise `max_tokens`, don't
  read it as "the model defended".
- **groovy Responses only.** chat/completions on a 5.15 model → "Invalid model name".
- **rift content may be in `reasoning_content`** when `content` is empty on short prompts.
- **Rate-limit/policy-block on the MetaGen token** under burst; pace and stop on 403 (retries entrench
  the block).
