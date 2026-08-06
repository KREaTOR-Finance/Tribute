# Mission Card — Culling Complete Micro-Match

**Product:** Tribunal (`games/tribunal`, Godot 4.3)  
**Slice name:** Culling complete micro-match  
**Primary scene:** `scenes/MeleeTest.tscn`  
**Parity board:** `design/gauntlet/CULLING_PARITY.md`  
**State:** `design/gauntlet/STATE.md`  
**Updated:** 2026-08-06  
**Producer:** game-producer (W0)

---

## Intent

Ship a single playable MeleeTest micro-match that feels like a compressed *The Culling* round: spawn armed, scavenge risk/reward, place traps, fight AI hunters (and optional hotseat P2), survive a shrinking zone, and end on a clear winner banner — with weighty melee (light/heavy commit, block, shove, dodge, stamina) and readable juice — so a cold player can say “this is Culling” in under three minutes without softlocks.

## One-paragraph mission

Close every gap on the [CULLING_PARITY.md](CULLING_PARITY.md) matrix that still lives only as stubs or TODOs: wire **ScavengingSystem + TrapSystem** into MeleeTest (E/Q), give hunters **roles + waves**, add **dodge + per-weapon hit ranges**, replace label HUD with **Culling-style bars / timer / kill feed**, add a **shrinking zone** on a short match timer, and pass **juice** (trails, death, SFX levels) — all in `games/tribunal` only this batch; no UE port, no netcode, no full meta. **Human is the brake** on final “≥ Culling” victory.

---

## In scope (testable)

- Scavenge caches live in MeleeTest; **E** picks up heal/weapon/trap-kit rolls
- **Q** places at least one trap type; hunters (and players) can trigger it
- Hunter spawner: ≥3 roles (rusher / baiter / scavenger), wave or timed respawn
- Player dodge/roll with stamina cost; sword/axe/dagger distinct range/arc damage
- HUD: HP/STA bars, match timer, weapon name, kill feed (≥3 lines)
- Zone: shrink ring + out-of-zone damage before match clock ends
- Match end: last living fighter → winner banner + restart (R or UI)
- Juice: hit trail or blood mist stub, death feedback, impact SFX audible
- Headless smoke + one-command play path still work

## Out of scope (explicit non-goals)

- `games/culling` UE5 systems this batch
- 16-player / netcode / dedicated server
- Full crafting tree / inventory UI
- Perfect-block spark polish beyond stub if dodge+ranges land first
- Paid assets; new Blender hero meshes (use existing skins/props)
- Declaring product PASS without Integration Critic + human

---

## Ordered acceptance criteria — “Culling complete micro-match”

Run order for QA / Integration Critic. **All must pass** for slice candidate; human still brakes final ship.

1. **Boot** — `MeleeTest.tscn` runs in Godot 4.3; mouse captured; no script errors on load.
2. **Melee soul** — P1: light, heavy windup, block, shove, stamina gate; hitstop + camera shake on hit.
3. **Weapon identity** — Equipped sword/axe/dagger (or loot equip) produce different reach and/or damage profile.
4. **Dodge** — Stamina-cost dodge/roll moves body and is usable mid-fight without breaking combat FSM.
5. **Scavenge** — ≥3 loot points in arena; **E** collects; bandage heals or weapon/trap kit applies visibly.
6. **Traps** — **Q** places armed trap; walking into it damages/slows; AI can trigger player traps.
7. **AI pressure** — ≥2 hunters with distinct roles; waves or re-aggro so arena never feels empty for 60s+.
8. **Zone** — Visible or clearly telegraphed shrink; outside ring damages; forces fights before timer end.
9. **HUD** — HP bar, STA bar, match timer, current weapon name, kill feed updates on elim.
10. **Match flow** — On sole survivor (or timer + standings): winner banner; restart returns to fight without softlock.
11. **Juice** — Hit VFX + death feedback + combat SFX present; fight remains readable (not mud).
12. **Shareable** — Documented run path (`QUICKSTART` / `dist/run-tribunal.sh` or equivalent) launches micro-match.

---

## Workstream status table (W1–W6)

| ID | Owner agent | Task | Paths (prefer) | Depends | Status |
|----|-------------|------|----------------|---------|--------|
| **W0** | game-producer + systems-designer | Mission card, parity gap order, STATE | `design/gauntlet/*`, `design/GDD.md` | — | **DONE** (this card) |
| **W1** | feature-implementer | Wire scavenge + traps into MeleeTest; E/Q; Area3D visuals | `ScavengingSystem.gd`, `TrapSystem.gd`, `ArenaManager.gd`, `MeleeTestScene.gd`, `PropSkins.gd` | — | **RUNNING** — systems exist as stubs; **not live in MeleeTest** (TODOs in ArenaManager) |
| **W2** | feature-implementer | 3 hunter roles + wave spawn; avoid soft-aggro mess | `HunterAI.gd`, new `HunterSpawner.gd`, `MeleeTestScene.gd` | W1 loot drops optional | **RUNNING** — spar hunters only; no roles/waves yet |
| **W3** | feature-implementer | Dodge + per-weapon hit ranges; do not break FSM | `PlayerController.gd`, `Weapon.gd` combat slice only | — | **RUNNING** — FSM + profiles exist; dodge + range differentiation incomplete |
| **W4** | feature-implementer | Culling HUD: bars, timer, kill feed, weapon name | new `TribunalHUD.gd`, `MeleeTest.tscn` UI | W2 deaths for feed | **RUNNING** — basic labels only |
| **W5** | feature-implementer | Shrinking zone + outside damage + match timer hook | new `ZoneSystem.gd`, `ArenaManager.gd`, MeleeTest | — | **RUNNING** — timer exists; zone TODO |
| **W6** | gauntlet-builder | Juice: trails, SFX levels, death | `HitParticles*`, `CombatAudio.gd`, `CameraShake.gd`, death path | W3 hits preferred | **RUNNING** — shake/hitstop/audio baseline; trails/death pass pending |
| **IC** | gauntlet-critic (fresh, read-only) | Blind judge MeleeTest vs criteria 1–12 | Artifacts only; no builder rationale | W1–W6 report done | **PENDING** builders |

### Integration order (builders)

```
W3 (dodge/ranges) ──┐
W1 (scav+traps)  ───┼──► W4 HUD + kill feed ──► W6 juice polish ──► IC
W2 (roles/waves) ───┤
W5 (zone) ──────────┘
```

Prefer parallel W1–W5; W4 should consume death/kill signals once W2 lands. W6 last polish pass if capacity limited.

---

## Risks

| Risk | Mitigation |
|------|------------|
| Scope thrash across 6 streams | One scene spine: **MeleeTest only**; no TribunalDemo feature split this batch |
| Trap/scavenge “print-only” false complete | Critic requires Area3D + damage/heal, not console logs |
| AI soft-aggro mess | Cap concurrent hunters; role speeds; leash to arena bounds |
| Godot headless ≠ feel | Smoke scripts for boot; human/PIE for soul |
| RAM/GPU on dense juice | Particles budgeted; no full ragdoll physics this slice |
| License | Free/first-party assets only (`ASSETS.md` / existing skins) |
| Agents declare victory | **Human brake** (below) |

---

## Human brake note

> **Human = brake.**  
> Agents never declare final victory that Tribunal is “equivalent or better than The Culling.”  
> Integration Critic may return **PASS | FAIL** on the micro-match criteria only.  
> Product-level “≥ Culling” requires **human feel sign-off** after a live MeleeTest play session.  
> If blocked: max three questions — do not invent scope.

### Decision needed from human (only if blocked)

1. Micro-match default length: **90s / 180s / 300s**? (producer default: **180s** with zone start ~60s.)  
2. Hotseat P2 required for slice PASS, or **P1 + AI** sufficient? (producer default: **P1 + AI**; keep hotseat if already stable.)  
3. Pre-match weapon pick + 1 perk this slice or **defer meta**? (producer default: **defer**; equip from loot only.)

---

## Files opened (producer evidence)

- `design/gauntlet/CULLING_PARITY.md`
- `design/gauntlet/STATE.md`
- `design/gauntlet/GAUNTLET.md`
- `design/GDD.md`
- `design/VERTICAL-SLICE.md`
- `games/tribunal/DESIGN.md`
- `games/tribunal/scripts/*` inventory (ArenaManager, MeleeTestScene, ScavengingSystem, TrapSystem, HunterAI, Weapon, CombatAudio, etc.)

## Run / evidence (for builders & critic)

```
Godot: /home/buidl/tools/Godot_v4.3-stable_linux.x86_64
Project: /home/buidl/ForgeStudio/games/tribunal
Scene: scenes/MeleeTest.tscn
Headless smoke: --path . --quit-after 4
```
