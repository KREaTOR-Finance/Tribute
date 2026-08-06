# Asset: WPN_Sword

| Field | Value |
|-------|-------|
| Category | Weapons |
| Status | `described` |
| Gameplay role | Mid-range primary melee profile visual |
| Reference bar | Clear blade length for spacing reads; not ornamental clutter |

## Visual goal

Simple, brutal one-handed sword. Silhouette must sell range vs fist/axe at a glance. No busy runes that kill readability.

## Gameplay requirements

- Grip socket matches `hand_r`
- Blade length informs weapon profile range data (keep consistent)
- Trail VFX attach point optional

## Technical budgets

- Tris LOD0: ≤ 8k
- Texture: 1K–2K
- Collision: simple capsule or box along blade for queries if mesh-based

## Blender notes

- May start from free CC0 (ledger required) then restyle
- Source: `assets/source/weapons/WPN_Sword.blend`

## Unreal notes

- `Content/Gameplay/Weapons/Sword/`
- Linked data asset `DA_Weapon_Sword`

## Critic history

| Round | Verdict | Single biggest gap |
|-------|---------|-------------------|
| 0 | — | Description only |
