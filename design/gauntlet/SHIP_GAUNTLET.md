# TRIBUNAL · Gauntlet — Ship readiness (vertical slice)

**Date:** 2026-08-06  
**Game:** Tribunal  
**Mode:** Gauntlet  
**Verdict:** **SHIP_SLICE_YES** — vertical slice ready to share as **TRIBUNAL Gauntlet**

Builders did **not** self-grade. Proof = automated harness + three blind critics.

---

## Proof

| Proof | Result |
|-------|--------|
| `tools/prove_gauntlet.gd` | **PROVE_GAUNTLET_PASS** |
| Art (8 skin OBJs load) | PASS |
| Audio (6 WAVs load + play API) | PASS |
| Full waves `[2,3,4,5]` clear → victory | PASS |
| Craft armor + DR | PASS |
| Trap place | PASS |
| Judgement chain | PASS |
| Finish board + replay | PASS |
| Input actions (pad bootstrap) | PASS |
| Critic combat+loop | **SHIP_SLICE_YES** |
| Critic controls+UX | **SHIP_SLICE_YES** |
| Critic art+audio | **SHIP_SLICE_YES** |

---

## Confirmed systems

### Art
- Humanoid SkinRig (players + AI)
- Character/weapon skin kit OBJs
- ArenaEnvironment courtyard, craft benches, props
- VisualPolish (ACES, SSAO, glow, fog)

### Sounds
- light/heavy hit, whoosh, block, walk/run steps
- Runtime WAV loader (no editor import required)

### Actions
- Move, look (mouse + pad), light/heavy, block, shove, dodge
- Scavenge (E / A), craft (T at bench), trap (Q)
- Attack input buffer, Judgement Chain

### Mechanics
- WaveDirector Gauntlet schedule + win-on-clear
- Crafting materials → armor/weapons/traps
- Armor damage reduction
- Scavenge channel, traps, zone
- Last stand, finish board, replay

---

## Not claimed (residual AAA)

- Skinned skeletal characters / full animation set
- AAA audio bank + music
- Store packaging / console certification
- Blind feel win vs original *The Culling*
- MainMenu legacy title cleanup if still present

---

## How to run

```bash
cd ~/ForgeStudio && ./dist/run-tribunal.sh
# or prove:
cd games/tribunal && godot --headless --path . -s tools/prove_gauntlet.gd
```

**Human remains brake** on marketing “AAA console ship.”  
**Engineering confirmation:** vertical slice **TRIBUNAL Gauntlet** is ready to ship as a playable shareable mode.
