# Game Design Document — Tribunal

> **Product:** **Tribunal** (console-ready melee battle royale)  
> **Reference bar:** *The Culling* (combat & movement soul only — not the product name)  
> **Repo:** https://github.com/KREaTOR-Finance/Tribute  
> **Playable slice:** Godot 4.3 · `games/tribunal/`  
> **Ship / console module:** Unreal Engine 5.8+ · `games/culling/` (module path; product remains Tribunal)  
> **Identity doc:** `design/PRODUCT.md`  
> **Status:** Gauntlet active · vertical slice in MeleeTest  

## Elevator pitch

**Tribunal** is a **skill-based melee battle royale** built to the bar of *The Culling*: movement, timing, spacing, and read/react win fights. Tools and traps support melee — they never replace it. Target is a **console-ready product**, not a prototype demo forever.

## Design pillars (locked)

1. **Melee identity is sacred** — Not a gun BR. Scavenge and traps feed melee.
2. **Feel first** — Weight, windups, hitstop, stamina, camera — before live-ops.
3. **Readable high stakes** — Clear silhouettes, telegraphs, juice without mud.
4. **Console-ready product** — Budgets, package path, finish screens, no floating jank.

## Player fantasy

You are a hunter in a lethal arena. Scavenge, place traps, control space, win close-range fights through skill.

## Reference bar (*The Culling* → Tribunal)

| Dimension | *The Culling* reference | Tribunal product target |
|-----------|-------------------------|-------------------------|
| Combat | Light/heavy commit, block, shove, spacing | Meet or beat + dodge, perfect block, weapon ranges |
| Movement | Weighty, readable camera | Sprint, dodge, follow-cam combat frame |
| Loop | Scavenge → trap → fight → zone | Same loop, finished arena + finish board |
| Juice | Impact identity | Hitstop, shake, audio, sparks/mist, kill credit |
| Polish | — | Console budgets, full round, rematch, product branding |

## Core loop (match)

```
Spawn pads → Scavenge & position → Encounter (melee) → Loot / heal / trap → Zone pressure → Last stand → Finish board
```

**60-second micro-loop (duel):**

```
Space & stamina → Commit (light/heavy) or bait → Hit/block/shove/dodge → Juice + state → Reset spacing
```

## Session targets

| Milestone | Goal |
|-----------|------|
| First fun | &lt; 2 min in MeleeTest |
| Vertical slice | Full round: intro → fight → finish board (shippable feel) |
| Console product | UE module + packages under Tribunal branding |

## Systems inventory (Gauntlet)

| ID | System | Priority |
|----|--------|----------|
| SYS-MOVE | Movement & camera | **P0** |
| SYS-MELEE | Core melee | **P0** |
| SYS-WEAPON | Weapon feel | P0 |
| SYS-LOADOUT | Perks / loadouts | P1 |
| SYS-AI | Hunters | P0 |
| SYS-MAP | Arena & zone | P0 slice |
| SYS-UI | HUD + finish board | **P0** |
| SYS-JUICE | VFX / audio / hit | **P0** |
| SYS-META | Progression | P2 |
| SYS-ASSETS | Pipeline | **P0** |
| SYS-PERF | Console readiness | **P0 ongoing** |

## Non-goals (until product gates clear)

- Branding as *The Culling* or “Culling remaster”
- Full 16–60 player netcode as day-one slice requirement
- Gun-meta primary combat
- Open-world map size

## Controls (slice)

| Action | P1 | P2 |
|--------|----|----|
| Move | WASD | IJKL |
| Look | Mouse | — |
| Light / Heavy | LMB / RMB | U / O |
| Block / Shove | Space / F | P / ; |
| Dodge | C / Alt | V |
| Scavenge (channel) | E | H |
| Trap | Q | B |
| Rematch | R (finish board) | R |

## Data-driven rule

Combat numbers and weapon profiles stay data/tables-friendly so UE port and console balance stay clean.

## Change log

| Date | Change |
|------|--------|
| 2026-08-05 | Gauntlet launch |
| 2026-08-06 | Product lock: **Tribunal** ships; *The Culling* = reference only; console-ready framing |
