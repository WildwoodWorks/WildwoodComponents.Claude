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

# 2. Configure MCP server
echo -e "${GREEN}[2/3]${NC} Configuring MCP server..."
MCP_FILE="$PROJECT_DIR/.mcp.json"
if [[ -f "$MCP_FILE" ]]; then
    # Merge - add wildwood server if not already present
    if grep -q '"wildwood"' "$MCP_FILE" 2>/dev/null; then
        echo "  ~ wildwood MCP server already configured, skipping"
    else
        # Use node/python if available, otherwise simple jq
        if command -v jq &>/dev/null; then
            jq '.mcpServers.wildwood = {"type": "http", "url": "https://api.wildwoodworks.io/mcp"}' "$MCP_FILE" > "${MCP_FILE}.tmp"
            mv "${MCP_FILE}.tmp" "$MCP_FILE"
            echo "  + merged wildwood server into existing .mcp.json"
        elif command -v node &>/dev/null; then
            node -e "
                const fs = require('fs');
                const cfg = JSON.parse(fs.readFileSync('$MCP_FILE', 'utf8'));
                cfg.mcpServers = cfg.mcpServers || {};
                cfg.mcpServers.wildwood = {type: 'http', url: 'https://api.wildwoodworks.io/mcp'};
                fs.writeFileSync('$MCP_FILE', JSON.stringify(cfg, null, 2) + '\n');
            "
            echo "  + merged wildwood server into existing .mcp.json"
        else
            echo -e "  ${YELLOW}! Could not merge .mcp.json (install jq or node). Add manually:${NC}"
            echo '    "wildwood": { "type": "http", "url": "https://api.wildwoodworks.io/mcp" }'
        fi
    fi
else
    cp "$PLUGIN_DIR/.mcp.json" "$MCP_FILE"
    echo "  + created .mcp.json with wildwood server"
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
echo -e "  1. Start Claude Code in your project directory"
echo -e "  2. Run ${CYAN}/wildwood setup${NC} to create your account"
echo -e "  3. Run ${CYAN}/wildwood integrate${NC} to add components to your project"
echo ""
echo -e "The MCP server will prompt for OAuth login on first use."
