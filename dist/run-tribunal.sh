#!/usr/bin/env bash
# Tribunal demo launcher (shareable until full export template pack is produced)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-$HOME/tools/Godot_v4.3-stable_linux.x86_64}"
PROJECT="$ROOT/games/tribunal"
if [[ ! -x "$GODOT" ]]; then
  echo "Godot not found at $GODOT"
  echo "Download Godot 4.3 Linux and set GODOT=/path/to/Godot"
  exit 1
fi
exec "$GODOT" --path "$PROJECT" "$@"
