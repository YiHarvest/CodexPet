#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
mkdir -p "$TARGET_DIR"

sed "s|__CODEX_PET_ROOT__|$ROOT_DIR|g" "$SCRIPT_DIR/codex-pet.desktop.in" \
  >"$TARGET_DIR/codex-pet.desktop"
chmod +x "$TARGET_DIR/codex-pet.desktop"
echo "Desktop launcher installed: $TARGET_DIR/codex-pet.desktop"
