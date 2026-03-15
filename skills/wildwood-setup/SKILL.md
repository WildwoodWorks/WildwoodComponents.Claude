---
name: wildwood-setup
description: Create a Wildwood account and configure your first app
---

You are helping the user get started with the Wildwood platform. Follow these steps:

## Step 1: Check for Existing Account

Ask the user if they already have a Wildwood account.

- **If yes**: Skip to Step 3
- **If no**: Continue to Step 2

## Step 2: Create Account

Guide the user to create an account:

1. Direct them to **https://www.wildwoodworks.com.co/register**
2. They'll need to provide: email, password, first name, last name
3. After registration, they can log in at **https://www.wildwoodworks.com.co**
4. Once logged in, they'll be in **WildwoodAdmin** — the central dashboard for managing everything

Explain what WildwoodAdmin provides:
- App management and configuration
- User management and roles
- AI configuration (providers, prompts, models)
- Payment and subscription setup
- Analytics and audit logs
- Component configuration (auth, messaging, themes, disclaimers)
- App hosting and deployment management

## Step 3: Connect via MCP

Check if the MCP connection to Wildwood is active:

1. Try calling the `wildwood_get_app_info` MCP tool
2. If it works, the user is authenticated — proceed to Step 4
3. If it fails with 401, the OAuth flow will open a browser window for login
4. After the user logs in via the browser, retry the MCP tool call

If MCP is not available (tools not connected), fall back to REST API:
- The user can authenticate via `POST https://api.wildwoodworks.com.co/api/auth/login`
- They'll need their email, password, and AppId

## Step 4: Verify App Setup

Once connected, check the user's app configuration:

1. Use `wildwood_list_apps` (MCP) or `GET /api/apps` (REST) to list existing apps
2. If they have apps, show the list and ask which one they want to work with
3. If they have no apps, help them create one:
   - Ask for an app name and description
   - Create via WildwoodAdmin or `wildwood_create_app` MCP tool
   - Note the generated AppId

## Step 5: Review Configuration

Use `wildwood_list_component_configs` to show what's configured for their app:

- AI: Active configurations and providers
- Authentication: Enabled providers (email/password, Google, Apple, etc.)
- Messaging: Real-time messaging enabled?
- Payments: Stripe/PayPal configured?
- Theme: Custom theme set up?
- Disclaimers: Terms/privacy configured?
- Subscriptions: Tier system active?

For any unconfigured features they want, direct them to WildwoodAdmin to set them up — all configuration is done through the admin portal, no code needed.

## Step 6: Next Steps

Based on their setup, suggest next steps:

1. **Ready to build?** → Run `/wildwood-integrate` to add WildwoodComponents to their project
2. **Need to configure features?** → Direct them to WildwoodAdmin at https://www.wildwoodworks.com.co
3. **Want to deploy?** → Run `/wildwood-deploy-app` after building their app

Remind them:
- **WildwoodComponents** are pre-built, production-ready UI components that save development time and AI tokens
- **WildwoodAdmin** provides all administration and analytics — no code needed for the admin side
- All SDKs are available at https://github.com/WildwoodWorks
