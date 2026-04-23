#!/bin/bash
# ============================================================
# Paperclip Multi-Agent Runtime Startup
# Run this to start all agents in locked down mode
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Paperclip Multi-Agent Runtime${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Check if volumes exist (setup has been run)
if ! docker volume inspect agent-configs &>/dev/null; then
    echo -e "${RED}Error: agent-configs volume not found${NC}"
    echo -e "${YELLOW}Please run setup.sh first to configure agents${NC}"
    exit 1
fi

# Verify configs exist
CONFIG_CHECK=$(docker run --rm -v agent-configs:/data alpine ls -la /data/ 2>/dev/null || echo "")
if [[ -z "$CONFIG_CHECK" ]]; then
    echo -e "${RED}Error: No agent configurations found${NC}"
    echo -e "${YELLOW}Please run setup.sh first${NC}"
    exit 1
fi

echo -e "${GREEN}Configurations found. Starting runtime...${NC}"
echo ""

# Create logs directory
mkdir -p ./logs

# Start the runtime stack
echo -e "${YELLOW}Starting Paperclip Hub and all agents...${NC}"
docker compose -f docker-compose.runtime.yml up -d

# Wait for Paperclip to be healthy
echo -e "${YELLOW}Waiting for Paperclip to be ready...${NC}"
sleep 5

# Check health
if docker compose -f docker-compose.runtime.yml ps | grep -q "healthy"; then
    echo -e "${GREEN}✓ Paperclip Hub is healthy${NC}"
else
    echo -e "${YELLOW}⚠ Paperclip may still be starting${NC}"
fi

echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  All Services Started${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo -e "${GREEN}Services running:${NC}"
docker compose -f docker-compose.runtime.yml ps
echo ""
echo -e "${GREEN}Access Points:${NC}"
echo "  Paperclip Hub: http://localhost:3100"
echo "  (Other agent ports depend on their configs)"
echo ""
echo -e "${YELLOW}View logs:${NC}"
echo "  docker logs -f paperclip-hub    (Paperclip)"
echo "  docker logs -f claude-agent     (Claude)"
echo "  docker logs -f hermes-agent     (Hermes)"
echo "  docker logs -f openclaw-agent   (OpenClaw)"
echo ""
echo -e "${YELLOW}Stop all:${NC} docker compose -f docker-compose.runtime.yml down"
echo ""