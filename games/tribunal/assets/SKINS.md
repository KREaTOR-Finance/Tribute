# Tribunal Art — Skins Catalog

## Character skins (`SkinCatalog`)

| ID | Name | Default |
|----|------|---------|
| `hunter_crimson` | Crimson Hunter | P1 |
| `hunter_azure` | Azure Hunter | P2 |
| `hunter_bone` | Bone Ritualist | cycle |
| `hunter_iron` | Ironclad | cycle |

**In-game:** P1 `[` cycles body skin · P2 `'` cycles body skin  

Built at runtime as multi-mesh **SkinRig** (torso/head/pads/legs) with Poly Haven metal/rock overlays where available.

## Weapon skins

| ID | Name | Default on |
|----|------|------------|
| `steel` | Steel | Sword |
| `bloodsteel` | Bloodsteel | cycle |
| `bronze` | Bronze | Axe |
| `bone` | Bone | cycle |
| `obsidian` | Obsidian | Dagger |

**In-game:** P1 `]` · P2 `.` cycle weapon skin  

Blade uses Poly Haven metal/rock PBR tinted to skin; grip is matte leather/wood tone.

## Arena skins (materials)

| Surface | PBR pack |
|---------|----------|
| Ground | aerial_rocks_02 |
| Crates | wood_cabinet_worn_long |
| Barrels | metal_plate |
| Sky | kloppenheim_06 HDRI |

## Mesh kit on disk

```
assets/models/skins/   # Blender export (build_skin_kit.py)
  char_crimson.obj …
  wpn_sword_steel.obj …
```

Runtime prefers **SkinCatalog procedural rigs** (no import lag). OBJ kit is for UE import + art reference.

## UE path

Mirror skin IDs under `games/culling/Content/Assets/Descriptions/` when porting materials.
