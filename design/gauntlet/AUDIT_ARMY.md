# Audit Army — Tribunal playthrough vs *The Culling*

**Product:** Tribunal (console-ready)  
**Reference:** *The Culling* (feel / loop bar only — not product name)  
**Rule:** No implementer grades their own work. Auditors are **read-only**, fresh context, separate from builders.  
**Identity:** `design/PRODUCT.md`

## Mission

Produce an evidence-based playthrough comparison: does a full Tribunal MeleeTest round (intro → fight → finish board) meet, approach, or miss *The Culling* soul on each dimension?

## Auditor roster

| ID | Role | Focus | Agent type |
|----|------|-------|------------|
| A0 | Audit lead / synthesizer | Assemble final board, no code edits | game-producer |
| A1 | Combat auditor | Melee FSM, spacing, block/shove/dodge, Judgement Chain vs Culling melee | gauntlet-critic |
| A2 | Loop auditor | Scavenge, traps, zone, hunters, last stand, round flow | gauntlet-critic |
| A3 | Presentation auditor | HUD, finish board, replay, visuals, readability | gauntlet-critic |
| A4 | Control auditor | KBM + gamepad, buffer, camera, seamless action | gauntlet-critic |
| A5 | Systems designer | Spec gap matrix vs GDD / Culling pillars | game-systems-designer |

## Rubric (each auditor)

Score each assigned dimension:

| Score | Meaning |
|-------|---------|
| **MEETS** | At or above Culling bar for a vertical slice |
| **APPROACHES** | Real system, still thinner than Culling A/B feel |
| **MISSES** | Missing, broken, or wrong fantasy |
| **N/A** | Out of slice scope (e.g. full 16p netcode) |

Output contract per auditor:

```markdown
### Auditor: A#
### Dimensions
| Dimension | Score | Evidence (path/line or command) | Gap if not MEETS |
### Verdict fragment: strongest win + single worst gap
```

## Synthesis (A0 only)

Write `design/gauntlet/CULLING_PLAYTHROUGH_AUDIT.md` with:

1. Executive scoreboard (table of all dimensions)
2. Playthrough walkthrough (expected player path)
3. Where Tribunal is **better** than Culling (if any)
4. Where it **loses** the A/B
5. Ordered P0 remediation list (max 10)
6. Explicit: human is brake on “console ready”

## Evidence sources

- `games/tribunal/scripts/*` especially MeleeTestScene, PlayerController, ArenaManager, HunterAI, ScavengingSystem, TrapSystem, ZoneSystem, ReplaySystem, FinishBoard, TribunalHUD, GamepadBootstrap, VisualPolish, ArenaEnvironment
- `design/GDD.md`, `design/PRODUCT.md`, `design/gauntlet/*`
- Optional: `~/TheCullingGodot/DESIGN.md` feel notes
- Godot: `/home/buidl/tools/Godot_v4.3-stable_linux.x86_64 --path games/tribunal`

## Anti-patterns

- Do not rebrand Tribunal as The Culling
- Do not accept builder commit messages as proof
- Do not PASS a dimension without a file path or runtime log line
