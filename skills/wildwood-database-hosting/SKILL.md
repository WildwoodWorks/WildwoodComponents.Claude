---
name: wildwood-database-hosting
description: Manage hosted databases on the Wildwood platform — provision, backup, restore, and monitor Azure SQL databases
---

You are helping the user manage hosted databases on the Wildwood platform. Wildwood provides managed Azure SQL databases as part of the Professional tier and above.

## Prerequisites

- MCP connection must be active (run `/wildwood-setup` if not)
- Company must have the `DB_HOSTING` feature enabled (Professional tier or higher)

## Available Commands

### List Databases
Show all hosted databases for the company:
```
database_hosting_list
```

### Get Database Details
Get details of a specific database:
```
database_hosting_get(databaseId: "...")
```

### Provision a New Database
Create a new hosted Azure SQL database:
```
database_hosting_create(
  name: "My App Database",
  slug: "my-app-db",
  appId: "...",
  description: "Primary database for my application",
  databaseType: "SqlServer",     // SqlServer (default) or PostgreSql (future)
  hostingTier: "Basic",          // Basic, Standard, or Elastic
  confirm: true
)
```

**Tier options:**
| Tier | DTU | Max Size | Best For |
|------|-----|----------|----------|
| Basic | 5 DTU | 2 GB | Dev/test, low-traffic apps |
| Standard | 10 DTU | 250 GB | Production workloads |
| Elastic | Pool | Pool | Multiple databases sharing resources |

### Get Connection String
Retrieve the decrypted connection string (audit-logged):
```
database_hosting_get_connection(databaseId: "...")
```

### Suspend / Resume
Pause a database to save costs, or bring it back online:
```
database_hosting_suspend(databaseId: "...", confirm: true)
database_hosting_resume(databaseId: "...", confirm: true)
```

### Create Backup
Create a manual backup of a database:
```
database_hosting_backup_create(databaseId: "...", confirm: true)
```

### List Backups
View all backups for a database:
```
database_hosting_backup_list(databaseId: "...")
```

### Restore from Backup
Restore a database from a previous backup (overwrites current data):
```
database_hosting_backup_restore(
  databaseId: "...",
  backupId: "...",
  confirm: true
)
```

### View Statistics
Get storage usage, DTU allocation, and connection stats:
```
database_hosting_stats(databaseId: "...")
```

### Update Settings
Change database name, description, or backup settings:
```
database_hosting_update(
  databaseId: "...",
  name: "Updated Name",
  backupEnabled: true,
  confirm: true
)
```

### Delete Database
Permanently delete a database and its Azure resources:
```
database_hosting_delete(databaseId: "...", confirm: true)
```

## Workflow: Set Up a New Database

1. **Check feature availability**: Ensure the company's tier includes `DB_HOSTING`
2. **List existing databases**: `database_hosting_list` to see current usage
3. **Create database**: `database_hosting_create(...)` with desired settings
4. **Wait for provisioning**: Status will change from `Provisioning` to `Active`
5. **Get connection string**: `database_hosting_get_connection(...)` once active
6. **Configure your app**: Use the connection string in your application's configuration

## Troubleshooting

- **"Feature not enabled"**: Upgrade to Professional tier or higher in WildwoodAdmin
- **"Limit exceeded"**: Company has reached its DB_HOSTED_COUNT limit. Upgrade tier or purchase the "Extra Hosted DBs" add-on
- **Database stuck in "Provisioning"**: The background service retries automatically (max 3 attempts). Check status with `database_hosting_get`
- **Database in "Failed" state**: An admin can retry provisioning from WildwoodAdmin > Hosting > Databases

## Admin Operations

Platform admins can access additional operations via WildwoodAdmin:
- View all databases across all companies
- Force-delete databases that failed provisioning
- Retry failed provisions
- View cross-tenant summary statistics
