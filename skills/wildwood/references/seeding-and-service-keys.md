# Seeding & Service Keys — field-tested knowledge

Operational knowledge from real production seeder work (SiteDataBridge, 2026-08). Read this
before writing seed tasks, minting API keys for automation, or debugging a seeder that
skips/401s/403s.

## Two kinds of API keys — the #1 source of confusion

Both live in the same `ApiKeys` table, but they are different credentials:

| | **Client key** (ambient) | **Service key** (scoped) |
|---|---|---|
| Created by | "Regenerate API Key" on the app page | Service Keys card (App Details) or `POST /api/apikeys` with `scopes` |
| Scopes | never — the server refuses to add any | ≥1, set at mint (`"ai:manage tiers:manage"`) |
| Mirrored to the app record | yes — that's the value the app page displays | never (would hand the capability to every client) |
| Expiry | optional | **forced, default 1 year** — plan an annual rotation |
| Value visible | any time, on the app record | **exactly once, at mint** — copy it immediately |
| Use | SDK clients / app runtime | seeder + server-side automation only |

Key facts:

- A scoped key authenticates everywhere the client key does **plus** the scoped surfaces —
  a seeder needs only ONE service key carrying all the scopes its tasks use.
- **Mint with all needed scopes at once**: `scopes: "ai:manage tiers:manage"` (space-delimited).
  Minting "a key for the app" without the scopes field produces a client key that will 403 on
  every scoped surface — necessary but not sufficient.
- The ambient client key **cannot be upgraded**: the API refuses to add scopes to it
  ("mint a separate scoped key instead").
- Only Admin/CompanyAdmin callers can mint or change scoped keys. Unknown scopes are rejected
  against an allowlist.
- **Env var convention**: keep the elevated key in a dedicated `WILDWOOD_SEEDER_API_KEY`
  (never reuse `WILDWOOD_API_KEY`, the conventional name for the general client key — a
  future reader WILL paste the wrong one somewhere client-visible). Treat empty string as
  unset when implementing fallbacks.

## Scopes and what they unlock

| Scope | Policy | Unlocks | Also requires (company tier feature) |
|---|---|---|---|
| `tiers:manage` | TierManagement | tier catalog: tiers, features, limits, pricing, add-ons, feature definitions | `APP_TIER_MANAGEMENT` |
| `ai:manage` | AIManagement | the app-scoped ensure routes: `PUT …/{appId}/ai/ensure`, `PUT …/{appId}/skills/ensure` | `AI_SKILLS` (skill leg) |

Deliberately **never** scoped: entitlement granting (subscriptions, tier changes, overrides,
usage resets — Roles-only), secret material (payment secrets, provider API keys), and
`apikeys:*` (a key that mints keys is self-escalation). Scopes never grant roles.

## The seed ledger — environment is a LABEL, not a target

- The **app id picks the target**. `WILDWOOD_ENV` (node) / `Environment` (.NET) is only the
  label stamped on ledger rows. A prod app seeded from a dev machine without `WILDWOOD_ENV`
  files its rows under **"Dev"** — looks like "prod was never seeded" when it was.
  Always set the label to match the app you're pointing at.
- The ledger gate skips any task whose recorded `installedVersion >= version` with status
  Success. **Version bumps are load-bearing**: change a task's catalog/payload without bumping
  its `version` and the change silently never reaches already-seeded apps.
- Read the ledger headlessly (plain app key works):
  `GET api/AppComponentConfigurations/{appId}/seeder/ledger` — or the MCP tools
  `wildwood_list_seed_ledger` / `wildwood_list_seed_history`.

## Live-API behaviors that WILL bite idempotent tasks

Verified against production; unit tests against assumed shapes missed all of these:

1. **Feature-definition codes come back UPPERCASED.** Send `content_seo`, read back
   `CONTENT_SEO`. Match case-insensitively or every re-run tries to re-create the whole
   catalog. (Add-on `featureCode` rows, by contrast, preserve the sent case.)
2. **Duplicate creates are not always 409.** Some create-only endpoints signal duplicates
   with `400 "… may already exist"`. Treat both 409 and a 400 matching `/already exist/i`
   as the idempotent no-op.
3. **403 vs 401 tells you what's wrong**: 401 = the key value is invalid (not an ApiKeys-table
   row, expired, inactive); 403 = the key authenticates but lacks the scope OR the company
   lacks the tier feature. Probe with a raw GET before blaming the seeder.
4. (Platform-side) Any endpoint a key should reach must declare the
   `Bearer,ApiKey` authentication scheme list — the default is Bearer-only, and the symptom
   is a 401 for a perfectly valid key.

## Seed-task design rules that held up

- **Skip loudly, never half-apply.** On 401/403/404 return a Skipped result whose message
  says exactly what to do ("mint the key with scopes X", "deploy the API version with Y",
  "grant tier feature Z") — the skip message is the runbook.
- **GET-precheck for idempotency, but tolerate the GET lying**: wrapped/paginated bodies must
  skip loudly (not read as "empty catalog"), and nested collections the GET omits fall back
  to create-with-conflict-tolerance.
- **Never let the seeder grant entitlements.** Defining the catalog is seedable; subscribing
  a client to it stays a human/admin action.
- **Reconcile only broken-by-definition state; never overwrite tuning.** See the ensure-route
  semantics in `ai-configuration.md` — the same philosophy applies to any ensure-style task
  you design.
