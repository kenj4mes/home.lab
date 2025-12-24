# Contributing to HomeLab

Thank you for your interest in contributing to HomeLab! This document provides guidelines and instructions for contributing.

## 🎯 Development Philosophy

- **Idempotency** - All scripts should be safe to run multiple times
- **Security First** - Never commit secrets, always use placeholders
- **Simplicity** - One-click setup should always be possible
- **Documentation** - All features must be documented

## 🚀 Quick Start for Contributors

1. **Fork the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/homelab.git
   cd homelab
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**

4. **Run validation**
   ```bash
   make validate
   ```

5. **Submit a Pull Request**

## 📝 Code Standards

### Bash Scripts

- Use `#!/usr/bin/env bash`
- Always include `set -euo pipefail`
- Source the common library: `source "${SCRIPT_DIR}/lib/common.sh"`
- Use the logging functions: `info`, `warn`, `error`, `success`
- Add meaningful comments for complex logic

```bash
#!/usr/bin/env bash
# ==============================================================================
# Script Purpose - Brief description
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

init_logging "script-name"

info "Starting operation..."
# Your code here
success "Operation complete"
```

### PowerShell Scripts

- Use `[CmdletBinding()]` for all functions
- Support `-WhatIf` for destructive operations
- Use approved verbs for function names
- Include help comments (`<# .SYNOPSIS #>`)

```powershell
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory=$true)]
    [string]$Parameter
)

if ($PSCmdlet.ShouldProcess("Target", "Action")) {
    # Your code here
}
```

### Docker Compose

- Include health checks for all services
- Use environment variables with defaults
- Add comments explaining each service
- Use named volumes, not bind mounts where possible

```yaml
service-name:
  image: org/image:tag
  container_name: service-name
  environment:
    - VAR=${VAR:-default_value}
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:PORT/health"]
    interval: 30s
    timeout: 10s
    retries: 3
  restart: unless-stopped
```

## 🔒 Security Guidelines

### Never Commit Secrets

- Use `CHANGEME_*` placeholders in example files
- Ensure `.env` files are in `.gitignore`
- Use Docker secrets for sensitive data where possible

### Review Checklist

Before submitting a PR, verify:

- [ ] No real passwords, tokens, or API keys
- [ ] All `.env` references use `.env.example` with placeholders
- [ ] New services have appropriate security options
- [ ] Network exposure is minimized (internal networks where possible)

## 📂 Project Structure

```
homelab/
├── docker/                 # All Docker Compose files
├── scripts/
│   ├── lib/               # Shared bash libraries
│   ├── models/            # Model catalogs and configs
│   └── *.sh               # Individual scripts
├── install/               # Platform-specific installers
├── configs/               # Service configuration templates
├── miniapps/              # Custom applications
├── terraform/             # Infrastructure as Code
└── docs/                  # Documentation
```

### Adding New Features

1. **New Service**: Add to appropriate `docker-compose.*.yml`
2. **New Script**: Place in `scripts/`, source `lib/common.sh`
3. **New Config**: Place in `configs/service-name/`
4. **New Quantum Feature**: Place in `miniapps/quantum-*/` with Flask API
5. **Documentation**: Update relevant docs in `docs/`

### Quantum Services Guidelines

When contributing to quantum features:

- Use Flask for REST APIs with standard endpoints (`/health`, `/info`)
- Include Dockerfile with health checks
- Support multiple backends where applicable
- Document all endpoints in README.md
- Follow security best practices (non-root user, limited resources)

```python
# Example quantum endpoint structure
@app.route("/health")
def health():
    return jsonify({"status": "healthy", "service": "service-name"})

@app.route("/info")
def info():
    return jsonify({"service": "Name", "version": "1.0.0", "endpoints": {...}})
```

## 🧪 Testing

### Local Testing

```bash
# Validate Docker Compose files
make validate

# Run linting (requires shellcheck, yamllint)
shellcheck scripts/*.sh
yamllint docker/*.yml
```

### CI Pipeline

The GitHub Actions workflow automatically runs:

- ShellCheck on all `.sh` files
- PSScriptAnalyzer on all `.ps1` files
- Docker Compose config validation
- YAML and JSON validation
- Terraform validation
- Security scanning for leaked secrets

## 📋 Pull Request Process

1. **Title**: Use conventional commits format
   - `feat: Add new monitoring dashboard`
   - `fix: Resolve Docker networking issue`
   - `docs: Update security guide`

2. **Description**: Include:
   - What changes were made
   - Why the changes are needed
   - How to test the changes

3. **Checklist**: Ensure all items are checked:
   - [ ] Code follows project style guidelines
   - [ ] Self-reviewed the changes
   - [ ] Added/updated documentation
   - [ ] No secrets committed
   - [ ] Tests pass locally

## 🐛 Reporting Issues

When reporting bugs, include:

- Operating system and version
- Docker and Docker Compose versions
- Relevant log output
- Steps to reproduce

## 💬 Questions?

- Open a [GitHub Discussion](https://github.com/YOUR_USERNAME/homelab/discussions)
- Check existing [Issues](https://github.com/YOUR_USERNAME/homelab/issues)

---

Thank you for contributing to HomeLab! 🏠
