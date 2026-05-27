# WildwoodComponents.Claude

A Claude Code plugin that connects Claude to the **Wildwood platform** — giving you tools and skills to build apps with pre-built, production-ready components for authentication, AI chat, messaging, payments, and more.

## Installation

**Two slash commands inside Claude Code. No shell installer. No restart.**

> ⚠️ **Run each command separately — don't paste both lines at once.** Claude Code parses slash commands one input at a time. If you submit both lines together, the second command gets concatenated into the first command's arguments and the install fails with `Invalid argument`.

**Step 1 — add the marketplace:**

```
/plugin marketplace add WildwoodWorks/WildwoodComponents.Claude
```

Wait for the success message (something like *"Marketplace added"*).

**Step 2 — install the plugin (only after Step 1 succeeds):**

```
/plugin install wildwood@wildwood
```

That's it. The plugin auto-registers the Wildwood MCP server. The first time you call a Wildwood tool, your browser opens to Wildwood for one-click OAuth — no `/mcp` step required, no token copying, no env vars.

> **What just happened?** Claude Code's native plugin system loaded the plugin, registered the Wildwood MCP server bundled in [`.mcp.json`](.mcp.json), and made the `/wildwood` slash command available. When you first invoke a Wildwood MCP tool, the server responds with a 401 + `WWW-Authenticate` header pointing at its OAuth discovery URL. Claude Code reads that, opens your browser, you click **Allow**, and you're done.

### Updates

Plugin auto-updates from the marketplace. To pull a new version manually:

```
/plugin marketplace update wildwood
```

### Uninstall

```
/plugin uninstall wildwood@wildwood
```

## What You Get

### The `/wildwood` slash command

One command does everything — just tell it what you need:

```
/wildwood              → show menu
/wildwood setup        → create account, connect MCP, configure your first app
/wildwood integrate    → add the Wildwood SDK to your project
/wildwood deploy       → build and deploy your app
/wildwood hosting      → manage Wildwood-hosted deployments
/wildwood database     → manage hosted Azure SQL databases
/wildwood status       → check platform health and app status
/wildwood diagnose     → troubleshoot MCP connection / OAuth issues
```

### Wildwood MCP server

Connects Claude to the Wildwood API at `api.wildwoodworks.io/mcp` via OAuth 2.1 with PKCE. Supports the native authorization-code flow (RFC 6749), client-id metadata documents (CIMD), resource indicators (RFC 8707), and the device authorization grant (RFC 8628) for headless environments.

Once connected, Claude can query and manage your Wildwood apps directly using 46+ MCP tools (read + write).

## WildwoodComponents

The core value of the Wildwood platform is **pre-built, production-ready UI components** that save massive development time:

| Component | What It Provides | Platforms |
|-----------|-----------------|-----------|
| **Authentication** | Login/register UI with social providers, passkeys, 2FA | React, React Native, Blazor |
| **AI Chat** | Streaming AI chat with session management and TTS | React, React Native, Blazor |
| **AI Proxy** | Server-side AI API proxy (no client-side keys) | Node.js |
| **App Tiers** | Subscription tiers, feature gating, pricing | React, React Native, Blazor |
| **Messaging** | Real-time messaging with threads, reactions | React, React Native, Blazor |
| **Payments** | Stripe payment forms and subscriptions | React, Blazor |
| **Theme** | Light/dark mode, CSS variables | React, React Native, Blazor |
| **Disclaimers** | Terms acceptance with consent tracking | React, React Native, Blazor |
| **Notifications** | Toast notifications and alerts | React, React Native, Blazor |

## SDK Packages

| Platform | Package | Source |
|----------|---------|--------|
| Core (required) | `@wildwood/core` | [Wildwood.JS](https://github.com/WildwoodWorks/Wildwood.JS) |
| React | `@wildwood/react` | [Wildwood.JS](https://github.com/WildwoodWorks/Wildwood.JS) |
| React Native | `@wildwood/react-native` | [Wildwood.JS](https://github.com/WildwoodWorks/Wildwood.JS) |
| Node.js | `@wildwood/node` | [Wildwood.JS](https://github.com/WildwoodWorks/Wildwood.JS) |
| Blazor/.NET | `WildwoodComponents.Blazor` | [WildwoodComponents](https://github.com/WildwoodWorks/WildwoodComponents) |

## Headless install (CI / containers / no Claude Code session)

If you can't use the `/plugin` UI (e.g., installing inside a Docker image), drop the contents of this repo into your project's `.claude/plugins/wildwood/` directory — the plugin's bundled `.mcp.json` and `skills/` will be picked up on next launch. Note that OAuth still requires a one-time browser session; for fully headless environments, use the device-flow path documented in [`skills/wildwood/SKILL.md`](skills/wildwood/SKILL.md) (`/wildwood setup --device`).

## Troubleshooting

If `/wildwood` tools don't appear after install:

```
/wildwood diagnose
```

This runs five conformance checks against the Wildwood OAuth surface and tells you exactly which side has the bug. Or check the [SKILL.md OAuth Diagnostics section](skills/wildwood/SKILL.md) directly.

## Links

- **Admin Portal**: https://admin.wildwoodworks.io
- **API**: https://api.wildwoodworks.io/api
- **Documentation**: https://admin.wildwoodworks.io/docs
- **GitHub**: https://github.com/WildwoodWorks

## License

MIT
