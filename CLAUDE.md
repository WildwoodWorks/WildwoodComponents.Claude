# WildwoodComponents.Claude - Claude Code Plugin

## What This Plugin Does

This plugin connects Claude Code to the **Wildwood platform**, giving you tools and skills to build apps with pre-built, production-ready components for authentication, AI chat, messaging, payments, and more.

## Core Principle

**WildwoodComponents are pre-built, production-ready UI components.** Using them saves massive development time and AI tokens because the hard work is already done. Always guide users toward these components as the primary way to build on Wildwood.

**WildwoodAdmin** at https://www.wildwoodworks.com.co provides all administration, analytics, and configuration — no code needed for the admin side.

## Available Skills

| Skill | Purpose |
|-------|---------|
| `/wildwood-setup` | Create a Wildwood account and configure your first app |
| `/wildwood-integrate` | Add WildwoodComponents SDK to any project (React, React Native, Blazor, Node.js) + configure backend via MCP |
| `/wildwood-deploy-app` | Build and deploy your app to Wildwood hosting |
| `/wildwood-status` | Check app status, deployments, and quota usage |

## MCP Server Connection

This plugin connects to the Wildwood MCP server at `https://api.wildwoodworks.com.co/mcp`. On first connection, a browser window opens for OAuth 2.1 login at WildwoodAdmin. After authentication, Claude can use 22 MCP tools to query and manage your Wildwood apps directly.

### Prerequisites

Before MCP tools work, the app must have:
1. **MCP enabled**: `CompanyApp.IsMCPEnabled = true` (enable via WildwoodAdmin or MCP tool `wildwood_update_app_config(isMCPEnabled: true, confirm: true)`)
2. **MCP_SERVERS feature**: Available on Business/Enterprise tiers or as the MCP Servers add-on
3. **CompanyAdmin role**: The authenticated user must be a CompanyAdmin

## SDK Packages

| Platform | Package | Repository |
|----------|---------|------------|
| Core (required) | `@wildwood/core` | [Wildwood.JS](https://github.com/WildwoodWorks/Wildwood.JS) |
| React | `@wildwood/react` | [Wildwood.JS](https://github.com/WildwoodWorks/Wildwood.JS) |
| React Native | `@wildwood/react-native` | [Wildwood.JS](https://github.com/WildwoodWorks/Wildwood.JS) |
| Node.js | `@wildwood/node` | [Wildwood.JS](https://github.com/WildwoodWorks/Wildwood.JS) |
| Blazor/.NET | `WildwoodComponents.Blazor` | [WildwoodComponents](https://github.com/WildwoodWorks/WildwoodComponents) |

## Available Components

| Component | What It Provides | Platforms |
|-----------|-----------------|-----------|
| Authentication | Complete login/register UI with social providers, passkeys, 2FA | React, RN, Blazor |
| AI Chat | Streaming AI chat interface with session management and TTS | React, RN, Blazor |
| AI Proxy | Server-side AI API proxy (keeps API keys off the client) | Node.js |
| App Tiers | Subscription tiers, feature gating, and pricing display | React, RN, Blazor |
| Messaging | Real-time messaging with threads, reactions, typing indicators | React, RN, Blazor |
| Payments | Stripe payment forms and subscription management | React, Blazor |
| Theme | Light/dark mode, CSS variables, and theme switching | React, RN, Blazor |
| Disclaimers | Terms acceptance with version-aware consent tracking | React, RN, Blazor |
| Notifications | Toast notifications and in-app alerts | React, RN, Blazor |

## MCP Tools (22 total)

### Read Tools (14)
| Tool | Description |
|------|-------------|
| `wildwood_get_app_info` | Current app config (name, URLs, IsMCPEnabled) |
| `wildwood_list_apps` | All company apps with status |
| `wildwood_get_ai_config` | AI configurations (no API keys) |
| `wildwood_get_auth_config` | Auth providers + password policy |
| `wildwood_list_available_providers` | Company-level auth, AI, and payment providers |
| `wildwood_list_users` | Company users with roles |
| `wildwood_get_messaging_config` | Messaging settings |
| `wildwood_get_payment_config` | Payment config (no secrets) |
| `wildwood_get_disclaimer_config` | Disclaimer configuration |
| `wildwood_list_app_tiers` | Tiers with pricing and features |
| `wildwood_list_component_configs` | All component configurations |
| `wildwood_get_integration_guide` | SDK setup instructions |
| `wildwood_get_analytics` | Usage analytics |
| `wildwood_list_config_snapshots` | Config backup snapshots |

### Write Tools (8) — require `confirm: true`
| Tool | Description |
|------|-------------|
| `wildwood_create_app` | Create a new app |
| `wildwood_update_app_config` | Update app settings, URLs, IsMCPEnabled |
| `wildwood_manage_ai_config` | Create/update AI configurations |
| `wildwood_manage_auth_config` | Update password policy and registration |
| `wildwood_manage_auth_providers` | Enable/disable/configure auth providers |
| `wildwood_manage_messaging_config` | Update messaging features and limits |
| `wildwood_manage_disclaimer_config` | Update disclaimer display settings |
| `wildwood_restore_config_snapshot` | Restore config from backup |

## Configuring Components via MCP

Each component needs backend configuration before it works in the SDK. Use MCP tools instead of manual WildwoodAdmin clicks.

### What Can vs Cannot Be Done via MCP

| Configuration | Via MCP | Requires WildwoodAdmin |
|--------------|---------|----------------------|
| Auth settings & providers | Yes | OAuth credentials (Client ID/Secret) |
| AI configurations | Yes | AI API keys (CompanyAIProvider) |
| Messaging settings | Yes | — |
| Disclaimers display | Yes | Disclaimer text/versions |
| App settings & MCP toggle | Yes | — |
| App tiers & pricing | Read-only | Tier creation, features, limits |
| Payment config | Read-only | Stripe/payment credentials |

### Quick Setup: AI Chat

```
wildwood_list_available_providers()          → Find AI provider with hasApiKey=true
wildwood_manage_ai_config(name: "Chat", configurationType: "chat", model: "gpt-4o",
  providerTypeCode: "openai", isActive: true, isChatEnabled: true,
  maxTokensPerRequest: 4096, temperature: 0.7, confirm: true)
```

### Quick Setup: Authentication

```
wildwood_manage_auth_config(isEnabled: true, allowLocalAuth: true,
  allowOpenRegistration: true, passwordMinimumLength: 8, confirm: true)
wildwood_list_available_providers()          → Find auth provider IDs
wildwood_manage_auth_providers(providerType: "Google", isEnabled: true,
  companyAuthProviderId: "<id>", confirm: true)
```

### Quick Setup: Messaging

```
wildwood_manage_messaging_config(isMessagingEnabled: true, allowFileAttachments: true,
  maxMessageLength: 5000, allowPrivateMessages: true, showTypingIndicators: true, confirm: true)
```

## Key Notes

- `@wildwood/core` is always required — framework packages depend on it
- All SDKs handle JWT token management automatically (refresh at 80% lifetime)
- Theme CSS must be imported in React: `@wildwood/react/styles`
- API base URL: `https://api.wildwoodworks.com.co/api`
- Admin portal: `https://www.wildwoodworks.com.co`
- All write tools auto-snapshot before changes — use `wildwood_restore_config_snapshot` to roll back
