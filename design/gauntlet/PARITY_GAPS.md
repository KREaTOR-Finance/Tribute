# Parity Gaps — Tribunal vs The Culling

**Product:** Tribunal (`games/tribunal`, Godot 4.3)  
**Bar:** Original *The Culling* combat/scavenge/trap/zone soul + modern juice  
**Primary surface:** MeleeTest (`scenes/MeleeTest.tscn` + `PlayerController.gd`)  
**Secondary surface:** TribunalDemo (has more loop pieces; **not** the MeleeTest spine)  
**Source board:** `design/gauntlet/CULLING_PARITY.md`  
**Evidence date:** 2026-08-06  

> Implementers: ship against **MeleeTest + PlayerController**. Demo features that do not live on the MeleeTest spine still count as **gaps** for parity.

---

## Dimension cards

### 1. Melee

| | |
|--|--|
| **Culling bar** | Light/heavy commitment, block, shove, stamina gates, readable windup, fair spacing, once-per-swing hits. |
| **Tribunal now** | Full FSM in `PlayerController.gd` (`IDLE → LIGHT_ACTIVE/RECOVERY`, `HEAVY_WINDUP/ACTIVE/RECOVERY`, `BLOCKING`, `SHOVING`, `DEAD`); stamina costs; local hitstop; once-per-swing `hit_this_swing`; shape query + Area3D. |
| **Gap severity** | **P1** |
| **Smallest shippable fix** | Add **perfect-block window** (first 0.12s of block → 100% mitigate + spark SFX/VFX flag) and **weapon-driven reach** into `_melee_shape_query` (see Weapons). No new states required. |

**Code evidence:** `PlayerController.gd` MeleeState enum ~L59–60; `_melee_shape_query` hardcodes sphere radius/reach ~L626–638; block is flat `block_reduction` 0.65 with no timing window ~L749–751; no perfect-block or hitstun cancel rules.

---

### 2. Movement

| | |
|--|--|
| **Culling bar** | Weighty accel/brake, sprint commitment, combat speed mults, dodge/roll as stamina spacing tool, readable third-person camera. |
| **Tribunal now** | Walk 6 / sprint 8.4, accel 38, friction 28, air control 0.35; state speed mults (block 0.48, heavy windup 0.32); mouse yaw look; `FollowCamera` punch-in on swing/hit. |
| **Gap severity** | **P1** |
| **Smallest shippable fix** | Add **dodge** on key (default `Alt` or double-tap A/D): 0.28s i-frames end only, 18 stamina, 6 m burst along input/look, recovery 0.35s, blocked during HEAVY_WINDUP/ACTIVE. No soft lock-on this sprint. |

**Code evidence:** movement block ~L22–30, L345–402; `_wants_sprint` Shift/Ctrl ~L336–342; `FollowCamera.gd` frame_swing/frame_hit; **no dodge/roll** in FSM or input map.

---

### 3. Weapons

| | |
|--|--|
| **Culling bar** | Distinct tools: damage, windup, recovery, **range/arc**, knockback; equip from loadout/loot. |
| **Tribunal now** | `Weapon.gd` profiles for Sword/Axe/Dagger (Spear data exists); keys 1–3 equip; visuals via `WeaponVisual` + skins. Timings/damage/knockback differ; **reach is hardcoded** (light 1.35 / heavy 1.65). |
| **Gap severity** | **P1** |
| **Smallest shippable fix** | Add `light_reach` / `heavy_reach` (and optional `hit_radius`) to `Weapon.gd` profiles; read them in `_melee_shape_query` + hitbox Z. Targets: Dagger 1.05/1.2, Sword 1.35/1.65, Axe 1.25/1.55, Spear 1.7/2.0. |

**Code evidence:** `Weapon.gd` L35–68 (no range fields); `PlayerController._melee_shape_query` L626–632; MeleeTest equips sword/axe at start, not from loot.

---

### 4. Scavenge

| | |
|--|--|
| **Culling bar** | Risk/reward crates: heal, weapons, trap kits; contested / noisy / decision-relevant. |
| **Tribunal now** | `ScavengingSystem.gd` exists (loot table + box proxies) but **not wired into MeleeTest**. Death drops via `PropSkins.spawn_loot` heal-only auto-pickup. Demo has walk-into gold caches (heal 15). |
| **Gap severity** | **P0** |
| **Smallest shippable fix** | In `MeleeTestScene._ready`: spawn 4–6 `PropSkins.spawn_loot` (or call `ScavengingSystem.spawn_loot_in_arena`) at fixed cover-adjacent positions; on pickup roll: 50% bandage (+25 HP), 30% weapon equip (random type), 20% trap kit (+1 place). Key `E` optional if auto-pickup already works. |

**Code evidence:** `ScavengingSystem.gd` TODO L54; `ArenaManager.gd` TODO L84; MeleeTest only spawns loot on **death** L256–258; Demo `_spawn_loot` L190–209 (heal only).

---

### 5. Traps

| | |
|--|--|
| **Culling bar** | Placeable map control; AI/player triggers; fight-changing damage/CC. |
| **Tribunal now** | `TrapSystem.gd` data dicts (bear/spike/tripwire) but **no mesh/Area3D** (TODO L32); never registered in MeleeTest. Demo has ad-hoc `KEY_Q` sphere trap (40 dmg to hunters, 2 charges). |
| **Gap severity** | **P0** |
| **Smallest shippable fix** | Wire Demo’s place-trap pattern into MeleeTest: `Q` places `Area3D` + emissive plate at player feet; triggers on `hunters` + `players` ≠ owner; 40 dmg + 0.5s slow (velocity * 0.4 for 1.5s); 2 kits start; +1 from loot. Leave full `TrapSystem` types for later. |

**Code evidence:** `TrapSystem.gd` L18–56; Demo `_place_trap` L387–414; MeleeTest instructions omit Q/E.

---

### 6. AI

| | |
|--|--|
| **Culling bar** | Aggressive hunters with role variety (pressure, bait, scavenge); wave/spawn tension. |
| **Tribunal now** | `HunterAI.gd`: seek nearest player, walk→range, 72% light / 28% heavy windup, skins + death loot; MeleeTest spawns 2 spar hunters. **Single behavior**, no roles/waves/block/shove, no trap avoidance. |
| **Gap severity** | **P0** |
| **Smallest shippable fix** | Add `@export var role` enum on `HunterAI`: **Rusher** (speed 5.6, attack_range 2.0, heavy chance 0.15), **Baiter** (speed 4.0, range 2.8, heavy 0.4, backs up when HP&lt;40%), **Scavenger** (speed 4.5, prioritizes loot groups if any). Spawn mix 1/1/0 or 1/1/1; wave 2 after 45s or first kill. |

**Code evidence:** `HunterAI._physics_process` L207–262 single path; MeleeTest `_spawn_spar_hunters` L161–178 fixed count 2; no spawner waves.

---

### 7. Zone

| | |
|--|--|
| **Culling bar** | Closing safe area forces fights; damage outside; readable ring. |
| **Tribunal now** | Demo shrinks torus radius (`40 → 10`, ~0.35 u/s) + periodic outside damage. **MeleeTest has no zone.** ArenaManager timer exists (`match_duration` 300s) but does nothing on expiry (L27–31 pass). |
| **Gap severity** | **P0** |
| **Smallest shippable fix** | New thin `ZoneSystem.gd` (or 40 lines in MeleeTest): start radius 14, shrink to 5 over 180s; torus/ring mesh; every 0.5s outside apply 4 dmg to players+hunters; show radius on HUD. |

**Code evidence:** Demo L416–431; ArenaManager L27–31; MeleeTest has no zone nodes/scripts.

---

### 8. Arena

| | |
|--|--|
| **Culling bar** | Cover lanes, chokes, height for spacing/trap plays. |
| **Tribunal now** | MeleeTest: ~20×20 ground, **2 crates + 2 barrels**, flat; PBR reskin. Demo: larger half-28 floor, 9 crates, pillar, walls — richer, but not MeleeTest. |
| **Gap severity** | **P1** |
| **Smallest shippable fix** | Add 4 more StaticBody cover pieces in MeleeTest (L/R lanes + mid choke + 1 raised 0.6m platform); keep bounds walls; total cover 6–8 per SYS-MAP. No new materials required (reuse PropSkins). |

**Code evidence:** `MeleeTest.tscn` Crate1/2 Barrel1/2; SYS-MAP wants 4–8 crates on ~24m floor; Demo has multi-cover L102–108.

---

### 9. UI / HUD

| | |
|--|--|
| **Culling bar** | Instant-read HP/STA bars, weapon name, match timer, kill feed; combat center clear. |
| **Tribunal now** | MeleeTest: text labels only (`P1 HP: n  STA: n`, weapon string, long instructions). Demo: ProgressBars + meta line (kills/hunters/zone/traps/time). **No kill feed, no bars on MeleeTest.** |
| **Gap severity** | **P0** |
| **Smallest shippable fix** | `TribunalHUD.gd` CanvasLayer on MeleeTest: two ProgressBars (HP red, STA blue) bound to signals; match timer from ArenaManager; weapon label; 3-line kill feed on `player_died` / hunter `died`. Kill instruction wall to one line. |

**Code evidence:** MeleeTest `_update_status` L210–214; Demo bars L254–278; no `TribunalHUD.gd` in repo (parity board target W4).

---

### 10. Juice

| | |
|--|--|
| **Culling bar** | Impact identity: hitstop, shake, SFX, readable VFX; death sells. |
| **Tribunal now** | Local hitstop (0.05/0.09), camera trauma, CPUParticles warm sparks, CombatAudio WAVs (hit/whoosh/block/steps), material emission flash, death pose → hide + death mark. Missing: blood mist, weapon trail, kill-cam, volume tuning pass, block spark. |
| **Gap severity** | **P1** |
| **Smallest shippable fix** | (1) Boost hit SFX +2–4 dB and duplicate red particle burst for heavy; (2) 0.25s weapon mesh trail (simple MeshInstance scale pulse on LIGHT/HEAVY_ACTIVE); (3) perfect-block white flash if melee fix lands. Defer kill-cam. |

**Code evidence:** `_apply_hit_feedback` L742–747; `HitParticles.gd` warm yellow/orange; `CombatAudio` volumes whoosh −6 / steps −12; death L807–818.

---

### 11. Match flow

| | |
|--|--|
| **Culling bar** | Drop → scavenge → fight → last stand → clear winner / rematch. |
| **Tribunal now** | MeleeTest: death → ArenaManager eliminates → match_ended when ≤1 human alive; **test_mode_respawn true** softens stakes; R reloads scene; no winner banner beyond instructions rewrite; hunters not in win condition. Demo: TITLE→TUTORIAL→COMBAT→VICTORY/DEFEAT with ENTER retry. |
| **Gap severity** | **P1** |
| **Smallest shippable fix** | MeleeTest modes: `hotseat_ffa` (default) and `vs_ai` (P2 disabled or AI-only). End when all enemy hunters dead **or** one human left; **disable respawn** in `vs_ai`; big center Label “WINNER: X” 2s then prompt R. |

**Code evidence:** ArenaManager L42–58 respawn; MeleeTest `_on_match_ended` L262–265; hunters never registered with ArenaManager.

---

### 12. Meta / loadout

| | |
|--|--|
| **Culling bar** | Pre-match tool/perk choice that changes duel math. |
| **Tribunal now** | Cosmetic skins only (`[`/`]` cycle). No perks. Weapon swap mid-fight via 1–3 only. SYS-LOADOUT (Berserker / Iron Lung / Scavenger) exists for UE path, not Godot. |
| **Gap severity** | **P2** |
| **Smallest shippable fix** | Pre-match hold: keys `7/8/9` apply one perk for the match — Berserker (+15% light dmg, −10% max STA), Iron Lung (+25% STA regen, +10 max STA), Scavenger (+1 trap kit, +10 loot heal). Store on PlayerController; no UI beyond label. |

**Code evidence:** no perk fields in PlayerController; SkinCatalog cosmetics only; GDD/SYS-LOADOUT describe UE slice.

---

### 13. Art

| | |
|--|--|
| **Culling bar** | Readable silhouettes, team distinction, props that read as Culling arena. |
| **Tribunal now** | Poseable SkinRig + character/weapon skins; prop reskins (crate wood, barrel metal); death marks; PBR ground/HDRI when available; glb humanoid fallback to capsule body. No ragdoll; thin cover density on MeleeTest. |
| **Gap severity** | **P2** |
| **Smallest shippable fix** | On death: tween collapse (rotate X 80° + sink 0.3m over 0.5s) instead of only hide — “ragdoll-ish” without physics. Optional: team color banner quad at spawns. |

**Code evidence:** CharacterSkin / SkinCatalog; die() L807–818; MeleeTest prop skins L148–158.

---

### 14. Shareable (parity matrix bonus)

| | |
|--|--|
| **Culling bar** | One-command playable demo; no softlocks. |
| **Tribunal now** | `dist/run-tribunal.sh` + project; MeleeTest + Demo runnable; ESC mouse; R restart; Demo F6 skips tutorial. Soft risk: MeleeTest respawn + no zone can feel endless. |
| **Gap severity** | **P2** |
| **Smallest shippable fix** | Ensure run script launches MeleeTest by default; print controls once; if vs_ai mode ends cleanly (see Match flow), softlock risk drops. |

---

## Severity summary

| Sev | Dimensions |
|-----|------------|
| **P0** | Scavenge (MeleeTest), Traps (MeleeTest), AI roles/waves, Zone (MeleeTest), UI bars/timer/feed |
| **P1** | Melee polish (perfect block + reach), Movement dodge, Weapons reach data, Arena cover density, Juice pass, Match flow win modes |
| **P2** | Meta/perks, Art death pose, Shareable polish |

---

## Ordered P0 backlog (≤12) — implementers

Ship order is dependency-aware: loop pieces that make MeleeTest feel like Culling **before** polish.

| # | Item | Owner files (prefer) | Acceptance (testable) |
|---|------|----------------------|------------------------|
| 1 | **HUD bars + timer + weapon** | new `TribunalHUD.gd`, `MeleeTestScene.gd` | HP/STA ProgressBars update live; match timer counts down from ArenaManager; weapon name visible mid-fight. |
| 2 | **Scavenge caches in MeleeTest** | `MeleeTestScene.gd`, `PropSkins.gd` / `ScavengingSystem.gd` | ≥4 loot nodes at start; pickup heals **or** equips weapon **or** grants trap kit (see roll table above). |
| 3 | **Placeable traps (Q)** | `MeleeTestScene.gd`, optional thin wrap of `TrapSystem.gd` | Q places armed trap; hunter walk-on takes ≥30 dmg and trap despawns; works with kits from loot. |
| 4 | **Zone shrink on MeleeTest** | new `ZoneSystem.gd` or MeleeTest | Ring visible; radius shrinks; outside ticks damage every 0.5s; players+hunters affected. |
| 5 | **Hunter roles (3)** | `HunterAI.gd` | Rusher / Baiter / Scavenger differ in speed, range, heavy %, and retreat-or-loot behavior; readable in 30s playtest. |
| 6 | **Wave spawn** | `MeleeTestScene.gd` (+ tiny spawner) | Start 2 hunters; wave 2 (+2) at 45s **or** when hunters_alive==0; no soft-aggro freezes. |
| 7 | **Weapon reach from profile** | `Weapon.gd`, `PlayerController.gd` | Dagger whiffs where sword connects; log or debug draw optional; 1–3 still swap. |
| 8 | **Dodge (stamina)** | `PlayerController.gd` | One key: burst + brief i-frame; cannot dodge during heavy active/windup; STA cost ≥15. |
| 9 | **Perfect block window** | `PlayerController.gd` | First 0.12s block = full mitigate + distinct SFX; late block keeps 0.65 reduction. |
| 10 | **Match end vs AI (no endless respawn)** | `ArenaManager.gd`, `MeleeTestScene.gd` | `test_mode_respawn=false` in vs_ai; all hunters dead → winner banner; R restarts. |
| 11 | **Kill feed (3 lines)** | `TribunalHUD.gd` | On player/hunter death, push “X eliminated Y”; auto-fade 4s. |
| 12 | **Arena cover density** | `MeleeTest.tscn` / MeleeTestScene | +4 cover pieces + 1 low platform; chokes force pathing around props. |

**Not in this P0 list (P1/P2 follow-ups):** blood mist / trails, kill-cam, perks 7–8–9, ragdoll-ish death, soft lock-on, full TrapSystem type set, UE port parity.

---

## Spec ↔ code gaps (quick)

| Spec claim | Reality |
|------------|---------|
| CULLING_PARITY: scavenge + traps “IN FLIGHT” for MeleeTest | Systems files exist; **MeleeTest does not call them** |
| CULLING_PARITY: zone “Partial in Demo” | Correct — **not** on MeleeTest spine |
| GDD controls: E scavenge, Q trap | Demo Q only; MeleeTest instructions omit both |
| SYS-MELEE: data-driven weapon profiles | Timings yes; **range/arc no** on PlayerController path |
| SYS-UI: always-visible HP/STA bars | Demo yes; **MeleeTest text only** |
| SYS-MAP: 4–8 crates, ~24m | MeleeTest ~20m, **4 props** |
| STATE W1–W5 “IN FLIGHT” | Align this doc; do not mark PASS until Integration Critic + human |

---

## Metrics / telemetry to watch

After P0 lands, log or HUD-debug counters (even `print` is fine for slice):

| Metric | Why |
|--------|-----|
| Time-to-first-hit (s) | Onboarding / arena spacing |
| Stamina empty events / min | Exhaust spam vs commitment |
| Perfect-block rate vs total blocks | Window fairness (target 10–25% of blocks) |
| Dodge uses / duel | Spacing tool adoption |
| Loot pickups / match | Scavenge relevance |
| Trap triggers (player vs AI) | Map-control fantasy |
| Outside-zone damage taken | Zone pressure working |
| Hunter role kill share | Role balance (rusher shouldn’t 70%+ kills) |
| Match length (vs_ai) | Target 3–8 min for slice |
| Softlock / stuck (reload without death) | Shareable bar |

---

## Change log

| Date | Change |
|------|--------|
| 2026-08-06 | Initial gap audit from GDD, CULLING_PARITY, SYS-*, and Tribunal scripts (PlayerController, HunterAI, ScavengingSystem, TrapSystem, ArenaManager, MeleeTestScene, TribunalDemo, Weapon, FollowCamera, PropSkins). |
