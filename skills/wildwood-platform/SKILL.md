---
name: wildwood-platform
description: Wildwood platform knowledge - architecture, SDK reference, component catalog, and API conventions
skill-version: 2.0.0
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

## MCP Tools Available

When connected via MCP (`/mcp` endpoint), these tools are available to CompanyAdmin users:

| Tool | Description |
|------|-------------|
| `wildwood_get_app_info` | Current app configuration |
| `wildwood_list_apps` | All company apps |
| `wildwood_get_ai_config` | AI configurations (no API keys) |
| `wildwood_get_auth_config` | Auth provider configuration |
| `wildwood_list_available_providers` | Available auth/AI/payment providers |
| `wildwood_list_users` | Company users |
| `wildwood_get_messaging_config` | Messaging settings |
| `wildwood_get_payment_config` | Payment config (no secrets) |
| `wildwood_get_disclaimer_config` | Disclaimer configuration |
| `wildwood_list_app_tiers` | Tiers and features |
| `wildwood_list_component_configs` | All component status |
| `wildwood_get_integration_guide` | SDK setup instructions |
| `wildwood_get_analytics` | Usage analytics |

## Key Patterns

1. **Components first**: Always suggest WildwoodComponents before custom implementations
2. **Admin for config**: All configuration happens in WildwoodAdmin, not in code
3. **SDK handles auth**: JWT management is automatic — no manual token handling needed
4. **AppId scoping**: Every API call is scoped to an AppId for multi-tenant isolation
5. **No secrets in code**: API keys, OAuth secrets, and payment credentials stay in WildwoodAdmin
