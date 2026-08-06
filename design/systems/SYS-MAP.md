# SYS-MAP — Map & Zone (MeleeTest Slice)

## Goal

Tiny, readable melee arena that proves spacing and positioning — Culling soul, not open-world BR yet.

## Independently judgeable

- Dedicated MeleeTest space (not only engine template)
- Cover / geometry that creates spacing decisions
- Clear bounds (invisible walls or cliffs)
- Spawn points for player + dummy
- Zone system deferred; optional pressure later

## Architecture

Prefer **procedural greybox spawn from C++** so the slice is source-controlled without binary `.umap` dependency. Optional later: authored `.umap` that uses the same metrics.

## Metrics (slice)

| Metric | Value |
|--------|-------|
| Floor size | ~2400 × 2400 cm (24 m) |
| Wall height | 400 cm |
| Cover crates | 4–8 |
| Player spawn | South |
| Dummy spawn | North |

## Critic checklist

- [ ] Runnable without custom editor-only assets
- [ ] Geometry supports spacing skill
- [ ] Spawns deterministic
- [ ] No soft-lock pits
