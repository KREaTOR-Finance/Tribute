# Asset: VFX_ImpactFlash

| Field | Value |
|-------|-------|
| Status | `implemented` (procedural actor) |
| Gameplay role | Connect readability |

## Visual goal
Short, high-contrast flash + light punch; never obscures silhouette for >0.15s.

## Implementation
`ACullingImpactFlash` — engine sphere + point light. Replace with Niagara later under same spawn API.
