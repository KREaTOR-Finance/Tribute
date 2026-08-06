# Asset: CHAR_Hunter

| Field | Value |
|-------|-------|
| Category | Characters |
| Status | `described` |
| Gameplay role | Default player hunter body for melee slice |
| Reference bar | Readable humanoid silhouette; Culling-era arena fighter, modern materials |
| Owner builder | blender-artist / technical-artist |

## Visual goal

Athletic humanoid, clear head/shoulders/weapon hand. Team colors (red/blue for local test) via material instance, not unique meshes. Must read as a person at 15–30m, not a blob.

## Gameplay requirements

- Capsule-compatible proportions (~180 cm)
- Socket: `hand_r` weapon grip
- Hit volumes: head / torso / limbs optional later; v0 single capsule OK
- Anim: idle, walk, light, heavy windup, block, hit react (placeholders OK)

## Technical budgets

See `Specs/CONSOLE_BUDGETS.md` — Player body row.

- Tris LOD0: ≤ 50k
- Texture: 2K set
- Nanite: No (skinned)

## Blender notes

- Source: `assets/source/characters/CHAR_Hunter.blend` (to create)
- Scale: cm
- Export: FBX skeletal or glTF as pipeline decides

## Unreal notes

- Path: `Content/Gameplay/Characters/Hunter/`
- MI team color params

## Critic history

| Round | Verdict | Single biggest gap |
|-------|---------|-------------------|
| 0 | — | Description only; no mesh yet |
