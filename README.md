# Paperclip Multi-Agent Setup on Coolify

A secure, containerized multi-agent AI setup running Paperclip with Claude, Hermes, and OpenClaw agents.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      COOLIFY SERVER                        │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              agent-net (Docker network)             │    │
│  │                                                      │    │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐         │    │
│  │  │Paperclip │  │  Claude  │  │  Hermes  │         │    │
│  │  │   Hub    │◄─┤  Agent   │◄─┤  Agent   │         │    │
│  │  │  :3100   │  │MiniMax   │  │   GLM    │         │    │
│  │  └────┬─────┘  └────┬─────┘  └────┬─────┘         │    │
│  │       │             │             │                 │    │
│  │       └─────────────┴─────────────┘                 │    │
│  │                      │                              │    │
│  │              ┌───────┴───────┐                      │    │
│  │              │   workspace   │                      │    │
│  │              │ /shared/projects│                    │    │
│  │              └───────────────┘                      │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                             │
│  Volumes: agent-configs (readonly), workspace (rw)           │
└─────────────────────────────────────────────────────────────┘
```

## Token Plan Configuration

This setup uses **budget-friendly token plans** instead of Anthropic subscriptions:

| Agent | Provider | Token Plan | Endpoint |
|-------|----------|------------|----------|
| Claude | MiniMax | [MiniMax Token Plan](https://platform.minimax.io/user-center/payment/token-plan) | `api.minimax.io/anthropic` |
| Hermes | Z.AI / GLM | [GLM Coding Plan](https://z.ai/model-api) | `api.z.ai/api/anthropic` |
| OpenClaw | MiniMax | [MiniMax Token Plan](https://platform.minimax.io/user-center/payment/token-plan) | `api.minimax.io/anthropic` |

### MiniMax Configuration (Claude + OpenClaw)

```bash
ANTHROPIC_BASE_URL=https://api.minimax.io/anthropic
ANTHROPIC_AUTH_TOKEN=<MINIMAX_API_KEY>
ANTHROPIC_MODEL=MiniMax-M2.7
```

### GLM Coding Plan Configuration (Hermes)

```bash
ANTHROPIC_BASE_URL=https://api.z.ai/api/anthropic
ANTHROPIC_AUTH_TOKEN=<GLM_API_KEY>
ANTHROPIC_MODEL=GLM-4.7
```

**Get GLM API Key:** https://z.ai/manage-apikey/apikey-list

## Security Features

- **Read-only configs**: Agent configurations mounted as read-only
- **No external network**: Agents can only communicate with Paperclip hub
- **Resource limits**: CPU/memory constraints per agent
- **No package installation**: Read-only filesystem prevents agent tampering
- **Audit logs**: All agent activity logged
- **Non-root users**: Each agent runs as own UID

## Files Overview

| File | Purpose |
|------|---------|
| `docker-compose.setup.yml` | One-time setup containers for each agent |
| `docker-compose.runtime.yml` | Locked-down production environment |
| `.env.example` | Environment variable template |
| `setup.sh` | Interactive setup wizard script |
| `start.sh` | Start runtime environment |
| `backup.sh` | Backup agent configurations |
| `update.sh` | Update images while preserving data |
| `restore.sh` | Restore from backup |

## Quick Start

### 1. Setup Environment

```bash
# Copy and edit environment variables
cp .env.example .env
nano .env  # Add your API keys
```

### 2. Configure API Keys in `.env`

```bash
# MiniMax Token Plan (Claude + OpenClaw)
MINIMAX_API_KEY=your_key_here
MINIMAX_ANTHROPIC_URL=https://api.minimax.io/anthropic

# GLM Coding Plan (Hermes)
GLM_API_KEY=your_key_here
GLM_ANTHROPIC_URL=https://api.z.ai/api/anthropic
```

### 3. Run Setup

```bash
chmod +x setup.sh start.sh backup.sh update.sh restore.sh
./setup.sh
```

This runs interactive wizards for:
- Paperclip → sets up company mission/goals
- Claude → configures MiniMax token plan
- Hermes → configures GLM coding plan (Z.AI)
- OpenClaw → daemon setup with MiniMax

### 4. Start Runtime

```bash
./start.sh
```

### 5. Access Paperclip

Open http://YOUR_SERVER:3100

## Coolify Deployment Steps

1. **Push files to GitHub** repo
2. **Connect repo** in Coolify
3. **Deploy** `docker-compose.runtime.yml` via Coolify UI
4. **Configure** environment variables in Coolify UI (from `.env`)
5. **Run setup** via Coolify Terminal: `./setup.sh`
6. **Manage** via Coolify dashboard

## Environment Variables

| Variable | Description | Agent |
|----------|-------------|-------|
| `MINIMAX_API_KEY` | MiniMax API key | Claude, OpenClaw |
| `MINIMAX_ANTHROPIC_URL` | MiniMax endpoint | Claude, OpenClaw |
| `MINIMAX_MODEL` | Model for MiniMax | Claude, OpenClaw |
| `GLM_API_KEY` | Z.AI API key for GLM | Hermes |
| `GLM_ANTHROPIC_URL` | Z.AI endpoint | Hermes |
| `GLM_MODEL` | Model for GLM (default: GLM-4.7) | Hermes |

## Volume Persistence

Configs persist across restarts and updates:

```yaml
volumes:
  agent-configs:     # Holds all agent auth/API keys
  paperclip-config:  # Paperclip DB + company data
  workspace:         # Shared code/projects (writable)
```

## Backup (Critical!)

```bash
./backup.sh
```

Or use Coolify's built-in S3 backup:
```
Application → Storage → Configure Backup → S3
```

## Update Process

**Paperclip/Hermes/OpenClaw update:**
```bash
./update.sh
```

**Manual update via Coolify:**
1. Pull new image
2. Redeploy (volumes auto-attached)

## Troubleshooting

### Agent can't connect to Paperclip
```bash
curl http://localhost:3100/health
docker compose -f docker-compose.runtime.yml logs
```

### GLM auth failing
```bash
# Verify API key works
curl -H "Authorization: Bearer $GLM_API_KEY" \
  https://api.z.ai/api/anthropic/v1/models
```

### MiniMax auth failing
```bash
curl -H "Authorization: Bearer $MINIMAX_API_KEY" \
  https://api.minimax.io/anthropic/v1/models
```

## Production Checklist

- [ ] Configure `.env` with real API keys
- [ ] Run setup.sh for all agents
- [ ] Verify backup.sh works
- [ ] Test agent communication
- [ ] Configure reverse proxy for HTTPS
- [ ] Set up monitoring
- [ ] Schedule regular backups
- [ ] Review security settings