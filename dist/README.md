# Tribunal — Playable Demo

**Spiritual successor to *The Culling*** — skill-based melee arena with tutorial, scavening, hunters, zone, traps.

## Quick play (Linux)

```bash
# Option A — launcher (requires Godot 4.3 binary once)
./run-tribunal.sh

# Option B — direct
$HOME/tools/Godot_v4.3-stable_linux.x86_64 --path ../games/tribunal
```

Project path: `games/tribunal/`

## Controls

| Input | Action |
|-------|--------|
| WASD | Move |
| Mouse | Look |
| LMB | Light attack |
| RMB | Heavy (windup commit) |
| Space | Block |
| F | Shove |
| 1 / 2 / 3 | Fist / Sword / Axe |
| Q | Place trap (hunt phase) |
| E | Finish tutorial → hunt |
| Enter | Start / replay |
| Esc | Toggle mouse |

## Demo flow

1. **Title** — TRIBUNAL
2. **Tutorial** — move, light, heavy, block/shove, loot
3. **The Hunt** — 4 AI hunters, shrinking zone, traps
4. **Victory / Defeat** — Enter to restart

## Assets

- **Poly Haven CC0** PBR (rock, wood, metal) + HDRI sky  
  License: https://polyhaven.com/license  
  Ledger: `assets/licenses/LEDGER.md`
- Runtime procedural characters (production mesh swap path ready)

## Unreal path

Production C++ UE project remains under `games/culling/` (module name legacy).  
Open `Culling.uproject` on a GPU workstation with UE 5.8+.

## Honest quality bar

This demo is a **complete playable loop** with production **textures** and Culling-soul combat verbs.  
Full skeletal cinematic mesh quality = continue art pipeline (Blender MCP + UE import) on a GPU machine.
