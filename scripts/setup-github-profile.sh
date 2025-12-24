#!/usr/bin/env bash
# ==============================================================================
# 📊 GitHub Profile Setup Script
# ==============================================================================
# Sets up GitHub profile repository with expert-tier analytics
#
# Usage:
#   ./setup-github-profile.sh [username]
#
# Dependencies:
#   - git
#   - curl
#   - GitHub CLI (gh) - optional but recommended
# ==============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging
log_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Banner
show_banner() {
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║       📊 GitHub Profile Expert Setup                             ║"
    echo "║       Transform your profile into a data-driven portfolio        ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Get username
get_username() {
    if [[ -n "${1:-}" ]]; then
        GITHUB_USERNAME="$1"
    elif command -v gh &> /dev/null && gh auth status &> /dev/null; then
        GITHUB_USERNAME=$(gh api user --jq '.login')
    else
        read -p "Enter your GitHub username: " GITHUB_USERNAME
    fi
    
    if [[ -z "$GITHUB_USERNAME" ]]; then
        log_error "GitHub username is required"
        exit 1
    fi
    
    log_success "GitHub username: $GITHUB_USERNAME"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local missing=()
    
    if ! command -v git &> /dev/null; then
        missing+=("git")
    fi
    
    if ! command -v curl &> /dev/null; then
        missing+=("curl")
    fi
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing[*]}"
        log_info "Please install them and try again"
        exit 1
    fi
    
    log_success "All prerequisites met"
}

# Create profile repository structure
create_profile_structure() {
    local profile_dir="${GITHUB_USERNAME}"
    
    log_info "Creating profile repository structure..."
    
    if [[ -d "$profile_dir" ]]; then
        log_warn "Directory $profile_dir already exists"
        read -p "Overwrite? (y/N): " confirm
        if [[ "${confirm,,}" != "y" ]]; then
            log_info "Aborting"
            exit 0
        fi
        rm -rf "$profile_dir"
    fi
    
    mkdir -p "$profile_dir/.github/workflows"
    
    log_success "Created directory structure"
}

# Copy workflow files
copy_workflows() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local homelab_root="$(dirname "$script_dir")"
    local workflows_src="$homelab_root/.github/workflows"
    local workflows_dst="${GITHUB_USERNAME}/.github/workflows"
    
    log_info "Copying workflow files..."
    
    if [[ -d "$workflows_src" ]]; then
        for workflow in profile-metrics.yml profile-snake.yml profile-waka-readme.yml profile-blog-posts.yml; do
            if [[ -f "$workflows_src/$workflow" ]]; then
                cp "$workflows_src/$workflow" "$workflows_dst/"
                log_success "Copied $workflow"
            fi
        done
    else
        log_warn "Workflow source directory not found at $workflows_src"
    fi
}

# Generate README from template
generate_readme() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local homelab_root="$(dirname "$script_dir")"
    local template_file="$homelab_root/templates/PROFILE_README.md"
    local readme_dst="${GITHUB_USERNAME}/README.md"
    
    log_info "Generating README.md..."
    
    if [[ -f "$template_file" ]]; then
        sed "s/YOUR_USERNAME/${GITHUB_USERNAME}/g" "$template_file" > "$readme_dst"
        log_success "Generated README.md"
    else
        # Create minimal README if template not found
        cat > "$readme_dst" << EOF
# Hi there 👋 I'm ${GITHUB_USERNAME}

![GitHub Stats](https://github-readme-stats.vercel.app/api?username=${GITHUB_USERNAME}&include_all_commits=true&count_private=true&show_icons=true&theme=tokyonight&hide_border=true)

![Trophies](https://github-profile-trophy.vercel.app/?username=${GITHUB_USERNAME}&theme=tokyonight&no-frame=true&column=7)
EOF
        log_success "Generated minimal README.md"
    fi
}

# Print next steps
print_next_steps() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    🎉 Setup Complete!                            ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Next Steps:${NC}"
    echo ""
    echo "1. Create the profile repository on GitHub:"
    echo "   gh repo create ${GITHUB_USERNAME} --public --description 'My GitHub Profile'"
    echo ""
    echo "2. Add required secrets in repository settings:"
    echo "   - METRICS_TOKEN: GitHub PAT with repo, read:user, read:org scopes"
    echo "   - GH_TOKEN: Same as METRICS_TOKEN"
    echo "   - WAKATIME_API_KEY: (Optional) From wakatime.com/settings/api-key"
    echo ""
    echo "3. Push the repository:"
    echo "   cd ${GITHUB_USERNAME}"
    echo "   git init"
    echo "   git add ."
    echo "   git commit -m 'Initial profile setup'"
    echo "   git branch -M main"
    echo "   git remote add origin https://github.com/${GITHUB_USERNAME}/${GITHUB_USERNAME}.git"
    echo "   git push -u origin main"
    echo ""
    echo "4. Run workflows manually to generate initial assets"
    echo ""
    echo -e "${YELLOW}Documentation:${NC} docs/GITHUB_PROFILE.md"
    echo ""
}

# Install WakaTime CLI (optional)
install_wakatime() {
    log_info "Checking WakaTime..."
    
    if command -v wakatime-cli &> /dev/null; then
        log_success "WakaTime CLI already installed"
        return
    fi
    
    read -p "Install WakaTime CLI? (y/N): " confirm
    if [[ "${confirm,,}" != "y" ]]; then
        return
    fi
    
    # Detect OS and install
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            log_info "Installing WakaTime via pip..."
            pip install --user wakatime
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew &> /dev/null; then
            brew install wakatime-cli
        fi
    fi
    
    log_info "Install WakaTime plugin for your IDE: https://wakatime.com/plugins"
}

# Main
main() {
    show_banner
    get_username "$@"
    check_prerequisites
    create_profile_structure
    copy_workflows
    generate_readme
    install_wakatime
    print_next_steps
}

main "$@"
