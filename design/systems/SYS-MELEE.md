# SYS-MELEE — Core Melee Combat Loop

## Goal

The soul of the game. Light / heavy / block / shove with stamina, hitstop, and fair resolution. Reference: **The Culling** melee identity + modern juice.

## Independently judgeable

- Light attack: speed, recovery, damage, cancel rules
- Heavy: windup telegraph, commit, punish window
- Block: damage reduction, stamina cost, break rules
- Shove: spacing tool, stamina, anti-block or gap-close role
- Stamina gate + regen
- Health / death
- Hit detection reliability (trace/volume)
- Hitstop + feedback hooks (juice may live SYS-JUICE but melee must call them)

## Architecture

```
Input → CombatStateMachine → WeaponProfile (data) → HitResolve → Damage/Stamina → Feedback events
```

- **No** hardcoding all weapons in one graph — profiles in data
- Presentation (meshes, VFX) listen to events; logic does not require specific meshes

## Paths

- This brief + GDD
- Target: `games/culling/Source/Culling/Combat/` and Content data assets
- Legacy: `~/TheCullingGodot` PlayerController melee (feel reference only)

## Non-negotiables

- Heavy has **readable windup**
- Block is a **decision**, not free
- Whiff recovery exists
- Hit feedback is mandatory on successful hit

## Critic checklist

- [ ] Would a Culling fan recognize the melee fantasy?
- [ ] Skill expression (spacing, timing) present?
- [ ] Data-driven profiles?
- [ ] Fair telegraphs?
- [ ] Not diluted into generic hit-spam?

## Initial weapon profiles (data targets)

| ID | Role |
|----|------|
| fist | Baseline |
| sword | Mid range slash |
| axe | Slow heavy |
| spear | Long poke (later) |
