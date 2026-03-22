#!/usr/bin/env bash
set -euo pipefail

AGENTS_DIR="$HOME/.agents"
UPDATE_SCRIPT="$AGENTS_DIR/update-usergenerated.sh"
CRON_MARKER="# usergenerated-agents-update"

REPOS=(
  "rules:https://github.com/UserGeneratedLLC/agent-rules.git"
  "skills:https://github.com/UserGeneratedLLC/agent-skills.git"
  "docs:https://github.com/UserGeneratedLLC/agent-docs.git"
  "commands:https://github.com/UserGeneratedLLC/agent-commands.git"
)

install() {
  command -v git >/dev/null 2>&1 || { echo "Error: git is required but not installed." >&2; exit 1; }

  mkdir -p "$AGENTS_DIR"

  for entry in "${REPOS[@]}"; do
    name="${entry%%:*}"
    url="${entry#*:}"
    dest="$AGENTS_DIR/$name/usergenerated"

    if [ -d "$dest/.git" ]; then
      echo "Updating $name..."
      git -C "$dest" pull --ff-only 2>/dev/null || echo "  Warning: pull failed for $name, skipping"
    else
      echo "Cloning $name..."
      mkdir -p "$(dirname "$dest")"
      git clone --quiet "$url" "$dest"
    fi
  done

  cat > "$UPDATE_SCRIPT" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail
for dir in "$HOME/.agents/rules/usergenerated" \
           "$HOME/.agents/skills/usergenerated" \
           "$HOME/.agents/docs/usergenerated" \
           "$HOME/.agents/commands/usergenerated"; do
  [ -d "$dir/.git" ] && git -C "$dir" pull --ff-only 2>/dev/null || true
done
EOF
  chmod +x "$UPDATE_SCRIPT"

  if crontab -l 2>/dev/null | grep -qF "$CRON_MARKER"; then
    echo "Cron job already exists."
  else
    (crontab -l 2>/dev/null || true; echo "0 * * * * $UPDATE_SCRIPT $CRON_MARKER") | crontab -
    echo "Added hourly cron job."
  fi

  echo "Installed to $AGENTS_DIR"
}

uninstall() {
  for entry in "${REPOS[@]}"; do
    name="${entry%%:*}"
    dest="$AGENTS_DIR/$name/usergenerated"
    if [ -d "$dest" ]; then
      echo "Removing $dest..."
      rm -rf "$dest"
    fi
    rmdir "$AGENTS_DIR/$name" 2>/dev/null || true
  done

  rm -f "$UPDATE_SCRIPT"

  if crontab -l 2>/dev/null | grep -qF "$CRON_MARKER"; then
    crontab -l 2>/dev/null | grep -vF "$CRON_MARKER" | crontab -
    echo "Removed cron job."
  fi

  rmdir "$AGENTS_DIR" 2>/dev/null || true
  echo "Uninstalled."
}

case "${1:-install}" in
  uninstall) uninstall ;;
  *)         install ;;
esac
