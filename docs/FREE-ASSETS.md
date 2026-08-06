# Free Asset Studios Playbook

## Priority sources (good for UE5)

| Source | Best for | License note |
|--------|----------|--------------|
| [Poly Haven](https://polyhaven.com) | HDRI, PBR textures, some models | CC0 |
| [Kenney](https://kenney.nl) | Prototyping, UI, low-poly | CC0 |
| [Quixel / Fab free](https://www.fab.com) | Photogrammetry, materials | Epic/Fab terms — read per asset |
| Epic sample content | Templates, learning | Epic EULA |
| [OpenGameArt](https://opengameart.org) | Characters, SFX | Mixed — **read each** |
| [Sketchfab](https://sketchfab.com) CC0 filter | Models | Filter downloadable CC0 |
| [Mixamo](https://www.mixamo.com) | Characters + anims | Adobe terms — check commercial |
| [Freesound](https://freesound.org) | SFX | Mixed CC |

## Import pipeline

```
download → assets/free/<source>/<pack>/
         → record assets/licenses/LEDGER.md
         → (optional) clean in Blender → assets/source/
         → export engine-ready → assets/imported/<pack>/
         → import to games/first-title/Content/ThirdParty/<Pack>/
```

## Naming

```
Content/ThirdParty/<VendorOrSource>/<PackName>/
  Meshes/
  Textures/
  Materials/
  Audio/
```

Never dump free packs into root Content.

## Quartermaster rules

1. Prefer **CC0** or Epic-granted free for shipping clarity.
2. If license is "NC" (non-commercial), **do not** put in shipping build without approval.
3. Keep original LICENSE / readme next to the pack.
4. One ledger row per pack (not per texture).
5. Reject "ripped from game" packs regardless of host site.

## Style lock

Before bulk download, lock art direction in GDD. Random free packs destroy visual coherence.
