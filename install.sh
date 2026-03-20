#!/usr/bin/env bash
set -euo pipefail

# WildwoodComponents.Claude installer
# Usage: curl -fsSL https://raw.githubusercontent.com/WildwoodWorks/WildwoodComponents.Claude/master/install.sh | bash
#   or:  ./install.sh              (from cloned repo)
#   or:  ./install.sh /path/to/project

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Determine project directory
PROJECT_DIR="${1:-.}"
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

# Determine plugin source - either local clone or temp download
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/CLAUDE.md" && -d "$SCRIPT_DIR/skills" ]]; then
    PLUGIN_DIR="$SCRIPT_DIR"
    CLEANUP=""
else
    # Running via curl pipe - clone to temp dir
    PLUGIN_DIR="$(mktemp -d)"
    CLEANUP="$PLUGIN_DIR"
    echo -e "${CYAN}Downloading WildwoodComponents.Claude...${NC}"
    git clone --depth 1 --quiet https://github.com/WildwoodWorks/WildwoodComponents.Claude.git "$PLUGIN_DIR"
fi

echo -e "${CYAN}Installing Wildwood plugin into: ${PROJECT_DIR}${NC}"
echo ""

# 1. Copy skills to .claude/commands/
echo -e "${GREEN}[1/3]${NC} Installing skills..."
mkdir -p "$PROJECT_DIR/.claude/commands"

# Remove old individual skill files from previous versions
for old_skill in wildwood-setup wildwood-integrate wildwood-deploy-app wildwood-hosting wildwood-database-hosting wildwood-status wildwood-platform; do
    if [[ -f "$PROJECT_DIR/.claude/commands/${old_skill}.md" ]]; then
        rm "$PROJECT_DIR/.claude/commands/${old_skill}.md"
        echo "  - removed old /${old_skill} (consolidated into /wildwood)"
    fi
done

for skill_dir in "$PLUGIN_DIR/skills"/*/; do
    skill_name="$(basename "$skill_dir")"
    cp "$skill_dir/SKILL.md" "$PROJECT_DIR/.claude/commands/${skill_name}.md"
    echo "  + /${skill_name}"
done

# 2. Configure MCP server (global ~/.mcp.json so Claude Code always has it)
echo -e "${GREEN}[2/3]${NC} Configuring MCP server..."

add_wildwood_mcp() {
    local target="$1"
    local label="$2"
    if [[ -f "$target" ]]; then
        if grep -q '"wildwood"' "$target" 2>/dev/null; then
            echo "  ~ $label already has wildwood server, skipping"
        else
            if command -v jq &>/dev/null; then
                jq '.mcpServers.wildwood = {"type": "http", "url": "https://api.wildwoodworks.io/mcp"}' "$target" > "${target}.tmp"
                mv "${target}.tmp" "$target"
                echo "  + merged wildwood server into $label"
            elif command -v node &>/dev/null; then
                node -e "
                    const fs = require('fs');
                    const cfg = JSON.parse(fs.readFileSync('$target', 'utf8'));
                    cfg.mcpServers = cfg.mcpServers || {};
                    cfg.mcpServers.wildwood = {type: 'http', url: 'https://api.wildwoodworks.io/mcp'};
                    fs.writeFileSync('$target', JSON.stringify(cfg, null, 2) + '\n');
                "
                echo "  + merged wildwood server into $label"
            else
                echo -e "  ${YELLOW}! Could not merge $label (install jq or node). Add manually:${NC}"
                echo '    "wildwood": { "type": "http", "url": "https://api.wildwoodworks.io/mcp" }'
            fi
        fi
    else
        cp "$PLUGIN_DIR/.mcp.json" "$target"
        echo "  + created $label with wildwood server"
    fi
}

# Global config (Claude Code reads this on startup)
add_wildwood_mcp "$HOME/.mcp.json" "~/.mcp.json"

# Project-level config (so the project is self-contained)
if [[ "$PROJECT_DIR" != "$HOME" ]]; then
    add_wildwood_mcp "$PROJECT_DIR/.mcp.json" "project .mcp.json"
fi

# 3. Install CLAUDE.md context
echo -e "${GREEN}[3/3]${NC} Installing platform context..."
CLAUDE_FILE="$PROJECT_DIR/.claude/CLAUDE.md"
mkdir -p "$PROJECT_DIR/.claude"
if [[ -f "$CLAUDE_FILE" ]]; then
    if grep -q "WildwoodComponents.Claude" "$CLAUDE_FILE" 2>/dev/null; then
        echo "  ~ Wildwood context already present, skipping"
    else
        echo "" >> "$CLAUDE_FILE"
        cat "$PLUGIN_DIR/CLAUDE.md" >> "$CLAUDE_FILE"
        echo "  + appended Wildwood context to existing .claude/CLAUDE.md"
    fi
else
    cp "$PLUGIN_DIR/CLAUDE.md" "$CLAUDE_FILE"
    echo "  + created .claude/CLAUDE.md"
fi

# Cleanup temp dir if we downloaded
if [[ -n "${CLEANUP:-}" ]]; then
    rm -rf "$CLEANUP"
fi

echo ""
echo -e "${GREEN}Done!${NC} Wildwood plugin installed successfully."
echo ""
echo -e "Next steps:"
echo -e "  1. ${CYAN}Restart Claude Code${NC} (or start it in your project directory)"
echo -e "     It will connect to the MCP server and open a browser for login."
echo -e "  2. Run ${CYAN}/wildwood${NC} to get started"
echo ""
