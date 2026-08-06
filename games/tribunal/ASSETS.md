# The Culling - Asset Tracking (CC0 / Public Domain / Permissive for Godot)

**Goal**: Replace placeholder capsules with real melee-feel assets (weapons, characters, impacts, props) while keeping scope tiny for the test arena.

**Priority for current melee focus**:
1. 3D Weapons (Sword, Axe, Dagger) - glTF preferred
2. Simple low-poly character / warrior models
3. Hit impact particles (already have CPUParticles) + **audio** (sword clangs, heavy thuds)
4. Arena props (crates, barrels, walls, spikes for cover and traps)

**All assets must be CC0, CC-BY, or explicitly free for commercial use with attribution.**

## Curated Free Assets (Verified / Promising)

### Weapons (3D)
- **Low Poly Sword 3D model** (OpenGameArt)
  - https://opengameart.org/content/low-poly-sword-3d-model
  - License: Likely CC0 (common on OGA)
  - Format: Probably .blend / .obj — convert to glTF with Blender if needed

- **Fantasy Weapons** (OpenGameArt)
  - https://opengameart.org/content/fantasy-weapons
  - Multiple swords + axes

- **3D Swords** (OpenGameArt)
  - https://opengameart.org/content/3d-swords

- **Pirate Kit** (Kenney.nl - CC0)
  - https://kenney.nl/assets/pirate-kit
  - Has swords, cutlasses, barrels, crates (perfect for arena props + weapons)
  - Direct download usually includes .glb / .obj

- **Fantasy Props MegaKit** (OpenGameArt)
  - https://opengameart.org/content/fantasy-props-megakit

- **Low Spec Pirate's Cutlass** (OpenGameArt)
  - https://opengameart.org/content/low-spec-pirates-cutlass

### Characters / Warriors
- **Warrior Female - 3D model** (OpenGameArt)
  - https://opengameart.org/content/warrior-female-3d-model
- **Low Poly Character Pack** (search)
  - https://opengameart.org/content/low-poly-character-pack (or similar)
- Kenney has "Cube Pets" and "Platformer Kit" characters (can be reskinned for warriors)

### Audio - Melee Impacts / Hits
- Search: "sword hit sound" on OpenGameArt (CC0)
  - https://opengameart.org/art-search-advanced?keys=sword+hit+sound+impact
  - Look for "sword clash", "metal impact", "heavy swing"
- Kenney Audio packs (many CC0 sword/impact sounds)
- Recommended: "UI Audio" or "Impact" free packs from Kenney

### Environment Props (for test arena)
- **Pirate Kit** (Kenney) — crates, barrels, ship parts
- **Modular Dungeon Kit** (Kenney) — walls, pillars, traps
- **Graveyard Kit** (Kenney) — tombstones, fences for cover
- **Fantasy Props MegaKit** (OGA)

## How to Import (Godot 4)
1. Download .zip / .glb / .gltf
2. Drag into `assets/weapons/`, `assets/characters/`, `assets/props/`, `assets/audio/impacts/`
3. For .obj/.fbx: Use Godot importer or Blender to export clean glTF (with normals + UVs)
4. For weapons: Parent a MeshInstance3D to the player's hand bone or just offset from capsule for MVP
5. Audio: Load as AudioStreamPlayer3D on hit in PlayerController

## Next Actions (High Autonomy)
- [ ] Download 2-3 weapon models + 1 character
- [ ] Download 4-5 impact sounds
- [ ] Download 1 prop pack (Pirate Kit recommended)
- [ ] Create simple WeaponVisual scenes that swap meshes based on equipped Weapon.WeaponType
- [ ] Wire audio playback on light/heavy hits (different for Axe vs Dagger)
- [ ] Update MeleeTest.tscn with a few placed props for cover

**Status**: Melee system (knockback, particles, weapons with profiles, camera follow, arena flow) is complete and testable.
Assets phase started — using browser + manual curation for quality CC0 sources.

## Direct Download Notes
- Kenney: Always CC0, clean, low-poly, perfect for Godot. Use the "Download" buttons on individual pages.
- OpenGameArt: Filter for CC0. Many are .blend — easy to export glTF.
- Avoid anything with "non-commercial only" for this prototype.

Last updated: 2026-06-13 (high autonomy asset hunt)
