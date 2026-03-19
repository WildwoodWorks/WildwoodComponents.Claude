# WildwoodComponents.Claude

A Claude Code plugin that connects Claude to the **Wildwood platform** — giving you tools and skills to build apps with pre-built, production-ready components for authentication, AI chat, messaging, payments, and more.

## Installation

### One-liner (recommended)

**macOS / Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/WildwoodWorks/WildwoodComponents.Claude/main/install.sh | bash
```

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/WildwoodWorks/WildwoodComponents.Claude/main/install.ps1 | iex
```

This installs skills, MCP server config, and platform context into your current project directory.

### From a cloned repo

```bash
git clone https://github.com/WildwoodWorks/WildwoodComponents.Claude.git
cd WildwoodComponents.Claude

# Install into current project
./install.sh /path/to/your/project       # macOS/Linux
.\install.ps1 -ProjectDir C:\your\project # Windows
```

### MCP server only

If you just want the MCP tools without the skills:
```bash
claude mcp add wildwood --transport http --url https://api.wildwoodworks.io/mcp
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

Connects Claude to the Wildwood API at `api.wildwoodworks.io/mcp` via OAuth 2.1. On first use, a browser window opens for authentication at [WildwoodAdmin](https://admin.wildwoodworks.io).

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

1. Run the install script (see Installation above)
2. Start Claude Code in your project directory
3. Run `/wildwood-setup` to create your account and first app
4. Run `/wildwood-integrate` to add components to your project
5. Run `/wildwood-deploy-app` to deploy

## Links

- **Admin Portal**: https://admin.wildwoodworks.io
- **API**: https://api.wildwoodworks.io/api
- **Documentation**: https://admin.wildwoodworks.io/docs
- **GitHub**: https://github.com/WildwoodWorks

## License

MIT
