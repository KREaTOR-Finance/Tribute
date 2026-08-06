# The Culling - Godot 4 Development Plan (High Autonomy)

## Phase 0: Foundation (COMPLETE)
- [x] project.godot with melee-focused input map (including Player 2 hotseat keys)
- [x] PlayerController.gd with tunable melee feel + player_id support
- [x] Basic scenes (Player.tscn, Arena.tscn, MainMenu.tscn, MeleeTest.tscn)
- [x] ArenaManager.gd
- [x] DESIGN.md + README.md
- [x] ScavengingSystem.gd
- [x] TrapSystem.gd
- [x] CameraShake.gd helper

## Phase 1: Prove the Melee Core Loop + Local 2-Player Testing (COMPLETE — per user directive "Start with number 7 then work through the first 3")

**Detailed implementation plan (executed):**
`.hermes/plans/2026-06-13-melee-core-loop-local-multiplayer.md`

Completed exactly as directed:
- **Number 7 (plan + start with local 2P):** Full plan written + Task 1 (local 2-player hotseat testing in MeleeTest.tscn with distinct P1 red / P2 blue, on-screen HP/STA labels, player_id wiring, and input action separation in project.godot).
- **First of the first 3:** Hitstop + Camera Shake + Screenshake (CameraShake.gd + integration in PlayerController with trauma on hits, time-scale hitstop).
- **Second of the first 3:** Stamina system (drain on heavy/block, regen, gating of expensive actions).
- **Third of the first 3:** Health + Death (damage with block reduction, death signal, visual feedback, elimination).

All systems are live and integrated in the tiny test arena.

## Phase 1.5: Assets for Melee (COMPLETE - 2026-06-13)

**assets-track-1 + assets-track-2 executed with high autonomy:**
- Curated and documented CC0 sources (OpenGameArt low-poly sword, swords pack, Kenney Pirate Kit recommendation).
- Downloaded real CC0 .blend files: lowpoly_sword.blend (981K), swords_pack.blend (3.5M).
- Generated immediate-use procedural .glb stand-ins using trimesh (sword_simple.glb, axe_simple.glb, crate, barrel, warrior_capsule).
- Organized full assets/ tree with README.md + audio/impacts/README.txt.
- Created WeaponVisual.gd (prefers real glb when present, falls back to nice procedural meshes with materials).
- Integrated into Player.tscn (Hand node + WeaponVisual child).
- Wired live weapon swapping (1-6 keys) in MeleeTestScene.gd with _sync_weapon_visual.
- Updated MeleeTest.tscn with arena props (crates/barrels using the glb shapes).
- Total: 4.6 MB of ready-to-import melee assets (procedural usable now + real CC0 sources for higher fidelity).

Player can now see distinct 3D weapons (sword/axe) when swapping profiles. Real .blend files are present for Blender → glTF export when desired.

## Phase 1.6: Humanoid Player Visuals (COMPLETE - 2026-06-13) [humanoid-players-1]

**Task executed with high autonomy:**
- Generated procedural low-poly humanoid .glb assets (neutral + red/blue team-colored variants) using trimesh in assets/models/characters/ (lowpoly_humanoid.glb, _red.glb, _blue.glb ~5KB each).
- Added full runtime loader in PlayerController.gd:
  - `_load_humanoid_visual()` + helper `_find_mesh_in_scene()`.
  - Loads colored glb at _ready() based on player_id (red for P1, blue for P2).
  - Replaces MeshInstance3D.mesh with the humanoid mesh.
  - Applies foot-alignment offset (Vector3(0, -0.32, 0)) + scale (0.92) so model stands correctly on the capsule origin.
  - Subtle modulate tint on top of the colored glb for extra distinction.
  - Falls back gracefully to neutral glb or logs warning.
- Updated scenes/Player.tscn:
  - MeshInstance3D now documented as "Humanoid visual mesh is loaded at runtime from assets/models/characters/lowpoly_humanoid_red.glb (P1) or ...blue.glb (P2).".
  - Added "Hand" Node3D child (positioned at right shoulder/forward for weapon grip on the humanoid rig proportions).
  - WeaponVisual.tscn instanced under Hand (for live weapon attachment on the humanoid body).
  - CollisionShape3D capsule kept (radius 0.4, height 1.8) for reliable physics/collision/hitbox – visual and collision are deliberately decoupled.
- Updated scenes/MeleeTest.tscn:
  - Removed old direct color overrides on Player instances (now handled in loader).
  - Added comments: "Team colors (P1 red, P2 blue) are now applied automatically in PlayerController._load_humanoid_visual()".
  - Updated instructions label to highlight "REAL HUMANOID BODIES (low-poly procedural) are LIVE".
- Full PlayerController.gd (510 lines) re-integrated cleanly with all prior melee systems (no breakage to weapons, knockback, particles, etc.).
- Verified: glbs present, function loads correctly, Hand attachment positioned for humanoid, capsule collision intact.

**Result:** Players are now proper low-poly humanoids instead of capsules. Weapons attach visibly to the Hand on the humanoid body. Team colors instant via colored assets. Collision/physics unchanged (good for melee reliability). Ready for playtest.

**How to test immediately:**
1. Open project in Godot 4.3+.
2. Play scenes/MeleeTest.tscn.
3. P1 (red humanoid) + P2 (blue humanoid) should appear.
4. 1-6 keys swap weapons that attach to the humanoid's hand.
5. Movement, attacks, blocks, shoves all work on the new bodies.
6. Report proportions, clipping, attachment feel, or any needed tweaks (then we can regenerate glb or adjust offsets in code).

This completes the visual upgrade while preserving the proven melee core loop.

## How to Playtest Immediately (High Autonomy)
1. Open `/home/buidl/TheCullingGodot` in Godot 4.3+.
2. Open and run `scenes/MeleeTest.tscn`.
3. Player 1 (RED humanoid): WASD move + mouse look, LMB = light jab, RMB = heavy (hold for windup), Space = block, F = shove.
4. Player 2 (BLUE humanoid, hotseat): IJKL move + mouse, U = light, O = heavy, P = block, ; = shove.
5. **Weapon test:** Press 1/2/3 on P1 or 4/5/6 on P2 — watch the 3D model on the hand change + attack profile change. Weapons now attach to the humanoid's Hand node.
6. Fight. Tweak @export values live on the Player nodes in the inspector.
7. Camera: Tab to switch to FollowCamera on P1 for much better melee feel.

When the combat feels weighty and satisfying in 30-60s fights (including visible weapons on real humanoid bodies), the core loop + assets + visuals phase is proven.

## Next Phase (Ready for Execution)
Once you confirm the melee feel + humanoid visuals + visible weapons is good:
- Wire ScavengingSystem.gd + TrapSystem.gd into MeleeTest.tscn (scripts already exist).
- Improve ArenaManager to properly handle deaths and declare winners.
- Add walls/cover/elevation + more props from the assets.
- Add simple hit audio (sword clangs, heavy thuds) — CC0 sources listed.
- Then expand to better camera or local split-screen.
- Optional: Open the .blend files in Blender, export clean glTF, replace the _simple.glb for production assets. Or refine the humanoid glb proportions/scale in code.

High autonomy: Tell me "wire scavenging and traps now", "add hit sounds", "improve heavy attack feel", "add walls to arena", "start next phase", or "tweak humanoid scale/offset" and I will execute the next bite-sized tasks from the plan with the same rigor.

## Status
- Phase 1 (melee core + local 2P testing) complete.
- Assets track (track down + organize CC0/procedural for melee) complete.
- Phase 1.6: Humanoid player visuals complete (runtime colored humanoids + Hand weapon attachment, capsule collision preserved for physics).
- The project is ready for obsessive solo-dev playtesting in Godot with real humanoid bodies + visible weapons on them.

All work followed the fusion decision: prove melee core in the smallest arena first, then add assets, then upgrade visuals, then expand.
