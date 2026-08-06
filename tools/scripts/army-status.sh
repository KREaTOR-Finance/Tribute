#!/usr/bin/env bash
# Quick readiness check for the Game Forge army
set -euo pipefail
echo "=== ForgeStudio Army Status ==="
echo "Host: $(hostname)"
echo "Date: $(date -Iseconds)"
echo
echo "-- Toolchain --"
command -v blender >/dev/null && blender --version | head -1 || echo "blender: MISSING"
command -v uvx >/dev/null && echo "uvx: OK" || echo "uvx: MISSING"
command -v UnrealEditor >/dev/null && UnrealEditor -version 2>/dev/null | head -1 || echo "UnrealEditor: not on PATH (expected on GPU workstation)"
echo
echo "-- Grok army --"
echo "Agents: $(ls -1 ~/.grok/agents 2>/dev/null | wc -l)"
echo "Workflows: $(ls -1 ~/.grok/workflows 2>/dev/null | wc -l)"
echo "Personas: $(ls -1 ~/.grok/personas 2>/dev/null | wc -l)"
test -f ~/.grok/skills/game-ops-army/SKILL.md && echo "skill game-ops-army: OK" || echo "skill game-ops-army: MISSING"
echo
echo "-- Project --"
ROOT="${1:-$HOME/ForgeStudio}"
echo "Root: $ROOT"
test -f "$ROOT/AGENTS.md" && echo "AGENTS.md: OK" || echo "AGENTS.md: MISSING"
test -f "$ROOT/design/GDD.md" && echo "GDD.md: OK" || echo "GDD.md: MISSING"
test -f "$ROOT/docs/MCP-SETUP.md" && echo "MCP-SETUP.md: OK" || echo "MCP-SETUP.md: MISSING"
echo
echo "-- MCP (live probes) --"
if curl -sS -m 1 -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/mcp 2>/dev/null | grep -qE '^[0-9]+$'; then
  echo "Unreal MCP :8000/mcp — reachable (or responding)"
else
  echo "Unreal MCP :8000/mcp — not reachable (start UE editor)"
fi
echo "Blender MCP — requires Blender + addon + uvx blender-mcp (not probed)"
echo
echo "Done."
