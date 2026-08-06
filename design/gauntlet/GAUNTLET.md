# Gauntlet Loop — The Culling (Grok Build)

> Technique: [Gauntlet Loop](https://somethingbig.ai/gauntlet-loop) (Matt Shumer, 2026)  
> Harness: Grok Build sub-agents + workflows  
> Project: `~/ForgeStudio/games/culling`

## Goal

Build **Tribunal** — a **console-ready** skill-based melee battle royale — at modern AAA polish, using ***The Culling*** only as the **combat/movement reference bar** (not the product name).

**Product:** Tribunal · **Reference:** *The Culling* soul + AAA juice + console budgets.  
**Identity:** `design/PRODUCT.md`

**Human = brake.** Agents do not declare final victory.

## Hard rules

1. **Builder never grades own work.**
2. **Critic always fresh context** (new sub-agent; no `resume_from` builder).
3. Critic judges **real artifacts** (code paths, running PIE notes, assets, specs) — not builder summaries alone.
4. Critic returns **one primary gap** when failing.
5. **No fixed round limit** — loop until pass or human stops.
6. Prefer **smallest independently judgeable** systems.
7. **Assets:** description before modeling.

## Systems (judge independently)

See `design/GDD.md` inventory. P0 first: **MOVE, MELEE, WEAPON, JUICE, ASSETS, PERF, UI-min, AI-dummy**.

## Agent mapping (Grok Build)

| Role | `subagent_type` | Capability |
|------|-----------------|------------|
| System Builder (gameplay) | `unreal-engineer` or `feature-implementer` | `all` |
| Feel / systems design | `game-systems-designer` | read-only or write design |
| Level | `level-designer` | all / read-write |
| Asset Builder | `blender-artist` + `asset-quartermaster` + `technical-artist` | all |
| Gauntlet Builder (generic) | `gauntlet-builder` | all |
| Gauntlet Critic | `gauntlet-critic` | **read-only** (must not edit) |
| Integration Critic | `gauntlet-critic` | read-only |
| Producer / prioritization | `game-producer` | read-write |

## Spawn protocol (lead agent)

For each system `SYS-*`:

```
1. Builder = spawn_subagent(
     subagent_type: gauntlet-builder | unreal-engineer | ...,
     prompt: SYSTEM_BRIEF + paths + last_gap + "implement; do not self-grade",
     isolation: worktree optional for parallel systems
   )
2. Wait for builder result
3. Critic = spawn_subagent(
     subagent_type: gauntlet-critic,
     capability_mode: read-only,
     prompt: BLIND CRITIC PROMPT — include reference bar, paths to inspect,
             forbid knowledge of builder reasoning; require PASS/FAIL + single gap
   )
4. If FAIL → append gap to design/gauntlet/STATE.md → re-spawn Builder with gap only
5. If PASS → mark system PASS in STATE.md
```

**Never** pass the builder's rationale into the critic prompt. Pass only: goal, reference, file paths, how to run/test.

## Critic output contract

```markdown
### Verdict: PASS | FAIL
### Blind comparison notes
### Evidence inspected (paths / commands)
### Single biggest gap (if FAIL)
### Console / architecture notes
```

## Workflows

```
/gauntlet-loop
/workflow gauntlet-culling   args: { "system": "SYS-MELEE", "root": "/home/buidl/ForgeStudio", "rounds": 3 }
```

`rounds` is a **batch ceiling for one workflow run**, not permanent victory. Human re-runs / continues.

## Startup sequence (this project)

1. ✅ Asset description tree under `games/culling/Content/Assets/`
2. ✅ GDD + budgets + gauntlet state
3. → First Builder+Critic pairs: **SYS-MOVE**, **SYS-MELEE**
4. Thin vertical slice: MeleeTest arena + combat feel + asset discipline

## State board

Live board: `design/gauntlet/STATE.md`
