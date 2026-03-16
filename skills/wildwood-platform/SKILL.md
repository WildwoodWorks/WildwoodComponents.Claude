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

### MCP Tools (46 total across 15 classes)

#### Read Tools (20)
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
| `wildwood_list_ai_providers` | Company AI providers with masked keys |
| `wildwood_list_system_providers` | Available system AI providers |
| `wildwood_get_theme` | App theme (colors, fonts, CSS) |
| `wildwood_get_captcha_config` | CAPTCHA config (no secret key) |
| `wildwood_get_subscription_config` | Subscription/billing settings |
| `wildwood_list_pricing_models` | Company pricing models |

#### Write Tools (26) — all require `confirm: true`
| Tool | Description |
|------|-------------|
| `wildwood_create_app` | Create a new app in the company |
| `wildwood_update_app_config` | Update app settings, URLs, limits, store URLs |
| `wildwood_manage_ai_config` | Create/update AI config (full TTS, provider linking) |
| `wildwood_manage_auth_config` | Update auth, rate limits, password expiry |
| `wildwood_manage_auth_providers` | Configure auth providers with OAuth credentials |
| `wildwood_manage_messaging_config` | Update messaging with notifications, file types |
| `wildwood_manage_disclaimer_config` | Create/update disclaimer configs |
| `wildwood_restore_config_snapshot` | Restore a config from a backup snapshot |
| `wildwood_manage_ai_provider` | Create/update company AI providers (encrypted API keys) |
| `wildwood_delete_ai_provider` | Delete AI provider (checks for usage) |
| `wildwood_manage_payment_config` | Update payment providers, features, invoices, refunds |
| `wildwood_set_payment_secrets` | Set encrypted payment secret keys |
| `wildwood_manage_theme` | Create/update app theme |
| `wildwood_manage_captcha_config` | Configure CAPTCHA (encrypted secret) |
| `wildwood_manage_subscription_config` | Update subscription/billing settings |
| `wildwood_manage_tier` | Create/update app tiers |
| `wildwood_delete_tier` | Delete tier (checks subscriptions) |
| `wildwood_manage_tier_feature` | Add/update/remove tier features |
| `wildwood_manage_tier_limit` | Add/update/remove tier usage limits |
| `wildwood_manage_tier_pricing` | Add/remove tier pricing options |
| `wildwood_manage_pricing_model` | Create/update pricing models |
| `wildwood_manage_addon` | Create/update add-ons |
| `wildwood_delete_addon` | Delete add-on |
| `wildwood_manage_addon_feature` | Add/remove add-on features |
| `wildwood_manage_addon_limit` | Add/update/remove add-on limits |
| `wildwood_manage_addon_pricing` | Add/remove add-on pricing |

All write tools automatically snapshot the current configuration before making changes.

### Configuration Snapshots & Rollback

Every write tool saves a snapshot of the entity's state **before** applying changes. This gives you an automatic undo for any MCP configuration change.

**When to use snapshots:**
- After a write tool produces unexpected results — offer to restore the previous state
- When the user wants to experiment with settings and may want to revert
- Before making a series of related changes — note the starting snapshot so the user can roll back the entire batch
- When troubleshooting a broken configuration — list recent snapshots to find the last known-good state

**How to use:**
```
Step 1: List recent snapshots (optionally filter by entity type)
→ wildwood_list_config_snapshots()
→ wildwood_list_config_snapshots(entityType: "AppAIConfiguration", take: 5)
  Returns: snapshots[] with { id, entityType, entityId, toolName, description, createdAt, wasRestored }

Step 2: Restore a specific snapshot
→ wildwood_restore_config_snapshot(snapshotId: "<snapshot-id>", confirm: true)
  This overwrites the current config with the snapshot's saved state.
  A new snapshot of the current state is saved first (so the restore itself is reversible).
```

**Supported entity types for restore:** AppAIConfiguration, CompanyApp, AppAuthProviderConfiguration, AppAuthenticationConfiguration, AppMessagingConfiguration, AppPaymentConfiguration, AppDisclaimerConfiguration, CompanyAIProvider, AppComponentTheme, AppCaptchaConfiguration, AppSubscriptionConfiguration

**Best practice:** After any write tool call, if the user expresses concern or the result looks wrong, immediately suggest: *"I can restore the previous configuration — would you like me to roll back?"*

## Configuring Components via MCP

Each WildwoodComponent requires backend configuration before it works in the SDK. Use the MCP tools below to set up each component. The general workflow is: **check current state → configure → verify**.

### AI Chat / AI Proxy Setup

**Required data chain:** Create/verify CompanyAIProvider (with API key) → create AppAIConfiguration linking to that provider.

```
Step 1: List system providers to find the ID
→ wildwood_list_system_providers()
  Returns: systemProviders[] with { id, providerId, name }

Step 2: Create company AI provider with API key (or check existing)
→ wildwood_list_ai_providers()  // Check if one exists
→ wildwood_manage_ai_provider(
    name: "OpenAI Production",
    systemAIProviderId: "<system-provider-id>",
    apiKey: "sk-...",            // Encrypted, never returned
    isEnabled: true,
    isDefault: true,
    confirm: true
  )

Step 3: Check existing AI configs
→ wildwood_get_ai_config()

Step 4: Create AI configuration linked to provider
→ wildwood_manage_ai_config(
    name: "Customer Support Chat",
    configurationType: "chat",       // "chat", "proxy", "tts", or "ttschat"
    model: "gpt-4o",                 // or "claude-sonnet-4-20250514", etc.
    providerTypeCode: "openai",      // "openai", "anthropic", "azure-openai", "google", "groq", "mistral"
    companyAIProviderId: "<provider-id-from-step-2>",
    isActive: true,
    isChatEnabled: true,
    maxTokensPerRequest: 4096,
    maxRequestsPerDay: 0,            // 0 = unlimited
    temperature: 0.7,
    welcomeMessage: "Hello! How can I help you today?",
    confirm: true
  )
```

**TTS Configuration:** Add text-to-speech to any AI config:
```
→ wildwood_manage_ai_config(
    configId: "<existing-config-id>",
    enableTTS: true,
    ttsCompanyAIProviderId: "<provider-id>",
    ttsModel: "tts-1",
    ttsDefaultVoice: "alloy",
    ttsDefaultSpeed: 1.0,
    ttsDefaultFormat: "mp3",
    confirm: true
  )
```

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

**OAuth credentials can now be set via MCP** using `wildwood_manage_auth_providers`:
```
→ wildwood_manage_auth_providers(
    providerType: "Google",
    isEnabled: true,
    clientId: "your-google-client-id.apps.googleusercontent.com",
    clientSecret: "GOCSPX-...",     // Encrypted, never returned
    redirectUri: "https://myapp.com/auth/callback",
    scope: "openid email profile",
    confirm: true
  )
```
Secrets (clientSecret, applePrivateKey) are encrypted via `IDataEncryptionService` and never returned in responses.

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

```
Step 1: Check current payment config
→ wildwood_get_payment_config()

Step 2: Configure payment settings and public keys
→ wildwood_manage_payment_config(
    isPaymentEnabled: true,
    defaultCurrency: "USD",
    supportedCurrencies: "USD,EUR,GBP",
    enableStripe: true,
    stripePublishableKey: "pk_live_...",
    allowSavedPaymentMethods: true,
    enablePaymentReceipts: true,
    require3DSecure: true,
    generateInvoices: true,
    invoicePrefix: "INV",
    allowRefunds: true,
    refundWindowDays: 30,
    confirm: true
  )

Step 3: Set secret keys (separate tool for security)
→ wildwood_set_payment_secrets(
    stripeSecretKey: "sk_live_...",
    stripeWebhookSecret: "whsec_...",
    confirm: true
  )
```

Secrets are encrypted and never returned in responses. The read tool shows `hasStripeSecretKey: true` instead of the actual value.

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

Full CRUD is available via MCP. The typical workflow:

```
Step 1: Create pricing models
→ wildwood_manage_pricing_model(
    name: "Monthly Pro",
    billingFrequency: "Monthly",     // OneTime, Monthly, Quarterly, Annually
    price: 29.99,
    isActive: true,
    confirm: true
  )

Step 2: Create tiers
→ wildwood_manage_tier(
    name: "Pro",
    description: "For growing teams",
    displayOrder: 1,
    isFreeTier: false,
    allowUpgrades: true,
    allowDowngrades: true,
    badgeColor: "#3B82F6",
    customBadgeText: "Most Popular",
    confirm: true
  )

Step 3: Add features to tier
→ wildwood_manage_tier_feature(
    tierId: "<tier-id>",
    featureCode: "AI_CHAT",
    displayName: "AI Chat",
    isEnabled: true,
    category: "AI",
    confirm: true
  )

Step 4: Add usage limits
→ wildwood_manage_tier_limit(
    tierId: "<tier-id>",
    limitCode: "API_REQUESTS",
    displayName: "API Requests",
    maxValue: 10000,                 // -1 = unlimited
    limitType: "Monthly",            // Daily, Weekly, Monthly, Total, Concurrent
    warningThresholdPercent: 80,
    enforceHardLimit: true,
    unit: "requests",
    confirm: true
  )

Step 5: Link pricing to tier
→ wildwood_manage_tier_pricing(
    tierId: "<tier-id>",
    pricingModelId: "<pricing-model-id>",
    isDefault: true,
    confirm: true
  )
```

**Add-ons** follow the same pattern:
```
→ wildwood_manage_addon(name: "MCP Servers", category: "Developer", confirm: true)
→ wildwood_manage_addon_feature(addOnId: "<id>", featureCode: "MCP_SERVERS", confirm: true)
→ wildwood_manage_addon_pricing(addOnId: "<id>", pricingModelId: "<id>", confirm: true)
```

**Subscription config** controls billing behavior:
```
→ wildwood_manage_subscription_config(
    isSubscriptionEnabled: true,
    allowTrialPeriods: true,
    defaultTrialDays: 14,
    billingCycle: "monthly",
    allowPlanUpgrade: true,
    prorateBillingChanges: true,
    confirm: true
  )
```

### Full App Configuration Workflow

To configure a complete app from scratch:

```
 1. wildwood_create_app(name: "My App", confirm: true)
 2. wildwood_update_app_config(isMCPEnabled: true, appUrl: "https://myapp.com", confirm: true)
 3. wildwood_manage_ai_provider(name: "OpenAI", systemAIProviderId: "<id>", apiKey: "sk-...", confirm: true)
 4. wildwood_manage_ai_config(name: "Chat", configurationType: "chat", companyAIProviderId: "<id>", ..., confirm: true)
 5. wildwood_manage_auth_config(isEnabled: true, allowLocalAuth: true, ..., confirm: true)
 6. wildwood_manage_auth_providers(providerType: "Google", clientId: "...", clientSecret: "...", confirm: true)
 7. wildwood_manage_messaging_config(isMessagingEnabled: true, ..., confirm: true)
 8. wildwood_manage_disclaimer_config(companyDisclaimerId: "<id>", showOn: "registration", confirm: true)
 9. wildwood_manage_theme(primaryColor: "#3B82F6", fontFamily: "Inter, sans-serif", confirm: true)
10. wildwood_manage_captcha_config(isEnabled: true, providerType: "GoogleReCaptcha", siteKey: "...", secretKey: "...", confirm: true)
11. wildwood_manage_payment_config(isPaymentEnabled: true, enableStripe: true, ..., confirm: true)
12. wildwood_set_payment_secrets(stripeSecretKey: "sk_...", stripeWebhookSecret: "whsec_...", confirm: true)
13. wildwood_manage_pricing_model(name: "Monthly Pro", billingFrequency: "Monthly", price: 29.99, confirm: true)
14. wildwood_manage_tier(name: "Pro", isFreeTier: false, ..., confirm: true)
15. wildwood_manage_tier_feature(tierId: "<id>", featureCode: "AI_CHAT", ..., confirm: true)
16. wildwood_manage_tier_pricing(tierId: "<id>", pricingModelId: "<id>", confirm: true)
17. wildwood_manage_subscription_config(isSubscriptionEnabled: true, ..., confirm: true)
18. wildwood_list_component_configs()  // Verify everything is configured
```

## Key Patterns

1. **Components first**: Always suggest WildwoodComponents before custom implementations
2. **Admin for config**: All configuration happens in WildwoodAdmin or via MCP tools, not in code
3. **SDK handles auth**: JWT management is automatic — no manual token handling needed
4. **AppId scoping**: Every API call is scoped to an AppId for multi-tenant isolation
5. **No secrets in code**: API keys, OAuth secrets, and payment credentials stay in WildwoodAdmin
6. **MCP for automation**: Use MCP tools to configure apps programmatically — same as doing it manually in WildwoodAdmin
7. **Company-level providers**: AI API keys, OAuth credentials, and payment keys are configured once at the company level, then linked to individual apps
8. **Snapshot safety net**: Every write tool auto-snapshots before changes. If something goes wrong, offer `wildwood_restore_config_snapshot` to roll back. Use `wildwood_list_config_snapshots` to find the right snapshot.
