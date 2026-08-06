# The Culling - Melee Core Loop & Local 2-Player Testing Implementation Plan

> **For Hermes & Subagents:** Use subagent-driven-development skill to implement this plan task-by-task with two-stage review (spec compliance then code quality). This is Phase 1 of the real game build per the grok-codex-deepseek-game-fusion decision (ITERATE on melee feel first in tiny arenas).

**Goal:** Ruthlessly prototype and prove the core melee combat loop (light jab, committed heavy, block, shove) feels incredible in the smallest possible arena. Add local 2-player testing (hotseat / same-keyboard or basic split-screen) so the solo dev can immediately playtest against another instance. Then layer in hitstop, screenshake, stamina, and health/death as the first concrete improvements.

**Architecture:** 
- Keep everything in GDScript for rapid iteration (Godot 4).
- PlayerController is the single source of truth for "feel".
- MeleeTest.tscn is the disposable rapid-prototyping arena (tiny 20x20 box with two players).
- All tuning exposed via @export for live tweaking in editor.
- Local multiplayer starts simple (two CharacterBody3D instances + shared physics + separate input actions or hotseat key remapping) before full split-screen Viewports.

**Tech Stack:** Godot 4.3+ (GDScript), no external plugins yet. Input map already defined in project.godot.

**Current State (as of this plan):**
- Basic PlayerController.gd with movement + first-pass melee (light/heavy/block/shove) using Area3D hitbox.
- MeleeTest.tscn with two Player instances + ArenaManager stub.
- Scavenging and Trap systems exist but not yet wired.
- No hit feedback, no resources (stamina/health), no death, no camera feel.
- Fusion directive: Prove melee before networking, full arenas, or crafting.

**Principles Applied:**
- TDD where possible (even in GDScript: use assertions in test scenes or simple print + manual verification).
- Bite-sized tasks (2-8 minutes each).
- Frequent "commits" via file writes + notes.
- YAGNI: Only add what's needed for feel testing right now.
- High autonomy: Execute without asking unless destructive.

**Files Likely to Change:**
- /home/buidl/TheCullingGodot/scripts/PlayerController.gd (main)
- /home/buidl/TheCullingGodot/scenes/MeleeTest.tscn (for 2-player setup)
- /home/buidl/TheCullingGodot/scripts/ArenaManager.gd (minor)
- /home/buidl/TheCullingGodot/DESIGN.md + PLAN.md (update status)
- New: /home/buidl/TheCullingGodot/scripts/CameraShake.gd (helper)
- New: Input actions for player 2 if needed

**Validation / Playtest Criteria (after each major group of tasks):**
- Open MeleeTest.tscn in Godot.
- Player 1 (WASD + mouse + LMB/RMB/Space/F) feels responsive.
- Player 2 (hotseat keys or second device) can move and melee independently.
- Attacks produce visible/audible (placeholder) feedback.
- Heavy attack has clear windup commitment.
- Block reduces incoming damage.
- Shove creates space.
- When health reaches 0, player dies (disappears or ragdoll stub) and match ends via ArenaManager.
- You can have a 30-second "fight" and say "this already feels better than most prototypes."

**Risks & Tradeoffs:**
- Full split-screen is more code — start with hotseat/same-keyboard + two players to get testing fast (per "start with number 7").
- Over-tuning too early — keep values as @export and document a "tuning session".
- No real animations yet — use scale tween or color flash for hitstop as placeholder.
- Godot not installed in the agent env — all changes are code + instructions for user to test.

---

## Task 0: Write & Commit This Plan (Number 7 starter — already in progress)

**Objective:** Formalize the work so subagents (or future self) can execute cleanly.

**Files:**
- Create: /home/buidl/TheCullingGodot/.hermes/plans/2026-06-13-melee-core-loop-local-multiplayer.md (this file)

**Steps:**
1. Write the full plan using the writing-plans / plan skill style.
2. Also update the root PLAN.md with a pointer to this file.
3. Note the plan in DESIGN.md.

**Verification:** Plan file exists and is readable. "Start with number 7" complete.

---

## Task 1: Set Up Local 2-Player Testing in MeleeTest Scene (Start with number 7)

**Objective:** Make it possible to test two players immediately on the same machine (hotseat with different keys or basic simultaneous control) so the dev can fight "the other player" right away. This is the foundation for obsessive playtesting.

**Files:**
- Modify: /home/buidl/TheCullingGodot/scenes/MeleeTest.tscn (add second player instance + labels + instructions)
- Modify: /home/buidl/TheCullingGodot/scripts/MeleeTestScene.gd (add player registration and simple "player 2 controls" notes)
- Possibly add temporary input actions in project.godot for player 2 if hotseat keys conflict

**Step 1: Add second player to the scene**
```gdscript
# In MeleeTest.tscn (via editor or scene file edit)
# Duplicate Player1 as Player2 at a different spawn position (e.g. x = +4)
# Give it a different color tint for visual distinction (MeshInstance modulate)
```

**Step 2: Update MeleeTestScene.gd**
```gdscript
extends Node3D

@onready var player1: PlayerController = $Player1
@onready var player2: PlayerController = $Player2
@onready var arena: ArenaManager = $ArenaManager

func _ready():
    print("=== MELEE FEEL + LOCAL 2P TEST SCENE ===")
    print("Player 1: WASD + Mouse | LMB=Light | RMB=Heavy | Space=Block | F=Shove")
    print("Player 2 (hotseat): IJKL or Arrow keys + U=Light | O=Heavy | P=Block | ; =Shove (or document and use same keys for now)")
    arena.register_player(player1)
    arena.register_player(player2)
    # Later: different input maps per player
```

**Step 3: Make PlayerController support multiple players (minimal)**
Add a simple `player_id` export and conditional input if we want separate actions later. For hotseat start, both can share the same actions (one person switches focus or use two keyboards/controllers).

**Step 4: Run / verify**
- Open scene in Godot
- Both players exist and move
- They can attack each other via the shared melee hitbox logic (already works because of Area3D)

**Verification:** Two distinct player capsules in the scene. Both can be moved and attack. ArenaManager sees both. Print statements confirm registration. This completes the "start with number 7".

---

## Task 2: Add Hitstop + Camera Shake + Screenshake to PlayerController (First of the first 3)

**Objective:** Give every successful melee hit immediate, juicy feedback so attacks feel weighty. This is the #1 "soul" item per the fusion panel.

**Files:**
- Modify: /home/buidl/TheCullingGodot/scripts/PlayerController.gd (add shake and hitstop logic)
- Create: /home/buidl/TheCullingGodot/scripts/CameraShake.gd (reusable helper)

**Step 1: Create simple CameraShake helper**
```gdscript
# scripts/CameraShake.gd
extends Node
class_name CameraShake

var camera: Camera3D
var trauma: float = 0.0
var trauma_decay: float = 0.8

func _ready():
    if get_parent() is Camera3D:
        camera = get_parent()

func add_trauma(amount: float):
    trauma = min(trauma + amount, 1.0)

func _process(delta):
    if not camera or trauma <= 0: return
    trauma = max(trauma - trauma_decay * delta, 0)
    var shake = trauma * trauma
    camera.h_offset = randf_range(-1,1) * shake * 0.15
    camera.v_offset = randf_range(-1,1) * shake * 0.15
```

**Step 2: Integrate into PlayerController**
- In _ready: attach or reference the shake node on the camera.
- In _on_melee_hit: call camera_shake.add_trauma(0.6 if is_heavy else 0.35)
- Add hitstop: 
```gdscript
func apply_hitstop(duration: float = 0.08):
    # Simple time-scale hitstop
    Engine.time_scale = 0.1
    await get_tree().create_timer(duration).timeout
    Engine.time_scale = 1.0
```
Call apply_hitstop() right after landing a hit (before or after damage).

**Step 3: Call from melee functions**
After successful _on_melee_hit or when hitbox connects.

**Verification:** In Godot, attack another player. Camera should shake on hit. Brief slow-mo on heavy hits. Feels more "punchy".

---

## Task 3: Add Stamina System (Second of the first 3)

**Objective:** Make blocking and heavy attacks have meaningful cost and risk. Heavy attacks should feel like a commitment.

**Files:**
- Modify: /home/buidl/TheCullingGodot/scripts/PlayerController.gd

**Step 1: Add vars**
```gdscript
@export var max_stamina: float = 100.0
@export var stamina_regen: float = 25.0
var stamina: float = 100.0
var is_exhausted: bool = false
```

**Step 2: Drain in combat functions**
- In start_block(): if stamina < block_stamina_cost: return; else stamina -= ...
- In perform_heavy_attack(): stamina -= 35 (or similar)
- In _physics_process: regen when not blocking/attacking

**Step 3: Gate actions**
```gdscript
if stamina < 20 and is_blocking:
    end_block()
```

**Step 4: UI placeholder**
Add a simple stamina bar label or later a ProgressBar in a CanvasLayer.

**Verification:** You cannot block forever. Heavy attacks are expensive. Stamina visibly drains and regens.

---

## Task 4: Add Health + Death (Third of the first 3)

**Objective:** Close the combat loop — players can actually die and matches have winners.

**Files:**
- Modify: /home/buidl/TheCullingGodot/scripts/PlayerController.gd
- Modify: /home/buidl/TheCullingGodot/scripts/ArenaManager.gd (listen for deaths)

**Step 1: Add health to PlayerController**
```gdscript
@export var max_health: int = 100
var health: int = 100

func take_damage(amount: int, attacker: Node):
    if is_blocking:
        amount = int(amount * (1.0 - block_reduction))
    health = max(health - amount, 0)
    print(name, " health:", health)
    if health <= 0:
        die(attacker)

func die(attacker: Node):
    print(name, " died to ", attacker.name)
    player_died.emit()
    # Simple death: disable, hide, or queue_free after delay
    set_physics_process(false)
    visible = false
```

**Step 2: Wire ArenaManager**
Already has `player_died` signal connection and win logic. Make sure it calls when health hits zero.

**Step 3: Add death feedback**
Simple: change mesh color to red, play a sound placeholder (AudioStreamPlayer), slight scale tween.

**Verification:** After enough damage, player dies. ArenaManager detects only one (or zero) players left and emits match_ended. The surviving player "wins" the test match.

---

## Task 5: Integration & Obsessive Playtest Loop (Complete the first 3 + 7)

**Objective:** Make sure everything works together in MeleeTest.tscn. Document a 10-minute playtest ritual.

**Files:**
- Update DESIGN.md and the root PLAN.md with status
- Add a small CanvasLayer in MeleeTest.tscn with "Health / Stamina" labels for both players (quick visual feedback)

**Steps:**
1. Wire the new systems into the test scene.
2. Add on-screen debug labels (health/stamina).
3. Write a short "How to playtest" section at the bottom of this plan.
4. Run the scene (user side) and iterate on the @export values in the inspector.

**Playtest Ritual (for the solo dev):**
1. Open MeleeTest.tscn
2. Select Player1 and tweak light_attack_cooldown, heavy_attack_windup, block_reduction, etc.
3. Play the scene.
4. Fight the second player for 30-60 seconds.
5. Note what feels bad (too floaty? not enough hitstop? stamina drains too fast?).
6. Stop, tweak exports, repeat.
7. When you say "this jab feels nasty and the heavy has weight", we are ready for the next phase (scavenging + traps).

**Next After This Plan:**
- Once these tasks pass review, move to wiring ScavengingSystem + TrapSystem into the same tiny arena.
- Then expand the arena with walls/cover.
- Then full split-screen if hotseat is not enough.

**End of Plan**

This plan was created by following the user's directive: "Start with number 7 then work through the first 3".

High autonomy execution begins immediately after plan is saved.
