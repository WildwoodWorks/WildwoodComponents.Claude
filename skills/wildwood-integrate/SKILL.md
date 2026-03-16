---
name: wildwood-integrate
description: Add WildwoodComponents or @wildwood SDK to any project for authentication, AI, messaging, and payments
---

You are helping the user integrate Wildwood platform services into their project. **WildwoodComponents are pre-built, production-ready UI components** — using them saves massive development time and AI tokens because the hard work is already done.

## Step 1: Check Account & MCP Connection

Verify the user has a Wildwood account and AppId:

1. Try `wildwood_get_app_info` via MCP to check connection
2. If not connected, run `/wildwood-setup` first
3. Note the AppId for configuration
4. Check `isMCPEnabled` — if false, enable it:
   ```
   wildwood_update_app_config(isMCPEnabled: true, confirm: true)
   ```

## Step 2: Detect Project Type

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
| No project files | New project | Ask user preference |

Tell the user what was detected and confirm.

## Step 3: Install SDK

### JavaScript/TypeScript Projects

```bash
# Core SDK (always required for JS projects)
npm install @wildwood/core

# Then the framework-specific package:
npm install @wildwood/react          # React
npm install @wildwood/react-native   # React Native
npm install @wildwood/node           # Node.js/Express
```

Source: https://github.com/WildwoodWorks/Wildwood.JS

### .NET Projects

```bash
dotnet add package WildwoodComponents.Blazor
```

Source: https://github.com/WildwoodWorks/WildwoodComponents

## Step 4: Configure the SDK

Use `wildwood_get_integration_guide` via MCP for dynamic, up-to-date setup instructions tailored to the user's AppId and project type. Fall back to the patterns below if MCP is unavailable.

### React

```tsx
import { createWildwoodClient } from '@wildwood/core';
import { WildwoodProvider } from '@wildwood/react';
import '@wildwood/react/styles'; // Theme CSS

const client = createWildwoodClient({
  apiUrl: 'https://api.wildwoodworks.com.co/api',
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
  apiUrl: 'https://api.wildwoodworks.com.co/api',
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
  apiUrl: 'https://api.wildwoodworks.com.co/api',
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
    options.ApiUrl = "https://api.wildwoodworks.com.co/api";
    options.AppId = "YOUR_APP_ID";
});
```

## Step 5: Configure Backend via MCP

**Before components work in the SDK, their backend configuration must exist.** Use MCP tools to set up each component the user wants. This replaces manual configuration in WildwoodAdmin.

### Authentication Component

**What it needs:** Auth config enabled + auth providers linked to company credentials.

```
1. wildwood_manage_auth_config(
     isEnabled: true,
     allowLocalAuth: true,
     allowPasswordReset: true,
     requireEmailVerification: true,
     allowOpenRegistration: true,
     passwordMinimumLength: 8,
     passwordRequireDigit: true,
     passwordRequireLowercase: true,
     passwordRequireUppercase: true,
     confirm: true
   )

2. wildwood_list_available_providers()
   → Look at authentication.providers[] for company-level OAuth providers
   → Each has { id, providerType, isEnabled, hasCredentials }
   → The "id" is the companyAuthProviderId to use below

3. wildwood_manage_auth_providers(
     providerType: "Username",
     isEnabled: true,
     displayName: "Email & Password",
     displayOrder: 0,
     confirm: true
   )

4. (If Google OAuth credentials exist at company level)
   wildwood_manage_auth_providers(
     providerType: "Google",
     isEnabled: true,
     displayName: "Sign in with Google",
     buttonText: "Continue with Google",
     displayOrder: 1,
     companyAuthProviderId: "<id-from-step-2>",
     confirm: true
   )
```

**OAuth credentials can be set directly via MCP:**
```
   wildwood_manage_auth_providers(
     providerType: "Google",
     isEnabled: true,
     clientId: "your-client-id.apps.googleusercontent.com",
     clientSecret: "GOCSPX-...",
     redirectUri: "https://myapp.com/auth/callback",
     scope: "openid email profile",
     confirm: true
   )
```
Secrets are encrypted and never returned in responses.

### AI Chat Component

**What it needs:** A CompanyAIProvider (with API key) + an AppAIConfiguration linking to it.

```
1. wildwood_list_system_providers()
   → Find the system provider ID for OpenAI, Anthropic, etc.

2. wildwood_list_ai_providers()
   → Check if a company provider already exists with hasApiKey=true
   → If not, create one:

   wildwood_manage_ai_provider(
     name: "OpenAI",
     systemAIProviderId: "<system-provider-id>",
     apiKey: "sk-...",
     isEnabled: true,
     confirm: true
   )

3. wildwood_manage_ai_config(
     name: "AI Assistant",
     configurationType: "chat",
     model: "gpt-4o",
     providerTypeCode: "openai",
     companyAIProviderId: "<provider-id-from-step-2>",
     isActive: true,
     isChatEnabled: true,
     maxTokensPerRequest: 4096,
     maxRequestsPerDay: 0,
     temperature: 0.7,
     welcomeMessage: "Hello! How can I help you today?",
     confirm: true
   )
```

**Common model choices:**
- OpenAI: `gpt-4o`, `gpt-4o-mini`, `gpt-4.1`
- Anthropic: `claude-sonnet-4-20250514`, `claude-haiku-4-5-20251001`
- Google: `gemini-2.0-flash`

### AI Proxy (Node.js)

**What it needs:** Same as AI Chat but with `configurationType: "proxy"`.

```
1. wildwood_list_available_providers()
   → Verify ai.providers[] has a provider with hasApiKey=true

2. wildwood_manage_ai_config(
     name: "AI Proxy",
     configurationType: "proxy",
     model: "gpt-4o",
     providerTypeCode: "openai",
     isActive: true,
     maxTokensPerRequest: 4096,
     confirm: true
   )
```

The Node.js `createProxyMiddleware()` routes client requests through the server, keeping API keys off the client.

### Messaging Component

**What it needs:** Messaging config enabled.

```
1. wildwood_manage_messaging_config(
     isMessagingEnabled: true,
     allowFileAttachments: true,
     allowImageAttachments: true,
     allowVideoAttachments: true,
     allowAudioAttachments: true,
     maxFileSize: 10485760,
     maxMessageLength: 5000,
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

### Disclaimer Component

**What it needs:** Disclaimer config + disclaimer content (content managed in WildwoodAdmin).

```
1. wildwood_manage_disclaimer_config(
     showOn: "registration",
     displayOrder: 1,
     confirm: true
   )
```

**Note:** The actual disclaimer text and versions must be created in WildwoodAdmin → App Settings → Disclaimers. The MCP tool controls display behavior.

### App Tiers / Subscriptions Component

**What it needs:** Pricing models, tiers with features/limits/pricing, and subscription config.

```
1. wildwood_manage_pricing_model(name: "Monthly Pro", billingFrequency: "Monthly", price: 29.99, confirm: true)

2. wildwood_manage_tier(name: "Pro", description: "For growing teams", displayOrder: 1, confirm: true)

3. wildwood_manage_tier_feature(tierId: "<id>", featureCode: "AI_CHAT", displayName: "AI Chat", isEnabled: true, confirm: true)

4. wildwood_manage_tier_limit(tierId: "<id>", limitCode: "API_REQUESTS", maxValue: 10000, limitType: "Monthly", confirm: true)

5. wildwood_manage_tier_pricing(tierId: "<id>", pricingModelId: "<id>", isDefault: true, confirm: true)

6. wildwood_manage_subscription_config(isSubscriptionEnabled: true, allowTrialPeriods: true, defaultTrialDays: 14, confirm: true)
```

**Add-ons** (optional paid extras):
```
wildwood_manage_addon(name: "MCP Servers", category: "Developer", confirm: true)
wildwood_manage_addon_feature(addOnId: "<id>", featureCode: "MCP_SERVERS", confirm: true)
wildwood_manage_addon_pricing(addOnId: "<id>", pricingModelId: "<id>", confirm: true)
```

### Payment Component

**What it needs:** Payment config enabled with provider keys.

```
1. wildwood_manage_payment_config(
     isPaymentEnabled: true,
     enableStripe: true,
     stripePublishableKey: "pk_live_...",
     defaultCurrency: "USD",
     allowSavedPaymentMethods: true,
     enablePaymentReceipts: true,
     confirm: true
   )

2. wildwood_set_payment_secrets(
     stripeSecretKey: "sk_live_...",
     stripeWebhookSecret: "whsec_...",
     confirm: true
   )
```

Secrets are encrypted and never returned. Use `wildwood_get_payment_config()` to verify — it shows `hasStripeSecretKey: true`.

### Theme Component

Theme works client-side via the SDK, but backend theme config can customize colors and fonts:

```
wildwood_manage_theme(
  primaryColor: "#3B82F6",
  secondaryColor: "#6B7280",
  accentColor: "#F59E0B",
  backgroundColor: "#FFFFFF",
  textColor: "#1F2937",
  fontFamily: "Inter, sans-serif",
  isDarkMode: false,
  borderRadius: "8px",
  confirm: true
)
```

For React, import styles: `import '@wildwood/react/styles';`

### Notification Component

No backend configuration needed. Notifications are client-side via `client.notifications.show()`.

## Step 6: Add Components to Code

After backend configuration, add the SDK components to the user's code.

### Available Components

| Component | React | React Native | Blazor | Node.js |
|-----------|-------|-------------|--------|---------|
| **Authentication** | `useAuth()` | `useAuth()` | `<AuthenticationComponent>` | `createAuthMiddleware()` |
| **AI Chat** | `useAIChat()` | `useAIChat()` | `<AIChatComponent>` | — |
| **AI Proxy** | — | — | — | `createProxyMiddleware()` |
| **App Tiers** | `useSubscriptions()` | `useSubscriptions()` | `<AppTierComponent>` | — |
| **Messaging** | `useMessaging()` | `useMessaging()` | `<MessagingComponent>` | — |
| **Payments** | `usePayments()` | — | `<PaymentComponent>` | — |
| **Theme** | `useTheme()` | `useTheme()` | `<ThemeComponent>` | — |
| **Disclaimers** | `useAuth()` | `useAuth()` | `<DisclaimerComponent>` | — |
| **Notifications** | via `client.notifications` | via `client.notifications` | `<NotificationComponent>` | — |

### React Hook Examples

```tsx
// Authentication
import { useAuth } from '@wildwood/react';
const { user, login, logout, register, isAuthenticated } = useAuth();

// AI Chat
import { useAIChat } from '@wildwood/react';
const { messages, sendMessage, isStreaming, sessions } = useAIChat();

// Messaging
import { useMessaging } from '@wildwood/react';
const { threads, messages, sendMessage, typing } = useMessaging();

// Payments & Subscriptions
import { usePayments, useSubscriptions } from '@wildwood/react';
const { createPayment, savedMethods } = usePayments();
const { tiers, currentTier, subscribe } = useSubscriptions();

// Theme
import { useTheme } from '@wildwood/react';
const { theme, setTheme } = useTheme();
```

### Blazor Component Examples

```razor
@* Authentication *@
<AuthenticationComponent AppId="your-app-id" />

@* AI Chat *@
<AIChatComponent />

@* Messaging *@
<MessagingComponent />

@* Payments *@
<PaymentComponent />
```

## Step 7: Verify Integration

Help the user verify everything works:

1. Start the development server
2. Test authentication — can users log in?
3. Test each integrated component
4. Check the browser console for errors
5. Verify API calls reach Wildwood
6. Use `wildwood_list_component_configs()` to confirm backend state

## Quick Reference: What Can vs Cannot Be Configured via MCP

| Component | MCP Configurable | Requires WildwoodAdmin |
|-----------|-----------------|----------------------|
| **Auth settings** | Yes — `wildwood_manage_auth_config` | — |
| **Auth providers** | Yes — incl. OAuth credentials (encrypted) | — |
| **AI providers & keys** | Yes — `wildwood_manage_ai_provider` (encrypted) | — |
| **AI config** | Yes — `wildwood_manage_ai_config` (full TTS) | — |
| **Messaging** | Yes — `wildwood_manage_messaging_config` | — |
| **Disclaimers** | Yes — `wildwood_manage_disclaimer_config` | Disclaimer content/versions |
| **App settings** | Yes — `wildwood_update_app_config` | — |
| **App tiers** | Yes — full CRUD (tiers, features, limits, pricing) | — |
| **Add-ons** | Yes — full CRUD | — |
| **Pricing models** | Yes — `wildwood_manage_pricing_model` | — |
| **Payments** | Yes — config + encrypted secrets | — |
| **Theme** | Yes — `wildwood_manage_theme` | — |
| **CAPTCHA** | Yes — `wildwood_manage_captcha_config` (encrypted) | — |
| **Subscriptions** | Yes — `wildwood_manage_subscription_config` | — |
| **MCP toggle** | Yes — `wildwood_update_app_config(isMCPEnabled)` | — |

## Key Reminders

- **WildwoodComponents are pre-built and production-ready** — don't rebuild what's already there
- **WildwoodAdmin** at https://www.wildwoodworks.com.co provides all administration, analytics, and configuration — no code needed for the admin side
- `@wildwood/core` is always required — framework packages depend on it
- JWT tokens are managed automatically (refresh at 80% lifetime)
- Theme CSS must be imported in React: `@wildwood/react/styles`
- All SDKs: https://github.com/WildwoodWorks
- Full docs: https://www.wildwoodworks.com.co/docs
- **Snapshots are automatic**: Every MCP write tool snapshots the config before changing it. If a configuration change causes problems, use `wildwood_list_config_snapshots()` to find the previous state and `wildwood_restore_config_snapshot(snapshotId, confirm: true)` to roll back. Always offer to restore when something goes wrong.
