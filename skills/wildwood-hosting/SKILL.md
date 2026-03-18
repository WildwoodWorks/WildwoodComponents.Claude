---
name: wildwood-hosting
description: Manage app hosting deployments on the Wildwood platform — create, deploy, start, stop, rollback, domains, and metrics
---

You are helping the user manage app hosting deployments on the Wildwood platform. Wildwood provides managed container hosting for web apps at `apps.wildwoodworks.io`.

## Prerequisites

- MCP connection must be active (run `/wildwood-setup` if not)
- Company must have the `APP_HOSTING` feature enabled (Starter tier or higher)

## Available Commands

### List Deployments
Show all hosted app deployments for the company:
```
hosting_deployment_list
```

### Get Deployment Details
Get details of a specific deployment:
```
hosting_deployment_get(deploymentId: "...")
```

### Create a New Deployment
Create a new app hosting deployment:
```
hosting_deployment_create(
  appId: "...",
  slug: "my-app",
  runtime: 1,           // 0=Static, 1=NodeJs, 2=DotNet, 3=Docker
  framework: "react",   // Optional: react, nextjs, express, etc.
  entryPoint: "server.js",  // Optional: entry point file
  buildCommand: "npm run build",  // Optional
  outputDirectory: "dist",        // Optional
  confirm: true
)
```

**Runtime options:**
| Runtime | Value | Best For |
|---------|-------|----------|
| Static | 0 | React, Vue, static HTML |
| Node.js | 1 | Express, Next.js, Nuxt |
| .NET | 2 | ASP.NET Core, Blazor Server |
| Docker | 3 | Custom containers |

### Check Slug Availability
Verify a deployment slug is available:
```
hosting_check_slug(slug: "my-app")
```

### Start / Stop Deployment
Start a stopped deployment or stop a running one:
```
hosting_deployment_start(deploymentId: "...", confirm: true)
hosting_deployment_stop(deploymentId: "...", confirm: true)
```

### Rollback Deployment
Rollback to the previous deployment version:
```
hosting_deployment_rollback(deploymentId: "...", confirm: true)
```

### Delete Deployment
Permanently delete a deployment and its resources:
```
hosting_deployment_delete(deploymentId: "...", confirm: true)
```

### View Deployment Logs
Get build and runtime logs:
```
hosting_deployment_logs(deploymentId: "...")
```

### Custom Domains
List domains for a deployment or remove one:
```
hosting_domain_list(deploymentId: "...")
hosting_domain_remove(domainId: "...", confirm: true)
```

### Performance Metrics
Get request counts, response times, error rates, and bandwidth:
```
hosting_metrics(deploymentId: "...", days: 30)
```

## Workflow: Deploy a New App

1. **Check feature availability**: Ensure the company's tier includes `APP_HOSTING`
2. **Check slug availability**: `hosting_check_slug(slug: "my-app")`
3. **Create deployment**: `hosting_deployment_create(...)` with desired settings
4. **Deploy code**: Upload your built app through WildwoodAdmin > Hosting > Deployments > Deploy
5. **Verify**: Check `hosting_deployment_get(...)` for status and visit the live URL
6. **Add custom domain** (optional): Configure in WildwoodAdmin > Hosting > Domains

## Tier Limits

| Limit | Starter | Professional | Business | Enterprise |
|-------|---------|-------------|----------|------------|
| Hosted Apps | 1 | 5 | 15 | Unlimited |
| Hosting Storage | 500 MB | 2 GB | 10 GB | Unlimited |
| Custom Domains | 0 | 3 | 10 | Unlimited |
| Bandwidth/mo | 10 GB | 50 GB | 200 GB | Unlimited |
| Max Container | Small | Small/Med | S/M/L | Any |

## Add-Ons

| Add-On | Price | What It Adds |
|--------|-------|-------------|
| Extra Hosting Apps (+3) | $15/mo | 3 additional deployments |
| Extra Hosting Storage (+2 GB) | $7/mo | 2 GB more storage |
| Extra Bandwidth (+50 GB) | $9/mo | 50 GB more monthly bandwidth |
| App Size Upgrade (Medium) | $10/mo | 0.5 vCPU, 1 GB RAM container |
| App Size Upgrade (Large) | $25/mo | 1 vCPU, 2 GB RAM container |
| Always-Warm | $5/mo | Eliminate cold starts (per-app) |

## Troubleshooting

- **"Feature not enabled"**: Upgrade to Starter tier or higher in WildwoodAdmin
- **"Limit exceeded"**: Company has reached its HOSTED_APPS limit. Upgrade tier or purchase the "Extra Hosting Apps" add-on
- **Deployment not starting**: Check logs with `hosting_deployment_logs` for build/runtime errors
- **Custom domain not working**: Verify DNS CNAME points to `apps.wildwoodworks.io` and SSL is provisioned
- **Slow cold starts**: Purchase the "Always-Warm" add-on to keep the container running
