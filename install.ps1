# WildwoodComponents.Claude installer for Windows
# Usage: irm https://raw.githubusercontent.com/WildwoodWorks/WildwoodComponents.Claude/main/install.ps1 | iex
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

Get-ChildItem (Join-Path $PluginDir "skills") -Directory | ForEach-Object {
    $SkillName = $_.Name
    Copy-Item (Join-Path $_.FullName "SKILL.md") (Join-Path $CommandsDir "$SkillName.md") -Force
    Write-Host "  + /$SkillName"
}

# 2. Configure MCP server
Write-Host "[2/3] Configuring MCP server..." -ForegroundColor Green
$McpFile = Join-Path $ProjectDir ".mcp.json"

if (Test-Path $McpFile) {
    $McpContent = Get-Content $McpFile -Raw
    if ($McpContent -match '"wildwood"') {
        Write-Host "  ~ wildwood MCP server already configured, skipping"
    } else {
        try {
            $McpJson = $McpContent | ConvertFrom-Json
            if (-not $McpJson.mcpServers) {
                $McpJson | Add-Member -NotePropertyName "mcpServers" -NotePropertyValue ([PSCustomObject]@{})
            }
            $WildwoodServer = [PSCustomObject]@{ type = "http"; url = "https://api.wildwoodworks.io/mcp" }
            $McpJson.mcpServers | Add-Member -NotePropertyName "wildwood" -NotePropertyValue $WildwoodServer
            $McpJson | ConvertTo-Json -Depth 10 | Set-Content $McpFile -Encoding UTF8
            Write-Host "  + merged wildwood server into existing .mcp.json"
        } catch {
            Write-Host "  ! Could not merge .mcp.json. Add manually:" -ForegroundColor Yellow
            Write-Host '    "wildwood": { "type": "http", "url": "https://api.wildwoodworks.io/mcp" }'
        }
    }
} else {
    Copy-Item (Join-Path $PluginDir ".mcp.json") $McpFile
    Write-Host "  + created .mcp.json with wildwood server"
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
Write-Host "  1. Start Claude Code in your project directory"
Write-Host "  2. Run /wildwood-setup to create your account" -ForegroundColor Cyan
Write-Host "  3. Run /wildwood-integrate to add components to your project" -ForegroundColor Cyan
Write-Host ""
Write-Host "The MCP server will prompt for OAuth login on first use."
