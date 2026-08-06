# Tribunal — Godot playable slice

**Product:** Tribunal (console-ready melee BR)  
**Reference:** *The Culling* combat soul (not the product title)

This folder is the **playable vertical slice** of Tribunal. Unreal production/console systems live under `games/culling/` but the **player-facing name is always Tribunal**.

## Run

```bash
# From ForgeStudio root
./dist/run-tribunal.sh

# Or
godot4 --path games/tribunal
```

Main scene: `scenes/MeleeTest.tscn` — finished courtyard, full round, finish board.

## Round flow

1. **INTRO** — fighters frozen, FIGHT banner  
2. **FIGHT** — melee, E/H scavenge channel, Q/B traps, hunters, closing zone  
3. **FINISH BOARD** — winner + K/SCAV/TRAP/HP · **R** rematch  

## Controls (P1)

| Input | Action |
|-------|--------|
| WASD + Mouse | Move / look |
| LMB / RMB | Light / heavy |
| Space / F | Block / shove |
| C | Dodge |
| E | Scavenge (hold channel) |
| Q | Place trap |
| R | Rematch (on finish board) |
| TAB | Camera follow / fixed |

P2: IJKL · U/O · P/; · V dodge · H scavenge · B trap.

## Philosophy

- Melee feel is non-negotiable (*The Culling* bar).  
- Scavenge and traps must matter.  
- Finished environment + complete round = product slice, not prototype junk drawer.  
- Path: slice → package → console (UE module under Tribunal branding).

See `../../design/PRODUCT.md` and `../../design/GDD.md`.
