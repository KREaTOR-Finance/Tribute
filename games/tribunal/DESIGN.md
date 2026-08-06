# The Culling - Godot 4 Prototype Design

## The Dream (from user conversation)
Rebuild **The Culling** as a real, complete, playable game in Godot 4 that could eventually go to console.

Not a gamified app. Not a web toy. A real game with weighty melee combat, scavenging risk/reward, brutal traps, and high-stakes 1v1 (scaling to 16-player) battles.

## Core Philosophy (from grok-codex-deepseek-game-fusion panel + supervisor)
- Prove the melee core loop first in the smallest possible arena.
- Every jab, heavy windup, block, and shove must feel incredible before adding networking, big maps, or crafting.
- Hit feedback (hitstop + screenshake) is non-negotiable for "soul".
- Stamina and health close the combat loop.
- Local 2-player testing (hotseat or split) is mandatory for a solo dev to iterate fast.
- Start tiny: 20x20 box, two players, prove the feel → then expand.

## Current Milestone (as of this update)
**Phase 1 complete for the "first 3 + 7" directive:**

- Detailed implementation plan written (`.hermes/plans/2026-06-13-melee-core-loop-local-multiplayer.md`)
- Local 2-player hotseat testing fully wired in MeleeTest.tscn
  - Player 1 (red): WASD + mouse, standard keys
  - Player 2 (blue): IJKL + mouse, U/O/P/; keys
  - On-screen HP + Stamina labels for both
  - Distinct visual colors
- Hitstop + Camera Shake + Screenshake
  - `CameraShake.gd` helper attached to the scene camera
  - Automatic trauma on every successful hit (heavier on heavy attacks)
  - Brief time-slow hitstop on hits
- Stamina system
  - Drains on heavy attacks and blocking
  - Regens when idle
  - Blocks and heavies are gated by stamina
- Health + Death
  - Damage application with block reduction
  - Death signal, visual feedback, elimination from arena
  - ArenaManager can now end matches

All of this is live in the PlayerController.gd and supporting files.

## How to Test Right Now (High Autonomy Playtest Loop)
1. Open the project folder in **Godot 4.3+**.
2. Open `scenes/MeleeTest.tscn`.
3. Run the scene (F5 or Play button).
4. Player 1 controls: WASD to move, mouse to look, LMB light jab, RMB heavy (hold to wind up), Space block, F shove.
5. Player 2 (hotseat): IJKL move, U light, O heavy, P block, ; shove.
6. Attack each other. Watch:
   - Hitstop (brief slow-mo especially on heavies)
   - Camera shake on the top-down view
   - Stamina drain on blocks/heavies
   - Health drop and eventual death
7. While the scene is running, select Player1 or Player2 in the inspector and tweak the @export values (light_attack_damage, heavy_attack_windup, block_reduction, etc.) live. This is the obsessive iteration loop.

When you can have a 30-60 second fight and say "this already feels better than most prototypes", we move to the next phase (wiring ScavengingSystem + TrapSystem into the same tiny arena).

## Next Steps (per the plan)
- Update ArenaManager to properly react to deaths and declare winners.
- Add simple on-hit audio placeholders.
- Wire ScavengingSystem and TrapSystem.
- Add basic cover/walls to the test arena.
- Then full local split-screen if hotseat is not enough.

## Non-Negotiables
- Melee feel is the only thing that matters right now.
- No scope creep into full 16-player, netcode, or big maps until the tiny arena feels nasty.
- High autonomy execution: the agent will continue implementing the plan tasks without hand-holding.

This document was updated after completing the first wave of core loop improvements (local 2P + hitstop/shake + stamina + health/death).
