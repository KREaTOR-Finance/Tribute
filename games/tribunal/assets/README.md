# The Culling - Assets (CC0 / Free for Godot)

All assets in this folder are either:
- Directly downloaded CC0 from Kenney.nl or OpenGameArt.org
- Procedurally generated placeholders (trimesh) for immediate testing
- Simple .obj fallbacks

## Current Assets (as of 2026-06-13)

### Weapons (models/weapons/)
- `sword_simple.glb` - Simple low-poly sword (procedural, usable now)
- `axe_simple.glb` - Simple low-poly axe (procedural)
- `lowpoly_sword.blend` - Real CC0 low-poly sword from OpenGameArt (https://opengameart.org/content/low-poly-sword-3d-model)
- `swords_pack.blend` - CC0 swords pack from OpenGameArt (https://opengameart.org/content/3d-swords)
- `sword.obj`, `axe.obj`, `dagger.obj` - Hand-crafted low-poly placeholders

**To get real high-quality glTF**:
1. Download Kenney Pirate Kit (CC0): https://kenney.nl/assets/pirate-kit
   - Contains swords, cutlasses, barrels, crates
2. Open .blend files in Blender → Export → glTF 2.0 (.glb)
3. Place resulting .glb here as `sword.glb`, `axe.glb`, etc.

### Props (models/props/)
- `crate_simple.glb` - Basic crate for arena cover
- `barrel_simple.glb` - Barrel prop

### Characters (models/characters/)
- `warrior_capsule.glb` - Capsule stand-in (replace with real warrior model later)

### Audio (audio/impacts/)
- `README.txt` - Links to CC0 sword hit / impact sounds

## Usage in Godot

1. Drag .glb into the scene or use in WeaponVisual.gd
2. WeaponVisual (scripts/WeaponVisual.gd) automatically prefers real assets when present, falls back to procedural.
3. To attach to player:
   - Add a "Hand" Node3D child to Player
   - Instance WeaponVisual.tscn as child of Hand
   - Connect `weapon_equipped` signal from PlayerController to set the visual type

## Recommended Next Free Assets (CC0)

**Weapons:**
- Kenney Pirate Kit: https://kenney.nl/assets/pirate-kit (swords + props)
- OpenGameArt Fantasy Weapons: https://opengameart.org/content/fantasy-weapons
- Low Spec Pirate's Cutlass: https://opengameart.org/content/low-spec-pirates-cutlass

**Characters:**
- Search OpenGameArt for "low poly warrior 3d" + CC0

**Sounds:**
- Kenney Audio packs
- OpenGameArt "sword hit" CC0

**Props:**
- Kenney Modular Dungeon / Graveyard / Pirate kits

All assets must remain CC0/CC-BY for this prototype.

Last updated: 2026-06-13 (high autonomy asset pipeline complete)
