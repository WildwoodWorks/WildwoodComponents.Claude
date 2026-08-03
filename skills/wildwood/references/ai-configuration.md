# AI Configuration — field-tested knowledge

Operational knowledge from taking a chat assistant live in production (SiteDataBridge,
2026-08). Read this before creating AppAIConfigurations, wiring the AI relay, or debugging
"the config exists but chat 400s / the config is invisible in WildwoodAdmin".

## Rule #1: the relay routes by MODEL NAME, not by the linked provider

WildwoodAPI infers the provider from the model string (`ModelProviderMap`):

| Model prefix | Routed provider |
|---|---|
| `gpt-*`, `dall-e*`, `o1-*`, `o3-*` | openai |
| `claude-*` | anthropic |
| `gemini-*` | google |
| `*mistral*` | mistral |
| `deepseek-*` | deepseek |
| `llama-*` | meta |
| anything else | openai (default) |

A configuration whose **model implies a different provider than its linked CompanyAIProvider
can never work** — the turn goes to the model-implied provider carrying the linked provider's
key. Observed failure signatures:

- No key for the model-implied provider →
  `"API key not configured for openai provider required by model gpt-4o"`.
- Key exists but belongs to the other provider → the upstream rejects it, e.g. OpenAI 401
  `invalid_api_key` complaining about an `sk-ant-…` key.

**Always pick a model whose prefix matches the linked provider.**

## Rule #2: ConfigurationType is a page filter — wrong value = invisible config

WildwoodAdmin's AI pages list configurations by exact `configurationType`:

| Page | Filter value |
|---|---|
| AI Chat | `ttschat` (legacy name — the chat+TTS page) |
| AI Proxy | `proxy` |
| AI Flows | `flow` |

A config created with any other type (e.g. a plausible-looking `"chat"`) **exists and works
via the API/relay but appears in NO admin page** — it can't be found or edited in the UI.
If a user says "I don't see the configuration in WildwoodAdmin", check its type first.

## Rule #3: model ids get retired upstream — verify against a LIVE config

Providers retire dated model ids (e.g. `claude-sonnet-4-20250514` → Anthropic 404
`not_found_error`). Hardcoded model ids in seeds, docs, and the `SystemAIModels` dropdown
catalog go stale. Before choosing a model id, find one a **currently-working** configuration
on the same platform uses, and prefer that. Symptom of a retired id: the relay 400s and the
provider's error names the model.

## The ensure routes — headless, idempotent provisioning

`PUT api/AppComponentConfigurations/{appId}/ai/ensure` and
`PUT api/AppComponentConfigurations/{appId}/skills/ensure` are the seeder path (AIManagement
policy: Admin/CompanyAdmin JWT **or** an api-key with `ai:manage`; the skill leg also needs
the company's `AI_SKILLS` tier feature). Semantics that matter:

**ai/ensure** — identity is (app, **name**) because the relay resolves configurations by
name. Mostly create-only; it reconciles exactly three broken-by-definition states and never
touches real tuning:
1. missing provider link → filled (explicit id-or-name, else auto-link when the company has
   exactly one enabled keyed provider / one default); an existing link is never changed;
2. drifted `configurationType` → corrected (it's page categorization, Rule #2);
3. model contradicting the linked provider (Rule #1) → repaired to the caller's consistent
   model; a **consistent** model is admin tuning and is never overwritten (so a retired-but-
   consistent model must be fixed in the UI or DB, not by re-ensuring).

**skills/ensure** — upserts a CompanySkill by name (company resolved from the app — the
caller never needs a company id) plus its AppSkillConfiguration attachment. Instructions
**reconcile** from the caller: the repo owning the skill markdown is the source of truth,
and re-ensuring converges the installed copy.

## The pattern for chat assistants (proven end-to-end)

- **The configuration's system prompt stays EMPTY.** The instructions live in a CompanySkill
  attached with `LoadingMode: "always"` — one versioned skill serves every tenant, and
  config edits never fork the prompt. Keep `INSTRUCTIONS_MARKDOWN` + a `SKILL_VERSION`
  constant in the app's repo; tie the seed task's version to `SKILL_VERSION` so bumping the
  markdown re-runs the task and updates the installed skill.
- The relay resolves the configuration **by name** (e.g. `"sdb-chat"`) — apps reference the
  name in env, not a GUID.
- The relay injects config prompt + skills server-side; the caller sends only conversation
  messages and tool definitions, and gets back text + unexecuted tool calls.

## Debugging relay failures

- The relay's non-OK responses carry a JSON body whose `errorMessage` usually names the exact
  misconfiguration — **surface it in your app's error path**; don't collapse it to
  "HTTP 400". (Generic "An error occurred…" = the model turn itself threw; the wildwood-api
  pod logs then have the full chain: `kubectl logs … | grep "AI relay failed"` shows app,
  config, model, provider, and the upstream error.)
- Triage order, matching the pre-flight checks: config found (by name)? → key for the
  model-implied provider? → provider supported? → then the actual model turn (retired model,
  provider outage, tool-schema issues).
