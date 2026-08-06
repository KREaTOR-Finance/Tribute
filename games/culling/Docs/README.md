# Culling (UE5) — Project Docs

Spiritual successor to **The Culling**. Gauntlet-driven development.

## Open in Unreal

1. Install UE **5.8+** on a GPU workstation (16GB+ RAM recommended).
2. Open `Culling.uproject` (generate project files if prompted).
3. Enable **Unreal MCP** + **All Toolsets**; Auto Start Server → `http://127.0.0.1:8000/mcp`.
4. See `../../docs/MCP-SETUP.md`.

## Gauntlet

- Studio rules: `../../design/gauntlet/GAUNTLET.md`
- State: `../../design/gauntlet/STATE.md`
- Skill: `/gauntlet-loop`
- Workflow: `/workflow gauntlet-culling`

## Code map (v0)

| Path | System |
|------|--------|
| `Source/Culling/Combat/` | SYS-MELEE |
| `Source/Culling/Movement/` | SYS-MOVE data |
| `Source/Culling/Character/` | Pawn shell |
| `Content/Assets/` | SYS-ASSETS descriptions |

## Legacy feel reference

`~/TheCullingGodot` — Godot prototype for melee feel; **not** a code port.
