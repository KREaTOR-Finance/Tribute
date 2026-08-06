# Product identity — Tribunal

| Role | Name |
|------|------|
| **Product / game (ships)** | **Tribunal** |
| **Flagship mode** | **Gauntlet** (solo humanoid vs AI waves + craft) |
| **Reference (feel bar only)** | *The Culling* (original) |
| **Repository** | [KREaTOR-Finance/Tribute](https://github.com/KREaTOR-Finance/Tribute) |
| **Godot playable slice** | `games/tribunal/` |
| **Unreal console/ship module** | `games/culling/` (project file name legacy; **product is still Tribunal**) |

## One sentence

**Tribunal** is a new skill-based melee battle royale built to *The Culling* combat soul, shipping as a **console-ready product** — not a remaster or fan port of *The Culling*.

## What *The Culling* is (and is not)

| *The Culling* is | *The Culling* is not |
|------------------|----------------------|
| Reference bar for melee, scavenge, traps, zone, readable fights | Product title |
| Soul / feel / loop benchmark | Codebase we ship |
| Something we must meet or beat | IP we claim to own |

## What Tribunal is

| Tribunal is | Tribunal is not |
|-------------|-----------------|
| The game name players see | “Culling 2” / unofficial remake branding |
| Console-ready product target (budgets, polish, package) | Prototype toy forever |
| Dual-engine path: Godot vertical slice → Unreal production | Web/minigame |

## Delivery surfaces

```
┌─────────────────────────────────────────────────────────┐
│  TRIBUNAL (product)                                     │
│  Reference bar: The Culling soul + modern AAA + console │
├──────────────────────┬──────────────────────────────────┤
│  games/tribunal      │  games/culling                   │
│  Godot 4.3           │  Unreal Engine 5.8+              │
│  Playable slice now  │  Console / ship systems path     │
│  dist/run-tribunal.sh│  Culling.uproject (module name)  │
└──────────────────────┴──────────────────────────────────┘
```

## Console-ready product bar

See `design/BUDGETS.md` and `design/systems/SYS-PERF.md`.

| Gate | Meaning |
|------|---------|
| Feel | Melee/move/camera pass Gauntlet vs *The Culling* reference |
| Slice | Full round: intro → fight → finish board, no prototype jank |
| Perf | Target console budgets; no unbounded particles/leaks in slice |
| Package | Shareable build path (`dist/`, export presets) |
| Identity | UI, launcher, docs say **Tribunal** — never brand as *The Culling* |

## Naming freeze

- Say **Tribunal** when talking about the game we are building.
- Say **The Culling** only as “reference / bar / soul.”
- Do **not** use **Tribune** (retired alias).
- Repo folder `games/culling` and `Culling.uproject` are **engine module paths**, not the product name.

## Change log

| Date | Change |
|------|--------|
| 2026-08-06 | Locked: Culling = reference, Tribunal = console-ready product |
