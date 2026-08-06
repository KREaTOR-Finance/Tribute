# Gauntlet State — Tribunal (console-ready product)

**Product:** **Tribunal**  
**Reference:** *The Culling* (feel bar only — not product name)  
**Playable slice:** `games/tribunal` MeleeTest  
**Ship module:** `games/culling` (UE; still branded Tribunal)  
**Identity:** `design/PRODUCT.md`  
**Updated:** 2026-08-06  
**Vertical slice:** **Gauntlet** mode — `design/systems/SYS-AI-WAVES.md` + crafting/armor/props

## Gauntlet mode (first vertical slice)

| | |
|--|--|
| Game | **Tribunal** |
| Mode | **Gauntlet** |
| Fantasy | Humanoid player vs waves of humanoid AI + Culling craft/armor/props |
| Spec | `SYS-AI-WAVES` + `CraftingSystem` |
| Status | WaveDirector + craft/armor/benches SHIPPED |
| Win | Clear wave schedule `[2,3,4,5]` |
| Lose | Player eliminated |
| Craft | wood/scrap/cloth/bone → armor, weapons, traps at bench (T) |

## Naming lock

| Say this | Not this |
|----------|----------|
| Tribunal | Tribune, “Culling 2”, shipping as The Culling |
| The Culling = reference | The Culling = our title |

## Delivery surfaces

| Surface | Status |
|---------|--------|
| Godot MeleeTest finished arena + full round + finish board | SHIPPED slice |
| Combat FSM, dodge, ranges, perfect block | SHIPPED |
| Scavenge (E channel) + traps | SHIPPED |
| Hunter roles + waves | SHIPPED |
| Zone + last stand | SHIPPED |
| TribunalHUD + FinishBoard | SHIPPED |
| Integration Critic (vertical slice) | PASS |
| Console package / UE product brand pass | NEXT |
| Human product sign-off | OPEN (human = brake) |

## Product gates (console-ready)

| Gate | Status |
|------|--------|
| Identity = Tribunal everywhere player-facing | IN PROGRESS (docs locked; keep UI clean) |
| Full round playthrough | DONE |
| Finish board | DONE |
| No out-of-place prototype geometry | DONE (ArenaEnvironment) |
| Perf budgets | ONGOING (`design/BUDGETS.md`) |
| Packaged binary | PENDING |

## Critic note

Vertical slice systems are in. Next product work: export/package, UE module named/described as Tribunal, console budget pass. Human owns “ready for store.”
