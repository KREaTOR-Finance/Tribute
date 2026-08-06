# Console Performance Budgets — Culling

Critics enforce these numbers. Exceptions need producer sign-off + this file update.

## Target platforms (v0)

| Platform | Priority |
|----------|----------|
| PC (dev) | Primary iteration |
| Console mid-gen class | Design for (Xbox Series S-class floor) |
| High-end PC | Upscale, not baseline |

## Frame

| Metric | Target | Hard floor |
|--------|--------|------------|
| FPS (1080p, Scalability Medium) | 60 | 45 |
| GPU ms | ≤ 16.6 | ≤ 22 |
| Game thread ms | ≤ 8 | ≤ 12 |
| Draw calls (main view, combat) | ≤ 2000 | ≤ 3500 |

## Memory

| Metric | Target | Hard |
|--------|--------|------|
| Working set (game) | ≤ 6 GB | ≤ 8 GB |
| Texture pool guidance | Prefer 1K props, 2K hero | 4K only unique hero if justified |

## Mesh / material

| Class | Tris LOD0 | Texture | Notes |
|-------|-----------|---------|-------|
| Player body | ≤ 40–50k | 2K | Readable silhouette for melee |
| Weapon | ≤ 8k | 1K–2K | Clear weapon class at distance |
| Prop (crate/trap) | ≤ 5k | 1K | High count on map |
| Environment modular piece | ≤ 15k | 1K–2K | Instance heavily |

## LOD policy

- LOD0 combat focus; LOD1/2 mandatory for multiplayer density
- Nanite: props/static only when profiling wins; do not Nanite skinned combat meshes by default

## Combat readability over fidelity

If a prettier asset hurts hit readability, the prettier asset **fails** the Assets Critic.
