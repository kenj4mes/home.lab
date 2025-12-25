# ==============================================================================
# 🏠 HomeLab Makefile - Cross-Platform Build & Management
# ==============================================================================
# Usage:
#   make start       - Start all services
#   make stop        - Stop all services
#   make status      - Show container status
#   make logs        - View logs (Ctrl+C to exit)
#   make update      - Pull latest images and restart
#   make base-start  - Start blockchain services
#   make models      - Download default Ollama models
#   make clean       - Remove stopped containers and dangling images
# ==============================================================================

.PHONY: start stop status logs restart update pull clean \
        base-start base-stop monitoring-start models help

# Default compose files
COMPOSE_FILE ?= docker/docker-compose.yml
COMPOSE_BASE ?= docker/docker-compose.base.yml
COMPOSE_MONITORING ?= docker/docker-compose.monitoring.yml

# Docker compose command
DC = docker compose -f $(COMPOSE_FILE)
DC_BASE = docker compose -f $(COMPOSE_BASE)
DC_MONITOR = docker compose -f $(COMPOSE_MONITORING)

# ==============================================================================
# CORE COMMANDS
# ==============================================================================

## Start all core services
start:
	@echo "🚀 Starting HomeLab services..."
	$(DC) up -d
	@echo "✅ Services started!"
	@echo ""
	@echo "Access your services:"
	@echo "  Jellyfin:    http://localhost:8096"
	@echo "  Open WebUI:  http://localhost:3000"
	@echo "  Portainer:   http://localhost:9000"
	@echo "  BookStack:   http://localhost:8082"

## Stop all services
stop:
	@echo "🛑 Stopping HomeLab services..."
	$(DC) down
	@echo "✅ Services stopped"

## Show container status
status:
	@echo "📊 HomeLab Status"
	@echo ""
	$(DC) ps

## View logs (follow mode)
logs:
	$(DC) logs -f --tail=100

## Restart all services
restart:
	@echo "🔄 Restarting HomeLab services..."
	$(DC) restart
	@echo "✅ Services restarted"

## Pull latest images
pull:
	@echo "📥 Pulling latest images..."
	$(DC) pull

## Update: pull and restart
update: pull
	@echo "🔄 Restarting with new images..."
	$(DC) up -d
	@echo "✅ Update complete!"

# ==============================================================================
# BLOCKCHAIN COMMANDS
# ==============================================================================

## Start Base blockchain services
base-start:
	@echo "🔗 Starting Base blockchain services..."
	$(DC_BASE) up -d
	@echo "✅ Blockchain services started!"
	@echo ""
	@echo "Access:"
	@echo "  Base RPC:     http://localhost:8545"
	@echo "  Explorer:     http://localhost:4000"
	@echo "  Wallet UI:    http://localhost:3001"
	@echo "  Wallet API:   http://localhost:5000"

## Stop blockchain services
base-stop:
	@echo "🛑 Stopping blockchain services..."
	$(DC_BASE) down

## Show blockchain status
base-status:
	$(DC_BASE) ps

## View blockchain logs
base-logs:
	$(DC_BASE) logs -f --tail=100

# ==============================================================================
# MODEL COMMANDS
# ==============================================================================

## Download default Ollama models (standard profile)
models:
	@echo "🤖 Downloading Ollama models..."
	./scripts/download-models.sh --profile standard

## Download minimal models only
models-minimal:
	./scripts/download-models.sh --profile minimal

## Download all models (large!)
models-full:
	./scripts/download-models.sh --profile full

## List available model groups
models-list:
	./scripts/download-models.sh --list-groups

# ==============================================================================
# MINIAPPS COMMANDS
# ==============================================================================

COMPOSE_MINIAPPS ?= miniapps/docker-compose.yml
DC_MINIAPPS = docker compose -f $(COMPOSE_MINIAPPS)

## Start all miniapps
miniapps-start:
	@echo "🚀 Starting miniapps..."
	$(DC_MINIAPPS) up -d
	@echo "✅ Miniapps started!"
	@echo ""
	@echo "Access your miniapps:"
	@echo "  Message Bus:      http://localhost:5100"
	@echo "  Event Store:      http://localhost:5101"
	@echo "  AI Orchestrator:  http://localhost:5200"
	@echo "  Dashboard:        http://localhost:5300"
	@echo "  Webhook Handler:  http://localhost:5400"
	@echo "  Log Aggregator:   http://localhost:5500"
	@echo "  Backup Manager:   http://localhost:5501"
	@echo "  Notification Hub: http://localhost:5502"

## Stop all miniapps
miniapps-stop:
	@echo "🛑 Stopping miniapps..."
	$(DC_MINIAPPS) down

## Show miniapps status
miniapps-status:
	$(DC_MINIAPPS) ps

## View miniapps logs
miniapps-logs:
	$(DC_MINIAPPS) logs -f --tail=100

## Build all miniapps
miniapps-build:
	@echo "🔨 Building miniapps..."
	$(DC_MINIAPPS) build

## Rebuild and restart miniapps
miniapps-rebuild:
	@echo "🔄 Rebuilding miniapps..."
	$(DC_MINIAPPS) up -d --build
	@echo "✅ Miniapps rebuilt and started!"

# ==============================================================================
# OPERATIONS COMMANDS
# ==============================================================================

## Run health check
health:
	@echo "🏥 Running health check..."
	./scripts/health-check.sh

## Run security audit
audit:
	@echo "🔒 Running security audit..."
	./scripts/security/audit.sh

## Run backup
backup:
	@echo "💾 Running backup..."
	./scripts/backup.sh

## Deploy to production
deploy:
	@echo "🚀 Deploying..."
	./scripts/deploy.sh production

## Deploy with rollback
rollback:
	@echo "⏪ Rolling back..."
	./scripts/deploy.sh production --rollback

# ==============================================================================
# SECURITY RESEARCH COMMANDS
# ==============================================================================

COMPOSE_SECURITY ?= docker/docker-compose.security-research.yml
DC_SECURITY = docker compose -f $(COMPOSE_SECURITY)

## Start all security research tools
security-start:
	@echo "🔬 Starting Security Research Stack..."
	$(DC_SECURITY) --profile ai-security --profile firmware-analysis up -d
	@echo "✅ Security research tools started!"
	@echo ""
	@echo "Access services:"
	@echo "  Dashboard:         http://localhost:5610"
	@echo "  Garak (LLM scan):  http://localhost:5600"
	@echo "  Firmware Analyzer: http://localhost:5602"

## Stop security research tools
security-stop:
	@echo "🛑 Stopping Security Research Stack..."
	$(DC_SECURITY) down
	@echo "✅ Security research tools stopped"

## Start AI security tools only
security-ai:
	@echo "🛡️ Starting AI Security Tools..."
	$(DC_SECURITY) --profile ai-security up -d
	@echo "✅ AI security tools started!"
	@echo "  Garak:      http://localhost:5600"
	@echo "  Counterfit: http://localhost:5601"

## Start firmware analysis
security-firmware:
	@echo "🔧 Starting Firmware Analysis..."
	$(DC_SECURITY) --profile firmware-analysis up -d
	@echo "✅ Firmware analyzer started!"
	@echo "  Firmware Analyzer: http://localhost:5602"

## Start RF analysis (requires GPU)
security-rf:
	@echo "📡 Starting RF Analysis (GPU required)..."
	$(DC_SECURITY) --profile rf-analysis up -d
	@echo "✅ RF analysis tools started!"
	@echo "  Signal Classifier: http://localhost:5604"

## Clone all security research repositories
security-clone:
	@echo "📥 Cloning security research repositories..."
	./scripts/clone-security-research.sh ./security-research
	@echo "✅ Repositories cloned to ./security-research"

## Security research status
security-status:
	@echo "📊 Security Research Status"
	$(DC_SECURITY) ps

## Security research logs
security-logs:
	$(DC_SECURITY) logs -f --tail=100

# ==============================================================================
# MAINTENANCE COMMANDS
# ==============================================================================

## Clean up Docker resources
clean:
	@echo "🧹 Cleaning up Docker resources..."
	docker container prune -f
	docker image prune -f
	docker volume prune -f
	@echo "✅ Cleanup complete"

## Full reset (WARNING: deletes all data!)
reset:
	@echo "⚠️  WARNING: This will delete ALL HomeLab data!"
	@read -p "Type 'YES' to confirm: " confirm && [ "$$confirm" = "YES" ] || exit 1
	$(DC) down -v
	$(DC) up -d
	@echo "✅ Reset complete"

## Generate .env with secure secrets
env:
	./scripts/env-generator.sh

## Validate compose files
validate:
	@echo "🔍 Validating Docker Compose files..."
	$(DC) config > /dev/null && echo "✅ docker-compose.yml: OK"
	$(DC_BASE) config > /dev/null && echo "✅ docker-compose.base.yml: OK"
	@echo ""
	@echo "All compose files are valid!"

# ==============================================================================
# HELP
# ==============================================================================

## Show this help
help:
	@echo ""
	@echo "╔══════════════════════════════════════════════════════════════╗"
	@echo "║                    🏠 HomeLab Makefile                       ║"
	@echo "╚══════════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "Core Commands:"
	@echo "  make start       Start all core services"
	@echo "  make stop        Stop all services"
	@echo "  make status      Show container status"
	@echo "  make logs        View logs (follow mode)"
	@echo "  make restart     Restart all services"
	@echo "  make update      Pull latest images and restart"
	@echo ""
	@echo "Miniapps Commands:"
	@echo "  make miniapps-start    Start all miniapps"
	@echo "  make miniapps-stop     Stop all miniapps"
	@echo "  make miniapps-status   Show miniapps status"
	@echo "  make miniapps-logs     View miniapps logs"
	@echo "  make miniapps-build    Build all miniapps"
	@echo "  make miniapps-rebuild  Rebuild and restart"
	@echo ""
	@echo "Blockchain Commands:"
	@echo "  make base-start  Start Base blockchain services"
	@echo "  make base-stop   Stop blockchain services"
	@echo "  make base-status Show blockchain container status"
	@echo "  make base-logs   View blockchain logs"
	@echo ""
	@echo "Model Commands:"
	@echo "  make models      Download standard Ollama models"
	@echo "  make models-list List available model groups"
	@echo ""
	@echo "Operations:"
	@echo "  make health      Run health check"
	@echo "  make audit       Run security audit"
	@echo "  make backup      Run backup"
	@echo "  make deploy      Deploy to production"
	@echo "  make rollback    Rollback deployment"
	@echo ""
	@echo "Security Research:"
	@echo "  make security-start   Start security research tools"
	@echo "  make security-stop    Stop security research tools"
	@echo "  make security-ai      Start AI security tools only"
	@echo "  make security-firmware Start firmware analysis"
	@echo "  make security-rf      Start RF analysis (GPU)"
	@echo "  make security-clone   Clone all research repos"
	@echo ""
	@echo "Maintenance:"
	@echo "  make clean       Remove unused Docker resources"
	@echo "  make reset       Full reset (deletes all data!)"
	@echo "  make env         Generate .env with secure secrets"
	@echo "  make validate    Validate compose files"
	@echo ""

# Default target
.DEFAULT_GOAL := help
