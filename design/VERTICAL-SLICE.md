# Vertical Slice — Tribunal · Mode: Gauntlet

> **Game:** **Tribunal** · **Mode:** **Gauntlet** · **Reference:** *The Culling* (feel only)

## Gauntlet mode (first vertical slice)

**Humanoid player battles waves of humanoid AI**, with Culling-style **scavenge → craft → armor/weapons/traps**.

Full AI/wave specification: **`design/systems/SYS-AI-WAVES.md`**.

### Naming

| Name | Means |
|------|--------|
| **Tribunal** | The game |
| **Gauntlet** | This mode (solo wave contest) |
| *The Culling* | Reference bar only |

### One sentence

In **Gauntlet** mode, a humanoid Tribunal fighter scavenges materials, crafts armor and tools, and clears escalating humanoid AI waves — or dies.

### Playable fantasy (Culling-derived)

*The Culling* solo/bot play was **FFA-shaped contestants**, not zombie hordes.  
Tribunal VS-1 **interprets** that as **waves of humanoid AI contestants** so solo play always has pressure.

### Must ship in VS-1

| # | Requirement |
|---|-------------|
| 1 | Humanoid player mesh/rig |
| 2 | Humanoid AI (same art family) |
| 3 | Wave director: counts `[2,3,4,5]`, reinforce/clear rules per SYS-AI-WAVES |
| 4 | Win = clear all waves · Lose = player elim |
| 5 | Finish board + rematch |
| 6 | Melee combat readable (Culling bar) |

### Not VS-1

Full 16p net, full meta loadout, UE package, open world.

### Prior checklist (superseded as *primary* slice)

Earlier MeleeTest systems (scavenge, traps, zone) remain useful **support** but **VS-1 primary win condition is wave clear**, not hotseat FFA between two humans only.

### Gauntlet

- Builder implements VS-1; **never self-grades**  
- Critic scores vs SYS-AI-WAVES + Culling contestant fantasy  
