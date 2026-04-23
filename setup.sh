#!/bin/bash
# ============================================================
# Paperclip Multi-Agent Setup Script
# Run this ONCE to configure all agents, then use runtime compose
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Paperclip Multi-Agent Setup Wizard${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Check if docker is available
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed or not running${NC}"
    exit 1
fi

# Create logs directory
mkdir -p ./logs

# Function to create volumes
create_volumes() {
    echo -e "${YELLOW}Creating Docker volumes...${NC}"
    docker volume create paperclip-config 2>/dev/null || true
    docker volume create agent-configs 2>/dev/null || true
    echo -e "${GREEN}Volumes created successfully${NC}"
}

# Function to run setup for a service
run_setup() {
    local SERVICE_NAME=$1
    local DISPLAY_NAME=$2

    echo ""
    echo -e "${YELLOW}============================================${NC}"
    echo -e "${YELLOW}  Setting up ${DISPLAY_NAME}${NC}"
    echo -e "${YELLOW}============================================${NC}"
    echo -e "${YELLOW}This is interactive - follow the prompts${NC}"
    echo ""

    echo -e "${GREEN}Starting ${DISPLAY_NAME} setup container...${NC}"
    echo -e "${YELLOW}Press Ctrl+C to skip this step if already configured${NC}"
    echo ""

    # Run the setup container interactively
    if docker compose -f docker-compose.setup.yml run --rm ${SERVICE_NAME}; then
        echo -e "${GREEN}✓ ${DISPLAY_NAME} setup completed${NC}"
    else
        echo -e "${YELLOW}⚠ ${DISPLAY_NAME} setup skipped or failed${NC}"
    fi

    # Give user a moment before next setup
    sleep 2
}

# Parse arguments
SKIP_PAPERCLIP=false
SKIP_CLAUDE=false
SKIP_HERMES=false
SKIP_OPENCLAW=false
SKIP_ALL=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-paperclip) SKIP_PAPERCLIP=true; shift ;;
        --skip-claude) SKIP_CLAUDE=true; shift ;;
        --skip-hermes) SKIP_HERMES=true; shift ;;
        --skip-openclaw) SKIP_OPENCLAW=true; shift ;;
        --skip-all)
            SKIP_PAPERCLIP=true
            SKIP_CLAUDE=true
            SKIP_HERMES=true
            SKIP_OPENCLAW=true
            shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# Create volumes
create_volumes

echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Setup Options Selected:${NC}"
echo -e "${BLUE}============================================${NC}"
[[ "$SKIP_PAPERCLIP" == "true" ]] && echo -e "  ${GREEN}✓${NC} Skip Paperclip" || echo -e "  ${YELLOW}○${NC} Paperclip"
[[ "$SKIP_CLAUDE" == "true" ]] && echo -e "  ${GREEN}✓${NC} Skip Claude" || echo -e "  ${YELLOW}○${NC} Claude"
[[ "$SKIP_HERMES" == "true" ]] && echo -e "  ${GREEN}✓${NC} Skip Hermes" || echo -e "  ${YELLOW}○${NC} Hermes"
[[ "$SKIP_OPENCLAW" == "true" ]] && echo -e "  ${GREEN}✓${NC} Skip OpenClaw" || echo -e "  ${YELLOW}○${NC} OpenClaw"
echo ""

if [[ "$SKIP_ALL" == "false" ]]; then
    echo -e "${YELLOW}Starting setup wizards...${NC}"
    echo -e "${YELLOW}Press Ctrl+C to skip any step${NC}"
    sleep 3
fi

# Run each setup (can be skipped with Ctrl+C)
if [[ "$SKIP_PAPERCLIP" == "false" && "$SKIP_ALL" == "false" ]]; then
    run_setup "setup-paperclip" "Paperclip (Hub/Orchestrator)"
fi

if [[ "$SKIP_CLAUDE" == "false" && "$SKIP_ALL" == "false" ]]; then
    run_setup "setup-claude" "Claude Agent"
fi

if [[ "$SKIP_HERMES" == "false" && "$SKIP_ALL" == "false" ]]; then
    run_setup "setup-hermes" "Hermes Agent"
fi

if [[ "$SKIP_OPENCLAW" == "false" && "$SKIP_ALL" == "false" ]]; then
    run_setup "setup-openclaw" "OpenClaw Agent"
fi

# Verify configurations were saved
echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Verifying Configurations${NC}"
echo -e "${BLUE}============================================${NC}"

echo -e "${YELLOW}Checking agent-configs volume...${NC}"
docker run --rm -v agent-configs:/data alpine ls -la /data/ 2>/dev/null || echo -e "${RED}No configs found in agent-configs${NC}"

echo ""
echo -e "${YELLOW}Checking paperclip-config volume...${NC}"
docker run --rm -v paperclip-config:/data alpine ls -la /data/ 2>/dev/null || echo -e "${RED}No configs found in paperclip-config${NC}"

echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Setup Complete!${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo -e "${GREEN}Next steps:${NC}"
echo "  1. Review the docker-compose.runtime.yml for your configuration"
echo "  2. Start the runtime with: ${YELLOW}docker-compose -f docker-compose.runtime.yml up -d${NC}"
echo "  3. Access Paperclip at: http://localhost:3100"
echo "  4. Monitor logs: docker logs -f paperclip-hub"
echo ""
echo -e "${YELLOW}IMPORTANT: Backup your agent-configs volume!${NC}"
echo -e "  docker run --rm -v agent-configs:/data -v \$(pwd):/backup alpine tar czf /backup/agent-configs-backup.tar.gz /data"
echo ""