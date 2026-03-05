# SSH Agent Pre-Commit Hook for KeePassXC

[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit)](https://github.com/pre-commit/pre-commit)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A pre-commit hook that ensures SSH keys are loaded in the SSH agent before attempting to sign commits. Designed for use with KeePassXC SSH agent integration.

## Problem Solved

When using SSH commit signing with KeePassXC, commits fail with:
```
error: Couldn't find key in agent?
fatal: failed to write commit object
```

This hook checks for SSH keys in the agent before the commit and prompts you to unlock KeePassXC if needed.

## Installation

### Prerequisites

- Git 2.34.0+ with SSH commit signing configured:
  ```bash
  git config --global commit.gpgsign true
  git config --global gpg.format ssh
  git config --global user.signingkey "ssh-ed25519 AAAA..."
  ```
- A password manager with SSH agent integration (e.g., [KeePassXC](https://keepassxc.org/), [1Password](https://1password.com/), etc.)
- [pre-commit](https://pre-commit.com/) framework installed (recommended)
- `ssh-add` available in PATH
- Bash-compatible shell

### Platform Support

- ✅ Linux
- ✅ macOS
- ✅ Windows (Git Bash/WSL)

### Using pre-commit (Recommended)

Add this to your repository's `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: https://github.com/joaoreis13/ssh-agent-precommit-hook
    rev: v1.0.0  # Use the latest version tag
    hooks:
      - id: check-ssh-agent-keys
```

Then install the hooks:
```bash
pre-commit install
```

### Bulk Setup Across Multiple Repositories

Use the included `setup-in-repos.sh` script to configure the hook across multiple repositories:

```bash
# Setup in current directory (searches recursively)
./setup-in-repos.sh

# Setup in specific directories
./setup-in-repos.sh ~/projects ~/work ~/dev

# Setup in multiple workspace directories
./setup-in-repos.sh ~/workspace ~/repos
```

The script will:
- Find all git repositories in the specified directories (up to 3 levels deep)
- Create `.pre-commit-config.yaml` if it doesn't exist
- Skip repositories that already have the hook configured
- Show instructions for repositories with existing configs
- Install pre-commit hooks automatically

### Manual Installation

If you don't use the pre-commit framework, you can copy the hook directly:

```bash
curl -o .git/hooks/pre-commit \
  https://raw.githubusercontent.com/joaoreis13/ssh-agent-precommit-hook/main/check-ssh-keys.sh
chmod +x .git/hooks/pre-commit
```

## How It Works

1. **Checks signing configuration**: Only runs when `commit.gpgsign=true` and `gpg.format=ssh`
2. **Verifies SSH agent**: Runs `ssh-add -l` to check for loaded keys
3. **If no keys found**:
   - Displays a command-line prompt asking you to unlock your password manager
   - Waits for you to press ENTER when ready (60 second timeout)
   - Checks for SSH keys for up to 30 seconds, showing progress
   - Aborts the commit if keys are still not loaded
4. **If keys are present**: Allows the commit to proceed normally

The hook uses standard ANSI color codes for better visibility and provides clear troubleshooting steps if issues occur.

## Configuration

The hook automatically respects your git configuration and only runs when SSH signing is enabled. No additional configuration is needed.

### Bypass the hook

If needed, you can bypass the hook for a specific commit:
```bash
git commit --no-verify
```

## Password Manager Setup

This hook works with any password manager that supports SSH agent integration. Here are setup instructions for popular options:

### KeePassXC

1. Open KeePassXC → **Settings** → **SSH Agent**
2. Enable **Enable SSH Agent integration**
3. Add your SSH private key to a KeePassXC entry:
   - Create/edit an entry
   - Go to **Advanced** → **Attachments**
   - Add your private key file (e.g., `id_ed25519`)
4. In the entry, go to **SSH Agent** and select **Add key to agent when database is unlocked**

### 1Password

1. Enable SSH agent in 1Password → **Settings** → **Developer**
2. Turn on **Use the SSH agent**
3. Import your SSH keys into 1Password
4. Keys will automatically load when 1Password is unlocked

### Other Password Managers

Any password manager that integrates with your system's SSH agent will work. The hook simply checks if keys are available via `ssh-add -l`.

## Troubleshooting

### Hook always fails

1. Verify your password manager's SSH agent integration is enabled
2. Ensure your SSH key is configured to load when the password manager is unlocked
3. Test manually:
   ```bash
   # Should show "Could not open a connection" or "no identities"
   ssh-add -l

   # Unlock your password manager

   # Should show your key
   ssh-add -l
   ```

### SSH agent not running

Start the SSH agent:
```bash
# Linux/macOS
eval "$(ssh-agent -s)"

# Or add to your shell profile (~/.bashrc, ~/.zshrc):
if [ -z "$SSH_AUTH_SOCK" ]; then
   eval "$(ssh-agent -s)"
fi
```

### SSH signing not working

Verify your git configuration:
```bash
git config --get commit.gpgsign  # Should return: true
git config --get gpg.format      # Should return: ssh
git config --get user.signingkey # Should show your public SSH key
```

### Colors not showing

If ANSI colors don't display correctly in your terminal, the hook will still work - you just won't see colored output.

## Development

Contributions are welcome! Please feel free to submit a Pull Request.

### Running tests locally

```bash
# Install pre-commit
pip install pre-commit

# Install hooks
pre-commit install

# Run hooks manually
pre-commit run --all-files
```

## License

MIT License - see [LICENSE](LICENSE) file for details.
