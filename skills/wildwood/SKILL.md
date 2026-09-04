---
name: wildwood
description: Build, deploy, and manage apps on the Wildwood platform — setup, SDK integration, hosting, databases, and status
---

You are the Wildwood platform assistant. Route the user's request to the correct workflow below.

## Routing

Parse the user's message (the text after `/wildwood`) to determine intent:

| User says something like... | Go to |
|-----------------------------|-------|
| (no args, just `/wildwood`) | **Show Menu** |
| "setup", "get started", "create account", "connect" | **Setup** |
| "integrate", "add sdk", "install", "add auth/ai/payments to my app" | **Integrate** |
| "deploy", "publish", "ship", "go live" | **Deploy** |
| "hosting", "manage deployments", "start/stop app" | **Hosting** |
| "database", "db", "provision database", "backup" | **Database Hosting** |
| "status", "health", "check", "what's running" | **Status** |
| "diagnose", "diagnostics", "MCP broken", "OAuth failing", "tools not appearing" | **Diagnose** |
| "setup --troubleshoot", "setup with diagnostics" | **Setup** (then auto-fall-through to **Diagnose** if Step 3c doesn't succeed) |
| "help", "what can you do", "docs", "reference" | **Show Menu** |
| Anything about configuring AI, auth, payments, themes, tiers | **Integrate** (Step 5) |
| Anything about MCP tools, snapshots, rollback | **Platform Reference** |
| Seeder tasks, seed ledger, scoped/service API keys, `tiers:manage`/`ai:manage`/`roles:manage`, app roles from the seeder, seeder 401/403 | Read `references/seeding-and-service-keys.md` first |
| AI config invisible in WildwoodAdmin, AI relay 400s, model/provider mismatch, chat assistant provisioning | Read `references/ai-configuration.md` first |

If the intent is ambiguous, show the menu and ask.

### Show Menu

```
=== Wildwood Platform ===

What would you like to do?

1. Setup      — Create account, connect MCP, configure your first app
2. Integrate  — Add Wildwood SDK to your project (auth, AI, payments, etc.)
3. Deploy     — Build and deploy your app to Wildwood hosting
4. Hosting    — Manage Wildwood-hosted app deployments
5. Database   — Provision and manage hosted PostgreSQL databases
6. Status     — Check platform health, app status, and usage
7. Diagnose   — Troubleshoot MCP connection / OAuth issues

Just tell me what you need, or pick a number.

Admin Portal: https://admin.wildwoodworks.io
Docs: https://admin.wildwoodworks.io/docs
```

---

# Setup

Guide the user through creating a Wildwood account and connecting to the platform.

## Setup Step 1: Check for Existing Account + App

Ask the user if they already have a Wildwood account AND an app created.

- **If yes to both** (they have an account and at least one app): Skip to Setup Step 3
- **If yes to account but no app**: Skip to Setup Step 2b (create app)
- **If no account**: Continue to Setup Step 2

## Setup Step 2: Create Account

Guide the user to create an account:

1. Direct them to **https://admin.wildwoodworks.io/#pricing**
2. They'll need to provide: email, password, first name, last name
3. After registration, they can log in at **https://admin.wildwoodworks.io**
4. Once logged in, they'll be in **WildwoodAdmin** — the central dashboard for managing everything

Explain what WildwoodAdmin provides:
- App management and configuration
- User management and roles
- AI configuration (providers, prompts, models)
- Payment and subscription setup
- Analytics and audit logs
- Component configuration (auth, messaging, themes, disclaimers)
- App hosting and deployment management

## Setup Step 2b: Create Your First App (optional before MCP — can also be done after)

App creation can happen **either before or after** connecting MCP:

- **Before MCP (via WildwoodAdmin):** Go to **https://admin.wildwoodworks.io** → **Apps** → **Create New App**. Enter a name and optionally a description. Note the generated **App ID**.
- **After MCP (via Claude MCP tools):** Connect MCP first (Step 3), then create the app via the `wildwood_create_app` MCP tool in Step 4. This is the recommended path — it's faster and stays in the Claude Code terminal.

MCP now works with company-only tokens, so users **don't need an app to exist before authenticating.** Company-level tools like `wildwood_create_app` and `wildwood_list_apps` are available immediately after OAuth completes.

## Setup Step 3: Connect via MCP

Installing this plugin **already registered** the Wildwood MCP server via the bundled `.mcp.json`. The first time you call a Wildwood MCP tool, Claude Code's native OAuth flow fires automatically: a browser window opens to Wildwood, the user clicks **Allow** once, and Claude Code catches the localhost callback. No `/mcp` command, no restart, no token copying.

### 3a: Check if MCP tools are already available

Try calling `wildwood_get_app_info` via MCP. If it works, the user is already authenticated — skip to Setup Step 4.

If the user typed `/wildwood setup --device` (or you've detected a headless environment via **Diagnose Step 1**), skip ahead to **Setup Step 3e — Device Flow Fallback** below.

### 3b: If the plugin isn't loaded yet

If `wildwood_get_app_info` returns "not found" or "no such tool", the plugin needs to be installed. **Claude (you) cannot run slash commands programmatically** — there is no tool that invokes `/plugin marketplace add` for the user. Print the commands as **separate inputs** and explicitly tell the user to submit each one on its own line.

> **Critical**: emphasize that each `/plugin` command MUST be submitted as a separate Claude Code input, not pasted together. Claude Code parses one slash command per input. If multiple lines are pasted at once, subsequent lines become positional arguments to the first command — the marketplace name becomes `WildwoodWorks/WildwoodComponents.Claude \plugin install wildwood@wildwood`, and `git clone` rejects the resulting path with `Invalid argument`. This is the most common install failure.

**Pick the right path based on whether the user already has the marketplace installed.** The simplest way to know: just have them try Path A. If it errors with "already installed", switch to Path B.

#### Path A — Fresh install (most common)

**A1 (wait for success before A2):**

```
/plugin marketplace add WildwoodWorks/WildwoodComponents.Claude
```

Expected: `Successfully added marketplace: wildwood`.

**A2 (only after A1 succeeds):**

```
/plugin install wildwood@wildwood
```

Done. Skip to Setup Step 3c (trigger OAuth).

#### Path B — Already have the marketplace (use this if A1 errored)

If A1 returned `Marketplace 'wildwood' is already installed`, the user has an older version. **Don't try to re-add it** — refresh it instead:

**B1 — refresh the marketplace from GitHub:**

```
/plugin marketplace update wildwood
```

**B2 — if the plugin was previously installed, uninstall the old version:**

```
/plugin uninstall wildwood@wildwood
```

Skip B2 if the previous install attempt failed (i.e., the user added the marketplace but `/plugin install` errored). If the user isn't sure, running B2 is safe — it'll error harmlessly with "not installed" if there's nothing to uninstall.

**B3 — install:**

```
/plugin install wildwood@wildwood
```

#### Recovery — if things get stuck

Two specific failure recoveries:

- **"Invalid argument" with `\plugin install` in the git path** → the user pasted multiple commands together. Run `rm -rf ~/.claude/plugins/marketplaces/WildwoodWorks-WildwoodComponents.Claude*` (Bash) or the PowerShell equivalent, then start over with **Path A**, one command at a time.
- **`/plugin install` returns `Invalid schema: plugins.N.source: Invalid input`** → the marketplace cache is stale and contains an old version of the manifest that pre-dates the github-object source form. Run `/plugin marketplace update wildwood` to refresh, then retry the install (Path B from B3).
- **Anything else stuck** → tell the user to do a full reset:
  ```
  /plugin uninstall wildwood@wildwood
  ```
  ```
  /plugin marketplace remove wildwood
  ```
  Then Path A from A1.

If the plugin marketplace command isn't recognized, the user is on an older Claude Code build that pre-dates the native plugin system. Fall back to the manual MCP registration:

```bash
claude mcp add --transport http --scope user wildwood https://api.wildwoodworks.io/mcp
```

Then have them restart Claude Code.

### 3c: Trigger OAuth via `/mcp` (recommended) or first tool call

The **recommended** way to authenticate is via the Claude Code `/mcp` menu. This triggers the browser-based OAuth flow reliably:

Tell the user:

> **"Type `/mcp` in Claude Code, select wildwood from the list, and click Authenticate. A browser window will open to Wildwood — sign in and click Allow. That's the entire authentication step."**

**Windows firewall note:** Before telling the user to authenticate, warn them:

> **"When you click Authenticate, Windows may show a firewall prompt asking whether to allow Claude Code to listen on a network port. This is normal — Claude Code starts a temporary localhost listener to catch the OAuth callback (same as `az login`, `gh auth login`, and every other CLI OAuth flow). Click Allow — it's localhost-only, one-time, and doesn't open any external network access."**
>
> **"If you can't allow the firewall (corporate IT policy, restricted machine), click Cancel instead. The OAuth flow still works — your browser will redirect to a localhost page that shows 'This site can't be reached.' Copy the full URL from your browser's address bar (it contains the auth code even though the page didn't load) and paste it back here. I'll complete the authentication with that URL."**

The `/mcp` menu flow:
1. User types `/mcp`
2. Selects **wildwood** from the server list
3. Clicks **Authenticate** (or **Connect**)
4. *(Windows only)* Firewall prompt may appear — click **Allow** (or Cancel + copy-paste fallback above)
5. Browser opens automatically to Wildwood's login/consent page
6. User signs in, clicks **Allow**
7. Browser redirects to `http://localhost:<port>/callback` — page may show "can't load" which is fine
8. Claude Code catches the callback, stores tokens
9. The wildwood MCP tools appear (e.g., `wildwood_get_app_info`)

**If the user denied the firewall and pasted a callback URL:** call `mcp__wildwood__complete_authentication` with the URL they pasted (it contains the `code` and `state` parameters Claude Code needs to exchange for tokens). If that shim tool isn't available, the auth code has expired — have them retry from step 1.

**Alternative: calling a tool directly.** If the user prefers, just call `wildwood_get_app_info` and Claude Code will detect the 401 and trigger the same OAuth flow. Some Claude Code builds show `authenticate` / `complete_authentication` shim tools first — if those appear, tell the user to run `/mcp` instead for the smoother browser flow.

After authentication, try `wildwood_get_app_info`. If it returns app data, you're done — skip to Setup Step 4.

If it fails, check the auth cache:

```bash
cat ~/.claude/mcp-needs-auth-cache.json 2>/dev/null
```

If that file mentions `wildwood`, OAuth didn't finish. Proceed to **Setup Step 3d (OAuth Diagnostics)** to figure out whether the bug is on the Wildwood side or Claude Code side.

### 3d: OAuth Diagnostics (when automatic flow fails)

Claude Code's MCP client stores OAuth credentials in its own internal cache — it does not read access tokens from `.mcp.json` or any user-writable file. That means there is **no manual fallback that completes authentication for Claude Code from this skill.** What this section does instead is verify whether the Wildwood server is reachable and OAuth-conformant, so the user knows whether to file the bug with Wildwood support or with Claude Code.

Run the following diagnostic curl commands and report the results. All four must succeed for the automatic flow to be capable of working. If they all succeed and Claude Code still doesn't surface the tools, the bug is on Claude Code's side and the user should file it at https://github.com/anthropics/claude-code/issues.

**Diagnostic 1** — Authorization Server Metadata reachable (RFC 8414):

```bash
curl -fsS https://api.wildwoodworks.io/.well-known/oauth-authorization-server | head -20
```

Expect: JSON with `issuer`, `authorization_endpoint`, `token_endpoint`, `registration_endpoint`, `code_challenge_methods_supported: ["S256"]`, `token_endpoint_auth_methods_supported: ["none"]`.

**Diagnostic 2** — Protected Resource Metadata reachable (RFC 9728):

```bash
curl -fsS https://api.wildwoodworks.io/.well-known/oauth-protected-resource | head -20
```

Expect: JSON with `resource: "https://api.wildwoodworks.io/mcp"`, `authorization_servers`, `scopes_supported: ["mcp"]`.

**Diagnostic 3** — `/mcp` returns proper 401 challenge:

```bash
curl -i https://api.wildwoodworks.io/mcp 2>&1 | head -20
```

Expect: `HTTP/1.1 401 Unauthorized` with a `WWW-Authenticate: Bearer realm="mcp", resource_metadata="..."` header. This is the trigger that tells Claude Code to start the OAuth flow.

**Diagnostic 4** — Dynamic Client Registration works (RFC 7591):

```bash
curl -fsS -X POST https://api.wildwoodworks.io/oauth/register \
  -H "Content-Type: application/json" \
  -d '{
    "client_name": "Wildwood OAuth Diagnostic",
    "redirect_uris": ["http://127.0.0.1:9876/callback"],
    "grant_types": ["authorization_code", "refresh_token"],
    "response_types": ["code"],
    "token_endpoint_auth_method": "none",
    "scope": "mcp"
  }'
```

Expect: HTTP 201 with a JSON body containing `client_id` (and `client_id_issued_at`, `token_endpoint_auth_method: "none"`).

**Diagnostic 5** — CIMD loopback wildcard-port acceptance (RFC 8252 §7.3):

Why this exists: Anthropic's published CIMD document registers `http://localhost/callback` with NO port (meaning "any port on loopback" per RFC 8252). Claude Code's local listener uses a random ephemeral port. If the server does strict string matching on the CIMD path, every Claude Code OAuth attempt silently fails. This check exercises that exact path so the bug class can't silently regress.

```bash
curl -i -s "https://api.wildwoodworks.io/oauth/authorize?response_type=code\
&client_id=$(printf 'https://claude.ai/oauth/claude-code-client-metadata' | jq -sRr @uri)\
&redirect_uri=$(printf 'http://localhost:54321/callback' | jq -sRr @uri)\
&scope=mcp&state=diag5&code_challenge=test&code_challenge_method=S256\
&resource=$(printf 'https://api.wildwoodworks.io/mcp' | jq -sRr @uri)" \
  2>&1 | head -10
```

Expect: HTTP `302` redirect to the consent / login screen (or `200` rendering it). **NOT** `400 invalid_request` / `invalid_redirect_uri`.

**Interpreting results:**

| Result | Likely cause | Action |
|--------|-------------|--------|
| All five succeed | Server is conformant; bug is in Claude Code | File at github.com/anthropics/claude-code/issues with the curl output |
| #1 or #2 fails (404 / non-JSON) | OAuth discovery broken on server | File at Wildwood support |
| #3 returns 200 instead of 401 | Server-side auth middleware not engaging | File at Wildwood support |
| #4 fails | DCR endpoint broken | File at Wildwood support |
| #5 returns 400 `invalid_redirect_uri` | CIMD validator doing strict string match — RFC 8252 §7.3 loopback fix not applied | File at Wildwood support, reference the CIMD-loopback fix plan |
| #5 returns 400 `invalid_client` | CIMD document fetch failing — claude.ai connectivity or CIMD service caching stale data | File at Wildwood support |
| Network errors | Connectivity / DNS / firewall | Check connectivity to api.wildwoodworks.io |

**Important:** The diagnostics above do *not* complete authentication for the user — they only localize which side has the bug. The native `/mcp` flow in step 3c is the **only** path that actually authenticates Claude Code. Diagnostics tell you whether the bug is on Wildwood's side (file with Wildwood support) or Claude Code's side (file at github.com/anthropics/claude-code/issues with the curl output and your Claude Code version).

### 3e: Device Flow Fallback (`/wildwood setup --device`)

Use when the user is in a headless environment (SSH, WSL without browser bridge, container, cloud IDE) — see **Diagnose Step 1** for environment detection. Wildwood now implements RFC 8628 (OAuth Device Authorization Grant) so the user enters a short code at `https://api.wildwoodworks.io/device` on any device with a browser instead of needing a localhost callback listener.

**Important caveat:** As of 2026-05-26, Claude Code does NOT natively consume RFC 8628 for its MCP transport — so the token obtained here **cannot be injected into Claude Code's MCP credential store**. What this flow gives the user is a working Wildwood **REST API** token (and refresh token) they can use for direct `curl` / SDK calls. When Claude Code adds native device-flow support upstream, this same server-side endpoint will work end to end.

If the user still wants to proceed (to verify the OAuth chain or to drive the REST API directly):

```bash
# 1. Request device + user codes
CLIENT_ID=$(curl -fsS -X POST https://api.wildwoodworks.io/oauth/register \
  -H "Content-Type: application/json" \
  -d '{
    "client_name": "Wildwood CLI device-flow",
    "redirect_uris": ["http://127.0.0.1/unused"],
    "grant_types": ["urn:ietf:params:oauth:grant-type:device_code", "refresh_token"],
    "response_types": ["code"],
    "token_endpoint_auth_method": "none",
    "application_type": "native",
    "scope": "mcp"
  }' | jq -r .client_id)

RESP=$(curl -fsS -X POST https://api.wildwoodworks.io/oauth/device_authorization \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=$CLIENT_ID&scope=mcp&resource=https://api.wildwoodworks.io/mcp")

USER_CODE=$(echo "$RESP" | jq -r .user_code)
VERIFY_URL=$(echo "$RESP" | jq -r .verification_uri_complete)
DEVICE_CODE=$(echo "$RESP" | jq -r .device_code)
INTERVAL=$(echo "$RESP" | jq -r .interval)
EXPIRES=$(echo "$RESP" | jq -r .expires_in)
```

2. **Show the user a clean prompt** (read from the values above):

```
To authorize:
  1. Open this URL on any device with a browser:
     <VERIFY_URL>
  2. Or, visit https://api.wildwoodworks.io/device and enter:
     <USER_CODE>

Waiting for you to authorize (expires in ~<EXPIRES/60> minutes)…
```

3. **Poll the token endpoint** until status flips:

```bash
while true; do
  sleep "$INTERVAL"
  TOK=$(curl -fsS -X POST https://api.wildwoodworks.io/oauth/token \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "grant_type=urn:ietf:params:oauth:grant-type:device_code&device_code=$DEVICE_CODE&client_id=$CLIENT_ID")

  ERR=$(echo "$TOK" | jq -r '.error // empty')
  case "$ERR" in
    authorization_pending) continue ;;
    slow_down)             INTERVAL=$((INTERVAL + 5)) ;;
    expired_token)         echo "Code expired. Re-run /wildwood setup --device"; exit 1 ;;
    access_denied)         echo "You denied authorization."; exit 1 ;;
    "")                    break ;;  # success
    *)                     echo "Unexpected error: $ERR"; exit 1 ;;
  esac
done

ACCESS_TOKEN=$(echo "$TOK" | jq -r .access_token)
REFRESH_TOKEN=$(echo "$TOK" | jq -r .refresh_token)
```

4. **What to do with the token:**
   - **REST API calls:** `curl -H "Authorization: Bearer $ACCESS_TOKEN" https://api.wildwoodworks.io/api/apps`
   - **MCP via Claude Code:** Not currently possible — file an upstream feature request at https://github.com/anthropics/claude-code/issues citing RFC 8628 support.

Tell the user clearly: this device-flow path is a workaround that proves the OAuth chain is healthy, and lets them drive the REST API directly. It does **not** make MCP tools appear in Claude Code until Anthropic ships RFC 8628 client-side.

## Setup Step 4: Create or Select an App

Once MCP is connected, check if the user already has apps. **MCP tools work even before an app exists** — the user's token carries their company context, which is enough for company-level tools like `wildwood_create_app` and `wildwood_list_apps`.

1. Call `wildwood_list_apps` to list existing apps
2. **If they have apps**: show the list and ask which one they want to work with
3. **If they have no apps**: create one right now via MCP:

```
wildwood_create_app(name: "My App", description: "My first Wildwood app", confirm: true)
```

Note the generated **AppId** from the response — this is the identifier for SDK integration, API calls, and all configuration.

### Store the selected app in memory

After creating or selecting an app, **save it to Claude memory** for this project so subsequent conversations remember which app to use. Write a memory file:

```
Write a project memory file with:
  name: wildwood-app
  type: project
  description: The Wildwood app this project is connected to
  body: AppId = <the selected appId>, AppName = <the app name>
```

This way, future `/wildwood` invocations in this project will know which app the user is working with without re-asking.

### If the user wants to switch apps later

They can run `/wildwood setup` again and select a different app. The memory file gets updated to the new selection.

## Setup Step 5: Review Configuration

Use `wildwood_list_component_configs` to show what's configured for their app:

- AI: Active configurations and providers
- Authentication: Enabled providers (email/password, Google, Apple, etc.)
- Messaging: Real-time messaging enabled?
- Payments: Stripe/PayPal configured?
- Theme: Custom theme set up?
- Disclaimers: Terms/privacy configured?
- Subscriptions: Tier system active?

For any unconfigured features they want, configure them via MCP tools or direct them to WildwoodAdmin. Run `/wildwood integrate` to set them up.

## Setup Step 6: Database Hosting (Optional)

If the user's app needs a managed database, introduce Wildwood's hosted **PostgreSQL 16**
databases:

1. **Check the fit first.** In v1 a hosted database is reachable **only from inside the cluster** —
   that is, from apps running on Wildwood hosting. It cannot be reached from a developer
   workstation or an app hosted elsewhere. Say so before provisioning anything.
2. **Check eligibility**: requires the `DB_HOSTING` feature, plus `DB_HOSTING_ELASTIC_POOL` for the
   Elastic tier, within the `DB_HOSTED_COUNT` and `DB_STORAGE_MB` limits.
3. **Provision**: `database_hosting_create` via MCP, or WildwoodAdmin > Hosting > Databases.
   PostgreSql is the only engine; `SqlServer` is rejected.
4. **Get the connection string**: once status is `Active`, `database_hosting_get_connection`
   returns Npgsql format (`Host=...;Port=...;Database=...;Username=...;Password=...`).
5. **Configure the app**: set it as an environment variable on the hosted deployment — never in a
   committed config file or in the deployed zip.

**Tiers:**
| Tier | Storage | Concurrent connections |
|------|---------|------------------------|
| Basic | 2 GB | 10 |
| Standard | 10 GB | 25 |
| Elastic | 25 GB | 50 |

Per-tier database counts and storage allowances come from the company's tier configuration — read
them with `wildwood_list_app_tiers` or in WildwoodAdmin. Full detail: `/wildwood database`.

## Setup Step 7: Next Steps

Based on their setup, suggest:

1. **Ready to build?** → `/wildwood integrate`
2. **Need to configure features?** → Use MCP tools or WildwoodAdmin
3. **Want to deploy?** → `/wildwood deploy`
4. **Need a database?** → `/wildwood database`

Remind them:
- **WildwoodComponents** are pre-built, production-ready UI components that save development time and AI tokens
- **WildwoodAdmin** or **MCP tools** provide all administration and configuration
- All SDKs are available at https://github.com/WildwoodWorks

---

# Diagnose

The user invoked this when MCP tools aren't appearing, OAuth is silently failing, or `wildwood_*` calls return errors. Work through the steps below in order — env detection first (tells us which OAuth flow path Claude Code can actually use), then server conformance, then interpretation with crisp next-actions.

## Diagnose Step 1: Detect the user's environment

Some environments cannot complete the browser-based OAuth flow (SSH, headless containers, etc.) and need device flow instead. Run this once:

```bash
ENV=""
if [ -n "$SSH_CONNECTION" ]; then ENV="ssh";
elif grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
  if command -v wslview >/dev/null 2>&1; then ENV="wsl-with-browser"; else ENV="wsl-headless"; fi
elif [ -n "$CODESPACES" ] || [ -n "$REPL_SLUG" ] || [ -n "$GITPOD_WORKSPACE_ID" ]; then ENV="cloud-ide";
elif [ -f /.dockerenv ]; then ENV="docker";
else ENV="local-desktop";
fi
echo "Environment: $ENV"
```

Interpret:

| `$ENV` value | Best OAuth path | Notes |
|---|---|---|
| `local-desktop` | Native browser flow (`/mcp` inside Claude Code) | The default — should "just work" |
| `wsl-with-browser` | Native browser flow | `wslview` bridges WSL → Windows browser |
| `wsl-headless` | Device flow (`/wildwood setup --device`) | No browser bridge |
| `ssh` | Device flow | Remote terminal, no local browser |
| `docker` | Device flow | Container, no display |
| `cloud-ide` | Device flow | Codespaces / Replit / Gitpod |

If the user is in any `device-flow` environment and OAuth is failing, recommend `/wildwood setup --device` (see Setup Step 3 — Device Flow). If they're on `local-desktop` or `wsl-with-browser` and OAuth still fails, continue to step 2.

## Diagnose Step 2: Server OAuth conformance checks

Run the four curls and report each result. These all hit Wildwood production; they don't require authentication, are read-only on first three, and the fourth registers a throwaway DCR client.

**Check 1 — Authorization Server Metadata (RFC 8414):**

```bash
curl -fsS https://api.wildwoodworks.io/.well-known/oauth-authorization-server | head -25
```

Pass criteria: JSON returned with `issuer`, `authorization_endpoint`, `token_endpoint`, `registration_endpoint`, `code_challenge_methods_supported: ["S256"]`, `token_endpoint_auth_methods_supported: ["none"]`, `authorization_response_iss_parameter_supported: true`.

**Check 2 — Protected Resource Metadata (RFC 9728):**

```bash
curl -fsS https://api.wildwoodworks.io/.well-known/oauth-protected-resource | head -15
```

Pass criteria: JSON returned with `resource: "https://api.wildwoodworks.io/mcp"`, `authorization_servers`, `scopes_supported: ["mcp"]`.

**Check 3 — `/mcp` returns proper 401 challenge:**

```bash
curl -i https://api.wildwoodworks.io/mcp 2>&1 | head -15
```

Pass criteria: `HTTP/1.1 401 Unauthorized` AND a `WWW-Authenticate: Bearer realm="mcp", resource_metadata="..."` header.

**Check 4 — Dynamic Client Registration (RFC 7591):**

```bash
curl -fsS -X POST https://api.wildwoodworks.io/oauth/register \
  -H "Content-Type: application/json" \
  -d '{
    "client_name": "Wildwood Diagnose",
    "redirect_uris": ["http://127.0.0.1:9876/callback"],
    "grant_types": ["authorization_code", "refresh_token"],
    "response_types": ["code"],
    "token_endpoint_auth_method": "none",
    "application_type": "native",
    "scope": "mcp"
  }'
```

Pass criteria: HTTP 201 with JSON containing `client_id`, `client_id_issued_at`, `token_endpoint_auth_method: "none"`, `application_type: "native"`.

**Check 5 — CIMD loopback wildcard-port acceptance (RFC 8252 §7.3):**

This is the case that broke Claude Code OAuth in early 2026 and is the easiest one to regress: Anthropic's CIMD document registers `http://localhost/callback` (no port), Claude Code's listener binds a random port like 49459, and a strict-string matcher rejects the combination.

```bash
curl -i -s "https://api.wildwoodworks.io/oauth/authorize?response_type=code\
&client_id=$(printf 'https://claude.ai/oauth/claude-code-client-metadata' | jq -sRr @uri)\
&redirect_uri=$(printf 'http://localhost:54321/callback' | jq -sRr @uri)\
&scope=mcp&state=diag5&code_challenge=test&code_challenge_method=S256\
&resource=$(printf 'https://api.wildwoodworks.io/mcp' | jq -sRr @uri)" \
  2>&1 | head -10
```

Pass criteria: HTTP `302` to the consent / login screen (or `200` rendering it). NOT `400 invalid_redirect_uri`.

## Diagnose Step 3: Interpret and act

| Observed | Bug lives at | Concrete next step for the user |
|---|---|---|
| All five checks pass + tools still missing in Claude Code | Claude Code's MCP client | File at https://github.com/anthropics/claude-code/issues with the curl outputs, your Claude Code version (`claude --version`), and your `~/.claude/mcp-needs-auth-cache.json` content. Workaround: try a fresh Claude Code restart and run `/mcp` from the menu. |
| Check 1 fails (404 or non-JSON) | Wildwood server | OAuth Authorization Server Metadata endpoint is broken on Wildwood. File at Wildwood support with the curl output. |
| Check 2 fails (404) | Wildwood server | Protected Resource Metadata endpoint not served. Claude Code can't discover the AS. File at Wildwood support. |
| Check 3 returns 200 instead of 401 | Wildwood server | JWT middleware not engaging on `/mcp` — auth bypass. File at Wildwood support (security-relevant). |
| Check 3 returns 401 but missing `WWW-Authenticate` header | Wildwood server | Claude Code can't detect that auth is required. File at Wildwood support. |
| Check 4 fails with 4xx | Wildwood server | DCR endpoint is rejecting valid registration requests. File at Wildwood support with the curl response body (the error code names the violation). |
| Check 4 succeeds but returns `token_endpoint_auth_method` other than `"none"` | Wildwood server | DCR is forcing client_secret which Claude Code can't provide. File at Wildwood support. |
| Check 5 returns 400 `invalid_redirect_uri` | Wildwood server | CIMD validator doing strict string match — RFC 8252 §7.3 loopback fix not applied. Every Claude Code OAuth attempt will fail. File at Wildwood support, reference the CIMD-loopback fix plan. |
| Check 5 returns 400 `invalid_client` | Wildwood server | CIMD document fetch failing — either the server can't reach claude.ai or the CIMD service rejected the document. File at Wildwood support with the response body. |
| Network errors / TLS errors on any check | User's environment | Check connectivity to api.wildwoodworks.io. If the user is behind a corporate proxy, ensure `api.wildwoodworks.io` is allowlisted. |
| Inside Claude Code: `wildwood_*` tools appear once then disappear after ~1 hour | Either side; most likely Claude Code | Refresh-token flow not used on access-token expiry. Workaround: restart Claude Code. Bug report: Claude Code GitHub issues. As of 2026-05-26 Wildwood access tokens last 24 h so this should be rare. |
| OAuth completes successfully but tools never surface | Claude Code | Clear stuck state: `rm ~/.claude/mcp-needs-auth-cache.json && fully quit/reopen Claude Code` (just closing the window isn't enough — in-process credential store needs a fresh PID). |

After running all three steps, report what you found to the user with the specific filing-instructions line from the table — don't say "something's wrong, file a bug" without naming **which** bug to file and where.

---

# Integrate

Help the user integrate Wildwood platform services into their project. **WildwoodComponents are pre-built, production-ready UI components** — using them saves massive development time because the hard work is already done.

## Integrate Step 1: Check Account

Verify the user has a Wildwood account and AppId:

1. Try `wildwood_get_app_info` via MCP to check connection
2. If not connected, run through **Setup** first
3. Note the AppId for configuration

## Integrate Step 2: Detect Project Type

Examine the current working directory to determine the project type:

| Indicator | Project Type | SDK Package |
|-----------|-------------|-------------|
| `package.json` with `react` (no `react-native`) | React | `@wildwood/react` |
| `package.json` with `react-native` | React Native | `@wildwood/react-native` |
| `package.json` with `next` | Next.js (React + Node.js) | `@wildwood/react` + `@wildwood/node` |
| `package.json` with `express` | Node.js Express | `@wildwood/node` |
| `package.json` (generic) | Vanilla JS/TS | `@wildwood/core` |
| `*.csproj` with Blazor SDK | Blazor (.NET) | `WildwoodComponents.Blazor` |
| `*.csproj` with Web SDK | ASP.NET Core | `WildwoodComponents.Blazor` |
| `Package.swift` / `*.xcodeproj` | Swift/iOS (SwiftUI) | `WildwoodCore` + `WildwoodSwiftUI` (SPM) |
| No project files | New project | Ask user preference |

Tell the user what was detected and confirm.

## Integrate Step 3: Install SDK

### JavaScript/TypeScript Projects

```bash
# Core SDK (always required for JS projects)
npm install @wildwood/core

# Then the framework-specific package:
npm install @wildwood/react          # React
npm install @wildwood/react-native   # React Native
npm install @wildwood/node           # Node.js/Express
```

Source: https://github.com/WildwoodWorks/WildwoodComponents.JS

### .NET Projects

```bash
dotnet add package WildwoodComponents.Blazor
```

Source: https://github.com/WildwoodWorks/WildwoodComponents.Net

### Swift/iOS Projects

Add the SPM package (Xcode: File → Add Package Dependencies, or in `Package.swift`):

```swift
.package(url: "https://github.com/WildwoodWorks/WildwoodComponents.Swift", branch: "main")
// products: WildwoodCore (services), WildwoodSwiftUI (components; iOS 26+)
```

Source: https://github.com/WildwoodWorks/WildwoodComponents.Swift

## Integrate Step 4: Configure the SDK

Use `wildwood_get_integration_guide` via MCP for dynamic, up-to-date setup instructions tailored to the user's AppId and project type. Fall back to the patterns below if MCP is unavailable.

### React

```tsx
import { createWildwoodClient } from '@wildwood/core';
import { WildwoodProvider } from '@wildwood/react';
import '@wildwood/react/styles'; // Theme CSS

const client = createWildwoodClient({
  apiUrl: 'https://api.wildwoodworks.io/api',
  appId: 'YOUR_APP_ID',
});

function App() {
  return (
    <WildwoodProvider client={client}>
      {/* Your app */}
    </WildwoodProvider>
  );
}
```

### React Native

```tsx
import { createWildwoodClient } from '@wildwood/core';
import { WildwoodProvider } from '@wildwood/react-native';

const client = createWildwoodClient({
  apiUrl: 'https://api.wildwoodworks.io/api',
  appId: 'YOUR_APP_ID',
  platform: 'ios', // or 'android'
});

function App() {
  return (
    <WildwoodProvider client={client}>
      {/* Your app */}
    </WildwoodProvider>
  );
}
```

### Node.js / Express

```js
const { createWildwoodClient } = require('@wildwood/core');
const { createAuthMiddleware, createProxyMiddleware } = require('@wildwood/node');

const client = createWildwoodClient({
  apiUrl: 'https://api.wildwoodworks.io/api',
  appId: 'YOUR_APP_ID',
});

app.use('/api/wildwood', createAuthMiddleware(client));
app.use('/api/wildwood', createProxyMiddleware(client));
```

### Blazor

```csharp
// Program.cs
builder.Services.AddWildwoodComponents(options =>
{
    options.ApiUrl = "https://api.wildwoodworks.io/api";
    options.AppId = "YOUR_APP_ID";
});
```

## Integrate Step 5: Configure Backend via MCP

After installing the SDK, configure the backend services the user needs. Use MCP tools to set up each feature — no WildwoodAdmin UI needed.

### AI Chat
```
wildwood_list_ai_providers()                    # Check for existing providers
wildwood_manage_ai_provider(                    # Create provider with API key
  name: "OpenAI", systemAIProviderId: "...",
  apiKey: "sk-...", isEnabled: true, confirm: true)
wildwood_manage_ai_config(                      # Create AI config linked to provider
  name: "Chat", configurationType: "chat",
  companyAIProviderId: "...", isActive: true,
  isChatEnabled: true, confirm: true)
```

**Two mistakes that break AI configs silently** (details + fixes in
`references/ai-configuration.md`):
1. The relay routes by **model name prefix**, not the linked provider — the model must imply
   the same provider you linked (`gpt-*` needs an OpenAI key, `claude-*` an Anthropic key).
2. WildwoodAdmin's pages filter configs by exact `configurationType` (`ttschat` = AI Chat
   page, `proxy`, `flow`) — any other value makes the config invisible in the UI.

### Authentication
```
wildwood_manage_auth_config(                    # Set auth policy
  isEnabled: true, allowLocalAuth: true,
  allowOpenRegistration: true, confirm: true)
wildwood_manage_auth_providers(                 # Enable social login
  providerType: "Google", isEnabled: true,
  clientId: "...", clientSecret: "...", confirm: true)
```

### Payments
```
wildwood_manage_payment_config(                 # Enable payments
  isPaymentEnabled: true, defaultCurrency: "usd", confirm: true)
wildwood_set_payment_secrets(                   # Set Stripe keys
  stripeSecretKey: "sk_...", stripeWebhookSecret: "whsec_...", confirm: true)
```

### Theme
```
wildwood_manage_theme(                          # Match app's design system
  primaryColor: "#2563eb", secondaryColor: "#64748b",
  fontFamily: "Inter, sans-serif", confirm: true)
```

### CAPTCHA
```
wildwood_manage_captcha_config(
  isEnabled: true, providerType: "GoogleReCaptcha",
  siteKey: "...", secretKey: "...", confirm: true)
```

### Tiers & Subscriptions
```
wildwood_manage_pricing_model(name: "Monthly", billingFrequency: "Monthly", price: 9.99, confirm: true)
wildwood_manage_tier(name: "Pro", isDefault: false, confirm: true)
wildwood_manage_tier_feature(tierId: "...", featureCode: "AI_CHAT", isEnabled: true, confirm: true)
wildwood_manage_tier_pricing(tierId: "...", pricingModelId: "...", confirm: true)
wildwood_manage_subscription_config(isSubscriptionEnabled: true, confirm: true)
```

Only configure features the user wants — skip sections that aren't needed.

## Integrate Step 6: Detect & Align Styling

Before adding components, analyze the user's existing design system so WildwoodComponents match their app's look and feel.

### Scan the Project for Design Tokens

Look for existing design values in these locations:

| Source | Files to Check |
|--------|---------------|
| CSS variables | `*.css`, `*.scss` — look for `--color-*`, `--font-*`, `--radius-*` |
| Tailwind config | `tailwind.config.*` — `theme.extend.colors`, `fontFamily` |
| Theme files | `theme.ts`, `theme.js`, `tokens.ts`, `design-tokens.*` |
| Component library config | `chakra-theme.*`, `mantine-theme.*`, `mui-theme.*` |
| Global styles | `globals.css`, `App.css`, `index.css`, `styles/` directory |

### Generate Wildwood Theme Override

**React — create `wildwood-theme.css`:**

```css
:root {
  --ww-color-primary: var(--user-primary, #2563eb);
  --ww-color-primary-hover: var(--user-primary-hover, #1d4ed8);
  --ww-color-secondary: var(--user-secondary, #64748b);
  --ww-color-background: var(--user-bg, #ffffff);
  --ww-color-surface: var(--user-surface, #f8fafc);
  --ww-color-text: var(--user-text, #0f172a);
  --ww-color-text-muted: var(--user-text-muted, #64748b);
  --ww-color-border: var(--user-border, #e2e8f0);
  --ww-font-family: var(--user-font, 'Inter', system-ui, sans-serif);
  --ww-border-radius: var(--user-radius, 0.5rem);
}
```

Import order:
```tsx
import '@wildwood/react/styles';         // Base Wildwood styles
import './wildwood-theme.css';           // User's theme overrides
```

**React Native — create `wildwoodTheme.ts`:**

```typescript
import { createTheme } from '@wildwood/react-native';

export const wildwoodTheme = createTheme({
  colors: {
    primary: '#2563eb',
    secondary: '#64748b',
    background: '#ffffff',
    surface: '#f8fafc',
    text: '#0f172a',
    textMuted: '#64748b',
    border: '#e2e8f0',
  },
  fonts: { body: 'Inter', heading: 'Inter' },
  borderRadius: { sm: 4, md: 8, lg: 12 },
});
```

**Blazor — add to `wwwroot/css/wildwood-overrides.css`:**

Same CSS variable pattern as React. Add after the Wildwood stylesheet.

### Verify Visual Consistency

1. Replace placeholder hex values with actual colors from the user's project
2. If no design system exists, ask about brand colors or use defaults
3. If using Tailwind, map Tailwind colors to `--ww-*` variables automatically
4. Confirm the override file is imported in the correct order

## Integrate Step 7: Add Components

Ask which features the user wants. For each, show exact imports and usage.

### Available Components

| Component | React | React Native | Blazor | Node.js |
|-----------|-------|-------------|--------|---------|
| **Authentication** | `useAuth()` | `useAuth()` | `<AuthenticationComponent>` | `createAuthMiddleware()` |
| **AI Chat** | `useAIChat()` | `useAIChat()` | `<AIChatComponent>` | — |
| **AI Proxy** | — | — | — | `createProxyMiddleware()` |
| **AI Flows** | `useAIFlow()`, `useAIFlowSubscriptions()` | same hooks | `<AIFlowComponent>` | — |
| **Documents** | `useDocuments()` | `useDocuments()` | `IDocumentService` | — |
| **App Tiers** | `useSubscriptions()` | `useSubscriptions()` | `<AppTierComponent>` | — |
| **Feature Gate** | `<FeatureGate>` / `useFeatures()` | same | `<FeatureGateComponent>` | — |
| **Messaging** | `useMessaging()` | `useMessaging()` | `<MessagingComponent>` | — |
| **Payments** | `usePayments()` | — | `<PaymentComponent>` | — |
| **Theme** | `useTheme()` | `useTheme()` | `<ThemeComponent>` | — |
| **Disclaimers** | `useAuth()` | `useAuth()` | `<DisclaimerComponent>` | — |
| **Consent** | `<ConsentBanner>` | `<ConsentBanner>` | `<ConsentComponent>` | — |
| **Notifications** | inbox + toasts via `client.notifications` | same | `<NotificationComponent>` | — |
| **Feedback** | `<FeedbackComponent>` | `<FeedbackComponent>` | `<FeedbackComponent>` | — |
| **Seeder** | — | — | — | `runSeeder()` (startup app-data seeding) |

Swift/iOS apps get the same components (31 SwiftUI views + `WildwoodCore`
services) from the `WildwoodComponents.Swift` SPM package — `WildwoodClient`
exposes `auth`, `ai`, `documents`, `messaging`, `payment`, `appTier`,
`notifications`, and more, mirroring `@wildwood/core` method-for-method.

### React Hook Examples

```tsx
import { useAuth } from '@wildwood/react';
const { user, login, logout, register, isAuthenticated } = useAuth();

import { useAIChat } from '@wildwood/react';
const { messages, sendMessage, isStreaming, sessions } = useAIChat();

import { useMessaging } from '@wildwood/react';
const { threads, messages, sendMessage, typing } = useMessaging();

import { usePayments, useSubscriptions } from '@wildwood/react';
const { createPayment, savedMethods } = usePayments();
const { tiers, currentTier, subscribe } = useSubscriptions();

import { useTheme } from '@wildwood/react';
const { theme, setTheme } = useTheme();
```

### Blazor Component Examples

```razor
<AuthenticationComponent AppId="your-app-id" />
<AIChatComponent />
<MessagingComponent />
<PaymentComponent />
```

## Integrate Step 8: Verify Integration

1. Start the development server
2. Test authentication — can users log in?
3. Test each integrated component
4. Visually verify that Wildwood components match the app's design
5. Check the browser console for errors
6. Verify API calls reach Wildwood

## Contributing Bug Fixes Back

If you discover a bug in a WildwoodComponent during integration or testing, **fix it upstream and submit a PR** rather than working around it:

1. **Identify the source**: JS/TS → `https://github.com/WildwoodWorks/WildwoodComponents.JS`, Blazor/.NET → `https://github.com/WildwoodWorks/WildwoodComponents.Net`, Swift → `https://github.com/WildwoodWorks/WildwoodComponents.Swift`
2. **Clone**, create a `fix/` branch, fix the bug, ensure tests pass
3. **PR** via `gh pr create` with reproduction steps
4. **Temporary workaround** in the user's app if urgent, with `// TODO: Remove workaround when WildwoodComponents PR #X is merged`

## Provisioning and Entitlement Traps

Five traps that have each cost a real app real user-facing breakage. They share a shape: the
account or request looks completely correct, and the failure appears somewhere far from the cause.
**Check these whenever an app provisions users, invites teammates, or gates features by tier.**

**1. Creating a user does not automatically grant app access.**
`POST api/users` takes `AppId` (stamped on the user record) and `AppIds` (the list
`GrantAppAccessAsync` walks). Only `AppIds` grants access, and login requires a `UserApps` row —
`AuthService` throws `UserNotAuthorizedForAppException` without one. The symptom is brutal to
diagnose: the member appears on the roster with the right company and the right app-role, the API
hands back a temporary password, and that password returns **403 NotAuthorizedForApplication**.
Supplying `AppId` alone is now normalised into `AppIds` by `UserCreationService`, so current
callers are fine — but if you provision through some other path, or against an older server, call
`POST api/UserRegistration/grant-app-access` (`{ userId, companyAppId }`, where `companyAppId` is
the app id) explicitly. It is idempotent and reactivates a revoked grant.
**Test it by logging in as the created user.** Asserting that they appear on the roster passes
throughout this bug's life.

**2. Revoking a registration token needs `revocationReason`, not `reason`.**
`RevokeTokenDto.RevocationReason` is `[Required]`, so the wrong field name fails model validation
with a 400 — which an app that maps upstream failures to its own status code will surface as a
confusing 502. A Revoke button can look wired up and have never once worked.

**3. Entitlements are per USER, and a teammate has no subscription.**
Only the person who bought the plan holds one. `app-tiers/{appId}/service/user-features/{userId}`
returns an **empty map** for everyone else, and an empty map from a 200 is a real "no access" — so
every teammate gets `feature_locked` and an upgrade prompt for a plan their team already pays for.
That makes any seat-based tier unsellable. If your app has teams, fall back to the tenant's
entitlement when the user's own check fails.
**Two things people miss.** First, do the same for LIMITS: a member with no subscription has no
limits either, and "no limits" reads as *unlimited*, so admitting them past the feature gate
without also metering them leaves seats, daily budgets and record caps binding the buyer alone.
Second, gate the fallback on the caller belonging to a *real* CompanyClient — see trap 4.

**4. Nothing in a JWT identifies the tenant's owner, and `company_client_id` can lie.**
The owner of a CompanyClient carries platform role `User` and no `app_role` — claims identical to
the teammates they invite. The only signal is their **ClientAdmin** role on the `UserCompanyClients`
row, which the roster exposes. Any "is this person an admin of their tenant" check that reads only
claims will lock the owner out the moment their team grows past one member.
Separately: `company_client_id` falls back to `company_id` when the claim is absent, so every
self-registered user in an app without per-signup client provisioning shares **one bucket**. That
bucket is not a team. Never inherit entitlement, metering or authority across it — an empty or
unreadable roster for a shared bucket fails open and hands paid features to everyone in it.

**5. A temporary password does not sign the user in.**
Login succeeds with **200 and `requiresPasswordReset: true`**, and the SDK holds the user on a
forced-reset step instead of returning a session. Two consequences: an API-level login check will
report the account healthy while a real user cannot get past the screen, so test this through the
UI; and `POST api/auth/reset-password` is `[Authorize]` and identifies the caller **from the JWT**
(the body carries no email or user id), so the reset must send the session token.

---

# Deploy

Build the user's app and publish it to **Wildwood hosting** — the default path. The app ends up
live at `https://{slug}.wildwoodapps.io`, managed entirely through MCP tools, with no other
provider account required.

Wildwood hosting runs each site as a container on Wildwood's own cluster. **It does not build your
code.** You build locally, zip the build output, and upload the zip; the platform unpacks it into
the container and serves it. `buildCommand` and `outputDirectory` are recorded on the deployment
for reference only — nothing runs them server-side.

If the user explicitly wants a different provider, or their stack is one Wildwood does not run
(Python, Go, Ruby, a custom Dockerfile), jump to
[Alternative: Other Hosting Platforms](#alternative-other-hosting-platforms).

## Deploy Step 1: Detect the Framework and Map It to a Runtime

Auto-detect the project type from the current working directory, then map it to a Wildwood runtime.
The runtime is an **integer** on `hosting_deployment_create`:

| Runtime | Value | Container | Serves |
|---------|-------|-----------|--------|
| Static | `1` | nginx | Files from the zip, with `index.html` fallback for unknown paths |
| React (SPA) | `2` | nginx | Same as Static — the label records intent |
| NodeJs | `3` | `node:22-alpine` | Runs `node <entryPoint>` (default `server.js`) |
| DotNet | `4` | `mcr.microsoft.com/dotnet/aspnet:10.0` | Runs `dotnet /workspace/<entryPoint>` |

Detection table:

| Indicator | Runtime | Value | What to ship |
|-----------|---------|-------|--------------|
| `package.json` with `vite`, `react`, `vue`, `svelte` (SPA build) | React | `2` | Contents of `dist/` (or `build/`) |
| Plain HTML/CSS/JS, or a static-site generator | Static | `1` | Contents of the output folder |
| `package.json` with `express`, `fastify`, `koa`, `hono` | NodeJs | `3` | App **plus** production `node_modules` |
| `package.json` with `next`, `nuxt` (SSR mode) | NodeJs | `3` | A self-contained server build — see the Node.js notes below |
| `package.json` with `next`/`nuxt` exporting a fully static site | Static | `1` | Contents of `out/` (or `.output/public`) |
| `*.csproj` — Blazor WebAssembly | Static | `1` | Contents of `publish/wwwroot/` |
| `*.csproj` — ASP.NET Core or Blazor **Server** | DotNet | `4` | Contents of `publish/`, `entryPoint` = the app `.dll` |
| `Dockerfile`, Python, Go, Ruby, PHP | *not supported* | — | Use the alternative platforms section |

Python is a declared runtime with **no serving image** — `hosting_deployment_create` rejects it
explicitly. Only `1`, `2`, `3` and `4` are accepted.

Tell the user what was detected and which runtime it maps to, and confirm before continuing.

### Start from a template (when there is nothing to detect)

If the directory holds no app yet, the platform ships starter projects that already carry a working
runtime, entry point and packaging shape:

```
hosting_list_templates()
   → id, name, runtime (the integer hosting_deployment_create takes), framework,
     buildCommand, outputDirectory, defaultEntryPoint, packagingNotes

hosting_get_template(templateId: "...", slug: "my-app")
   → the same metadata plus files: { "path/in/project": "content" }
```

Write each `files` entry to that path, then fill in whatever `remainingPlaceholders` reports —
`{{APP_ID}}` has no parameter on purpose, because the app id is yours to supply. From there the
flow is the normal one: Step 2 onwards, using the `runtime`, `defaultEntryPoint`, `buildCommand` and
`outputDirectory` the template reported, and `packagingNotes` for what to zip. Templates whose
packaging has more than one step (Next.js) ship a `README.md` in `files` that spells it out.

## Deploy Step 2: Pre-Flight Checks

1. **MCP connection active** — run `/wildwood setup` if not.
2. **Tier features.** Deployment creation is refused without them:
   - `APP_HOSTING` — required for every hosted site
   - `HOSTING_NODEJS` — additionally required for runtime `3`
   - `HOSTING_DOTNET` — additionally required for runtime `4`
   - `HOSTING_APP_COUNT` — the limit on how many sites the company may have
3. **Style check.** If WildwoodComponents are installed, check for a theme override file
   (`wildwood-theme.css`, `wildwoodTheme.ts`, `wildwood-overrides.css`). If missing, suggest
   `/wildwood integrate`; if present, scan for design token drift and offer to auto-fix.
4. **Environment variables.** Identify what the app needs — Wildwood SDK config
   (`VITE_WILDWOOD_API_URL`, `VITE_WILDWOOD_APP_ID`, or the framework equivalent) plus anything in
   `.env` / `.env.example`. For a client-side build (Static/React) these are baked in at build time
   and Wildwood never sees them. For NodeJs and DotNet they are supplied to the running container
   from the deployment's environment variables — set them with
   `hosting_set_env_vars(deploymentId, envVars, confirm: true)` **before** the deploy that should
   pick them up (see [Environment Variables](#environment-variables)).
   **Never put secrets in the zip** — see the blocked-file rules in Step 4.

## Deploy Step 3: Claim a Slug and Create the Deployment

```
hosting_check_slug(slug: "my-app")
```

Returns `{ slug, available: { available, reason, suggestions }, url }`. Rules: 3–50 characters,
lowercase alphanumeric with single hyphens, starting and ending alphanumeric. Platform names
(`www`, `api`, `admin`, `app`, `apps`, `docs`, `status`, `login`, `auth`, `mcp`, `cdn`, `portal`,
`console`, …) are reserved, as is the `stg-` prefix. An unavailable slug comes back with a reason
and suggested alternatives.

The `url` field is only present when the slug is available, and it reflects the **effective** slug
— on staging the platform prefixes `stg-`, so trust the returned URL rather than assembling one.
That prefix also eats into the length: the stored slug must fit 50 characters *including* it, so
**on staging the ceiling is 46**, not 50. The rejection message states the applicable maximum.

Then create the hosting slot:

```
hosting_deployment_create(
  appId: "...",
  slug: "my-app",
  runtime: 2,                    // 1=Static, 2=React, 3=NodeJs, 4=DotNet
  framework: "react",            // free-text label
  entryPoint: null,              // optional for NodeJs (default "server.js"),
                                 // REQUIRED for DotNet, unused for Static/React
  buildCommand: "npm run build", // recorded for reference only — never executed
  outputDirectory: "dist",       // the folder whose CONTENTS you zip
  containerSize: 0,              // optional: 0=Small (default), 1=Medium, 2=Large, 3=XL
                                 // Large/XL need HOSTING_LARGE_CONTAINERS
  confirm: true
)
```

The site is created **Pending** and serves nothing until a build is deployed. The response carries
`nextStep` naming the upload call with the new deployment id.

## Deploy Step 4: Build Locally and Package the Zip

### The zip-root rule (gets this wrong most often)

The platform unpacks the artifact with `unzip -o` straight into `/workspace`, which is the
container's document root / working directory. **The build output must be at the root of the zip,
not nested inside a folder.**

```bash
# Correct — contents at the zip root
cd dist && zip -r ../site.zip . && cd ..

# Wrong — creates site.zip containing a "dist/" folder; the site serves nothing
zip -r site.zip dist
```

```powershell
# PowerShell equivalent — note the \* which packs the CONTENTS
Compress-Archive -Path dist\* -DestinationPath site.zip -Force
```

Verify before uploading: `unzip -l site.zip | head` must show `index.html` / `server.js` /
`MyApp.dll` at the top level, with no leading directory component.

### Per-runtime build and packaging

| Runtime | Build | Zip the contents of | `entryPoint` |
|---------|-------|---------------------|--------------|
| Static / React (Vite) | `npm ci && npm run build` | `dist/` | — |
| Static (Next.js/Nuxt static export) | `npm ci && npm run build` | `out/` or `.output/public/` | — |
| NodeJs | `npm ci --omit=dev` | project root, **including `node_modules/`** | `server.js` (default) |
| NodeJs (Next.js SSR) | `npm ci && npm run build` with `output: 'standalone'` | `.next/standalone/` — after copying `.next/static` into `.next/standalone/.next/static` and `public/` into `.next/standalone/public` | `server.js` (the standalone one) |
| DotNet | `dotnet publish -c Release -o publish` | `publish/` | the app `.dll`, e.g. `MyApp.dll` |
| Static (Blazor WASM) | `dotnet publish -c Release -o publish` | `publish/wwwroot/` | — |

Miss the two copy steps on the Next.js row and the site loads with every stylesheet and script
404ing — the standalone output deliberately excludes both directories.

### Node.js notes

- **Dependencies must be in the zip.** Nothing runs `npm install` on the platform. Run
  `npm ci --omit=dev` locally and include the resulting `node_modules/` in the archive.
- **Listen on `process.env.PORT`.** The platform sets `PORT=8080` and binds the container port,
  Service and NetworkPolicy to 8080. That variable is applied *after* the deployment's own
  environment variables, so it cannot be overridden — an app that hard-codes a different port
  starts, looks healthy, and is unreachable.
- **`entryPoint`** defaults to `server.js`. If the app starts from `index.js` or `dist/main.js`,
  pass that path — it is resolved relative to `/workspace`.
- Next.js/Nuxt in SSR mode must produce a self-contained server bundle
  (`output: 'standalone'` for Next.js, `.output/` for Nuxt) whose entry file you name as
  `entryPoint`, with its dependencies packed alongside. `hosting_get_template` ships a Next.js
  starter already configured this way — do not hand-roll a `server.js` that wraps `next()`: it needs
  the full `node_modules` nothing installs on the platform, and binding anything but `0.0.0.0`
  leaves the container unreachable.

### .NET notes

- **`entryPoint` is required** and is the application assembly, e.g. `MyApp.dll`. There is no safe
  default, and creation of the container fails without it.
- The platform runs `dotnet /workspace/<entryPoint>` and sets `ASPNETCORE_URLS=http://+:8080`; like
  `PORT`, that value wins over anything the deployment sets.
- **Configure through environment variables, not environment-specific config files.**
  `appsettings.*.json` is on the platform's blocked-file list, and config-file reloading is
  disabled in the container. Keep `appsettings.json` for non-secret defaults and supply
  per-environment values as deployment environment variables (`ConnectionStrings__Default`,
  `Logging__LogLevel__Default`, and so on — `__` is the nesting separator).

### Package limits and rejected content

Validation runs before a single byte is stored, so a rejected package changes nothing:

| Rule | Limit |
|------|-------|
| Zip size | 100 MB |
| Entries | 10,000 |
| Total uncompressed | 500 MB |
| Per-entry compression ratio | 100× |
| Path traversal (`..`) or absolute paths | rejected |

Blocked files — the deploy fails with `Blocked file detected in zip` if any entry's **file name**
ends in **`.env`**, **`.pem`** or **`.key`**, is exactly **`web.config`**, or matches
**`appsettings.*.json`** — so `appsettings.Production.json` is rejected while a plain
`appsettings.json` of non-secret defaults still ships. The rules are matched against the file name
rather than the path, so a nested `config/.env` is caught the same as one at the zip root.

Secrets belong in deployment environment variables, never in the artifact. Do not try to work
around a block by renaming the file — the point is that the artifact is stored and unpacked into a
container, so anything in it is recoverable.

## Deploy Step 5: Get an Upload URL and Upload the Zip

Uploading goes straight to object storage rather than through the MCP connection — a zip cannot
travel as JSON.

```
hosting_get_upload_url(deploymentId: "...")
```

Returns:

```json
{
  "deploymentId": "...",
  "uploadId": "3f2a...32 hex chars...",
  "uploadUrl": "https://...presigned...",
  "expiresInMinutes": 15,
  "curlExample": "curl -X PUT --upload-file site.zip \"https://...\"",
  "nextStep": "After the upload finishes, call hosting_deployment_deploy(...)"
}
```

**Run the returned `curlExample` verbatim** (substituting your zip's path if it is not
`site.zip`). Do not add a `Content-Type` header — the URL is signed without one, and adding it
fails the signature check in a way that looks like a broken URL.

The URL authorizes exactly one object and **expires 15 minutes** after it is issued. Each upload is
consumed by one deploy, so a repeat deploy needs a fresh `hosting_get_upload_url` call.

## Deploy Step 6: Publish the Upload

```
hosting_deployment_deploy(deploymentId: "...", uploadId: "...", confirm: true)
```

Pass the **same `uploadId`** from Step 5. The tool validates the package, stores it as the next
numbered artifact version, points the site's container workload at it, and **waits for the rollout
to become ready** before answering.

Response fields: `success`, `alreadyInProgress`, `version`, `url`, `status`, `packageSizeBytes`,
`message` (the failure reason when the rollout did not come up) and the full `log` entry.

## Deploy Step 7: Verify

```
hosting_deployment_get(deploymentId: "...")
```

Returns `{ deployment, workload, note }`. `workload` is live cluster state:

| `workload.phase` | Meaning |
|------------------|---------|
| `Running` | The site is up — this is what you are waiting for |
| `Progressing` | Rollout still in flight; poll again |
| `Failed` | The container did not come up — go to `hosting_deployment_logs` |
| `Stopped` | Scaled to zero (see `hosting_deployment_start`) |
| `NotFound` | No workload exists yet — nothing has been deployed |

If the cluster cannot be reached, `workload` is `null` and `note` explains why; the stored
deployment record is still returned.

Once `Running`, visit the `url` on the returned `deployment` and test: the app loads, client-side
routes resolve, WildwoodComponents work (auth flow, styling, API calls). Use that field rather than
assembling `https://{slug}.wildwoodapps.io` yourself — on staging the platform prefixes the slug
with `stg-`, so a hand-built URL points at a hostname that does not exist.

## Deploy Step 8: Failure Paths

| Symptom | Cause and fix |
|---------|---------------|
| `"A deployment is already in progress for this site."` | Only one deploy or rollback per site runs at a time; a second is **refused, not queued**. The staged upload is consumed anyway — call `hosting_get_upload_url` and upload again before retrying. |
| `"No uploaded package found for uploadId ..."` | The 15-minute URL expired, the upload never completed, or that upload was already deployed. Get a fresh upload URL and re-upload. |
| `"Invalid uploadId"` | It must be the 32-character hex id returned by `hosting_get_upload_url`. |
| Deploy fails immediately, before any rollout, with `"Deployment failed. Contact support if the issue persists."` | The package was refused by validation and **nothing was uploaded**. The server deliberately does not echo the reason to the client, so check the package yourself: a `.env` / `.pem` / `.key` / `web.config` / `appsettings.*.json` entry (see the blocked-file rules above), a zip over 100 MB or 10,000 entries, or a `..` path. Remove the offending file and move its values into `hosting_set_env_vars`. |
| `"The uploaded package is N MB, which exceeds the 100 MB limit"` | Refused before it was even downloaded, and the staged upload is discarded. Trim the build — drop source maps, `node_modules` and bundled media — and upload again with a fresh `hosting_get_upload_url`. |
| Deploy succeeds, site returns 404s or a blank page | Almost always the zip-root rule (Step 4). Check `unzip -l site.zip`. |
| Deploy succeeds, site behaves wrong or crashes | `hosting_deployment_logs(deploymentId: "...", source: "runtime")` — the last ~200 lines of the container's own output. |
| Rollout failed | `hosting_deployment_logs(deploymentId: "...", source: "build")` — the platform's deploy history including the failure message. |
| Node app unreachable though the pod is healthy | It is not listening on `process.env.PORT` (8080). |
| Creation returned an error about features/limits | `APP_HOSTING`, plus `HOSTING_NODEJS` / `HOSTING_DOTNET`, plus the `HOSTING_APP_COUNT` limit. |

To undo a bad deploy: `hosting_deployment_rollback(deploymentId: "...", confirm: true)`.

## Deploy Step 9: Report

Report: the live URL, the runtime, the container size, the deployed version number,
`workload.phase`, and the NAMES of the environment variables set (never their values).

---

## Alternative: Other Hosting Platforms

Use this branch only when the user asks for a specific external provider, or their stack is one
Wildwood hosting does not run (Python, Go, Ruby, PHP, a custom Dockerfile). These are third-party
services with their own accounts and billing — Wildwood does not manage them, and none of the MCP
hosting tools apply.

| Platform | Best for | Deploy |
|----------|----------|--------|
| **Vercel** | React, Next.js, frontend | `npm i -g vercel && vercel --prod` |
| **Netlify** | Static sites, JAMstack | `npm i -g netlify-cli && netlify deploy --dir=dist --prod` |
| **Cloudflare Pages** | Global static delivery | `npm i -g wrangler && wrangler pages deploy dist --project-name=my-app` |
| **GitHub Pages** | Simple static sites, public repos | `npm i -D gh-pages && npx gh-pages -d dist` |
| **Railway** | Node.js, quick full-stack deploy | `npm i -g @railway/cli && railway up` |
| **Fly.io** | Containers, .NET, any Dockerfile | `fly auth login && fly launch && fly deploy` |
| **Render** | Node.js with auto-deploy from git | Dashboard |

Notes:

- Env vars: `vercel env add KEY`, `railway variables set KEY=value`, `fly secrets set KEY=value`.
- SPA routing on Netlify needs a `_redirects` file containing `/* /index.html 200`.
- Most of these support connecting a GitHub repo for automatic deploys on push — worth recommending
  for ongoing projects.
- Build locally first with the same commands as Step 4; these platforms differ in whether they
  rebuild server-side.

After deploying externally, verify the live URL and check for the usual suspects: SPA routing
404s, missing env vars, CORS, and mixed content.

---

# Hosting

Manage Wildwood-hosted app deployments. Every site is served at
`https://{slug}.wildwoodapps.io`.

Each deployment is one container on Wildwood's cluster: an init container unpacks the uploaded
build artifact into `/workspace`, and the runtime container serves it. Static and React sites are
served by nginx with an `index.html` fallback for client-side routes; NodeJs and DotNet sites run
your process on port 8080.

For the end-to-end build-and-publish walkthrough, see **[Deploy](#deploy)**. This section is the
tool reference and the lifecycle operations.

## Prerequisites

- MCP connection active (run `/wildwood setup` if not)
- `APP_HOSTING` tier feature, plus `HOSTING_NODEJS` or `HOSTING_DOTNET` for those runtimes
- Within the `HOSTING_APP_COUNT` limit

## Tool Reference

### Read

| Tool | Notes |
|------|-------|
| `hosting_deployment_list` | Every site in the company: name, slug, runtime, framework, status, current version, live URL. Live cluster state is deliberately excluded (one round-trip per row). |
| `hosting_deployment_get(deploymentId)` | `{ deployment, workload, note }` — `workload.phase` is `NotFound` / `Progressing` / `Running` / `Failed` / `Stopped`, with `readyReplicas`, `desiredReplicas` and a message. `workload` is `null` and `note` explains when the cluster is unreachable. |
| `hosting_get_upload_url(deploymentId)` | Step 1 of deploying. Presigned PUT URL + `uploadId`, valid **15 minutes**. Creates nothing and changes no state. |
| `hosting_deployment_logs(deploymentId, source)` | `source: "build"` (default) = platform deploy/rollback/start/stop history, newest first, with failure messages. `source: "runtime"` = last ~200 lines of the live container's output. Runtime logs are empty until a pod is running. |
| `hosting_check_slug(slug)` | Availability plus a reason and suggestions when taken. The returned `url` uses the *effective* slug (staging prefixes `stg-`). |
| `hosting_domain_list(deploymentId)` | Custom domains recorded for a deployment. |
| `hosting_metrics(deploymentId, days)` | Requests, response times, error rates, bandwidth. Defaults to 30 days. |

### Write (all require `confirm: true`)

| Tool | Notes |
|------|-------|
| `hosting_deployment_create(appId, slug, runtime, ...)` | Creates the slot, **Pending**, serving nothing. `runtime` is `1`=Static, `2`=React, `3`=NodeJs, `4`=DotNet. Optional `containerSize`: `0`=Small (default), `1`=Medium, `2`=Large, `3`=XL — Large/XL need `HOSTING_LARGE_CONTAINERS`. |
| `hosting_deployment_deploy(deploymentId, uploadId, confirm)` | Step 2 of deploying. Publishes an already-uploaded package, waits for the rollout. The package size is checked **before** it is downloaded, so an oversized upload is refused rather than deployed. |
| `hosting_set_env_vars(deploymentId, envVars, confirm)` | **Replaces** the site's environment variables (encrypted at rest, never read back). Applied on the **next deploy or rollback**, not immediately. See [Environment Variables](#environment-variables). |
| `hosting_deployment_start(deploymentId, confirm)` | Scales back up. **Only a `Stopped` site that already has a deployed artifact.** |
| `hosting_deployment_stop(deploymentId, confirm)` | Scales to zero, keeps the artifact. **An `Active` or `Failed` site** — a failed site's container is often still running. |
| `hosting_deployment_rollback(deploymentId, confirm)` | Back one version, `v{N}` → `v{N-1}`, and waits for the rollout. |
| `hosting_deployment_delete(deploymentId, confirm)` | Removes the workload, every artifact version and the record. The slug becomes claimable again. Irreversible. A site that is mid-build or mid-deploy is refused — wait for the deploy to finish, then delete. |
| `hosting_domain_add(deploymentId, domain, confirm)` | Records a custom domain — see the note below. |
| `hosting_domain_remove(domainId, confirm)` | Removes it; the site stays reachable at its `wildwoodapps.io` address. |

### Create parameters

```
hosting_deployment_create(
  appId: "...",
  slug: "my-app",
  runtime: 2,                    // 1=Static, 2=React, 3=NodeJs, 4=DotNet
  framework: "react",            // free-text label
  entryPoint: null,              // optional for NodeJs (default "server.js"),
                                 // REQUIRED for DotNet, unused for Static/React
  buildCommand: "npm run build", // reference only — never executed server-side
  outputDirectory: "dist",
  containerSize: 0,              // optional: 0=Small (default), 1=Medium, 2=Large, 3=XL
  confirm: true
)
```

An out-of-range `runtime` or `containerSize` is rejected up front. Python is a declared runtime with
no serving image and is refused explicitly.

## Workflow: Deploy a New App

1. Check features and limits (`APP_HOSTING`, plus `HOSTING_NODEJS`/`HOSTING_DOTNET`)
2. `hosting_check_slug(slug: "my-app")`
3. `hosting_deployment_create(...)` — see the runtime table above
4. For NodeJs/DotNet: `hosting_set_env_vars(deploymentId, envVars, confirm: true)` — BEFORE the
   deploy, since variables are only applied during a rollout
5. Build locally and zip the **contents** of the output directory (see [Deploy](#deploy) Step 4)
6. `hosting_get_upload_url(deploymentId)` → run the returned `curlExample` to PUT the zip
7. `hosting_deployment_deploy(deploymentId, uploadId, confirm: true)`
8. `hosting_deployment_get(deploymentId)` until `workload.phase` is `Running`, then visit the URL

## Start / Stop Guards

Stop and start are **scale operations**, not redeploys — the artifact and version are untouched, so
a stopped site comes straight back up on the same build.

- `hosting_deployment_stop` accepts status **Active or Failed**. A failed site's container is often
  still running — a rollout that never became ready, a pod that crashlooped after serving — so
  stopping it is how a broken site is taken off the air. A **Pending** site has never had a workload,
  and a site that is mid-build, mid-deploy or being deleted belongs to that operation; both are
  refused.
- `hosting_deployment_start` requires status **Stopped** *and* an already-deployed artifact. A site
  that has never been deployed cannot be started — deploy it instead.

Both return `success: false` with an explanatory `message` rather than throwing.

## Rollback Semantics

`hosting_deployment_rollback` moves the site back exactly one version and waits for that rollout.

- Only the **last few versions are retained**. A rollback whose target artifact has already been
  pruned is refused, and the site keeps serving what it is serving.
- Refusals (nothing to roll back to, or a deploy already in flight) come back as `success: false`
  with the reason. A rollback that reaches the cluster but does not come up is reported as a
  failure, not a success.
- A failed deploy keeps the new version number and artifact key on purpose — the workload really
  was pointed at them. Rollback is the way back, not a status edit.

## Custom Domains

`hosting_domain_add` / `hosting_domain_list` / `hosting_domain_remove` record and track a custom
domain against a deployment, but **routing for custom domains is not wired up yet** — the site's
ingress currently serves only `{slug}.wildwoodapps.io`. Adding a domain will not make it serve.

**Custom domain routing is coming in v1.1.** Until then, use the `wildwoodapps.io` subdomain, or
put the site behind your own CDN/proxy pointing at that hostname.

## Environment Variables

A deployment's environment variables are delivered to the running container (NodeJs and DotNet;
Static/React are already built, so their configuration must be baked in at build time instead).

```
hosting_set_env_vars(
  deploymentId: "...",
  envVars: { "DATABASE_URL": "Host=...;Port=5432;...", "NODE_ENV": "production" },
  confirm: true
)
```

Four things to know:

- **It REPLACES the whole set.** Pass every variable the site needs, not just the changed ones;
  `{}` clears them all. There is no per-key edit.
- **Names are restricted** to letters, digits, `-`, `_` and `.` — each one becomes a key of the
  site's Kubernetes Secret, which allows nothing else. An invalid name is refused by the tool, by
  name, rather than failing a later deploy.
- **Values are encrypted at rest** and never read back: the tool answers with the variable *names*
  and a count, never the values.
- **They take effect on the NEXT DEPLOY OR ROLLBACK — not immediately.** The site's Secret is
  written during a rollout, and a container reads its environment once at start. Setting variables
  on a running site changes nothing until you deploy again (`hosting_get_upload_url` →
  `hosting_deployment_deploy`). Set them *before* the deploy that should use them.

The platform's own wiring wins over yours: `PORT=8080` for NodeJs and
`ASPNETCORE_URLS=http://+:8080` for DotNet are applied last, because the container port, Service
and network policy all hard-code 8080.

## Container Size

Every site runs `Small` (0.25 vCPU / 0.5 GB) unless told otherwise. Pass `containerSize` to
`hosting_deployment_create`, or `PUT /api/hosting/deployments/{id}` to change it later:

| Value | Size | CPU / memory limit | Gated by |
|-------|------|--------------------|----------|
| `0` | Small (default) | 0.25 vCPU / 0.5 GB | — |
| `1` | Medium | 0.5 vCPU / 1 GB | — |
| `2` | Large | 1 vCPU / 2 GB | `HOSTING_LARGE_CONTAINERS` |
| `3` | XL | 2 vCPU / 4 GB | `HOSTING_LARGE_CONTAINERS` |

Like environment variables, a size change **takes effect on the next deploy** — the resource
envelope lives in the pod template, which is rewritten during a rollout. Moving *down* a size is
always allowed; moving *up* into Large/XL is re-checked against the feature every time.

## Tier Features and Limits

The platform enforces these keys; the actual per-tier numbers live in your tier configuration —
read them with `wildwood_list_app_tiers` or in WildwoodAdmin, and see WildwoodAdmin for add-on
pricing.

| Key | Kind | Governs |
|-----|------|---------|
| `APP_HOSTING` | feature | Access to hosting at all |
| `HOSTING_NODEJS` | feature | Creating a NodeJs (`3`) deployment |
| `HOSTING_DOTNET` | feature | Creating a DotNet (`4`) deployment |
| `HOSTING_LARGE_CONTAINERS` | feature | `containerSize` Large (`2`) and XL (`3`) |
| `HOSTING_APP_COUNT` | limit | Number of hosted sites |
| `HOSTING_STORAGE_MB` | limit | Artifact storage, checked on every deploy |
| `HOSTING_BANDWIDTH_GB` | limit | Monthly bandwidth |
| `HOSTING_CUSTOM_DOMAIN_COUNT` | limit | Custom domains per company |

Bandwidth is metered against `HOSTING_BANDWIDTH_GB` and enforced automatically: the platform warns
a company's admins at 80% of the monthly allowance and **stops its sites at 150%**.

A company can be exempted with a `HOSTING_BANDWIDTH_UNMETERED` feature override, which belongs to no
tier by design. **Granting it is a Wildwood-operator action, not something you can do from here** —
`wildwood_set_feature_override` cannot write it. The exemption has to be recorded against
(app `wildwood-admin`, the *customer's* company id), and the MCP tool takes both ids from the
caller's own token, so it can only ever write the override for the caller's own company against
their own app. Ask Wildwood support; internally it is a platform-admin call:

```
POST /api/app-tiers/wildwood-admin/admin/feature-overrides
{ "featureCode": "HOSTING_BANDWIDTH_UNMETERED", "isEnabled": true,
  "targetCompanyId": "<customer company id>", "reason": "..." }
```

`targetCompanyId` is refused for anyone who is not a platform admin. It is revoked by re-posting the
same override with `"isEnabled": false`.

Package ceilings are platform-wide, not tier-based: 100 MB zip, 10,000 entries, 500 MB
uncompressed.

## Troubleshooting

- **"Feature not enabled" / create returned an error**: check `APP_HOSTING`, and
  `HOSTING_NODEJS` / `HOSTING_DOTNET` for that runtime.
- **"Limit exceeded"**: `HOSTING_APP_COUNT` on create, `HOSTING_STORAGE_MB` on deploy. Upgrade the
  tier or add an add-on.
- **"A deployment is already in progress"**: one deploy or rollback per site at a time; the second
  is refused, not queued, and the staged upload is discarded. Get a fresh upload URL and retry.
- **Deploy succeeded but the site 404s or is blank**: the zip almost certainly has a nested folder
  at its root. Check `unzip -l site.zip`.
- **Deploy succeeded but the app misbehaves**: `hosting_deployment_logs(source: "runtime")`.
- **Rollout failed**: `hosting_deployment_logs(source: "build")` for the failure message.
- **Site unreachable though the pod looks healthy**: the app is not listening on 8080.
- **Custom domain not serving**: expected — routing lands in v1.1 (see above).

---

# Database Hosting

Provision and manage **hosted PostgreSQL 16 databases** on Wildwood's managed cluster. Each
database gets its own dedicated owner role, its own storage quota and its own connection budget.

> **Read this before provisioning: the database is reachable from inside the cluster only.**
> In v1 the hosted PostgreSQL instance is not exposed to the public internet. The connection string
> works from apps running on **Wildwood hosting**; it will **not** connect from a developer
> workstation, from CI, or from an app hosted anywhere else. If the user needs to connect from
> their laptop, this is not the right product for them yet — tell them plainly rather than letting
> them provision and then debug a timeout.

## Prerequisites

- MCP connection active (run `/wildwood setup` if not)
- `DB_HOSTING` tier feature — creation throws `FeatureNotEnabledException` without it
- `DB_HOSTING_ELASTIC_POOL` additionally, for the Elastic tier
- Within the `DB_HOSTED_COUNT` and `DB_STORAGE_MB` limits

## Tool Reference

### Read

| Tool | Notes |
|------|-------|
| `database_hosting_list` | Names, slugs, engines, tiers, statuses, storage usage. |
| `database_hosting_get(databaseId)` | One database's configuration, status and storage usage. |
| `database_hosting_stats(databaseId)` | Current on-disk size, the tier's storage quota, active backend connections. |
| `database_hosting_get_connection(databaseId)` | The Npgsql connection string for the owner role. **Sensitive — audit-logged.** |
| `database_hosting_backup_list(databaseId)` | Each `Completed` entry is a `pg_dump` custom-format archive stored off-server. |

### Write (all require `confirm: true`)

| Tool | Notes |
|------|-------|
| `database_hosting_create(name, slug, appId, ...)` | Provisions in the background — returns `Provisioning`, becomes `Active` shortly after. |
| `database_hosting_update(databaseId, ...)` | Metadata only: `name`, `description`, `backupEnabled`. Does **not** change engine, tier or credentials. |
| `database_hosting_suspend(databaseId)` | Refuses new connections, terminates existing sessions, drops the owner role's connection budget to zero. Data retained. |
| `database_hosting_resume(databaseId)` | Reopens connections and restores the tier's connection budget. |
| `database_hosting_rotate_credentials(databaseId)` | Mints a new owner-role password and **returns the new connection string** — the only time it is shown. The old password stops working immediately, so update every consumer. **Sensitive — audit-logged.** Requires an `Active` database. |
| `database_hosting_backup_create(databaseId)` | Runs in the background — returns `InProgress`, becomes `Completed` once uploaded. |
| `database_hosting_backup_restore(databaseId, backupId)` | **Overwrites the database.** Synchronous; can take a while. |
| `database_hosting_delete(databaseId)` | Soft-deletes immediately and recoverably; the database and its owner role are dropped for good after a **7-day grace period**. |

### Provision a database

```
database_hosting_create(
  name: "My App Database",
  slug: "my-app-db",
  appId: "...",
  description: "Primary database for my application",
  databaseType: "PostgreSql",    // optional; the only engine offered and the default
  hostingTier: "Basic",          // Basic (default), Standard, or Elastic
  confirm: true
)
```

`databaseType: "SqlServer"` is **rejected** — SQL Server hosting is not offered on this platform.
Omit `databaseType` and the platform default (PostgreSql) applies.

**Tiers:**

| Tier | Storage (soft quota) | Concurrent connections |
|------|----------------------|------------------------|
| Basic | 2 GB | 10 |
| Standard | 10 GB | 25 |
| Elastic | 25 GB | 50 |

Storage is a soft quota; the connection budget is enforced on the database's owner role, so
exceeding it produces connection refusals rather than a throttle. Elastic additionally requires the
`DB_HOSTING_ELASTIC_POOL` feature.

## Workflow: Set Up a New Database

1. Confirm the app will run **on Wildwood hosting** — see the reachability note above
2. Check `DB_HOSTING` availability and existing databases: `database_hosting_list`
3. `database_hosting_create(...)`
4. Poll `database_hosting_get(databaseId)` until `status` is `Active`. Statuses are `Pending`,
   `Provisioning`, `Active`, `Suspended`, `Deleting`, `Failed`. (WildwoodAdmin's Databases page
   gets the same transitions pushed live over SignalR; via MCP you poll.)
5. `database_hosting_get_connection(databaseId)` — returns Npgsql format:
   `Host=...;Port=5432;Database=...;Username=...;Password=...`
6. Store it as an environment variable on the hosted deployment —
   `hosting_set_env_vars(deploymentId, envVars: { "DATABASE_URL": "<the connection string>" }, confirm: true)`
   — never in the deployed zip, which rejects `.env` files. Remember it replaces the whole set, and
   that the site only picks it up on its **next deploy**

## Connecting From Your App

The connection string comes back in **Npgsql key/value form**. Some clients want a URL instead:
`postgresql://{username}:{password}@{host}:{port}/{database}`.

**C# / .NET (Npgsql)** — use the string as returned:

```csharp
// Program.cs
builder.Services.AddDbContext<AppDbContext>(o =>
    o.UseNpgsql(builder.Configuration.GetConnectionString("Default")));
```

Supply it as the `ConnectionStrings__Default` environment variable on the deployment. Do not put it
in `appsettings.Production.json` — those files are on the hosting blocked-file list.

**Node.js (node-postgres)**:

```js
import pg from 'pg';
const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL });
// DATABASE_URL = postgresql://user:password@host:5432/dbname
```

**Prisma** — needs the URL form in `DATABASE_URL`:

```prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}
```

```
DATABASE_URL="postgresql://user:password@host:5432/dbname"
```

Note that Prisma migrations run from wherever you run the CLI — which, given the in-cluster-only
reachability, means they cannot be run from a laptop in v1.

**Python (psycopg)**:

```python
import psycopg
conn = psycopg.connect(os.environ["DATABASE_URL"])  # postgresql://user:password@host:5432/dbname
```

Keep a connection pool sized under the tier's connection budget (10 / 25 / 50) — the limit is
enforced on the role, and serverless or per-request connections exhaust it quickly.

## Backups

- A backup is a **`pg_dump` custom-format archive** (`.dump`), not plain SQL, stored off-server.
- `database_hosting_backup_create` runs in the background: the row is returned `InProgress` and
  becomes `Completed` when the archive has uploaded. Poll `database_hosting_backup_list`.
- Restore runs **`pg_restore --clean --if-exists`**: every existing object is dropped and recreated
  from the archive. Anything written since that backup is gone. It runs synchronously and can take
  a while on a large database.
- Automatic backups are toggled with `database_hosting_update(backupEnabled: ...)`.

## Rotating Credentials

`database_hosting_rotate_credentials(databaseId, confirm: true)` mints a new owner-role password and
returns the new connection string in its answer. (It is not the only way to read it afterwards —
`database_hosting_get_connection` returns the current string too — but taking it from the rotation's
own answer saves a second audit-logged reveal.)

**The old password stops working immediately**, so treat rotation as a two-step change: rotate, then
push the new string to every consumer. On Wildwood hosting that is
`hosting_set_env_vars(deploymentId, envVars: { "DATABASE_URL": "<the new string>" }, confirm: true)`
followed by a **redeploy** — env vars are applied on the next deploy, so a rotation without one
leaves the site holding a password that no longer works.

Requires an `Active` database. Rotate on a schedule, when a connection string has been shared or
committed by accident, or when someone with access leaves.

## Troubleshooting

- **"Feature not enabled"**: the company lacks `DB_HOSTING` (or `DB_HOSTING_ELASTIC_POOL` for
  Elastic). Upgrade the tier.
- **"Limit exceeded"**: `DB_HOSTED_COUNT` or `DB_STORAGE_MB`. Note the storage limit is charged at
  create time against the *tier's* quota, so a Standard database needs 10 GB of headroom.
- **"SQL Server hosting is not offered on this platform; use PostgreSql."**: drop the
  `databaseType` argument.
- **Connection times out from a local machine**: expected in v1 — the instance is in-cluster only.
- **Connection refused / too many clients**: the owner role's connection budget for the tier is
  exhausted, or the database is `Suspended`. Check `database_hosting_stats` and
  `database_hosting_get`.
- **Authentication suddenly failing after a rotation**: the site is still running with the old
  `DATABASE_URL`. Env vars take effect on the **next deploy** — set them, then redeploy.
- **Stuck in "Provisioning"**: re-check with `database_hosting_get`; a `Failed` database can be
  retried from WildwoodAdmin > Hosting > Databases.

---

# Status

Check the health and status of Wildwood platform resources.

## Status Step 1: Check MCP Server Health

Verify the MCP server is reachable by fetching the health endpoint (no auth required):

```
GET https://api.wildwoodworks.io/api/health/mcp
```

Use `WebFetch` or `curl` to call this endpoint. Parse the JSON response:

- **If 200 + `status: "healthy"`**: Report "MCP server: Online" and show `toolCount` from the response
- **If non-200 or unreachable**: Report "MCP server: Unreachable" — the server may be down. Suggest checking https://api.wildwoodworks.io/api/health for general API health.

## Status Step 2: Check MCP Client Connection

1. Try calling `wildwood_get_app_info` via MCP
2. If successful, report: "MCP connection: Authenticated — connected as {user}"
3. If MCP tools are not available in this session:
   - Report: "MCP connection: Not Connected"
   - If the health check passed (server is online), the issue is client-side. Follow **Setup Step 3** (3a → 3b → 3c) to re-register and reconnect the MCP server. If the browser popup still doesn't appear after restart, run the **OAuth Diagnostics** in Setup Step 3d to determine whether the bug is in Wildwood or in Claude Code.
   - If the health check also failed, the server itself may be down

## Status Step 3: App Overview

Use MCP tools to gather:

### Current App
- `wildwood_get_app_info` — App name, ID, status, creation date

### All Apps
- `wildwood_list_apps` — List all company apps with status

### Component Status
- `wildwood_list_component_configs` — Show which features are enabled:
  - AI configurations (active count)
  - Authentication (enabled, provider count)
  - Messaging (enabled/disabled)
  - Payments (enabled/disabled)
  - Theme (configured/not)
  - Captcha (enabled/disabled)
  - Disclaimers (count)
  - Subscriptions (enabled/disabled)

## Status Step 4: Hosting & Database Status

### App Hosting
- `hosting_deployment_list` — List all hosted deployments
- Show: Name, slug, status, framework, URL. Deployment statuses are `Pending`, `Building`,
  `Deploying`, `Active`, `Failed`, `Stopped`, `Deleting` — a serving site is **`Active`**. (`Running`
  is the *workload* phase reported by `hosting_deployment_get`, which is a different vocabulary.)
  `Deleting` is transient: a site whose delete is in flight. A site left sitting in it means a delete
  died half-way — deleting it again is the recovery, and is allowed.

### Database Hosting
- `database_hosting_list` — List all hosted databases
- Show: Name, slug, tier, status, storage usage

## Status Step 5: Analytics

Use `wildwood_get_analytics` to show recent usage:
- Total users
- AI requests (last 30 days)
- Messages (last 30 days)
- Top actions by frequency

## Status Step 6: Tier & Quota Usage

Use `wildwood_list_app_tiers` to show:
- Available tiers and pricing
- Feature limits per tier
- Current tier (if subscription data available)

## Status Step 7: Report Summary

Present a clean status report:

```
=== Wildwood Platform Status ===

MCP Server:     Online ({toolCount} tools)
MCP Connection: Authenticated
App: {name} ({appId})
Company: {companyName}

Components:
  AI:             {count} active configs
  Authentication: Enabled ({providerCount} providers)
  Messaging:      Enabled/Disabled
  Payments:       Enabled/Disabled
  Subscriptions:  Enabled/Disabled

Hosting:
  Deployments: {count} ({active} active)
  Databases:   {count} ({active} active, {totalMB}MB used)

Usage (Last 30 Days):
  Users:       {total}
  AI Requests: {count}
  Messages:    {count}

Admin Portal: https://admin.wildwoodworks.io
```

## Troubleshooting

- **MCP server unreachable** → API may be down, check https://api.wildwoodworks.io/api/health
- **MCP not connected** → Run `/wildwood setup`
- **No apps** → Create one in WildwoodAdmin or via `/wildwood setup`
- **Features not configured** → Configure in WildwoodAdmin or via `/wildwood integrate`
- **No deployments** → Run `/wildwood deploy`

---

# Platform Reference

Background knowledge about the Wildwood platform architecture, SDK, and MCP tools.

**Deep references** (in this skill's `references/` directory — read when the topic comes up):
- `seeding-and-service-keys.md` — client vs service keys, scopes (`tiers:manage`, `ai:manage`, `roles:manage`),
  the seed ledger's environment label, live-API gotchas for idempotent tasks
- `ai-configuration.md` — model-name→provider routing, `configurationType` page filters,
  retired model ids, the ensure routes, the skill-carries-the-prompt chat pattern

## Platform Architecture

```
User's App (React, RN, Blazor, Swift/iOS, Node.js)
  └─ WildwoodComponents SDK (@wildwood/core + framework pkg, or WildwoodCore/WildwoodSwiftUI)
       │ HTTPS + JWT + SignalR
       ▼
WildwoodAPI (.NET 10) — api.wildwoodworks.io
  REST API (/api/*) + SignalR (/hubs/*) + MCP (/mcp)
  Multi-tenant: Company → App → User
       │
       ▼
WildwoodAdmin (Razor Pages) — admin.wildwoodworks.io
  App config, analytics, users, AI, payments, hosting
```

## Multi-Tenant Model

- **Company**: Root tenant. Owns apps, users, providers, configuration.
- **CompanyApp**: Application within a company. All data scoped by AppId.
- **User**: Belongs to company, accesses apps based on roles.
- **Roles**: Admin (platform), CompanyAdmin (company-level), User (app-level).

## SDK Package Reference

### @wildwood/core (Always Required)

**Services:** AuthService, SessionManager, AIService, AIFlowService, AIFlowSubscriptionService, DocumentService, MessagingService, PaymentService, TwoFactorService, CaptchaService, DisclaimerService, AppTierService, ThemeService, NotificationService, FeedbackService

**Client Factory:**
```typescript
import { createWildwoodClient } from '@wildwood/core';
const client = createWildwoodClient({ apiUrl, appId, platform? });
```

**Events:** `authChanged`, `sessionExpired`, `tokenRefreshed`, `themeChanged`, `error`

### @wildwood/react
- Provider: `<WildwoodProvider client={client}>`
- Hooks: `useAuth()`, `useAIChat()`, `useAIFlow()`, `useDocuments()`, `useMessaging()`, `usePayments()`, `useSubscriptions()`, `useFeatures()`, `useTheme()` (21 hooks)
- 59 pre-built UI components
- Styles: `@wildwood/react/styles`

### @wildwood/react-native
- Same hook API as React (shared via `@wildwood/react-shared`), native UI components, StyleSheet themes

### @wildwood/node
- `createAuthMiddleware(client)` — JWT validation for Express
- `createProxyMiddleware(client)` — AI API proxy
- `AdminClient` — server-side admin operations
- `tokenValidator` — JWT verification
- `runSeeder(options, tasks)` — idempotent startup app-data seeding (X-API-Key auth; mint ONE service key with `scopes: "ai:manage roles:manage tiers:manage"` for tier-catalog, AI, and app-roles provisioning tasks; server-side ledger + history — see `references/seeding-and-service-keys.md`)

### WildwoodComponents.Blazor
- Components: `<AuthenticationComponent>`, `<AIChatComponent>`, `<AIFlowComponent>`, `<MessagingComponent>`, `<PaymentComponent>`, `<ThemeComponent>`, `<AppTierComponent>`, `<FeatureGateComponent>`, `<DisclaimerComponent>`, `<ConsentComponent>`, `<NotificationComponent>`, `<FeedbackComponent>` (29 components; `WildwoodComponents.Razor` mirrors them as MVC ViewComponents)
- `WildwoodComponents.Shared` hosts the framework-neutral Seeder (`ISeederTask`, `SeederRunner`, auto-startup `SeederRunnerService`)

### WildwoodComponents.Swift (WildwoodCore + WildwoodSwiftUI)
- SPM package, iOS 26+, Swift 6 strict concurrency
- `WildwoodClient` factory mirrors `@wildwood/core` method-for-method: `auth`, `session`, `ai` (+ flows and flow subscriptions), `documents`, `messaging`, `payment`, `appTier`, `twoFactor`, `captcha`, `disclaimer`, `feedback`, `notifications`, `theme`
- 31 SwiftUI components with `@Observable` view models; tokens stored in the Keychain
- Payments are processor-agnostic: StoreKit 2 for the App Store path, web checkout for other providers

## API Conventions

- Base URL: `https://api.wildwoodworks.io/api`
- Auth: JWT Bearer token
- Login response: `{ jwtToken, email, firstName, ... }` (no `token` alias, no `user` sub-object)
- DTO naming: PascalCase (Email, Password, AppId)

## MCP Tools (114 total: 53 read, 61 write)

All write tools require `confirm: true` and auto-snapshot before changes.

> The tables below list the most-used tools, not every one. The counts in the headings are the true
> totals (verified by counting `[McpServerTool]` in the server's `MCPServerTools/`); the rows are a
> subset.

### Read Tools (53)

| Tool | Description |
|------|-------------|
| `wildwood_get_app_info` | Current app configuration |
| `wildwood_list_apps` | All company apps |
| `wildwood_get_ai_config` | AI configurations (no API keys) |
| `wildwood_get_auth_config` | Auth provider configuration |
| `wildwood_list_available_providers` | Available auth, AI, payment providers |
| `wildwood_list_users` | Company users with roles |
| `wildwood_get_messaging_config` | Messaging settings |
| `wildwood_get_payment_config` | Payment config (no secrets) |
| `wildwood_get_disclaimer_config` | Disclaimer configuration |
| `wildwood_list_app_tiers` | Tiers with features, limits, pricing |
| `wildwood_list_component_configs` | All component status (incl. seeder summary) |
| `wildwood_get_integration_guide` | Dynamic SDK setup instructions |
| `wildwood_get_analytics` | App usage analytics |
| `wildwood_list_config_snapshots` | Config backup snapshots |
| `wildwood_list_ai_providers` | Company AI providers (masked keys) |
| `wildwood_list_system_providers` | System-level AI providers |
| `wildwood_list_pricing_models` | Company pricing models |
| `wildwood_get_theme` | App theme configuration |
| `wildwood_get_captcha_config` | CAPTCHA configuration (no secrets) |
| `wildwood_get_subscription_config` | Subscription settings |
| `wildwood_list_feature_overrides` | Active per-user / per-company feature overrides |
| `wildwood_list_expiring_overrides` | Feature overrides expiring within N days |
| `wildwood_get_feedback_config` | App feedback-widget configuration |
| `wildwood_get_feedback_analytics` | Feedback volume/trend analytics |
| `wildwood_get_consent_config` | App cookie/consent configuration |
| `wildwood_list_company_scripts` | Company-level third-party scripts |
| `wildwood_list_app_scripts` | App-level third-party scripts |
| `wildwood_list_app_settings` | App key/value settings (encrypted values masked) |
| `wildwood_list_seed_ledger` | Seed run ledger (seeded state per task per environment) |
| `wildwood_list_seed_history` | Dated seed run history, newest first |
| `wildwood_list_api_providers` | Company API providers (slug, auth, spec, MCP wrap state) |
| `wildwood_detect_api` | Detect any API's spec/auth/endpoints from a URL or pasted spec |
| `wildwood_get_mcp_wrap_url` | Public MCP wrap URL + claude mcp add instructions |
| `hosting_list_templates` | Starter templates: runtime, build command, output directory, entry point, packaging notes |
| `hosting_get_template` | One template's metadata plus its files as `{ path: content }`, placeholders substituted |
| `hosting_check_slug` | Check if a hosting subdomain slug is available |
| `hosting_deployment_list` | List app deployments |
| `hosting_deployment_get` | Deployment record + live cluster workload phase |
| `hosting_get_upload_url` | Presigned URL to upload a build package (step 1 of deploying) |
| `hosting_deployment_logs` | Deploy history (`source: "build"`) or live container output (`source: "runtime"`) |
| `hosting_domain_list` | List custom domains for a deployment |
| `hosting_metrics` | Hosting metrics (requests, bandwidth, errors) |
| `database_hosting_list` | List provisioned PostgreSQL databases |
| `database_hosting_get` | Get database details |
| `database_hosting_stats` | Database size, quota, active connections |
| `database_hosting_get_connection` | Npgsql connection string (in-cluster reachable only) |
| `database_hosting_backup_list` | List `pg_dump` archive backups |

### Write Tools (61)

| Tool | Description |
|------|-------------|
| `wildwood_create_app` | Create new app |
| `wildwood_update_app_config` | Update app settings |
| `wildwood_manage_ai_config` | Create/update AI configurations |
| `wildwood_manage_ai_provider` | Create/update AI provider |
| `wildwood_delete_ai_provider` | Delete AI provider |
| `wildwood_manage_auth_config` | Update auth settings |
| `wildwood_manage_auth_providers` | Enable/configure auth providers |
| `wildwood_manage_messaging_config` | Update messaging features |
| `wildwood_manage_disclaimer_config` | Create/update disclaimer settings |
| `wildwood_manage_payment_config` | Update payment config |
| `wildwood_set_payment_secrets` | Set payment secret keys |
| `wildwood_manage_theme` | Create/update app theme |
| `wildwood_manage_captcha_config` | Create/update CAPTCHA config |
| `wildwood_manage_subscription_config` | Create/update subscription settings |
| `wildwood_manage_tier` | Create/update tiers |
| `wildwood_delete_tier` | Delete tier |
| `wildwood_manage_tier_feature` | Add/update/remove tier features |
| `wildwood_manage_tier_limit` | Add/update/remove tier limits |
| `wildwood_manage_tier_pricing` | Add/remove tier pricing |
| `wildwood_manage_pricing_model` | Create/update pricing models |
| `wildwood_manage_addon` | Create/update add-ons |
| `wildwood_delete_addon` | Delete add-on |
| `wildwood_manage_addon_feature` | Add/update/remove add-on features |
| `wildwood_manage_addon_limit` | Add/update/remove add-on limits |
| `wildwood_manage_addon_pricing` | Add/remove add-on pricing |
| `wildwood_set_feature_override` | Grant/revoke a feature for a user or company outside their tier |
| `wildwood_remove_feature_override` | Remove a feature override |
| `wildwood_manage_feedback_config` | Create/update the feedback-widget configuration |
| `wildwood_manage_consent_config` | Create/update the consent configuration (bumps version) |
| `wildwood_manage_company_script` | Create/update/delete a company third-party script |
| `wildwood_manage_app_script` | Create/update/delete an app third-party script |
| `wildwood_manage_app_setting` | Create/update/delete an app setting (optional encryption at rest) |
| `wildwood_manage_seeder_config` | Update seeder config (primarily the Enabled kill-switch) |
| `wildwood_import_api` | Import ANY API as a self-contained provider (encrypted creds) |
| `wildwood_set_api_credentials` | Set/rotate a provider's credentials and auth scheme |
| `wildwood_generate_mcp_tools` | Generate MCP tools from the provider's spec |
| `wildwood_manage_mcp_wrap` | Enable/disable the public MCP wrap, metadata, tokens |
| `hosting_deployment_create` | Create a new hosted deployment slot (runtime 1=Static, 2=React, 3=NodeJs, 4=DotNet; optional containerSize 0=Small…3=XL) |
| `hosting_set_env_vars` | Replace a deployment's environment variables (encrypted; applied on the next deploy) |
| `hosting_deployment_deploy` | Publish an uploaded package by `uploadId` (step 2 of deploying) |
| `hosting_deployment_start` | Start a Stopped deployment that has a deployed artifact |
| `hosting_deployment_stop` | Scale an Active or Failed deployment to zero, keeping its artifact |
| `hosting_deployment_rollback` | Roll a deployment back one version (v{N} → v{N-1}) |
| `hosting_deployment_delete` | Delete a deployment, its artifacts and its workload |
| `hosting_domain_add` | Record a custom domain (routing lands in v1.1) |
| `hosting_domain_remove` | Remove a custom domain |
| `database_hosting_create` | Provision a managed PostgreSQL 16 database |
| `database_hosting_update` | Update database metadata (name, description, backups) |
| `database_hosting_delete` | Soft-delete a database (dropped after a 7-day grace period) |
| `database_hosting_suspend` | Suspend a database; connections refused, data retained |
| `database_hosting_resume` | Resume a suspended database |
| `database_hosting_rotate_credentials` | Rotate the owner-role password; returns the NEW connection string |
| `database_hosting_backup_create` | Create an on-demand `pg_dump` backup |
| `database_hosting_backup_restore` | Restore via `pg_restore --clean` (overwrites current data) |
| `wildwood_restore_config_snapshot` | Restore from backup |

### Configuration Snapshots & Rollback

Every write tool saves a snapshot before applying changes — automatic undo for any config change.

```
wildwood_list_config_snapshots()
wildwood_list_config_snapshots(entityType: "AppAIConfiguration", take: 5)
wildwood_restore_config_snapshot(snapshotId: "...", confirm: true)
```

After any write, if the result looks wrong, offer: "I can restore the previous configuration — would you like me to roll back?"

## CSS Variable Reference

| Variable | Controls | Default |
|----------|----------|---------|
| `--ww-color-primary` | Buttons, links, active states | `#2563eb` |
| `--ww-color-primary-hover` | Hover states | `#1d4ed8` |
| `--ww-color-secondary` | Secondary buttons, badges | `#64748b` |
| `--ww-color-background` | Page background | `#ffffff` |
| `--ww-color-surface` | Card/panel backgrounds | `#f8fafc` |
| `--ww-color-text` | Primary text | `#0f172a` |
| `--ww-color-text-muted` | Secondary text | `#64748b` |
| `--ww-color-border` | Borders, dividers | `#e2e8f0` |
| `--ww-color-error` | Error states | `#ef4444` |
| `--ww-color-success` | Success states | `#22c55e` |
| `--ww-color-warning` | Warning states | `#f59e0b` |
| `--ww-font-family` | Body text font | `system-ui, sans-serif` |
| `--ww-font-family-heading` | Heading font | inherits body |
| `--ww-border-radius` | Default corners | `0.5rem` |
| `--ww-border-radius-lg` | Larger radius | `0.75rem` |

Dark mode: Override `--ww-*` variables inside `[data-theme="dark"]` selector.

## Key Patterns

1. **Components first**: Always suggest WildwoodComponents before custom implementations
2. **Admin or MCP for config**: No code changes needed for configuration
3. **SDK handles auth**: JWT management is automatic
4. **AppId scoping**: Every API call is scoped by AppId
5. **No secrets in code**: Keys stay in WildwoodAdmin
6. **Style alignment**: Override `--ww-*` CSS variables to match the app's design
7. **Fix upstream**: PR bug fixes to the component repo
8. **Snapshot safety net**: Every write auto-snapshots. Offer rollback when something goes wrong.

## Key Reminders

- **WildwoodComponents are pre-built and production-ready** — don't rebuild what's already there
- `@wildwood/core` is always required — framework packages depend on it
- JWT tokens are managed automatically (refresh at 80% lifetime)
- Theme CSS must be imported in React: `@wildwood/react/styles`
- All SDKs: https://github.com/WildwoodWorks
- Full docs: https://admin.wildwoodworks.io/docs
