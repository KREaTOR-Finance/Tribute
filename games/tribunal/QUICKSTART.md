# The Culling - Quickstart (Godot 4)

## Open & Run the Melee Test (Core Loop Proof)

1. Open Godot 4.3+ → Import Project → select the `TheCullingGodot` folder.
2. Open `scenes/MeleeTest.tscn`.
3. Press **Play** (F5).

## Controls (Hotseat 2-Player on one machine)

**Player 1 (Red capsule):**
- WASD: Move
- Mouse: Look
- **LMB**: Light Jab (fast)
- **RMB**: Heavy Attack (windup + big damage + knockback)
- **Space**: Block
- **F**: Shove
- **1**: Equip Sword (balanced)
- **2**: Equip Axe (brutal heavy, high knockback)
- **3**: Equip Dagger (fast lights)

**Player 2 (Blue capsule):**
- IJKL: Move
- Mouse: Look
- **U**: Light
- **O**: Heavy
- **P**: Block
- **;**: Shove
- **4**: Sword
- **5**: Axe
- **6**: Dagger

**Camera:**
- **Tab**: Toggle fixed overview camera ↔ FollowCamera on P1 (much better for feeling melee weight)

**Inspector Magic (while running):**
Select Player1 or Player2 in the scene tree → tweak any @export in PlayerController (light_attack_damage, heavy_attack_windup, stamina_drain, etc.). Changes are live. Perfect for tuning the "juicy" feel.

## Current State (Assets + Melee Complete)

- ✅ Phase 1 melee core: light/heavy, block, shove, stamina, health, death, hitstop, camera shake, knockback, hit particles.
- ✅ Weapon system: equippable Sword / Axe / Dagger with distinct profiles.
- ✅ **Assets track complete**:
  - Real CC0 sources: `lowpoly_sword.blend` + `swords_pack.blend` (OpenGameArt)
  - Procedural but fully usable .glb: sword_simple.glb, axe_simple.glb, crate, barrel, warrior stand-in.
  - WeaponVisual.gd automatically uses real glb when present, falls back to nice procedural meshes.
  - Player.tscn now has a "Hand" node with WeaponVisual child.
  - MeleeTestScene syncs the 3D model when you press 1-6.

## Next Immediate Things (if you want to continue melee focus)

- Open the .blend files in Blender → Export as glTF (.glb) → replace the _simple.glb for higher fidelity swords.
- Add simple attack animations (or at least better windup/release tweens on the weapon visual).
- Wire ScavengingSystem.gd + TrapSystem.gd into the arena (already written, just need registration).
- Add walls / elevation / more cover props.
- Switch to real character models (search OpenGameArt "low poly warrior" CC0).

## How to Feel the Juice

Run the scene. Fight for 30 seconds using only lights. Then switch to heavy on the axe. Notice the windup, the bigger knockback, the screen shake, the particle burst, the stamina cost. Then block an incoming heavy. The core loop should already feel *consequential*.

Tweak values live in the inspector until every hit "pops".

## Project Files of Note

- `scenes/MeleeTest.tscn` — the rapid iteration arena
- `scripts/PlayerController.gd` — the heart (all the juicy parameters are @export)
- `scripts/Weapon.gd` — attack profiles
- `scripts/WeaponVisual.gd` — 3D weapon swapping (real assets + procedural)
- `assets/` — all the CC0 + stand-in models (4.6 MB total)

High autonomy note: everything above was set up without manual copy-paste. The fusion decision (prove melee in tiny arena first) is being followed ruthlessly.

Press Play and report how the weight feels.
