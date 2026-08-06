# Gauntlet State — Tribunal ≥ Culling

**Product:** Tribunal (Godot playable) / Tribune (UE path)  
**Reference:** The Culling — equivalent or better in vertical-slice dimensions  
**Playable:** `games/tribunal` MeleeTest  
**Parity board:** `design/gauntlet/CULLING_PARITY.md`  
**Mission card:** `design/gauntlet/MISSION_CARD.md`  
**Gaps:** `design/gauntlet/PARITY_GAPS.md` (pre-army; code now ahead of doc)  
**Updated:** 2026-08-06 (finished environment + finish board + full round)

## Delivery surfaces

| Surface | Status |
|---------|--------|
| MeleeTest combat FSM + dodge + ranges + perfect block | SHIPPED |
| Scavenge + traps in MeleeTest | SHIPPED (W1) |
| Hunter roles + waves (wave2 @45s) | SHIPPED (W2) |
| Culling HUD | SHIPPED (W4) |
| Zone pressure | SHIPPED (W5) |
| Juice (particles, audio, cam) | SHIPPED (W6) |
| Integration Critic | **PASS** (vertical slice) |
| Human “≥ Culling forever” | **OPEN** — human is brake |
| UE games/culling | Structure only; next army batch |
| Packaged binary | PENDING |

## Army board

| Stream | Status | Notes |
|--------|--------|-------|
| W0 Producer / design | DONE | MISSION_CARD.md |
| W1 Scavenge+Traps | DONE | PropSkins caches, Q/B traps |
| W2 Hunter AI | DONE | RUSHER/BAITER/SCAVENGER + wave2 |
| W3 Melee depth | DONE | Dodge, weapon range_mul, perfect block |
| W4 HUD | DONE | TribunalHUD bars/timer/feed |
| W5 Zone | DONE | Closing ring + damage |
| W6 Juice | DONE | Sparks/blood, audio mix |
| Integration Critic | **PASS** | — |
| Dense cover | DONE | 19 cover pieces / lanes |
| Contested E-loot | DONE | 1.05s channel, interruptible |
| Last stand | DONE | test_mode_respawn=false |

## Critic note

Vertical-slice P0 systems are present and MeleeTest boots clean.  
Human owns final “better than Culling” feel A/B. Do not declare product victory.

| Finished env + finish board | DONE | Courtyard, intro→fight→board |
