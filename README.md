# n8n Docker Setup

n8n is a workflow automation tool that allows you to connect different services and automate tasks.

## Prerequisites

- Docker
- Docker Compose

## Quick Start

1. Copy the example environment file and configure it:
   ```bash
   cp .env.example .env
   ```

2. Generate an encryption key:
   ```bash
   openssl rand -base64 32
   ```
   Update `N8N_ENCRYPTION_KEY` in the `.env` file with this key.

3. Start n8n:
   ```bash
   docker-compose up -d
   ```

4. Access n8n at `http://localhost:5678`

## Configuration

Edit the `.env` file to customize:

- `N8N_HOST`: The hostname for n8n (default: localhost)
- `N8N_PROTOCOL`: http or https
- `WEBHOOK_URL`: The webhook URL for n8n
- `TIMEZONE`: Your timezone (e.g., America/New_York)
- `N8N_ENCRYPTION_KEY`: **Required** - Encryption key for credentials

## Data Persistence

- Workflow and credential data is stored in Docker volumes
- Additional folders for workflows and credentials are mounted for easy backup

## Management Commands

Start n8n:
```bash
docker-compose up -d
```

Stop n8n:
```bash
docker-compose down
```

View logs:
```bash
docker-compose logs -f n8n
```

Restart n8n:
```bash
docker-compose restart
```

## Backup

To backup your workflows and credentials:
```bash
docker-compose exec n8n n8n export:workflow --backup --output=/home/node/.n8n/workflows/
docker-compose exec n8n n8n export:credentials --backup --output=/home/node/.n8n/credentials/
```

## Additional Resources

- [n8n Documentation](https://docs.n8n.io/)
- [n8n Community](https://community.n8n.io/)


# Makefile Command
## Main Commands
make help - Display all available commands
make setup - Initial setup (creates .env and generates encryption key)
make install - Full installation (setup + build + start)

## Docker Operations
make build - Build the Docker image
make up - Start n8n in detached mode
make down - Stop and remove containers
make start/stop/restart - Container lifecycle management
make logs - View logs (follow mode)
make ps/status - Check container status

## Development
make shell - Open shell in n8n container
make rebuild - Rebuild and restart
make update - Pull latest n8n image and update
make dev - Start with visible logs

## Backup & Restore
make backup - Create timestamped backup of workflows/credentials
make restore BACKUP=file - Restore from backup file

## Cleanup
make clean - Remove stopped containers and volumes
make clean-all - Remove everything including images and backups