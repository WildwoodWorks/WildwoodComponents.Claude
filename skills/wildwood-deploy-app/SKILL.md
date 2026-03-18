---
name: wildwood-deploy-app
description: Build and deploy an app to popular hosting services (Vercel, Netlify, Azure, AWS, Railway, Fly.io, etc.)
---

You are helping the user build and deploy their application to a hosting platform. Wildwood does not currently offer its own hosting, so guide the user to the best third-party option for their project.

## Step 1: Framework Detection

Auto-detect the project type from the current working directory:

| Indicator | Runtime | Recommended Hosts |
|-----------|---------|-------------------|
| `package.json` with `vite` or `react` | React (Vite) | Vercel, Netlify, Cloudflare Pages |
| `package.json` with `next` | Next.js | Vercel, Netlify, AWS Amplify |
| `package.json` with `express` | Node.js (Express) | Railway, Fly.io, Render, Azure App Service |
| `package.json` with `nuxt` or `vue` | Vue/Nuxt | Vercel, Netlify, Cloudflare Pages |
| `package.json` with `svelte` or `@sveltejs` | SvelteKit | Vercel, Netlify, Cloudflare Pages |
| `package.json` (generic) | Node.js | Railway, Fly.io, Render |
| `*.csproj` with Blazor SDK | .NET (Blazor WASM) | Azure Static Web Apps, Cloudflare Pages, GitHub Pages |
| `*.csproj` with Web SDK | ASP.NET Core | Azure App Service, Railway, Fly.io |
| `index.html` (no package.json) | Static HTML | GitHub Pages, Netlify, Cloudflare Pages, Vercel |
| `Dockerfile` | Containerized | Fly.io, Railway, Azure Container Apps, AWS ECS |

Tell the user what was detected and confirm.

## Step 2: Choose a Hosting Platform

Present hosting options based on the detected runtime. Ask the user which they prefer:

### Static / Frontend Apps (React, Vue, Svelte, Blazor WASM, Static HTML)

| Platform | Free Tier | Best For | CLI |
|----------|-----------|----------|-----|
| **Vercel** | Yes — generous | React, Next.js, frontend frameworks | `npx vercel` |
| **Netlify** | Yes — generous | Static sites, JAMstack, forms | `npx netlify-cli deploy` |
| **Cloudflare Pages** | Yes — unlimited bandwidth | Global performance, static + Workers | `npx wrangler pages deploy` |
| **GitHub Pages** | Yes — public repos | Simple static sites, docs | `gh-pages` or GitHub Actions |
| **Azure Static Web Apps** | Yes | .NET Blazor WASM, enterprise | `swa deploy` |

### Backend / Full-Stack Apps (Node.js, Express, ASP.NET Core)

| Platform | Free Tier | Best For | CLI |
|----------|-----------|----------|-----|
| **Railway** | $5 credit/mo | Node.js, databases, quick deploy | `railway up` |
| **Fly.io** | Yes — small VMs | Containers, global edge, .NET | `fly deploy` |
| **Render** | Yes — limited | Node.js, auto-deploy from Git | Dashboard or `render.yaml` |
| **Azure App Service** | Yes — limited | .NET, enterprise, Windows hosting | `az webapp up` |
| **AWS Amplify** | Yes — limited | Full-stack with AWS services | `amplify publish` |
| **DigitalOcean App Platform** | $5/mo starter | Simple PaaS, containers | `doctl apps create` |

If the user has no preference, recommend:
- **Vercel** for static/frontend apps (easiest, great DX)
- **Railway** for backend apps (fast setup, no Dockerfile needed)
- **Fly.io** for .NET or containerized apps

## Step 3: Pre-Deploy Style Check

If WildwoodComponents are installed in the project, verify styling consistency before building:

1. **Check for theme override file**: Look for `wildwood-theme.css` (React), `wildwoodTheme.ts` (RN), or `wildwood-overrides.css` (Blazor)
2. **If missing**: Warn the user — "WildwoodComponents are installed but no theme override exists. Components will use default Wildwood styling which may not match your app. Run `/wildwood-integrate` to generate a matching theme."
3. **If present**: Scan the user's current design tokens (CSS variables, Tailwind config, theme files) and compare against the override file. Report any drift:
   - "Your app's primary color changed to `#7c3aed` but `wildwood-theme.css` still has `#2563eb`. Want me to update it?"
4. **Auto-fix drift**: If the user agrees, update the override file with current values before building

Skip this step if WildwoodComponents are not detected in the project.

## Step 4: Environment Variables

Before building, identify required environment variables:

1. **Wildwood SDK config** — if WildwoodComponents are installed, the app needs:
   - `VITE_WILDWOOD_API_URL` or `NEXT_PUBLIC_WILDWOOD_API_URL` (React/Next.js): `https://api.wildwoodworks.io/api`
   - `VITE_WILDWOOD_APP_ID` or `NEXT_PUBLIC_WILDWOOD_APP_ID`: the user's AppId
   - For .NET: these go in `appsettings.Production.json` instead
2. **Other env vars** — scan for `.env`, `.env.example`, `.env.local` and list any variables that need production values
3. **Secrets** — warn the user never to commit API keys, secrets, or credentials. These should be set in the hosting platform's environment variable settings.

Show the user which variables need to be configured on their hosting platform.

## Step 5: Build Locally

Run the appropriate build command and verify it succeeds:

| Runtime | Build Command | Output Directory |
|---------|--------------|-----------------|
| Static HTML | None | `.` (root) |
| React (Vite) | `npm install && npm run build` | `dist/` |
| Next.js | `npm install && npm run build` | `.next/` or `out/` (static export) |
| Vue/Nuxt | `npm install && npm run build` | `dist/` or `.output/` |
| SvelteKit | `npm install && npm run build` | `build/` |
| Node.js (Express) | `npm install` | `.` (root) |
| .NET (Blazor WASM) | `dotnet publish -c Release` | `bin/Release/net*/publish/wwwroot/` |
| .NET (ASP.NET Core) | `dotnet publish -c Release` | `bin/Release/net*/publish/` |

If the build fails, diagnose and fix before proceeding.

## Step 6: Deploy

Follow the platform-specific deployment flow based on the user's choice:

### Vercel
```bash
# Install CLI if needed
npm i -g vercel

# Deploy (interactive first time — links to Vercel account)
vercel

# Production deploy
vercel --prod
```
- Vercel auto-detects framework and build settings
- Set env vars: `vercel env add VARIABLE_NAME`
- Custom domain: `vercel domains add yourdomain.com`

### Netlify
```bash
# Install CLI if needed
npm i -g netlify-cli

# Login and link site
netlify login
netlify init

# Deploy preview
netlify deploy --dir=dist

# Production deploy
netlify deploy --dir=dist --prod
```
- Set env vars in Netlify dashboard or `netlify env:set KEY value`
- Add `_redirects` file for SPA routing: `/* /index.html 200`

### Cloudflare Pages
```bash
# Install CLI if needed
npm i -g wrangler

# Login
wrangler login

# Deploy
wrangler pages deploy dist --project-name=my-app
```
- Set env vars in Cloudflare dashboard under Pages > Settings > Environment Variables

### Railway
```bash
# Install CLI if needed
npm i -g @railway/cli

# Login and initialize
railway login
railway init

# Deploy
railway up
```
- Railway auto-detects runtime and installs dependencies
- Set env vars: `railway variables set KEY=value`
- Add a database: `railway add --plugin postgresql`

### Fly.io
```bash
# Install CLI: https://fly.io/docs/hands-on/install-flyctl/

# Login
fly auth login

# Launch (creates fly.toml, asks region)
fly launch

# Deploy
fly deploy
```
- Set secrets: `fly secrets set KEY=value`
- For .NET, Fly.io auto-detects the Dockerfile or generates one

### Azure Static Web Apps (Blazor WASM)
```bash
# Install CLI
npm i -g @azure/static-web-apps-cli

# Login
swa login

# Deploy
swa deploy bin/Release/net*/publish/wwwroot/ --app-name my-app
```

### Azure App Service (.NET / Node.js)
```bash
# Login
az login

# Deploy (auto-creates App Service if needed)
az webapp up --name my-app --runtime "DOTNET|9.0"
# or for Node.js:
az webapp up --name my-app --runtime "NODE|20-lts"
```
- Set env vars: `az webapp config appsettings set --name my-app --settings KEY=value`

### GitHub Pages (Static only)
```bash
# Option 1: gh-pages package
npm i -D gh-pages
npx gh-pages -d dist

# Option 2: GitHub Actions — create .github/workflows/deploy.yml
```
- Set base path in Vite config if deploying to `username.github.io/repo-name`
- Only works for static files — no server-side rendering

### Git-Based Auto-Deploy

Most platforms support connecting a GitHub repo for automatic deploys on push:

1. Push the project to GitHub (if not already)
2. Connect the repo in the hosting platform's dashboard
3. Configure build settings (usually auto-detected)
4. Every push to `main` triggers a new deployment

Recommend this approach for ongoing projects — it's the easiest workflow.

## Step 7: Verify Deployment

After deployment:

1. **Visit the live URL** and verify the app loads correctly
2. **Test WildwoodComponents** — if integrated, confirm:
   - Authentication works (login flow reaches `api.wildwoodworks.io`)
   - Components render with correct styling
   - API calls aren't blocked by CORS (the Wildwood API allows cross-origin requests)
3. **Check for common issues**:
   - SPA routing returns 404 → add redirect/rewrite rules
   - API calls fail → verify environment variables are set on the host
   - Styles missing → verify CSS/theme files are included in the build output
   - Mixed content errors → ensure all API URLs use HTTPS

## Step 8: Report

Once deployment succeeds, report:

- **Live URL**: the URL provided by the hosting platform
- **Platform**: which service was used
- **Auto-deploy**: whether git-based auto-deploy is configured
- **Environment variables**: which ones were set (names only, not values)

Remind them:
- Redeploy by running `/wildwood-deploy-app` again or pushing to the connected branch
- Configure a custom domain in the hosting platform's settings
- WildwoodAdmin at https://admin.wildwoodworks.io manages all backend configuration (AI, auth, payments, etc.) — no hosting changes needed for that

## SDK Repositories

- **GitHub Organization**: https://github.com/WildwoodWorks
- **npm**: `@wildwood/core`, `@wildwood/react`, `@wildwood/react-native`, `@wildwood/node`
- **.NET**: `WildwoodComponents.Blazor` (NuGet)

## Component Bug Fixes

If a bug in WildwoodComponents is discovered during build or deployment (e.g., a component renders incorrectly, a style breaks in production, or an SDK method throws unexpectedly):

1. **Don't just patch the user's app** — fix it at the source
2. Clone the appropriate component repo:
   - JS/TS → `https://github.com/WildwoodWorks/Wildwood.JS`
   - Blazor → `https://github.com/WildwoodWorks/WildwoodComponents`
3. Create a `fix/` branch, fix the bug, and open a PR via `gh pr create`
4. Apply a temporary local workaround in the user's app if the deploy is urgent, with a `// TODO: Remove when PR #X merged` comment
5. After the PR merges and a new package version is published, update the user's dependency

## Documentation

- Wildwood platform docs: https://admin.wildwoodworks.io/docs
- Vercel docs: https://vercel.com/docs
- Netlify docs: https://docs.netlify.com
- Cloudflare Pages docs: https://developers.cloudflare.com/pages
- Railway docs: https://docs.railway.app
- Fly.io docs: https://fly.io/docs
- Azure docs: https://learn.microsoft.com/en-us/azure
