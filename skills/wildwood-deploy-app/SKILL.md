---
name: wildwood-deploy-app
description: Build and deploy an app to Wildwood hosting at apps.wildwoodworks.com.co
---

You are helping the user deploy their application to the Wildwood App Hosting Platform. Follow these steps carefully:

## Step 1: Authentication

Check if the user is authenticated:

1. Try `wildwood_get_app_info` via MCP to verify connection
2. If not connected, run `/wildwood-setup` first
3. If MCP is unavailable, authenticate via REST:
   - `POST https://api.wildwoodworks.com.co/api/auth/login` with credentials
   - Store the JWT token for subsequent API calls

## Step 2: App Setup

Determine which CompanyApp to associate the deployment with:

1. Use `wildwood_list_apps` (MCP) or `GET /api/apps` (REST) to list existing apps
2. If the user wants a new app, create one via WildwoodAdmin or MCP
3. Note the `AppId` and `ApiKey`
4. Check the `HOSTING_APP_COUNT` tier limit to ensure they haven't exceeded their quota

## Step 3: Framework Detection

Auto-detect the project type from the current working directory:

| Indicator | Runtime |
|-----------|---------|
| `package.json` with `vite` or `react` | React (Vite) |
| `package.json` with `next` | Node.js (Next.js) |
| `package.json` with `express` | Node.js (Express) |
| `package.json` (generic) | Node.js |
| `*.csproj` with Blazor SDK | .NET (Blazor) |
| `*.csproj` with Web SDK | .NET |
| `index.html` (no package.json) | Static HTML |

Tell the user what was detected and confirm the runtime choice.

## Step 4: Subdomain Selection

Help the user choose a subdomain slug for `{slug}.apps.wildwoodworks.com.co`:

1. Suggest a slug based on the project/directory name (lowercase, hyphens, 3-50 chars)
2. Check availability via `GET /api/hosting/check-slug?slug={slug}`
3. If taken, show the suggestions from the API response and re-prompt
4. Slug rules: lowercase alphanumeric + hyphens, no consecutive hyphens, must start/end with alphanumeric
5. Reserved words: `www`, `api`, `admin`, `mail`, `ftp`, `_engine`, `_shared`, `status`, `docs`

## Step 5: Create Deployment

Create the deployment record:

```
POST /api/hosting/deployments
{
  "appId": "{appId}",
  "slug": "{slug}",
  "runtime": "Static" | "React" | "NodeJs" | "DotNet",
  "framework": "{detected-framework}",
  "entryPoint": "{entry-point-if-applicable}",
  "buildCommand": "{build-command}",
  "outputDirectory": "{output-dir}"
}
```

## Step 6: Build Locally

Run the appropriate build command:

| Runtime | Build Command | Output Directory |
|---------|--------------|-----------------|
| Static HTML | None | `.` (root) |
| React (Vite) | `npm install && npm run build` | `dist/` |
| Node.js (Express) | `npm install` | `.` (root) |
| Node.js (Next.js) | `npm install && npm run build` | `.` (root) |
| .NET | `dotnet publish -c Release` | `bin/Release/net*/publish/` |

Verify the build succeeds before proceeding.

## Step 7: Deploy

1. Create a zip of the build output (excluding `node_modules/`, `.git/`, `.env`, `*.pem`, `*.key`)
2. Upload via `POST /api/hosting/deploy/{deploymentId}` with the zip as multipart form data
3. Monitor the response — if status is `Failed`, show the error message

## Step 8: Report

Once deployment succeeds, report:

- **Live URL**: `https://{slug}.apps.wildwoodworks.com.co`
- **Status**: Active
- **Version**: v{version}
- **Deployment ID**: {id}

Remind them they can:
- View deployment details in WildwoodAdmin under Hosting > Deployments
- Redeploy by running `/wildwood-deploy-app` again
- Rollback via the API: `POST /api/hosting/deploy/{deploymentId}/rollback`

## Environment Variables

If the user needs environment variables:

```
PUT /api/hosting/deployments/{id}
{ "environmentVariables": { "KEY": "value" } }
```

These are encrypted at rest via `IDataEncryptionService`.

## API Base URL

- **Production**: `https://api.wildwoodworks.com.co/api`
- **Development**: `https://localhost:7046/api`

Use production unless the user specifies development.

## SDK Repositories

- **GitHub Organization**: https://github.com/WildwoodWorks
- **npm**: `@wildwood/core`, `@wildwood/react`, `@wildwood/react-native`, `@wildwood/node`
- **.NET**: `WildwoodComponents.Blazor` (NuGet)

## Error Handling

- No `APP_HOSTING` tier feature → explain they need to upgrade their tier
- Exceeded `HOSTING_APP_COUNT` → suggest removing unused deployments
- Exceeded `HOSTING_STORAGE_MB` → suggest optimizing build output or upgrading
- Slug taken → show suggestions and let them pick a new one

## Documentation

Full platform documentation: https://www.wildwoodworks.com.co/docs
