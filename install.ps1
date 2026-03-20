# WildwoodComponents.Claude installer for Windows
# Usage: irm https://raw.githubusercontent.com/WildwoodWorks/WildwoodComponents.Claude/master/install.ps1 | iex
#   or:  .\install.ps1              (from cloned repo)
#   or:  .\install.ps1 -ProjectDir C:\path\to\project

param(
    [string]$ProjectDir = "."
)

$ErrorActionPreference = "Stop"
$ProjectDir = (Resolve-Path $ProjectDir).Path

# Determine plugin source
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
$Cleanup = $null

if (Test-Path (Join-Path $ScriptDir "CLAUDE.md")) {
    $PluginDir = $ScriptDir
} else {
    # Running via web download - clone to temp dir
    $PluginDir = Join-Path $env:TEMP "WildwoodComponents.Claude-$(Get-Random)"
    $Cleanup = $PluginDir
    Write-Host "Downloading WildwoodComponents.Claude..." -ForegroundColor Cyan
    git clone --depth 1 --quiet https://github.com/WildwoodWorks/WildwoodComponents.Claude.git $PluginDir
}

Write-Host "Installing Wildwood plugin into: $ProjectDir" -ForegroundColor Cyan
Write-Host ""

# 1. Copy skills
Write-Host "[1/3] Installing skills..." -ForegroundColor Green
$CommandsDir = Join-Path $ProjectDir ".claude\commands"
New-Item -ItemType Directory -Path $CommandsDir -Force | Out-Null

# Remove old individual skill files from previous versions
$OldSkills = @("wildwood-setup", "wildwood-integrate", "wildwood-deploy-app", "wildwood-hosting", "wildwood-database-hosting", "wildwood-status", "wildwood-platform")
foreach ($OldSkill in $OldSkills) {
    $OldFile = Join-Path $CommandsDir "$OldSkill.md"
    if (Test-Path $OldFile) {
        Remove-Item $OldFile
        Write-Host "  - removed old /$OldSkill (consolidated into /wildwood)"
    }
}

Get-ChildItem (Join-Path $PluginDir "skills") -Directory | ForEach-Object {
    $SkillName = $_.Name
    Copy-Item (Join-Path $_.FullName "SKILL.md") (Join-Path $CommandsDir "$SkillName.md") -Force
    Write-Host "  + /$SkillName"
}

# 2. Configure MCP server (global + project)
Write-Host "[2/3] Configuring MCP server..." -ForegroundColor Green

function Add-WildwoodMcp {
    param([string]$Target, [string]$Label)
    if (Test-Path $Target) {
        $Content = Get-Content $Target -Raw
        if ($Content -match '"wildwood"') {
            Write-Host "  ~ $Label already has wildwood server, skipping"
        } else {
            try {
                $Json = $Content | ConvertFrom-Json
                if (-not $Json.mcpServers) {
                    $Json | Add-Member -NotePropertyName "mcpServers" -NotePropertyValue ([PSCustomObject]@{})
                }
                $Server = [PSCustomObject]@{ type = "http"; url = "https://api.wildwoodworks.io/mcp" }
                $Json.mcpServers | Add-Member -NotePropertyName "wildwood" -NotePropertyValue $Server
                $Json | ConvertTo-Json -Depth 10 | Set-Content $Target -Encoding UTF8
                Write-Host "  + merged wildwood server into $Label"
            } catch {
                Write-Host "  ! Could not merge $Label. Add manually:" -ForegroundColor Yellow
                Write-Host '    "wildwood": { "type": "http", "url": "https://api.wildwoodworks.io/mcp" }'
            }
        }
    } else {
        Copy-Item (Join-Path $PluginDir ".mcp.json") $Target
        Write-Host "  + created $Label with wildwood server"
    }
}

# Global config (Claude Code reads this on startup)
$GlobalMcp = Join-Path $env:USERPROFILE ".mcp.json"
Add-WildwoodMcp -Target $GlobalMcp -Label "~/.mcp.json"

# Project-level config (so the project is self-contained)
$ProjectMcp = Join-Path $ProjectDir ".mcp.json"
if ($ProjectDir -ne $env:USERPROFILE) {
    Add-WildwoodMcp -Target $ProjectMcp -Label "project .mcp.json"
}

# 3. Install CLAUDE.md context
Write-Host "[3/3] Installing platform context..." -ForegroundColor Green
$ClaudeDir = Join-Path $ProjectDir ".claude"
$ClaudeFile = Join-Path $ClaudeDir "CLAUDE.md"
New-Item -ItemType Directory -Path $ClaudeDir -Force | Out-Null

if (Test-Path $ClaudeFile) {
    $Content = Get-Content $ClaudeFile -Raw
    if ($Content -match "WildwoodComponents\.Claude") {
        Write-Host "  ~ Wildwood context already present, skipping"
    } else {
        $PluginContent = Get-Content (Join-Path $PluginDir "CLAUDE.md") -Raw
        Add-Content $ClaudeFile "`n$PluginContent"
        Write-Host "  + appended Wildwood context to existing .claude/CLAUDE.md"
    }
} else {
    Copy-Item (Join-Path $PluginDir "CLAUDE.md") $ClaudeFile
    Write-Host "  + created .claude/CLAUDE.md"
}

# Cleanup
if ($Cleanup -and (Test-Path $Cleanup)) {
    Remove-Item $Cleanup -Recurse -Force
}

Write-Host ""
Write-Host "Done! Wildwood plugin installed successfully." -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Restart Claude Code (or start it in your project directory)" -ForegroundColor Cyan
Write-Host "     It will connect to the MCP server and open a browser for login."
Write-Host "  2. Run /wildwood to get started" -ForegroundColor Cyan
Write-Host ""
