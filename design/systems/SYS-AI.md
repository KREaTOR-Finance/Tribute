# SYS-AI — Bots / Training Dummy

## Goal

Opponents for combat feel iteration: start with a **training dummy**, then a simple hunter bot.

## Independently judgeable

- Dummy has `UCullingCombatComponent` + capsule collision
- Takes damage, can die / reset
- Optional: telegraphed light attacks for sparring
- Distinct team color / label

## Architecture

`ACullingDummy` or AI character sharing combat component — no separate damage system.

## Critic checklist

- [ ] Hits register from player melee
- [ ] Readable as enemy
- [ ] Does not require netcode
