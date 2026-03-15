# WildwoodComponents.Claude

A Claude Code plugin that connects Claude to the **Wildwood platform** — giving you tools and skills to build apps with pre-built, production-ready components for authentication, AI chat, messaging, payments, and more.

## Installation

```
/plugin install github:WildwoodWorks/WildwoodComponents.Claude
```

Or clone and reference locally:

```bash
git clone https://github.com/WildwoodWorks/WildwoodComponents.Claude.git
```

## What You Get

### Skills

| Skill | Description |
|-------|-------------|
| `/wildwood-setup` | Create a Wildwood account and configure your first app |
| `/wildwood-integrate` | Add WildwoodComponents SDK to any project |
| `/wildwood-deploy-app` | Build and deploy to Wildwood hosting |
| `/wildwood-status` | Check app status, deployments, and quotas |

### MCP Server Connection

Connects Claude to the Wildwood API at `api.wildwoodworks.com.co/mcp` via OAuth 2.1. On first use, a browser window opens for authentication at [WildwoodAdmin](https://www.wildwoodworks.com.co).

Once connected, Claude can query and manage your Wildwood apps directly using 14+ MCP tools.

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

## Quick Start

1. Install the plugin: `/plugin install github:WildwoodWorks/WildwoodComponents.Claude`
2. Run `/wildwood-setup` to create your account and first app
3. Run `/wildwood-integrate` to add components to your project
4. Run `/wildwood-deploy-app` to deploy

## Links

- **Admin Portal**: https://www.wildwoodworks.com.co
- **API**: https://api.wildwoodworks.com.co/api
- **Documentation**: https://www.wildwoodworks.com.co/docs
- **GitHub**: https://github.com/WildwoodWorks

## License

MIT
