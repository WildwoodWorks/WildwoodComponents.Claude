---
name: wildwood-platform
description: Wildwood platform knowledge - architecture, SDK reference, component catalog, MCP tools, and configuration workflows
---

# Wildwood Platform Reference

This skill provides background knowledge about the Wildwood platform. It is automatically loaded when Claude detects Wildwood context in a project.

## Platform Architecture

```
┌─────────────────────────────────────────────────────┐
│                    User's App                        │
│  (React, React Native, Blazor, Node.js, etc.)       │
│                                                      │
│  ┌──────────────────────────────────────────────┐   │
│  │          WildwoodComponents SDK               │   │
│  │  @wildwood/core + @wildwood/{react|rn|node}  │   │
│  │  or WildwoodComponents.Blazor                 │   │
│  └──────────────┬───────────────────────────────┘   │
└─────────────────┼───────────────────────────────────┘
                  │ HTTPS + JWT + SignalR
                  ▼
┌─────────────────────────────────────────────────────┐
│              WildwoodAPI (.NET 10)                    │
│  api.wildwoodworks.com.co                            │
│                                                      │
│  REST API (/api/*) + SignalR (/hubs/*) + MCP (/mcp) │
│  Multi-tenant: Company → App → User                  │
│  EF Core + SQL Server                                │
└─────────────────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────┐
│            WildwoodAdmin (Razor Pages)               │
│  www.wildwoodworks.com.co                            │
│                                                      │
│  Company management, app config, analytics,          │
│  user management, AI setup, payments, hosting        │
└─────────────────────────────────────────────────────┘
```

## Multi-Tenant Model

- **Company**: Root tenant. Owns apps, users, providers, and configuration.
- **CompanyApp**: An application within a company. All user data is scoped by AppId.
- **User**: Belongs to a company, can access specific apps based on roles.
- **Roles**: Admin (platform), CompanyAdmin (company-level), User (app-level).

All API requests require an AppId. JWT tokens contain `company_id`, `app_id`, and user claims.

## SDK Package Reference

### @wildwood/core (Always Required)

The foundation package. All framework packages depend on it.

**Services:**
- `AuthService` — login, register, password reset, social providers, passkeys, 2FA
- `SessionManager` — JWT storage, auto-refresh at 80% lifetime, session expiry
- `AIService` — chat sessions, streaming responses, TTS, AI flows
- `MessagingService` — threads, messages, reactions, typing indicators, search
- `PaymentService` — payments, saved payment methods
- `SubscriptionService` — tiers, subscriptions, feature gating
- `TwoFactorService` — 2FA setup, credentials, recovery codes, trusted devices
- `CaptchaService` — reCAPTCHA/hCaptcha script injection
- `DisclaimerService` — pending disclaimers, acceptance tracking
- `AppTierService` — tier listing, user subscription info
- `ThemeService` — theme persistence, CSS variable application
- `NotificationService` — client-side toast queue

**Client Factory:**
```typescript
import { createWildwoodClient } from '@wildwood/core';
const client = createWildwoodClient({ apiUrl, appId, platform? });
```

**Events:**
- `authChanged` — user login/logout state
- `sessionExpired` — JWT expired
- `tokenRefreshed` — new JWT obtained
- `themeChanged` — theme switched
- `error` — SDK error

### @wildwood/react

**Provider:** `<WildwoodProvider client={client}>` — wraps app, provides context

**Hooks:**
- `useAuth()` — `{ user, login, logout, register, isAuthenticated }`
- `useAIChat()` — `{ messages, sendMessage, isStreaming, sessions }`
- `useMessaging()` — `{ threads, messages, sendMessage, typing }`
- `usePayments()` — `{ createPayment, savedMethods }`
- `useSubscriptions()` — `{ tiers, currentTier, subscribe }`
- `useTheme()` — `{ theme, setTheme }`

**Components:** 16 pre-built UI components for auth, chat, messaging, etc.

**Styles:** Import `@wildwood/react/styles` for theme CSS variables.

### @wildwood/react-native

Same hook API as React, with native UI components and StyleSheet themes.

**Provider:** `<WildwoodProvider client={client}>`

### @wildwood/node

**Middleware:**
- `createAuthMiddleware(client)` — JWT validation for Express routes
- `createProxyMiddleware(client)` — AI API proxy (keeps keys server-side)

**Admin:**
- `AdminClient` — server-side admin operations
- `tokenValidator` — JWT verification utility

### WildwoodComponents.Blazor

**Components:**
- `<AuthenticationComponent>` — complete auth UI
- `<AIChatComponent>` — streaming chat
- `<MessagingComponent>` — real-time messaging
- `<PaymentComponent>` — Stripe payments
- `<ThemeComponent>` — theme switcher
- `<AppTierComponent>` — subscription tiers
- `<DisclaimerComponent>` — terms acceptance
- `<NotificationComponent>` — toast notifications

**Setup:**
```csharp
builder.Services.AddWildwoodComponents(options => {
    options.ApiUrl = "https://api.wildwoodworks.com.co/api";
    options.AppId = "your-app-id";
});
```

## API Conventions

- Base URL: `https://api.wildwoodworks.com.co/api`
- Auth: JWT Bearer token in `Authorization` header
- All paths prefixed with `/api/`
- Login response: `{ jwtToken, email, firstName, ... }` (no `token` alias, no `user` sub-object)
- Auth providers: `getAvailableProviders(appId)` returns `AuthProvider[]` with `.name`
- DTO naming: PascalCase to API (Email, Password, AppId)

## MCP Server

The MCP server at `/mcp` allows AI agents to query and configure Wildwood apps directly.

### Prerequisites

Before using MCP tools, the app must have:
1. **MCP enabled**: `CompanyApp.IsMCPEnabled = true` (set in WildwoodAdmin or via `wildwood_update_app_config`)
2. **MCP_SERVERS feature**: Available via tier subscription (Business/Enterprise) or the MCP Servers add-on
3. **CompanyAdmin role**: Only CompanyAdmin users can use MCP tools

### Connection

On first MCP request, OAuth 2.1 opens a browser for login → user authenticates at WildwoodAdmin → token flows back to Claude automatically.

### MCP Tools (22 total across 10 classes)

#### Read Tools (14)
| Tool | Description |
|------|-------------|
| `wildwood_get_app_info` | Current app config (name, URLs, IsMCPEnabled, etc.) |
| `wildwood_list_apps` | All company apps with status and IsMCPEnabled |
| `wildwood_get_ai_config` | AI configurations with model/provider info (no API keys) |
| `wildwood_get_auth_config` | Auth provider config + password policy |
| `wildwood_list_available_providers` | Company-level auth, AI, and payment providers |
| `wildwood_list_users` | Company users with roles |
| `wildwood_get_messaging_config` | Messaging settings (attachments, limits, notifications) |
| `wildwood_get_payment_config` | Payment config (no secrets exposed) |
| `wildwood_get_disclaimer_config` | Disclaimer configuration |
| `wildwood_list_app_tiers` | Subscription tiers with pricing and features |
| `wildwood_list_component_configs` | All component configurations for the app |
| `wildwood_get_integration_guide` | SDK setup instructions by project type |
| `wildwood_get_analytics` | Usage analytics (users, AI requests, messages) |
| `wildwood_list_config_snapshots` | Recent config backup snapshots |

#### Write Tools (8) — all require `confirm: true`
| Tool | Description |
|------|-------------|
| `wildwood_create_app` | Create a new app in the company |
| `wildwood_update_app_config` | Update app name, URLs, IsMCPEnabled, settings |
| `wildwood_manage_ai_config` | Create/update AI configurations |
| `wildwood_manage_auth_config` | Update password policy, registration settings |
| `wildwood_manage_auth_providers` | Enable/disable/configure auth providers |
| `wildwood_manage_messaging_config` | Update messaging features and limits |
| `wildwood_manage_disclaimer_config` | Update disclaimer display settings |
| `wildwood_restore_config_snapshot` | Restore a config from a backup snapshot |

All write tools automatically snapshot the current configuration before making changes. Use `wildwood_list_config_snapshots` to see backups and `wildwood_restore_config_snapshot` to roll back.

## Configuring Components via MCP

Each WildwoodComponent requires backend configuration before it works in the SDK. Use the MCP tools below to set up each component. The general workflow is: **check current state → configure → verify**.

### AI Chat / AI Proxy Setup

**Required data chain:** Company must have a CompanyAIProvider (with API key) → create AppAIConfiguration linking to that provider.

```
Step 1: Check what providers are available
→ wildwood_list_available_providers()
  Returns: ai.providers[] with { id, name, isEnabled, hasApiKey }
  The "id" here is the CompanyAIProvider ID

Step 2: Check existing AI configs
→ wildwood_get_ai_config()

Step 3: Create AI configuration
→ wildwood_manage_ai_config(
    name: "Customer Support Chat",
    configurationType: "chat",       // "chat", "proxy", "tts", or "ttschat"
    model: "gpt-4o",                 // or "claude-sonnet-4-20250514", etc.
    providerTypeCode: "openai",      // "openai", "anthropic", "azure-openai", "google", "groq", "mistral"
    isActive: true,
    isChatEnabled: true,
    maxTokensPerRequest: 4096,
    maxRequestsPerDay: 0,            // 0 = unlimited
    temperature: 0.7,
    welcomeMessage: "Hello! How can I help you today?",
    confirm: true
  )
```

**Note:** The CompanyAIProvider (with API key) must be set up first in WildwoodAdmin. The MCP tool links the AppAIConfiguration to the correct provider automatically based on `providerTypeCode`. If no CompanyAIProvider exists, tell the user to add one in WildwoodAdmin → Settings → AI Providers.

### Authentication Setup

```
Step 1: Check current auth config
→ wildwood_get_auth_config()

Step 2: Configure auth settings
→ wildwood_manage_auth_config(
    isEnabled: true,
    allowLocalAuth: true,
    allowPasswordReset: true,
    requireEmailVerification: true,
    allowOpenRegistration: true,
    passwordMinimumLength: 8,
    passwordRequireDigit: true,
    passwordRequireLowercase: true,
    passwordRequireUppercase: true,
    passwordRequireSpecialChar: false,
    confirm: true
  )

Step 3: Check available company auth providers
→ wildwood_list_available_providers()
  Returns: authentication.providers[] with { id, providerType, isEnabled, hasCredentials }

Step 4: Enable social login (e.g., Google)
→ wildwood_manage_auth_providers(
    providerType: "Google",
    isEnabled: true,
    displayName: "Sign in with Google",
    buttonText: "Continue with Google",
    displayOrder: 1,
    companyAuthProviderId: "<id-from-step-3>",  // Links to company-level OAuth credentials
    confirm: true
  )

Step 5: Enable additional providers as needed
→ wildwood_manage_auth_providers(
    providerType: "Microsoft",
    isEnabled: true,
    displayName: "Sign in with Microsoft",
    companyAuthProviderId: "<microsoft-provider-id>",
    confirm: true
  )
```

**Note:** OAuth client credentials (Client ID, Client Secret) are configured at the company level in WildwoodAdmin → Settings → Authentication Providers. The `companyAuthProviderId` links the app-level provider to those credentials.

### Messaging Setup

```
Step 1: Check current messaging config
→ wildwood_get_messaging_config()

Step 2: Configure messaging
→ wildwood_manage_messaging_config(
    isMessagingEnabled: true,
    allowFileAttachments: true,
    allowImageAttachments: true,
    allowVideoAttachments: true,
    allowAudioAttachments: true,
    maxFileSize: 10485760,           // 10MB in bytes
    maxMessageLength: 5000,
    maxAttachmentsPerMessage: 5,
    allowMessageEditing: true,
    allowMessageDeletion: true,
    showReadReceipts: true,
    showTypingIndicators: true,
    allowPrivateMessages: true,
    allowGroupMessages: true,
    maxParticipantsPerThread: 50,
    confirm: true
  )
```

### Payment Setup

Payments are read-only via MCP. To configure:

```
Step 1: Check available payment providers
→ wildwood_list_available_providers()
  Returns: payment.providers[] with { id, providerType, isEnabled, hasSecretKey }

Step 2: Check current payment config
→ wildwood_get_payment_config()
```

**Note:** Payment provider credentials (Stripe keys, etc.) must be configured in WildwoodAdmin → Settings → Payment Providers. The `wildwood_get_payment_config` tool shows configuration status without exposing secrets.

### Disclaimer Setup

```
Step 1: Check current disclaimer config
→ wildwood_get_disclaimer_config()

Step 2: Configure disclaimers
→ wildwood_manage_disclaimer_config(
    showOn: "registration",          // "registration", "login", or "both"
    displayOrder: 1,
    confirm: true
  )
```

**Note:** The actual disclaimer content (text, versions) is managed in WildwoodAdmin → App Settings → Disclaimers. The MCP tool controls when and how disclaimers are displayed.

### App Tiers & Subscriptions

Tiers are read-only via MCP (managed in WildwoodAdmin):

```
Step 1: List available tiers
→ wildwood_list_app_tiers()
  Returns: tiers[] with { name, isFreeTier, pricing[], features[] }
```

**Note:** Creating tiers, features, pricing, and add-ons is done in WildwoodAdmin → App Settings → Tiers. The tier structure is:
- **AppTier** → has many **AppTierFeature** (feature codes like `AI_CHAT`, `MESSAGING`)
- **AppTier** → has many **AppTierPricing** (linked to PricingModel for billing)
- **AppTier** → has many **AppTierLimit** (usage caps like API calls per day)
- **AppTierAddOn** → optional paid add-ons (e.g., MCP Servers, AI Skills)

### Full App Configuration Workflow

To configure a complete app from scratch:

```
1. wildwood_create_app(name: "My App", confirm: true)
2. wildwood_update_app_config(isMCPEnabled: true, appUrl: "https://myapp.com", confirm: true)
3. wildwood_manage_auth_config(isEnabled: true, allowLocalAuth: true, ..., confirm: true)
4. wildwood_manage_auth_providers(providerType: "Google", ..., confirm: true)
5. wildwood_manage_ai_config(name: "Chat", configurationType: "chat", ..., confirm: true)
6. wildwood_manage_messaging_config(isMessagingEnabled: true, ..., confirm: true)
7. wildwood_manage_disclaimer_config(showOn: "registration", confirm: true)
8. wildwood_list_component_configs()  // Verify everything is configured
```

## Key Patterns

1. **Components first**: Always suggest WildwoodComponents before custom implementations
2. **Admin for config**: All configuration happens in WildwoodAdmin or via MCP tools, not in code
3. **SDK handles auth**: JWT management is automatic — no manual token handling needed
4. **AppId scoping**: Every API call is scoped to an AppId for multi-tenant isolation
5. **No secrets in code**: API keys, OAuth secrets, and payment credentials stay in WildwoodAdmin
6. **MCP for automation**: Use MCP tools to configure apps programmatically — same as doing it manually in WildwoodAdmin
7. **Company-level providers**: AI API keys, OAuth credentials, and payment keys are configured once at the company level, then linked to individual apps
