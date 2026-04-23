#!/bin/bash
# ============================================================
# Paperclip Multi-Agent Update Script
# Preserves all data while updating images
# ============================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  Paperclip Multi-Agent Update${NC}"
echo -e "${BLUE}============================================${NC}"

# Check if volumes exist
if ! docker volume inspect agent-configs &>/dev/null; then
    echo -e "${RED}Error: agent-configs volume not found${NC}"
    echo -e "${YELLOW}Have you run setup.sh first?${NC}"
    exit 1
fi

echo -e "${YELLOW}IMPORTANT: Backing up before update...${NC}"
./backup.sh

echo ""
echo -e "${YELLOW}Current versions:${NC}"
grep "image:" docker-compose.runtime.yml | grep -v "^#"

echo ""
echo -e "${YELLOW}Enter new versions (leave blank to keep current):${NC}"
read -p "Paperclip version [latest]: " PAPERCLIP_VERSION
read -p "Agent base version [latest]: " AGENT_BASE_VERSION

PAPERCLIP_VERSION=${PAPERCLIP_VERSION:-latest}
AGENT_BASE_VERSION=${AGENT_BASE_VERSION:-latest}

# Update image versions in runtime compose
echo -e "${YELLOW}Updating docker-compose.runtime.yml...${NC}"

# Use sed to update image tags (if specific version provided)
if [[ "$PAPERCLIP_VERSION" != "latest" ]]; then
    sed -i "s|paperclipai/paperclip:latest|paperclipai/paperclip:${PAPERCLIP_VERSION}|g" docker-compose.runtime.yml
fi

# For agents - they use node:22-alpine base, agents are installed at runtime
# If you want to pin agent versions, you'd need a custom image
echo -e "${GREEN}Updated Paperclip to: ${PAPERCLIP_VERSION}${NC}"

echo ""
echo -e "${YELLOW}Stopping current runtime...${NC}"
docker compose -f docker-compose.runtime.yml down

echo -e "${YELLOW}Pulling new images...${NC}"
docker pull paperclipai/paperclip:${PAPERCLIP_VERSION}

echo -e "${YELLOW}Starting updated runtime...${NC}"
docker compose -f docker-compose.runtime.yml up -d

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}  Update Complete!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "${GREEN}✓ Data persisted in volumes${NC}"
echo -e "${GREEN}✓ Agents running with updated images${NC}"
echo ""
echo -e "${YELLOW}Check status:${NC}"
docker compose -f docker-compose.runtime.yml ps

echo ""
echo -e "${YELLOW}If issues, rollback with:${NC}"
echo -e "  docker compose -f docker-compose.runtime.yml down"
echo -e "  docker pull paperclipai/paperclip:<old-version>"
echo -e "  docker compose -f docker-compose.runtime.yml up -d"