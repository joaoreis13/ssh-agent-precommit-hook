#!/bin/bash
# Pre-commit hook to ensure SSH keys are loaded in agent for commit signing
# Works on Linux, macOS, and Windows (Git Bash)

set -e

# ANSI color codes for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if commit signing is enabled
GPGSIGN=$(git config --get commit.gpgsign 2>/dev/null || echo "false")
GPGFORMAT=$(git config --get gpg.format 2>/dev/null || echo "")

# Only run if SSH signing is enabled
if [[ "$GPGSIGN" == "true" && "$GPGFORMAT" == "ssh" ]]; then
    # Check if any SSH keys are loaded in the agent
    if ! ssh-add -l &>/dev/null; then
        echo ""
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}⚠  SSH Key Required for Commit Signing${NC}"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo "No SSH keys found in the agent."
        echo ""
        echo "Please unlock your password manager (KeePassXC, 1Password, etc.)"
        echo "to load your SSH keys into the agent."
        echo ""
        echo -n "Press ENTER when ready to continue (or Ctrl+C to abort): "

        # Read user input with timeout
        if read -r -t 60; then
            echo ""
            echo "Checking for SSH keys..."

            # Wait for keys to appear in agent (max 30 seconds)
            TIMEOUT=30
            ELAPSED=0
            while [ $ELAPSED -lt $TIMEOUT ]; do
                if ssh-add -l &>/dev/null; then
                    echo -e "${GREEN}✓ SSH keys detected in agent${NC}"
                    echo ""
                    exit 0
                fi
                sleep 1
                ELAPSED=$((ELAPSED + 1))

                # Show progress every 5 seconds
                if [ $((ELAPSED % 5)) -eq 0 ]; then
                    echo "Still waiting for SSH keys... ($ELAPSED/$TIMEOUT seconds)"
                fi
            done

            # Timeout - no keys found
            echo ""
            echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "${RED}✗ Commit Aborted${NC}"
            echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo ""
            echo "No SSH keys were detected in the agent after 30 seconds."
            echo ""
            echo "Troubleshooting:"
            echo "  1. Ensure your password manager is unlocked"
            echo "  2. Verify SSH agent integration is enabled"
            echo "  3. Check that SSH keys are configured to load automatically"
            echo "  4. Test manually with: ssh-add -l"
            echo ""
            exit 1
        else
            # Timeout on read
            echo ""
            echo -e "${RED}ERROR: No response. Please unlock your password manager and try again.${NC}"
            exit 1
        fi
    fi
fi

# Keys are present, allow commit
exit 0
