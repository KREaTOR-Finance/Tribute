# SYS-AI-WAVES — Culling solo AI pressure (found → interpreted)

**Game:** Tribunal  
**Mode:** **Gauntlet** (first vertical slice)  
**Reference:** *The Culling* (Xaviant) solo / bot-filled play  
**Status:** WaveDirector live · craft/armor/props in Gauntlet  
**Updated:** 2026-08-06

---

## 1. What was found (evidence)

### Confirmed from *The Culling* product shape

| Fact | Source confidence | Notes |
|------|-------------------|--------|
| Core mode is **multiplayer FFA BR**, not a classic horde mode | **High** | Marketing/wiki: 12–16 contestants, ~20 min island match |
| Loop: scavenge → craft/tools → traps → melee → last standing | **High** | Coherent Labs / Steam / design lore |
| Match length order-of-magnitude **~20 minutes** | **High** | Repeated public descriptions |
| Lobby size **up to 16** contestants | **High** | Public specs |
| **Offline / solo with AI bots** was discussed / requested and reported as available in some builds | **Medium** | Steam community: “offline singleplayer with AI bots” |
| Bots **fill the role of other contestants** (humanoid hunters), not zombies | **High** (design fantasy) | Same fantasy as PvP opponents |
| Continuous **pressure** as the field thins (zone + remaining fighters) | **High** | BR structure |

### Not found as published tables

| Item | Status |
|------|--------|
| Official Xaviant `wave_count`, `spawn_interval`, bot difficulty curves | **Not publicly documented** |
| Exact bot nav / aggression coefficients | **Not reverse-engineered here** |
| Dedicated “Wave 1/2/3 survival” mode separate from BR | **No solid public evidence** |

**Honest read:** *The Culling* solo was not Call-of-Duty-style endless waves. It was **a full FFA match simulated with AI contestants** (and/or bots filling empty slots): humanoid enemies who scavenge, engage, and die under the same arena rules as players.

---

## 2. Interpretation for Tribunal (locked)

We **interpret** the solo system as:

> **Humanoid contestant pressure in escalating waves**, approximating a bot-filled Culling FFA for one (or local 2P) human player(s).

### Design translation

| Culling idea | Tribunal interpretation |
|--------------|-------------------------|
| Other contestants | **Humanoid Hunter AI** (same skin/rig family as players) |
| Field population | **Waves** that spawn / reinforce so the arena never goes empty too long |
| Escalation | Later waves: more hunters, faster, higher heavy chance |
| End of match | Player dies → defeat · clear all waves / last standing under zone → victory |
| 20 min BR | Slice uses **shorter match** (5–8 min) with same *shape* of pressure |

### Parameters (interpreted — slice table)

These are **Tribunal design parameters** derived from the interpretation above, not leaked Xaviant constants.

| Parameter | Symbol | VS-1 value | Rationale |
|-----------|--------|------------|-----------|
| Max simultaneous AI | `max_alive` | **6** | Readable melee; not a swarm |
| Opening field | `wave_0_count` | **2** | Immediate spar (Culling first contact) |
| Wave sizes | `wave_counts` | **[2, 3, 4, 5]** | Escalating contestant pressure |
| Spawn on clear | `spawn_when_alive_le` | **0** | New wave when field empty |
| Timed reinforce | `reinforce_seconds` | **45** | Pressure if player camps |
| Inter-wave delay | `wave_delay` | **3.0 s** | Breath + banner |
| Total waves to win | `waves_to_clear` | **4** | Complete solo arc |
| Role mix | `roles` | Rusher / Baiter / Scavenger round-robin | Variety of contestant styles |
| AI humanoid | required | **true** | Same SkinRig / skins as players |
| Target | | Primary human player (P1); optional agro switch | Solo focus |
| Difficulty scale per wave | `speed_mul` | **1.0 + 0.08*(w-1)** | Slight ramp |
| | `heavy_chance_add` | **+0.05 per wave** | More commits later |
| | `damage_mul` | **1.0 + 0.1*(w-1)** | Optional later |
| Match fail | | Player eliminated (last stand) | |
| Match win | | Survive all waves **or** be last human+AI standing under rules | VS-1: **clear waves** primary |

### Wave schedule (interpreted)

```
t=0     INTRO 1.6s
t=1.6   WAVE 1  → 2 humanoid hunters
        on clear OR t+=45s with alive>0 still reinforce per rules
        after clear → 3s delay → WAVE 2 (3)
        → WAVE 3 (4)
        → WAVE 4 (5)
        → VICTORY finish board
player death anytime → DEFEAT finish board
```

---

## 3. Confirmation statement

| Claim | Status |
|-------|--------|
| Found the *kind* of solo system *The Culling* used for solo/bot play | **YES** — bot/AI **contestants** in an FFA-shaped match |
| Found official numeric wave tables from Xaviant | **NO** — not public; we **interpret** parameters |
| Interpretation is explicit and usable for VS-1 | **YES** — table above |
| First vertical slice is humanoid player vs humanoid AI waves | **LOCKED** |

---

## 4. Vertical Slice 1 (LOCKED)

**Name:** `VS-1 Humanoid Wave Gauntlet`  
**One line:** Humanoid player(s) battle escalating waves of humanoid AI hunters in a finished arena until clear or death.

### In scope

- Humanoid player body + weapons  
- Humanoid AI (roles, skins, weapons)  
- Wave director using parameters above  
- Win/lose finish board  
- Melee feel + juice enough to sell Culling-class fights  

### Out of scope (later)

- Full 16-player netcode  
- Full scavenge/craft economy as win condition  
- UE package  

### Acceptance (slice done when)

1. Solo (P1) can play a complete wave arc without softlock  
2. Every AI is humanoid (SkinRig), not a sphere  
3. Waves escalate per table  
4. Victory and defeat both show FinishBoard  
5. Blind critic can score MEETS/APPROACHES on “solo AI pressure vs Culling fantasy” without builder self-grade  

### Implementation map (next build)

| Component | Path |
|-----------|------|
| Wave director | extend `HunterSpawner.gd` or new `WaveDirector.gd` |
| AI body | `HunterAI.gd` + `SkinCatalog` humanoids |
| Player | `PlayerController` + humanoid skin |
| Arena | `ArenaEnvironment` |
| End | `ArenaManager` + `FinishBoard` win on waves cleared |

---

## 5. Relation to current code

| Have now | Gap vs VS-1 |
|----------|-------------|
| `HunterSpawner.spawn_wave`, roles, skins | Not a full **wave director** with win-on-clear of N waves |
| Wave 2 at 45s | Ad hoc; not full schedule `[2,3,4,5]` |
| Match end on human elim | Doesn’t win on “all waves cleared” |
| Humanoid SkinRig | Keep; ensure AI always uses it |

---

**Human brake:** Confirm this interpretation; next Gauntlet builder implements `WaveDirector` + VS-1 mode only.
