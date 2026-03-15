---
name: wildwood-integrate
description: Add WildwoodComponents or @wildwood SDK to any project for authentication, AI, messaging, and payments
skill-version: 2.0.0
---

You are helping the user integrate Wildwood platform services into their project. **WildwoodComponents are pre-built, production-ready UI components** — using them saves massive development time and AI tokens because the hard work is already done.

## Step 1: Check Account

Verify the user has a Wildwood account and AppId:

1. Try `wildwood_get_app_info` via MCP to check connection
2. If not connected, run `/wildwood-setup` first
3. Note the AppId for configuration

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

## Step 5: Add Components

Ask which features the user wants. For each selected component, show the exact imports and usage.

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

## Step 6: Verify Integration

Help the user verify everything works:

1. Start the development server
2. Test authentication — can users log in?
3. Test each integrated component
4. Check the browser console for errors
5. Verify API calls reach Wildwood

## Key Reminders

- **WildwoodComponents are pre-built and production-ready** — don't rebuild what's already there
- **WildwoodAdmin** at https://www.wildwoodworks.com.co provides all administration, analytics, and configuration — no code needed for the admin side
- `@wildwood/core` is always required — framework packages depend on it
- JWT tokens are managed automatically (refresh at 80% lifetime)
- Theme CSS must be imported in React: `@wildwood/react/styles`
- All SDKs: https://github.com/WildwoodWorks
- Full docs: https://www.wildwoodworks.com.co/docs
