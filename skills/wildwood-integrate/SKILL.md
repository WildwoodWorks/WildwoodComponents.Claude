---
name: wildwood-integrate
description: Add WildwoodComponents or @wildwood SDK to any project for authentication, AI, messaging, and payments
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

## Step 5: Detect & Align Styling

Before adding components, analyze the user's existing design system so WildwoodComponents match their app's look and feel.

### 5a: Scan the Project for Design Tokens

Look for existing design values in these locations (check in order):

| Source | Files to Check |
|--------|---------------|
| CSS variables | `*.css`, `*.scss` — look for `--color-*`, `--font-*`, `--radius-*`, `--spacing-*` |
| Tailwind config | `tailwind.config.*` — `theme.extend.colors`, `fontFamily`, `borderRadius` |
| Theme files | `theme.ts`, `theme.js`, `tokens.ts`, `design-tokens.*` |
| Component library config | `chakra-theme.*`, `mantine-theme.*`, `mui-theme.*` |
| Global styles | `globals.css`, `App.css`, `index.css`, `styles/` directory |

Extract the following design tokens if present:

- **Primary color** (brand color used for buttons, links, accents)
- **Secondary color** (supporting accent)
- **Background colors** (page background, surface/card background)
- **Text colors** (primary text, secondary/muted text)
- **Font family** (heading and body fonts)
- **Border radius** (rounded corners — sharp, rounded, pill)
- **Spacing scale** (if custom)

### 5b: Generate Wildwood Theme Override

Create a theme configuration that maps the user's design tokens to WildwoodComponents CSS variables.

**React — create `wildwood-theme.css`:**

```css
:root {
  /* Map to user's design system */
  --ww-color-primary: var(--user-primary, #2563eb);
  --ww-color-primary-hover: var(--user-primary-hover, #1d4ed8);
  --ww-color-secondary: var(--user-secondary, #64748b);
  --ww-color-background: var(--user-bg, #ffffff);
  --ww-color-surface: var(--user-surface, #f8fafc);
  --ww-color-text: var(--user-text, #0f172a);
  --ww-color-text-muted: var(--user-text-muted, #64748b);
  --ww-color-border: var(--user-border, #e2e8f0);
  --ww-font-family: var(--user-font, 'Inter', system-ui, sans-serif);
  --ww-font-family-heading: var(--user-font-heading, var(--ww-font-family));
  --ww-border-radius: var(--user-radius, 0.5rem);
  --ww-border-radius-lg: var(--user-radius-lg, 0.75rem);
}
```

Import order in the app entry point:
```tsx
import '@wildwood/react/styles';         // Base Wildwood styles
import './wildwood-theme.css';           // User's theme overrides (loaded after to win specificity)
```

**React Native — create `wildwoodTheme.ts`:**

```typescript
import { createTheme } from '@wildwood/react-native';

export const wildwoodTheme = createTheme({
  colors: {
    primary: '#2563eb',       // ← user's primary color
    secondary: '#64748b',     // ← user's secondary color
    background: '#ffffff',
    surface: '#f8fafc',
    text: '#0f172a',
    textMuted: '#64748b',
    border: '#e2e8f0',
  },
  fonts: {
    body: 'Inter',            // ← user's font
    heading: 'Inter',
  },
  borderRadius: {
    sm: 4,
    md: 8,
    lg: 12,
  },
});
```

Pass to provider:
```tsx
<WildwoodProvider client={client} theme={wildwoodTheme}>
```

**Blazor — add to `wwwroot/css/wildwood-overrides.css`:**

```css
:root {
  --ww-color-primary: #2563eb;
  --ww-color-primary-hover: #1d4ed8;
  /* ... same pattern as React */
}
```

Add to `_Host.cshtml` or `App.razor` after the Wildwood stylesheet.

### 5c: Verify Visual Consistency

After generating the theme override:

1. Replace placeholder hex values with the actual colors extracted from the user's project
2. If no design system exists yet, ask: "Do you have brand colors or a design preference? I can set up a cohesive theme, or use sensible defaults."
3. If using Tailwind, map Tailwind color names to Wildwood variables automatically (e.g., `colors.blue.600` → `--ww-color-primary`)
4. Confirm the override file is imported in the correct order (after Wildwood base styles)

## Step 6: Add Components

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

## Step 7: Verify Integration

Help the user verify everything works:

1. Start the development server
2. Test authentication — can users log in?
3. Test each integrated component
4. **Visually verify** that Wildwood components match the app's design (colors, fonts, border radius)
5. Check the browser console for errors
6. Verify API calls reach Wildwood

## Step 8: Keep Styles In Sync

Tell the user: "If you change your app's design system later (new brand colors, fonts, etc.), update the Wildwood theme override file to match. Run `/wildwood-integrate` again and I'll re-scan your design tokens and update the overrides."

**Proactive style detection**: Whenever you're working in a project with WildwoodComponents installed, check if the theme override file exists and whether it still matches the app's current design tokens. If drift is detected, suggest updating.

## Contributing Bug Fixes Back

If you discover a bug in a WildwoodComponent during integration or testing, **fix it and submit a PR** to the upstream repository rather than working around it in the user's app:

1. **Identify the source**: Determine which package contains the bug
   - JS/TS packages (`@wildwood/core`, `@wildwood/react`, `@wildwood/react-native`, `@wildwood/node`) → `https://github.com/WildwoodWorks/Wildwood.JS`
   - Blazor/.NET (`WildwoodComponents.Blazor`) → `https://github.com/WildwoodWorks/WildwoodComponents`

2. **Clone the component repo** (if not already local):
   ```bash
   git clone https://github.com/WildwoodWorks/Wildwood.JS.git    # JS/TS
   git clone https://github.com/WildwoodWorks/WildwoodComponents.git  # Blazor
   ```

3. **Create a fix branch**:
   ```bash
   git checkout -b fix/short-description-of-bug
   ```

4. **Fix the bug** in the component source, ensuring:
   - The fix is minimal and focused on the bug
   - Existing tests still pass
   - New tests are added if the bug wasn't previously covered

5. **Submit a PR** via `gh pr create` with:
   - Clear title describing the bug
   - Steps to reproduce in the PR body
   - Reference to the user's project/context if relevant

6. **In the meantime**, apply a local workaround in the user's app if they can't wait for the PR to be merged. Add a `// TODO: Remove workaround when WildwoodComponents PR #X is merged` comment so it gets cleaned up later.

**Always prefer fixing upstream over local workarounds.** This keeps the components healthy for all users.

## Key Reminders

- **WildwoodComponents are pre-built and production-ready** — don't rebuild what's already there
- **WildwoodAdmin** at https://www.wildwoodworks.com.co provides all administration, analytics, and configuration — no code needed for the admin side
- `@wildwood/core` is always required — framework packages depend on it
- JWT tokens are managed automatically (refresh at 80% lifetime)
- Theme CSS must be imported in React: `@wildwood/react/styles`
- All SDKs: https://github.com/WildwoodWorks
- Full docs: https://www.wildwoodworks.com.co/docs
