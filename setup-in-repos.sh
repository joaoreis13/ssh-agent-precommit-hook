#!/bin/bash
# Script to configure SSH agent pre-commit hook in git repositories
# Usage: ./setup-in-repos.sh [directory1] [directory2] ...
# If no directories specified, searches current directory recursively

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

HOOK_REPO="https://github.com/joaoreis13/ssh-agent-precommit-hook"
HOOK_VERSION="v1.0.0"

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}SSH Agent Pre-Commit Hook Setup${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if pre-commit is installed
if ! command -v pre-commit &> /dev/null; then
    echo -e "${YELLOW}⚠  pre-commit is not installed${NC}"
    echo ""
    echo "Install with one of:"
    echo "  pip install pre-commit"
    echo "  pip3 install --user pre-commit"
    echo "  brew install pre-commit"
    echo ""
    exit 1
fi

# Function to setup hook in a repository
setup_hook() {
    local repo_path="$1"
    local repo_name=$(basename "$repo_path")

    echo -e "${BLUE}→ Configuring: $repo_path${NC}"

    cd "$repo_path"

    # Check if .pre-commit-config.yaml exists
    if [ -f ".pre-commit-config.yaml" ]; then
        # Check if hook is already configured
        if grep -q "ssh-agent-precommit-hook" ".pre-commit-config.yaml" 2>/dev/null; then
            echo -e "  ${GREEN}✓ Hook already configured${NC}"
            return
        fi

        echo -e "  ${YELLOW}⚠  .pre-commit-config.yaml exists, skipping${NC}"
        echo -e "  ${YELLOW}  Manually add to your .pre-commit-config.yaml:${NC}"
        echo ""
        echo "  repos:"
        echo "    - repo: $HOOK_REPO"
        echo "      rev: $HOOK_VERSION"
        echo "      hooks:"
        echo "        - id: check-ssh-agent-keys"
        echo ""
    else
        # Create new config
        cat > .pre-commit-config.yaml << EOF
repos:
  - repo: $HOOK_REPO
    rev: $HOOK_VERSION
    hooks:
      - id: check-ssh-agent-keys
EOF
        echo -e "  ${GREEN}✓ Created .pre-commit-config.yaml${NC}"
    fi

    # Install the hook
    if pre-commit install 2>/dev/null; then
        echo -e "  ${GREEN}✓ Pre-commit hooks installed${NC}"
    else
        echo -e "  ${YELLOW}⚠  Failed to install hooks${NC}"
    fi

    echo ""
}

# Determine directories to scan
SEARCH_DIRS=()

if [ $# -eq 0 ]; then
    # No arguments - use current directory
    SEARCH_DIRS=(".")
else
    # Use provided directories
    SEARCH_DIRS=("$@")
fi

# Counter for repos processed
TOTAL_REPOS=0
CONFIGURED_REPOS=0

# Process each search directory
for search_dir in "${SEARCH_DIRS[@]}"; do
    if [ ! -d "$search_dir" ]; then
        echo -e "${RED}✗ Directory not found: $search_dir${NC}"
        continue
    fi

    echo -e "${BLUE}Searching in: $search_dir${NC}"
    echo ""

    # Find all git repositories (max depth 3 to avoid going too deep)
    while IFS= read -r -d '' git_dir; do
        repo_path=$(dirname "$git_dir")

        # Skip .git subdirectories (e.g., submodules)
        if [[ "$repo_path" == *"/.git/"* ]]; then
            continue
        fi

        TOTAL_REPOS=$((TOTAL_REPOS + 1))
        setup_hook "$repo_path"
        CONFIGURED_REPOS=$((CONFIGURED_REPOS + 1))
    done < <(find "$search_dir" -maxdepth 3 -name ".git" -type d -print0 2>/dev/null)
done

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
if [ $TOTAL_REPOS -eq 0 ]; then
    echo -e "${YELLOW}No git repositories found in the specified directories${NC}"
else
    echo -e "${GREEN}✓ Processed $TOTAL_REPOS repositories${NC}"
    echo ""
    echo "The hook will check for SSH keys before each commit."
fi
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
