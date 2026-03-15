---
name: wildwood-status
description: Check Wildwood app status, deployments, and quota usage
skill-version: 2.0.0
---

You are helping the user check the status of their Wildwood platform resources. Gather and display a comprehensive status report.

## Step 1: Check MCP Connection

1. Try calling `wildwood_get_app_info` via MCP
2. If successful, report: "MCP connection active — authenticated as {user}"
3. If failed, report the error and suggest running `/wildwood-setup`

## Step 2: App Overview

Use MCP tools (preferred) or REST API to gather:

### Current App
- `wildwood_get_app_info` → App name, ID, status, creation date

### All Apps
- `wildwood_list_apps` → List all company apps with status

### Component Status
- `wildwood_list_component_configs` → Show which features are enabled:
  - AI configurations (active count)
  - Authentication (enabled, provider count)
  - Messaging (enabled/disabled)
  - Payments (enabled/disabled)
  - Theme (configured/not)
  - Captcha (enabled/disabled)
  - Disclaimers (count)
  - Notifications (configured/not)
  - Subscriptions (enabled/disabled)

## Step 3: Analytics

Use `wildwood_get_analytics` to show recent usage:
- Total users
- AI requests (last 30 days)
- Messages (last 30 days)
- Top actions by frequency

## Step 4: Tier & Quota Usage

Use `wildwood_list_app_tiers` to show:
- Available tiers and pricing
- Feature limits per tier
- Current tier (if subscription data available)

## Step 5: Deployment Status (if applicable)

Check for active deployments via REST API:
- `GET /api/hosting/deployments` → List deployments
- Show: slug, URL, status, runtime, last deployed, storage used

## Step 6: Report Summary

Present a clean status report:

```
=== Wildwood Platform Status ===

MCP Connection: Active ✓
App: {name} ({appId})
Company: {companyName}

Components:
  AI:             {count} active configs
  Authentication: Enabled ({providerCount} providers)
  Messaging:      Enabled/Disabled
  Payments:       Enabled/Disabled
  Subscriptions:  Enabled/Disabled

Usage (Last 30 Days):
  Users:       {total}
  AI Requests: {count}
  Messages:    {count}

Deployments:
  {slug}.apps.wildwoodworks.com.co — Active (v{version})

Admin Portal: https://www.wildwoodworks.com.co
```

## Troubleshooting

If issues are detected, suggest remediation:
- **MCP not connected** → Run `/wildwood-setup`
- **No apps** → Create one in WildwoodAdmin or via `/wildwood-setup`
- **Features not configured** → Configure in WildwoodAdmin
- **No deployments** → Run `/wildwood-deploy-app`
