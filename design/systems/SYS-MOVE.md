# SYS-MOVE — Movement & Camera Feel

## Goal

Player locomotion and camera that sell **weighty, skillful melee** — not floaty arena FPS. Reference: original The Culling movement commitment + modern AAA camera polish.

## Independently judgeable

- Walk / sprint feel (if sprint exists)
- Acceleration / deceleration / turn
- Camera: sensitivity curve, ADS-free third or first (default **third-person over-shoulder** for melee reads — lock choice in implementation and document)
- Collision / slope / step
- Landing / jump (if any — keep minimal for slice)

## Architecture (Unreal-ready)

- Movement component or CharacterMovement params data-driven
- Camera as separate component/rig; no combat logic inside camera boom only
- Input buffering interface explicit

## Paths

- Design: this file, `design/GDD.md`
- Code (target): `games/culling/Source/Culling/` + Content Gameplay Blueprints
- Legacy feel notes: `~/TheCullingGodot/scripts` PlayerController movement portions

## Builder instructions

Implement or improve movement/camera for the vertical slice. Prefer data knobs over magic numbers in deep graphs. Document defaults in this file's Tuning table after changes.

## Critic checklist

- [ ] Does movement allow spacing skill (not ice skating / not molasses)?
- [ ] Camera readable in 1v1 melee?
- [ ] Params tunable without rewriting logic?
- [ ] No combat damage code inside movement (separation)?

## Tuning table (v0 defaults — also in C++ fallbacks)

| Param | Value | Notes |
|-------|-------|-------|
| Max walk speed | 480 cm/s | Weighty mid-pace |
| Acceleration | 1600 | |
| Braking | 1400 | |
| Ground friction | 8 | |
| Rotation rate yaw | 480 | |
| Camera arm length | 280 cm | Over-shoulder |
| Camera socket offset | (0, 55, 55) | |
| Camera lag | 12 | On |
| Block move mult | 0.55 | |
| Heavy windup move mult | 0.4 | Commitment |
| Step height | 45 | Applied in ApplyMovementDefaults |
| Walkable floor angle | 45° | |

**Runtime path:**

- `ACullingGameMode` sets `DefaultPawnClass = ACullingCharacter`
- `Config/DefaultEngine.ini` → `GlobalDefaultGameMode=/Script/Culling.CullingGameMode`
- `ApplyMovementDefaults()` applies data asset **or** C++ fallbacks if null
- Input: `Config/DefaultInput.ini` (M&K + gamepad combat actions)
