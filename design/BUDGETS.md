# Performance & Content Budgets

Targets for vertical slice on a mid-range PC. Tighten for shipping later.

## Runtime (PIE / packaged Dev)

| Metric | Target | Hard ceiling |
|--------|--------|--------------|
| FPS (1080p, Medium) | 60 | 45 |
| GPU frame time | ≤ 16 ms | 22 ms |
| Game thread | ≤ 8 ms | 12 ms |
| RAM (editor closed, game) | ≤ 6 GB | 8 GB |
| VRAM | ≤ 6 GB | 8 GB |

## Art

| Asset | Budget |
|-------|--------|
| Hero character tris (LOD0) | ≤ 50k |
| NPC / prop mid | ≤ 15k |
| Texture max (unique hero) | 2K |
| Texture max (props) | 1K |
| Material complexity | Prefer master materials + instances |
| Draw calls (main view) | &lt; 2k preferred |

## Level

- One streaming cell for slice
- No full open world
- HLOD / Nanite only if machine can cook; otherwise LODs

## Audio

- Music: streaming OGG/WAV &lt; 15 MB bed
- SFX pool: prioritize 20 critical events

## Agent rule

If a change blows a budget, either optimize or get producer approval and update this file.
