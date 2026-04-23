#!/bin/sh
set -e

# Match container user UID/GID to host for volume permissions
PUID=${USER_UID:-1000}
PGID=${USER_GID:-1000}

changed=0

if [ "$(id -u node)" -ne "$PUID" ]; then
    echo "Updating node UID to $PUID"
    usermod -o -u "$PUID" node
    changed=1
fi

if [ "$(id -g node)" -ne "$PGID" ]; then
    echo "Updating node GID to $PGID"
    groupmod -o -g "$PGID" node
    usermod -g "$PGID" node
    changed=1
fi

# Always ensure /paperclip and /workspace are owned by node
chown -R node:node /paperclip
chown -R node:node /workspace

# Inject GLM API key into Claude Code settings for Z.AI (GLM Coding Plan)
if [ -n "$GLM_API_KEY" ] && [ -d "/root/.claude" ]; then
    echo "Configuring Claude Code for Z.AI (GLM Coding Plan)..."
    mkdir -p /root/.claude
    cat > /root/.claude/settings.json << EOF
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "$GLM_API_KEY",
    "ANTHROPIC_BASE_URL": "${GLM_ANTHROPIC_URL:-https://api.z.ai/api/anthropic}",
    "API_TIMEOUT_MS": "3000000"
  }
}
EOF
    chmod 600 /root/.claude/settings.json
fi

exec gosu node "$@"