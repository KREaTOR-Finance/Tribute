# Tribune — Completion Snapshot

**Product:** Tribune (spiritual successor to *The Culling*)  
**Repo:** https://github.com/KREaTOR-Finance/Tribute  
**Engine path:** `games/culling/`  
**Method:** Gauntlet Loop (builder ≠ critic)

## Systems complete (structure)

| ID | Status |
|----|--------|
| MOVE, MELEE, MAP, AI, JUICE, WEAPON, UI | PASS |
| LOADOUT, META, PERF, ASSETS | implemented + critic gate |
| INTEG | PASS (telegraphs) |

## How to run

1. Open `games/culling/Culling.uproject` in UE **5.8+** (GPU workstation).
2. Enable Unreal MCP optional (`docs/MCP-SETUP.md`).
3. PIE — GameMode spawns arena, dummy, UMG vitals.
4. Re-export proxies: `blender --background --python tools/scripts/export_slice_proxies.py`

## Remaining for AAA feel (post-structure)

- Skeletal hunter meshes / anim montages
- Niagara impact FX pack
- Authored MeleeTest map art pass
- Netcode BR shell
- Human PIE tuning session

These are **art/polish tracks**, not missing core MeleeTest systems.
