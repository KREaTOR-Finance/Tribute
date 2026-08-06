# Culling Parity Mission — Tribunal ≥ The Culling

**Goal:** Tribunal (`games/tribunal`, Godot 4.3) is **equivalent or better** than original *The Culling* in every playable dimension of the vertical slice.

**Reference:** Original Culling soul (melee commitment, scavenge risk, traps, zone, readable fights) + modern AAA juice/readability.

**Human = brake.** Agents never declare final victory.

## Delivery surface (locked)

| Surface | Role |
|---------|------|
| `games/tribunal` MeleeTest + TribunalDemo | **Primary playable** parity target |
| `games/culling` UE5 | Parallel systems port (secondary this batch) |
| GitHub `KREaTOR-Finance/Tribute` | Ship continuous |

## Parity matrix (judge each independently)

| Dimension | Culling bar | Tribunal now (2026-08-06) | Target this army |
|-----------|-------------|---------------------------|------------------|
| **Melee soul** | Light/heavy commit, block, shove, stamina, spacing | FSM + poses + hitstop + lunge | Perfect timing windows, weapon ranges, perfect-block spark |
| **Movement** | Weighty, readable camera | Sprint, air control, follow cam punch-in | Dodge/roll stamina, camera collision, lock-on soft bias |
| **Weapons** | Distinct tools | Sword/axe/dagger profiles + skins | Range/arc per weapon, equip from loot |
| **Scavenge** | Risk/reward crates | Prop skins + loot caches | Wire into MeleeTest loop + heal/weapon rolls |
| **Traps** | Brutal map control | TrapSystem exists | Placeable traps in MeleeTest, AI trigger |
| **AI hunters** | Aggressive pressure | Spar hunters + skins | Roles: rusher / baiter / scavenger; spawn waves |
| **Zone** | Closing pressure | Partial in Demo | Shrinking zone on MeleeTest match timer |
| **Arena** | Cover + routes | Crates/barrels | Multi-lane cover, height, choke |
| **UI/HUD** | Instant read | Basic HP/STA labels | Culling-style bars, kill feed, match timer, crosshair |
| **Juice** | Impact identity | Shake, hitstop, audio WAVs, particles | Blood mist, trail, kill cam stub, better SFX levels |
| **Match flow** | Drop → fight → last stand | Match end on death | Round/restart, winner banner, 1v1 + free-for-all vs AI |
| **Meta/loadout** | Pre-match tools | Skins only | Pre-match weapon pick, 1 perk |
| **Art** | Readable silhouettes | Poseable SkinRig + skins | Death ragdoll-ish, team banners, arena PBR denser |
| **Shareable** | Playable demo | run-tribunal.sh | One-command demo; no softlocks |

## Army workstreams (non-overlapping)

| ID | Owner agent | Owns files (prefer) | Acceptance |
|----|-------------|---------------------|------------|
| W1 | feature-implementer | `ArenaManager`, `TrapSystem`, `ScavengingSystem`, `MeleeTestScene` | Scavenge + traps live in MeleeTest; E/Q keys |
| W2 | feature-implementer | `HunterAI`, new `HunterSpawner` | 3 roles, wave spawn, avoid soft-aggro mess |
| W3 | feature-implementer | `PlayerController` combat slice only | Dodge + weapon hit ranges; no break FSM |
| W4 | feature-implementer | new `TribunalHUD.gd`, MeleeTest UI | Bars, timer, kill feed, weapon name |
| W5 | feature-implementer | new `ZoneSystem.gd`, MeleeTest | Shrink ring, damage outside |
| W6 | gauntlet-builder | juice: particles, audio levels, death | Hit trails, louder impacts, death juice |
| W0 | game-producer + systems-designer | `design/*` | Updated STATE + gap prioritization |

## Critic protocol

After builders report: spawn **fresh** `gauntlet-critic` (read-only) on MeleeTest artifacts.  
Verdict: PASS | FAIL + **single biggest gap**.

## Run / evidence

```
Godot: /home/buidl/tools/Godot_v4.3-stable_linux.x86_64
Project: /home/buidl/ForgeStudio/games/tribunal
Headless: --path . --quit-after 4
Smoke: custom -s scripts under /tmp or tools/
```
