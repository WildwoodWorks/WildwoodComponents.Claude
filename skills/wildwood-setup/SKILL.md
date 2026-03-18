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

1. Direct them to **https://admin.wildwoodworks.io/register**
2. They'll need to provide: email, password, first name, last name
3. After registration, they can log in at **https://admin.wildwoodworks.io**
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
- The user can authenticate via `POST https://api.wildwoodworks.io/api/auth/login`
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

For any unconfigured features they want, configure them via MCP tools or direct them to WildwoodAdmin. MCP tools can now fully configure AI providers, auth, payments, themes, CAPTCHA, tiers, and subscriptions — run `/wildwood-integrate` to set them up.

## Step 6: Database Hosting (Optional)

If the user's app needs a managed database, introduce Wildwood's hosted Azure SQL databases:

1. **Check eligibility**: Database hosting requires **Professional** tier or higher (`DB_HOSTING` feature)
2. **Provision a database**: Use `database_hosting_create` MCP tool or WildwoodAdmin > Hosting > Databases
   - Choose a tier: Basic (5 DTU, 2 GB), Standard (10 DTU, 250 GB), or Elastic (shared pool)
   - Pick a unique slug (used in the database name)
3. **Get connection string**: Once status is `Active`, use `database_hosting_get_connection` to retrieve it
4. **Configure your app**: Add the connection string to your app's environment variables or configuration
5. **Backups**: Automatic backups are enabled by default; create manual backups with `database_hosting_backup_create`

For full database management, run `/wildwood-database-hosting`.

**Tier limits:**
| Tier | Databases | Storage |
|------|-----------|---------|
| Professional | 1 | 500 MB |
| Business | 5 | 5 GB |
| Enterprise | Unlimited | Unlimited |

Need more? Purchase the **DB Hosting Starter** or **Extra Hosted DBs** add-ons.

## Step 7: Next Steps

Based on their setup, suggest next steps:

1. **Ready to build?** → Run `/wildwood-integrate` to add WildwoodComponents to their project
2. **Need to configure features?** → Use MCP tools via `/wildwood-integrate` or WildwoodAdmin at https://admin.wildwoodworks.io
3. **Want to deploy?** → Run `/wildwood-deploy-app` after building their app
4. **Need a database?** → Run `/wildwood-database-hosting` to provision and manage hosted databases

Remind them:
- **WildwoodComponents** are pre-built, production-ready UI components that save development time and AI tokens
- **WildwoodAdmin** or **MCP tools** provide all administration and configuration — no code needed for the admin side
- **Hosted databases** and **app hosting** are managed through the same platform — no separate cloud accounts needed
- All SDKs are available at https://github.com/WildwoodWorks
