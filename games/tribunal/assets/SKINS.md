# Tribunal Art — Skins Catalog

First-class art identity for the Culling mirror: character body skins, weapon skins,
hunter AI skins, and death/loot prop skins. Runtime prefers **skin kit OBJs**.

## Character skins (`SkinCatalog`)

| ID | Name | OBJ | Default |
|----|------|-----|---------|
| `hunter_crimson` | Crimson Hunter | `char_crimson.obj` | P1 |
| `hunter_azure` | Azure Hunter | `char_azure.obj` | P2 |
| `hunter_bone` | Bone Ritualist | `char_bone.obj` | cycle / AI |
| `hunter_iron` | Ironclad | `char_iron.obj` | cycle / AI |

**In-game (MeleeTest):** P1 `[` cycles body · P2 `'` cycles body  

Pipeline: `ObjMeshLoader` → `ArrayMesh` → `SkinCatalog.build_character_rig` (OBJ first, procedural fallback). Accent shoulder pads keep team readability.

## Weapon skins

| ID | Name | OBJ preference | Default on |
|----|------|----------------|------------|
| `steel` | Steel | `wpn_sword_steel.obj` | Sword |
| `bloodsteel` | Bloodsteel | `wpn_sword_blood.obj` | AI default |
| `bronze` | Bronze | `wpn_axe_bronze.obj` | Axe |
| `bone` | Bone | (tinted sword) | cycle |
| `obsidian` | Obsidian | `wpn_dagger_obsidian.obj` | Dagger |

**In-game:** P1 `]` · P2 `.` cycle weapon skin  

`WeaponVisual` load order: skin kit OBJ → legacy glb → procedural boxes.

## Hunter AI skins

`HunterAI` pulls the same character + weapon skin IDs:

- Random or assigned `skin_id` from the character catalog
- Weapon stick uses `weapon_mesh_path` OBJ when present
- On death: `PropSkins.spawn_death_mark` + `PropSkins.spawn_loot`

MeleeTest optional: `spawn_spar_hunters = true` for live skin preview.

## Prop skins (death / loot / cover)

| ID | Name | Use |
|----|------|-----|
| `crate_wood` | Wood Crate | Arena cover (Crate1/2) |
| `barrel_metal` | Iron Barrel | Arena cover (Barrel1/2) |
| `loot_gold` | Scavenge Cache | World loot + hunter death drops |
| `death_mark` | Fallen Mark | Elimination stain + fallen blade token |

MeleeTest applies prop skins on ready; player elimination spawns death mark + loot.

## Arena materials (PBR)

| Surface | PBR pack |
|---------|----------|
| Ground | aerial_rocks_02 |
| Crates | wood_cabinet_worn_long (via prop skin) |
| Barrels | metal_plate (via prop skin) |
| Sky | kloppenheim_06 HDRI |

## Mesh kit on disk

```
assets/models/skins/          # Blender export (tools/scripts/build_skin_kit.py)
  char_crimson.obj …
  char_azure.obj …
  char_bone.obj …
  char_iron.obj …
  wpn_sword_steel.obj …
  wpn_sword_blood.obj …
  wpn_axe_bronze.obj …
  wpn_dagger_obsidian.obj …
```

**Runtime:** `scripts/ObjMeshLoader.gd` loads OBJs without editor import.  
**UE path:** mirror skin IDs under `games/culling/Content/Assets/Descriptions/`.

## Key scripts

| Script | Role |
|--------|------|
| `ObjMeshLoader.gd` | OBJ → ArrayMesh |
| `SkinCatalog.gd` | IDs, materials, `build_character_rig`, `weapon_mesh_path` |
| `CharacterSkin.gd` | Apply body skin to PlayerController |
| `WeaponVisual.gd` | Hand weapon mesh + skin paint |
| `HunterAI.gd` | AI hunters with catalog skins + death drops |
| `PropSkins.gd` | Loot / death mark / static prop reskin |
