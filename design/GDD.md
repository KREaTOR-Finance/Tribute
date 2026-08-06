# Game Design Document — Tribune

> **Product name:** Tribune  
> **Codename / module:** Culling (`games/culling/`)  
> **Repo:** https://github.com/KREaTOR-Finance/Tribute  
> **Engine:** Unreal Engine 5.8+ (primary)  
> **Status:** Gauntlet active  
> **Reference bar:** Original *The Culling* combat & movement soul + modern AAA polish/juice + console readiness  
> **Legacy prototype:** `~/TheCullingGodot` (feel reference, not code port)

## Elevator pitch

**Tribune** is a **skill-based melee battle royale** — a spiritual successor to *The Culling* — where movement, timing, spacing, and read/react win fights. Not spray. Not cover camping. Every duel should feel tense, readable, and earned.

## Design pillars (locked)

1. **Melee identity is sacred** — Do not dilute into a generic gun BR. Tools and traps support melee; they never replace it.
2. **Feel first** — Weight, windups, hitstop, stamina, camera — before maps, cosmetics, or live-ops.
3. **Readable high stakes** — Clear silhouettes, clear telegraphs, clean juice; deaths feel fair.

## Player fantasy

You are a hunter dropped into a lethal arena. Scavenge tools, set traps, control space, and win close-range fights through skill. Loadouts and perks matter; raw mechanical skill matters more.

## Reference bar (what “winning” means)

| Dimension | Bar |
|-----------|-----|
| Combat | Original Culling: light/heavy commitment, block, shove, spacing |
| Movement | Responsive but weighty; camera that sells impact |
| Juice | Modern AAA hit feedback (hitstop, shake, audio, VFX) without muddying reads |
| Systems | Loadouts/perks meaningful; scavenging risk/reward |
| Polish | Console-ready budgets; no prototype jank in vertical slice |

## Core loop (match)

```
Drop / spawn → Scavenge & position → Encounter (melee duel) → Loot / heal / reposition → Zone pressure → Final confrontations
```

**60-second micro-loop (duel):**

```
Space & stamina manage → Commit (light/heavy) or bait → Hit/block/shove resolve → Juice + state change → Reset spacing
```

## Session targets

| Milestone | Goal |
|-----------|------|
| First fun | &lt; 2 min in MeleeTest |
| Vertical slice | 10–15 min: warm-up arena + 1 scav route + 2–4 fighter encounter |
| Full match fantasy | Later — after slice clears Gauntlet |

## Systems inventory (Gauntlet pieces)

| ID | System | Slice priority |
|----|--------|----------------|
| SYS-MOVE | Movement & camera feel | **P0** |
| SYS-MELEE | Core melee combat loop | **P0** |
| SYS-WEAPON | Weapon / tool feel & timing | P0 |
| SYS-LOADOUT | Abilities / perks / loadouts | P1 |
| SYS-AI | Bot behavior (test dummies → hunters) | P0 test bots |
| SYS-MAP | Map & zone systems | P1 (tiny arena first) |
| SYS-UI | HUD readability | P0 minimal |
| SYS-JUICE | VFX, audio, hit feedback | **P0** |
| SYS-META | Progression / meta | P2 |
| SYS-ASSETS | Asset descriptions + pipeline | **P0** |
| SYS-PERF | Performance & console readiness | **P0 ongoing** |

## Non-goals (until Gauntlet clears P0)

- Full 16–60 player netcode shipping
- Battle pass / live ops
- Gun-meta primary combat
- Open-world map size

## Controls (target — slice)

| Action | Default (PC) |
|--------|----------------|
| Move | WASD |
| Look | Mouse |
| Light | LMB |
| Heavy (windup) | RMB hold |
| Block | Space / RMB context TBD — **lock in slice**: Space block |
| Shove | F |
| Interact / scavenge | E |
| Place trap | Q |

## Data-driven rule

Combat numbers, weapon profiles, perk defs live in data assets / tables — not buried only in Blueprint graphs — so Unreal iteration and future balancing stay clean.

## Change log

| Date | Change |
|------|--------|
| 2026-08-05 | Gauntlet launch: Culling identity locked, systems listed |
