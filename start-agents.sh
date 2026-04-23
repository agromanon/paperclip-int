#!/bin/bash
# =============================================================================
# Start agents with token plan configuration
# =============================================================================

set -e

echo "============================================"
echo "  Paperclip Multi-Agent Startup"
echo "============================================"

# Source environment variables if .env file exists
if [ -f /workspace/.env ]; then
    echo "Loading environment from /workspace/.env"
    set -a
    source /workspace/.env
    set +a
fi

# Ensure workspace directory exists
mkdir -p /workspace

echo ""
echo "Starting agents with token plan configuration:"
echo "  - Claude/OpenClaw: MiniMax (${MINIMAX_ANTHROPIC_URL:-https://api.minimax.io/anthropic})"
echo "  - Claude (Z.AI): GLM Coding Plan (${GLM_ANTHROPIC_URL:-https://api.z.ai/api/anthropic})"
echo ""

# Function to start an agent in background
start_agent() {
    local name=$1
    local cmd=$2
    echo "Starting $name..."
    $cmd &
    sleep 1
}

# Start Claude Code (MiniMax Token Plan)
start_agent "Claude Agent (MiniMax)" "claude-code start --workspace /workspace --non-interactive"

# Start OpenClaw (MiniMax Token Plan)
start_agent "OpenClaw Agent" "openclaw agent start --workspace /workspace"

echo ""
echo "All agents started. Use 'docker logs' to view agent output."
echo "Agent processes:"
pgrep -a -f "claude-code|openclaw" || echo "  (no agents running yet)"

# Keep container running
echo ""
echo "Keeping container alive..."
tail -f /dev/null