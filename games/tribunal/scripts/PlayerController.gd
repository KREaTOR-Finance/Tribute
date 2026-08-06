# PlayerController.gd
# The heart of The Culling: weighty, impactful melee combat.
# Goal: every jab, charged attack, block, shove must feel satisfying and consequential.
# This is the #1 thing to obsess over in the tiny test arena before anything else.
#
# Continued melee focus (post Phase 1):
# - Knockback + hit reactions on receiver
# - Hit particles (integrated with HitParticles.tscn)
# - Improved attack tweens/feedback for windup and impact
# - Basic weapon system (equip, different attack profiles for light/heavy)
#
# humanoid-players-1: Proper low-poly humanoid visuals (procedural glb) replace capsules.
# Team-colored variants (red for P1, blue for P2) + subtle modulate.
# CollisionShape3D capsule remains for reliable physics.
# Hand node + WeaponVisual for weapon grip on the humanoid.

extends CharacterBody3D
class_name PlayerController

@export var player_id: int = 1  # 1 or 2 for local multiplayer input separation

# === MOVEMENT (weighty Culling locomotion) ===
@export var move_speed: float = 6.0
@export var sprint_speed: float = 8.4
@export var acceleration: float = 38.0
@export var friction: float = 28.0
@export var air_control: float = 0.35
@export var jump_velocity: float = 6.0
@export var sprint_stamina_cost: float = 18.0
@export var attack_lunge: float = 3.2

# === MELEE FEEL TUNING (these are the soul — tweak obsessively in inspector) ===
# These are the BASE values. When a weapon is equipped, they are overridden by the weapon's profile.
@export var light_attack_damage: int = 12
@export var light_attack_cooldown: float = 0.35
@export var heavy_attack_damage: int = 35
@export var heavy_attack_windup: float = 0.55
@export var heavy_attack_cooldown: float = 0.9
@export var block_reduction: float = 0.65  # 0.65 = 65% damage reduction while blocking
@export var block_stamina_cost: float = 18.0
@export var perfect_block_window: float = 0.15  # first 0.15s of block = full mitigate
@export var shove_force: float = 18.0
@export var shove_cooldown: float = 1.0
@export var dodge_stamina_cost: float = 15.0
@export var dodge_duration: float = 0.28
@export var dodge_iframe_duration: float = 0.20
@export var dodge_burst_speed: float = 11.0
@export var dodge_cooldown: float = 0.45

# === RESOURCES (added in task 3 & 4) ===
@export var max_health: int = 100
@export var max_stamina: float = 100.0
@export var stamina_regen: float = 22.0

# === MELEE REACTION TUNING (new for knockback + juice) ===
@export var hit_knockback_force: float = 12.0
@export var hit_reaction_duration: float = 0.18
@export var heavy_knockback_multiplier: float = 1.6

# === TRIBUNAL UNIQUE: Judgement Chain ===
# Land hits within the window to build chain. At 3+, next heavy is Judgement (free STA + bonus dmg + gold FX).
@export var chain_window: float = 0.9
@export var chain_judgement_threshold: int = 3
@export var judgement_damage_mul: float = 1.35
@export var pad_look_sens: float = 2.6
@export var attack_buffer_time: float = 0.14

var health: int = 100
var stamina: float = 100.0
var is_exhausted: bool = false
var judgement_chain: int = 0
var chain_timer: float = 0.0
var judgement_ready: bool = false
var _attack_buffer: String = ""  # "light" | "heavy" | ""
var _attack_buffer_t: float = 0.0
var _chain_mats: Array = []

# === CULLING MELEE STATE MACHINE ===
enum MeleeState { IDLE, LIGHT_ACTIVE, LIGHT_RECOVERY, HEAVY_WINDUP, HEAVY_ACTIVE, HEAVY_RECOVERY, BLOCKING, SHOVING, DODGING, DEAD }
var melee_state: MeleeState = MeleeState.IDLE
var state_time: float = 0.0
var hit_this_swing: Dictionary = {}  # instance_id -> true, once per swing
var active_is_heavy: bool = false
var local_hitstop: float = 0.0  # local slow (not global Engine.time_scale)
var invuln_timer: float = 0.0  # i-frames during dodge
var block_hold_time: float = 0.0  # time spent in current block (for perfect window)
var dodge_cooldown_timer: float = 0.0
var dodge_dir: Vector3 = Vector3.ZERO

# legacy flags kept in sync for any external reads
var is_blocking: bool = false
var is_winding_heavy: bool = false
var is_dodging: bool = false
var windup_timer: float = 0.0
var attack_cooldown_timer: float = 0.0
var shove_cooldown_timer: float = 0.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var mesh_instance: MeshInstance3D
var melee_hitbox: Area3D
var camera: Camera3D
var camera_shake: CameraShake

# === WEAPON SYSTEM (melee-continue-2) ===
var current_weapon: Weapon = null
var base_light_damage: int
var base_light_cooldown: float
var base_heavy_damage: int
var base_heavy_windup: float
var base_heavy_cooldown: float
var base_knockback_multiplier: float = 1.0

# Signals for ArenaManager and UI
signal player_died
signal health_changed(new_health: int)
signal stamina_changed(new_stamina: float)
signal weapon_equipped(weapon_name: String)
signal judgement_chain_changed(chain: int, ready: bool)

# Preload for particles (will be instantiated on hits)
const HitParticlesScene = preload("res://scripts/HitParticles.tscn")
const SkinCat = preload("res://scripts/SkinCatalog.gd")
const CharSkinScript = preload("res://scripts/CharacterSkin.gd")
const CharAnimScript = preload("res://scripts/CharacterAnimator.gd")
const CombatAudioScript = preload("res://scripts/CombatAudio.gd")

var character_skin_id: String = ""
var weapon_skin_id: String = ""
var _char_skin = null
var _char_anim = null
var _combat_audio = null
var _follow_cam = null  # FollowCamera if present in scene
var _is_sprinting: bool = false
var _move_input: Vector2 = Vector2.ZERO

# === HUMANNOID VISUAL HELPERS (humanoid-players-1) ===
# Load the pre-generated low-poly humanoid glb at runtime and replace the capsule mesh.
# Colored variants (red/blue) give instant team distinction; modulate adds subtle extra tint.
# Feet are aligned by offsetting the mesh_instance position.
func _find_mesh_in_scene(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D and node.mesh != null:
		return node
	for child in node.get_children():
		var result = _find_mesh_in_scene(child)
		if result:
			return result
	return null

func _team_color() -> Color:
	return Color(0.22, 0.45, 0.95) if player_id == 2 else Color(0.9, 0.18, 0.15)


func _apply_body_material(mi: MeshInstance3D, color: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.55
	mat.metallic = 0.12
	mi.material_override = mat


func _build_culling_body() -> void:
	## Reliable Culling-style low-poly body when glb imports are unavailable.
	if not mesh_instance:
		return
	var body := CapsuleMesh.new()
	body.radius = 0.38
	body.height = 1.35
	mesh_instance.mesh = body
	mesh_instance.position = Vector3(0, 0.95, 0)
	mesh_instance.scale = Vector3.ONE
	_apply_body_material(mesh_instance, _team_color())
	# Head
	var head := MeshInstance3D.new()
	head.name = "Head"
	var hs := SphereMesh.new()
	hs.radius = 0.22
	head.mesh = hs
	head.position = Vector3(0, 1.85, 0)
	_apply_body_material(head, _team_color().lightened(0.15))
	add_child(head)
	print("Culling body built for ", name)


func _load_humanoid_visual():
	if not mesh_instance:
		return
	var glb_path = "res://assets/models/characters/lowpoly_humanoid_red.glb"
	if player_id == 2:
		glb_path = "res://assets/models/characters/lowpoly_humanoid_blue.glb"
	var humanoid_res = null
	if ResourceLoader.exists(glb_path):
		humanoid_res = load(glb_path)
	if humanoid_res == null and ResourceLoader.exists("res://assets/models/characters/lowpoly_humanoid.glb"):
		humanoid_res = load("res://assets/models/characters/lowpoly_humanoid.glb")
	if humanoid_res is PackedScene:
		var inst = humanoid_res.instantiate()
		var found = _find_mesh_in_scene(inst)
		if found and found.mesh:
			mesh_instance.mesh = found.mesh
			mesh_instance.position = Vector3(0, -0.32, 0)
			mesh_instance.scale = Vector3(0.92, 0.92, 0.92)
			_apply_body_material(mesh_instance, _team_color())
			inst.queue_free()
			print("Humanoid glb loaded for ", name)
			return
		inst.queue_free()
	_build_culling_body()


func _ready():
	add_to_group("players")
	add_to_group("damageable")
	mesh_instance = $MeshInstance3D
	melee_hitbox = $MeleeHitbox
	camera = get_node_or_null("Camera3D")

	# Resolve shake: on self, parent, or scene camera (MeleeTest: Camera3D/CameraShake)
	if has_node("CameraShake"):
		camera_shake = $CameraShake
	else:
		var parent = get_parent()
		if parent:
			if parent.has_node("CameraShake"):
				camera_shake = parent.get_node("CameraShake")
			elif parent.has_node("Camera3D/CameraShake"):
				camera_shake = parent.get_node("Camera3D/CameraShake")

	health = max_health
	stamina = max_stamina
	base_light_damage = light_attack_damage
	base_light_cooldown = light_attack_cooldown
	base_heavy_damage = heavy_attack_damage
	base_heavy_windup = heavy_attack_windup
	base_heavy_cooldown = heavy_attack_cooldown

	_load_humanoid_visual()
	_ensure_hand_weapon_visual()
	# Art skins (poseable SkinRig) + animator for move/action poses
	character_skin_id = SkinCat.default_character_skin(player_id)
	weapon_skin_id = SkinCat.default_weapon_skin(1)
	_char_skin = CharSkinScript.new()
	add_child(_char_skin)
	_char_skin.apply_to_player(self, character_skin_id)
	_char_anim = CharAnimScript.new()
	_char_anim.name = "CharacterAnimator"
	add_child(_char_anim)
	_char_anim.bind(self)
	_combat_audio = CombatAudioScript.new()
	_combat_audio.name = "CombatAudio"
	add_child(_combat_audio)
	_combat_audio.bind(self)
	_resolve_follow_camera()
	_apply_weapon_skin_to_hand()

	# Forward melee hitbox (Culling reach)
	if melee_hitbox:
		melee_hitbox.position = Vector3(0, 1.0, -1.1)
		var hb_shape = melee_hitbox.get_node_or_null("CollisionShape3D")
		if hb_shape and hb_shape.shape is CapsuleShape3D:
			var cap := hb_shape.shape as CapsuleShape3D
			cap.radius = 0.55
			cap.height = 1.2
		if not melee_hitbox.body_entered.is_connected(_on_melee_hit):
			melee_hitbox.body_entered.connect(_on_melee_hit)
		melee_hitbox.monitoring = false
		melee_hitbox.collision_mask = 0xFFFFFFFF

	print(name, " ready (Player ", player_id, ") — Culling melee soul")

func equip_weapon(weapon: Weapon):
	if not weapon:
		return

	current_weapon = weapon

	# Override melee values with weapon profile
	light_attack_damage = weapon.get_light_damage()
	light_attack_cooldown = weapon.get_light_cooldown()
	heavy_attack_damage = weapon.get_heavy_damage()
	heavy_attack_windup = weapon.get_heavy_windup()
	heavy_attack_cooldown = weapon.get_heavy_cooldown()

	# Store weapon's knockback multiplier for use in hit reactions
	base_knockback_multiplier = weapon.get_knockback_multiplier()
	_sync_melee_hitbox_reach()

	weapon_equipped.emit(weapon.weapon_name)
	print(name, " equipped ", weapon.weapon_name, " reach L/H=", _weapon_reach(false), "/", _weapon_reach(true))

func unequip_weapon():
	if current_weapon:
		# Restore base values
		light_attack_damage = base_light_damage
		light_attack_cooldown = base_light_cooldown
		heavy_attack_damage = base_heavy_damage
		heavy_attack_windup = base_heavy_windup
		heavy_attack_cooldown = base_heavy_cooldown
		base_knockback_multiplier = 1.0
		
		current_weapon = null
		weapon_equipped.emit("None")
		print(name, " unequipped weapon")

var _mouse_yaw: float = 0.0
var _mouse_pitch: float = 0.0
const MOUSE_SENS := 0.0025


func _unhandled_input(event):
	# Mouse look (Culling third-person / free look for melee spacing)
	if player_id == 1 and event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_mouse_yaw -= event.relative.x * MOUSE_SENS
		_mouse_pitch = clampf(_mouse_pitch - event.relative.y * MOUSE_SENS, deg_to_rad(-50), deg_to_rad(30))
		rotation.y = _mouse_yaw
	_handle_combat_input(event)


func _set_melee_state(s: MeleeState, duration: float = 0.0) -> void:
	melee_state = s
	state_time = duration
	is_blocking = (s == MeleeState.BLOCKING)
	is_winding_heavy = (s == MeleeState.HEAVY_WINDUP)
	is_dodging = (s == MeleeState.DODGING)
	if s == MeleeState.BLOCKING:
		block_hold_time = 0.0
	if s == MeleeState.LIGHT_ACTIVE or s == MeleeState.HEAVY_ACTIVE or s == MeleeState.HEAVY_WINDUP:
		hit_this_swing.clear()
	if s == MeleeState.HEAVY_ACTIVE:
		active_is_heavy = true
	elif s == MeleeState.LIGHT_ACTIVE:
		active_is_heavy = false
	_sync_action_pose(s, duration)


func _sync_action_pose(s: MeleeState, duration: float) -> void:
	if _char_anim == null:
		return
	match s:
		MeleeState.IDLE, MeleeState.LIGHT_RECOVERY, MeleeState.HEAVY_RECOVERY:
			if _is_sprinting and _move_input.length() > 0.1:
				_char_anim.set_pose(CharAnimScript.Pose.SPRINT)
			elif _move_input.length() > 0.1:
				_char_anim.set_pose(CharAnimScript.Pose.WALK)
			else:
				_char_anim.set_pose(CharAnimScript.Pose.IDLE)
		MeleeState.LIGHT_ACTIVE:
			_char_anim.set_pose(CharAnimScript.Pose.LIGHT_SWING, duration if duration > 0.0 else 0.10)
		MeleeState.HEAVY_WINDUP:
			_char_anim.set_pose(CharAnimScript.Pose.HEAVY_WINDUP, duration if duration > 0.0 else heavy_attack_windup)
		MeleeState.HEAVY_ACTIVE:
			_char_anim.set_pose(CharAnimScript.Pose.HEAVY_SWING, duration if duration > 0.0 else 0.14)
		MeleeState.BLOCKING:
			_char_anim.set_pose(CharAnimScript.Pose.BLOCK)
		MeleeState.SHOVING:
			_char_anim.set_pose(CharAnimScript.Pose.SHOVE, duration if duration > 0.0 else 0.18)
		MeleeState.DODGING:
			_char_anim.set_pose(CharAnimScript.Pose.DODGE, duration if duration > 0.0 else dodge_duration)
		MeleeState.DEAD:
			_char_anim.set_pose(CharAnimScript.Pose.DEAD)
		_:
			_char_anim.set_pose(CharAnimScript.Pose.IDLE)


func _can_act() -> bool:
	return melee_state in [MeleeState.IDLE, MeleeState.LIGHT_RECOVERY, MeleeState.HEAVY_RECOVERY]


func _wants_sprint() -> bool:
	if player_id == 1:
		if InputMap.has_action("sprint") and Input.is_action_pressed("sprint"):
			return true
		return Input.is_key_pressed(KEY_SHIFT)
	# P2: Ctrl
	return Input.is_key_pressed(KEY_CTRL)


func _physics_process(delta: float):
	if melee_state == MeleeState.DEAD:
		return
	# Local hitstop: freeze combat tick presentation without global time_scale
	var step := delta
	if local_hitstop > 0.0:
		local_hitstop = max(0.0, local_hitstop - delta)
		step = delta * 0.15

	# Judgement chain decay
	if chain_timer > 0.0:
		chain_timer = maxf(0.0, chain_timer - step)
		if chain_timer <= 0.0 and judgement_chain > 0:
			_set_chain(0)
	# Attack input buffer flush
	if _attack_buffer_t > 0.0:
		_attack_buffer_t = maxf(0.0, _attack_buffer_t - step)
		if _attack_buffer_t <= 0.0:
			_attack_buffer = ""
		elif _can_act():
			var buf := _attack_buffer
			_attack_buffer = ""
			_attack_buffer_t = 0.0
			if buf == "light":
				_perform_light_attack()
			elif buf == "heavy":
				start_heavy_windup()

	# Gamepad right-stick look (P1) — seamless camera/facing
	if player_id == 1:
		_apply_pad_look(step)

	if not is_on_floor():
		velocity.y -= gravity * step

	var input_dir = _get_movement_input()
	_move_input = input_dir

	# Sprint (Culling chase) — burns stamina, blocked during heavy commit
	_is_sprinting = false
	var base_spd := move_speed
	if _wants_sprint() and input_dir.length() > 0.1 and stamina > 5.0 \
			and melee_state in [MeleeState.IDLE, MeleeState.LIGHT_RECOVERY, MeleeState.HEAVY_RECOVERY]:
		_is_sprinting = true
		base_spd = sprint_speed
		stamina = max(0.0, stamina - sprint_stamina_cost * step)
		stamina_changed.emit(stamina)
		if stamina <= 0.0:
			_is_sprinting = false
			base_spd = move_speed

	var speed_mul := 1.0
	match melee_state:
		MeleeState.BLOCKING:
			speed_mul = 0.48
		MeleeState.HEAVY_WINDUP:
			speed_mul = 0.32
		MeleeState.HEAVY_ACTIVE:
			speed_mul = 0.55
		MeleeState.LIGHT_ACTIVE:
			speed_mul = 0.82
		MeleeState.SHOVING:
			speed_mul = 0.7
		MeleeState.DODGING:
			speed_mul = 0.0  # burst-driven; ignore normal steer
		MeleeState.LIGHT_RECOVERY, MeleeState.HEAVY_RECOVERY:
			speed_mul = 0.88
		_:
			speed_mul = 1.0

	if invuln_timer > 0.0:
		invuln_timer = max(0.0, invuln_timer - step)
	if dodge_cooldown_timer > 0.0:
		dodge_cooldown_timer = max(0.0, dodge_cooldown_timer - step)

	if melee_state == MeleeState.DODGING and dodge_dir.length_squared() > 0.01:
		# Sideways/back burst — hold direction through dodge window
		var burst := dodge_dir * dodge_burst_speed
		velocity.x = burst.x
		velocity.z = burst.z
	else:
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		var accel := acceleration
		if not is_on_floor():
			accel *= air_control
		var target_spd := base_spd * speed_mul
		if direction:
			velocity.x = move_toward(velocity.x, direction.x * target_spd, accel * step)
			velocity.z = move_toward(velocity.z, direction.z * target_spd, accel * step)
		else:
			var fric := friction if is_on_floor() else friction * 0.15
			velocity.x = move_toward(velocity.x, 0, fric * step)
			velocity.z = move_toward(velocity.z, 0, fric * step)
	move_and_slide()

	# Feed locomotion to character art + footfalls
	var hspd := Vector2(velocity.x, velocity.z).length()
	if _char_anim:
		_char_anim.set_move_blend(hspd, sprint_speed, _is_sprinting)
		# Keep walk/idle pose when not in special combat pose
		if melee_state in [MeleeState.IDLE, MeleeState.LIGHT_RECOVERY, MeleeState.HEAVY_RECOVERY]:
			if _is_sprinting and hspd > 0.4:
				_char_anim.set_pose(CharAnimScript.Pose.SPRINT)
			elif hspd > 0.35:
				_char_anim.set_pose(CharAnimScript.Pose.WALK)
			else:
				_char_anim.set_pose(CharAnimScript.Pose.IDLE)
	if _combat_audio:
		_combat_audio.tick_footsteps(step, hspd, _is_sprinting, is_on_floor())

	if shove_cooldown_timer > 0:
		shove_cooldown_timer -= step
	attack_cooldown_timer = 0.0 if _can_act() else 0.2

	# Continuous active-frame traces (Culling soul)
	if melee_state == MeleeState.LIGHT_ACTIVE or melee_state == MeleeState.HEAVY_ACTIVE:
		_melee_shape_query(active_is_heavy)
		if melee_hitbox:
			melee_hitbox.monitoring = true
	elif melee_hitbox:
		melee_hitbox.monitoring = false

	# State machine advance
	if state_time > 0.0:
		state_time -= step
		if state_time <= 0.0:
			_advance_melee_state()

	# Stamina + perfect-block window clock
	if melee_state == MeleeState.BLOCKING and stamina > 0:
		block_hold_time += step
		stamina -= block_stamina_cost * step * 0.5
		stamina_changed.emit(stamina)
		if stamina <= 0:
			_set_melee_state(MeleeState.IDLE)
	elif melee_state == MeleeState.IDLE and not _is_sprinting and stamina < max_stamina:
		stamina = min(stamina + stamina_regen * step, max_stamina)
		stamina_changed.emit(stamina)


func _advance_melee_state() -> void:
	match melee_state:
		MeleeState.LIGHT_ACTIVE:
			_set_melee_state(MeleeState.LIGHT_RECOVERY, light_attack_cooldown * 0.7)
		MeleeState.LIGHT_RECOVERY:
			_set_melee_state(MeleeState.IDLE)
		MeleeState.HEAVY_WINDUP:
			_set_melee_state(MeleeState.HEAVY_ACTIVE, 0.14)
			# Commit lunge into heavy strike
			var fwd := -global_transform.basis.z
			velocity += fwd * attack_lunge * 1.35
		MeleeState.HEAVY_ACTIVE:
			_set_melee_state(MeleeState.HEAVY_RECOVERY, heavy_attack_cooldown * 0.65)
		MeleeState.HEAVY_RECOVERY:
			_set_melee_state(MeleeState.IDLE)
		MeleeState.SHOVING:
			_set_melee_state(MeleeState.IDLE)
		MeleeState.DODGING:
			is_dodging = false
			dodge_dir = Vector3.ZERO
			_set_melee_state(MeleeState.IDLE)
		_:
			_set_melee_state(MeleeState.IDLE)

func _get_movement_input() -> Vector2:
	var input = Vector2.ZERO
	if player_id == 1:
		# Strength-based = seamless stick + keys
		input.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
		input.y = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	else:
		if Input.is_action_pressed("p2_move_forward"):  input.y -= 1
		if Input.is_action_pressed("p2_move_backward"): input.y += 1
		if Input.is_action_pressed("p2_move_left"):     input.x -= 1
		if Input.is_action_pressed("p2_move_right"):    input.x += 1
	if input.length() > 1.0:
		input = input.normalized()
	elif input.length() < 0.18:
		input = Vector2.ZERO
	return input


func _apply_pad_look(delta: float) -> void:
	if not InputMap.has_action("look_left"):
		return
	var lx := Input.get_action_strength("look_right") - Input.get_action_strength("look_left")
	var ly := Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
	if absf(lx) < 0.12:
		lx = 0.0
	if absf(ly) < 0.12:
		ly = 0.0
	if lx == 0.0 and ly == 0.0:
		return
	_mouse_yaw -= lx * pad_look_sens * delta
	_mouse_pitch = clampf(_mouse_pitch - ly * pad_look_sens * 0.65 * delta, deg_to_rad(-50), deg_to_rad(30))
	rotation.y = _mouse_yaw


func _queue_attack(kind: String) -> void:
	if _can_act():
		if kind == "light":
			_perform_light_attack()
		else:
			start_heavy_windup()
	else:
		_attack_buffer = kind
		_attack_buffer_t = attack_buffer_time


func _handle_combat_input(event):
	if (player_id == 1 and event.is_action_pressed("light_attack")) or (player_id == 2 and event.is_action_pressed("p2_light_attack")):
		_queue_attack("light")
	if (player_id == 1 and event.is_action_pressed("heavy_attack")) or (player_id == 2 and event.is_action_pressed("p2_heavy_attack")):
		_queue_attack("heavy")
	if (player_id == 1 and event.is_action_pressed("block")) or (player_id == 2 and event.is_action_pressed("p2_block")):
		start_block()
	elif (player_id == 1 and event.is_action_released("block")) or (player_id == 2 and event.is_action_released("p2_block")):
		end_block()
	if (player_id == 1 and event.is_action_pressed("shove")) or (player_id == 2 and event.is_action_pressed("p2_shove")):
		_perform_shove()

	# Dodge — keys + pad action
	if player_id == 1 and event.is_action_pressed("dodge"):
		_perform_dodge()
	if event is InputEventKey and event.pressed and not event.echo:
		var kc: int = event.keycode
		var pkc: int = event.physical_keycode
		if player_id == 1 and (kc == KEY_C or pkc == KEY_C or kc == KEY_ALT or pkc == KEY_ALT):
			_perform_dodge()
		elif player_id == 2 and (kc == KEY_V or pkc == KEY_V):
			_perform_dodge()

	# Interact / trap via actions (pad) + keys
	if player_id == 1:
		if event.is_action_pressed("interact"):
			_try_scavenge()
		if event.is_action_pressed("place_trap"):
			_try_place_trap()
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_1:
				_equip_test_weapon(Weapon.WeaponType.SWORD)
			elif event.keycode == KEY_2:
				_equip_test_weapon(Weapon.WeaponType.AXE)
			elif event.keycode == KEY_3:
				_equip_test_weapon(Weapon.WeaponType.DAGGER)
			elif event.keycode == KEY_BRACKETLEFT:
				_cycle_character_skin()
			elif event.keycode == KEY_BRACKETRIGHT:
				_cycle_weapon_skin()
			elif event.keycode == KEY_Q:
				_try_place_trap()
			elif event.keycode == KEY_E:
				_try_scavenge()
			elif event.keycode == KEY_T:
				_try_craft()
	elif player_id == 2:
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_4:
				_equip_test_weapon(Weapon.WeaponType.SWORD)
			elif event.keycode == KEY_5:
				_equip_test_weapon(Weapon.WeaponType.AXE)
			elif event.keycode == KEY_6:
				_equip_test_weapon(Weapon.WeaponType.DAGGER)
			elif event.keycode == KEY_APOSTROPHE:
				_cycle_character_skin()
			elif event.keycode == KEY_PERIOD:
				_cycle_weapon_skin()
			elif event.keycode == KEY_B:
				_try_place_trap()
			elif event.keycode == KEY_H:
				_try_scavenge()

func _equip_test_weapon(weapon_type: int):
	var w = Weapon.new()
	w.weapon_type = weapon_type
	w._apply_profile()
	equip_weapon(w)
	weapon_skin_id = SkinCat.default_weapon_skin(int(weapon_type) + 1)
	_apply_weapon_skin_to_hand()


func _try_place_trap() -> void:
	if melee_state == MeleeState.DEAD or melee_state == MeleeState.DODGING:
		return
	var parent = get_parent()
	if parent == null:
		return
	# MeleeTestScene helper or TrapSystem node
	if parent.has_method("place_trap_for"):
		parent.place_trap_for(self, "bear_trap")
		return
	var traps = parent.get_node_or_null("TrapSystem")
	if traps and traps.has_method("place_trap"):
		traps.place_trap(self, "bear_trap")


func _try_scavenge() -> void:
	if melee_state == MeleeState.DEAD or melee_state == MeleeState.HEAVY_WINDUP:
		return
	if melee_state == MeleeState.LIGHT_ACTIVE or melee_state == MeleeState.HEAVY_ACTIVE:
		return
	var parent = get_parent()
	if parent == null:
		return
	var scav = parent.get_node_or_null("ScavengingSystem")
	if scav and scav.has_method("try_begin_scavenge"):
		if scav.try_begin_scavenge(self):
			velocity *= 0.35
			print(name, " holding scavenge channel (stay still)")
		return
	if parent.has_method("try_scavenge_for"):
		parent.try_scavenge_for(self)


func _try_craft() -> void:
	if melee_state == MeleeState.DEAD:
		return
	var parent = get_parent()
	if parent == null:
		return
	var craft = parent.get_node_or_null("CraftingSystem")
	if craft and craft.has_method("try_craft_at_station"):
		craft.try_craft_at_station(self)



func _resolve_follow_camera() -> void:
	_follow_cam = null
	var parent = get_parent()
	if parent and parent.has_node("Camera3D"):
		var cam = parent.get_node("Camera3D")
		if cam is FollowCamera:
			_follow_cam = cam
	# Also accept any FollowCamera in group
	if _follow_cam == null:
		var cams = get_tree().get_nodes_in_group("follow_cameras") if get_tree() else []
		if cams.size() > 0:
			_follow_cam = cams[0]


func _notify_camera_swing(heavy: bool) -> void:
	if _follow_cam and _follow_cam.has_method("frame_swing"):
		_follow_cam.frame_swing(heavy, -global_transform.basis.z)


func _notify_camera_hit(heavy: bool) -> void:
	if _follow_cam and _follow_cam.has_method("frame_hit"):
		_follow_cam.frame_hit(heavy)


func _ensure_hand_weapon_visual() -> void:
	# First-class weapon skins require Hand + WeaponVisual (scene may omit if parse-glitched)
	var hand = get_node_or_null("Hand")
	if hand == null:
		hand = Node3D.new()
		hand.name = "Hand"
		hand.position = Vector3(-0.42, 1.05, 0.25)
		hand.rotation_degrees = Vector3(0, 30, 0)
		add_child(hand)
		print(name, ": created Hand (missing from scene)")
	var wv = hand.get_node_or_null("WeaponVisual")
	if wv == null:
		var WVS = load("res://scripts/WeaponVisual.gd")
		wv = WVS.new()
		wv.name = "WeaponVisual"
		hand.add_child(wv)
		print(name, ": created WeaponVisual (missing from scene)")


func _apply_weapon_skin_to_hand() -> void:
	_ensure_hand_weapon_visual()
	var hand = get_node_or_null("Hand")
	if hand == null:
		return
	var wv = hand.get_node_or_null("WeaponVisual")
	if wv and wv.has_method("set_weapon_type"):
		var wtype := 1
		if current_weapon:
			match current_weapon.weapon_type:
				Weapon.WeaponType.AXE:
					wtype = 2
				Weapon.WeaponType.DAGGER:
					wtype = 3
				_:
					wtype = 1
		wv.set_weapon_type(wtype, weapon_skin_id)


func _cycle_character_skin() -> void:
	if _char_skin and _char_skin.has_method("cycle_skin"):
		character_skin_id = _char_skin.cycle_skin(self)
		if _char_anim:
			_char_anim.bind(self)
		print(name, " character skin -> ", character_skin_id)


func _cycle_weapon_skin() -> void:
	var hand = get_node_or_null("Hand")
	if hand == null:
		return
	var wv = hand.get_node_or_null("WeaponVisual")
	if wv and wv.has_method("cycle_skin"):
		weapon_skin_id = wv.cycle_skin()
		print(name, " weapon skin -> ", weapon_skin_id)

func start_heavy_windup():
	if not _can_act():
		return
	var free_judgement := judgement_ready and judgement_chain >= chain_judgement_threshold
	if not free_judgement and stamina < 25:
		return
	if free_judgement:
		print(name, " JUDGEMENT heavy (chain ", judgement_chain, ")")
	else:
		stamina -= 25
		stamina_changed.emit(stamina)
	_set_melee_state(MeleeState.HEAVY_WINDUP, heavy_attack_windup * (0.85 if free_judgement else 1.0))
	_notify_camera_swing(true)
	if _combat_audio:
		_combat_audio.play_whoosh(true)
	if not free_judgement:
		print(name, " winding heavy (readable commit)...")

func _weapon_range_mul() -> float:
	if current_weapon and current_weapon.has_method("get_range_mul"):
		return current_weapon.get_range_mul()
	if current_weapon:
		return current_weapon.range_mul
	return 1.0


func _weapon_arc() -> float:
	if current_weapon and current_weapon.has_method("get_arc"):
		return current_weapon.get_arc()
	if current_weapon:
		return current_weapon.arc
	return 1.0


func _weapon_reach(heavy: bool) -> float:
	if current_weapon:
		if heavy and current_weapon.has_method("get_heavy_reach"):
			return current_weapon.get_heavy_reach()
		if not heavy and current_weapon.has_method("get_light_reach"):
			return current_weapon.get_light_reach()
		if "heavy_reach" in current_weapon and heavy:
			return float(current_weapon.heavy_reach)
		if "light_reach" in current_weapon and not heavy:
			return float(current_weapon.light_reach)
	# Fallback legacy mul
	return (1.65 if heavy else 1.35) * _weapon_range_mul()


func _weapon_hit_radius(heavy: bool) -> float:
	if current_weapon and current_weapon.has_method("get_hit_radius"):
		return current_weapon.get_hit_radius(heavy)
	var amul := _weapon_arc()
	return (0.7 if heavy else 0.55) * clampf(amul, 0.5, 1.5)


func _sync_melee_hitbox_reach() -> void:
	if melee_hitbox == null:
		return
	var reach := _weapon_reach(false)
	melee_hitbox.position = Vector3(0, 1.0, -reach * 0.82)
	var hb_shape = melee_hitbox.get_node_or_null("CollisionShape3D")
	if hb_shape and hb_shape.shape is CapsuleShape3D:
		var cap := hb_shape.shape as CapsuleShape3D
		var r := _weapon_hit_radius(false)
		cap.radius = r
		cap.height = maxf(0.9, reach * 0.55)


func _melee_shape_query(heavy: bool) -> void:
	var space := get_world_3d().direct_space_state
	var q := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	var amul := _weapon_arc()
	# Distinct tool feel: weapon absolute reach + arc-scaled radius
	sphere.radius = _weapon_hit_radius(heavy) * clampf(amul, 0.75, 1.35)
	q.shape = sphere
	var reach := _weapon_reach(heavy)
	q.transform = Transform3D(Basis(), global_position + Vector3(0, 1.0, 0) + (-global_transform.basis.z) * reach)
	q.exclude = [get_rid()]
	q.collision_mask = 0xFFFFFFFF
	for h in space.intersect_shape(q, 12):
		var col = h.get("collider")
		if col and col is CharacterBody3D:
			_on_melee_hit(col)


func _perform_light_attack():
	if not _can_act() or stamina < 6:
		return
	stamina -= 6
	stamina_changed.emit(stamina)
	_set_melee_state(MeleeState.LIGHT_ACTIVE, 0.10)
	# Short forward lunge into the cut
	var fwd := -global_transform.basis.z
	velocity += fwd * attack_lunge * 0.65
	_notify_camera_swing(false)
	if _combat_audio:
		_combat_audio.play_whoosh(false)
	print(name, " light jab!")

func start_block():
	if not _can_act() or stamina < block_stamina_cost * 0.5:
		return
	block_hold_time = 0.0
	_set_melee_state(MeleeState.BLOCKING)
	if _combat_audio:
		_combat_audio.play_block()
	print(name, " blocking")

func end_block():
	if melee_state == MeleeState.BLOCKING:
		_set_melee_state(MeleeState.IDLE)

func _perform_dodge() -> void:
	if not _can_act() or dodge_cooldown_timer > 0.0 or stamina < dodge_stamina_cost:
		return
	stamina -= dodge_stamina_cost
	stamina_changed.emit(stamina)
	dodge_cooldown_timer = dodge_cooldown
	# Sideways / back preference: use move input, default back if none
	var input_dir := _get_movement_input()
	var local_dir := Vector3(input_dir.x, 0.0, input_dir.y)
	if local_dir.length_squared() < 0.01:
		local_dir = Vector3(0.0, 0.0, 1.0)  # back relative to facing
	else:
		# Bias away from pure forward so dodge is mostly side/back (Culling-style evade)
		if local_dir.z < -0.2:
			local_dir.z = 0.0  # cancel pure forward; keep lateral
		if local_dir.length_squared() < 0.01:
			local_dir = Vector3(0.0, 0.0, 1.0)
	local_dir = local_dir.normalized()
	dodge_dir = (transform.basis * local_dir).normalized()
	invuln_timer = dodge_iframe_duration
	_set_melee_state(MeleeState.DODGING, dodge_duration)
	velocity.x = dodge_dir.x * dodge_burst_speed
	velocity.z = dodge_dir.z * dodge_burst_speed
	velocity.y = maxf(velocity.y, 1.5)
	if _combat_audio:
		_combat_audio.play_whoosh(false)
	print(name, " dodge!")


func _perform_shove():
	if not _can_act() or shove_cooldown_timer > 0 or stamina < 12:
		return
	shove_cooldown_timer = shove_cooldown
	stamina -= 12
	stamina_changed.emit(stamina)
	_set_melee_state(MeleeState.SHOVING, 0.18)
	# Step into the shove
	var fwd := -global_transform.basis.z
	velocity += fwd * attack_lunge * 1.1 + Vector3(0, 1.2, 0)
	_notify_camera_swing(false)
	if _combat_audio:
		_combat_audio.play_whoosh(false)
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.0
	query.shape = sphere
	query.transform = Transform3D(Basis(), global_position + Vector3(0, 1, 0) + (-global_transform.basis.z) * 1.2)
	query.exclude = [get_rid()]
	for result in space_state.intersect_shape(query, 8):
		var body = result.collider
		if body and body is CharacterBody3D and body != self:
			var push_dir = (body.global_position - global_position).normalized()
			body.velocity += push_dir * shove_force + Vector3(0, 3, 0)
			print(name, " shoved ", body.name)

func apply_damage(amount: int, from: Node = null, knockback: float = 0.0) -> void:
	# AI / systems entry point (Tribunal demo)
	take_damage(amount, from)
	if from and knockback > 0.0 and from is Node3D:
		var push_dir = (global_position - from.global_position).normalized()
		velocity += push_dir * knockback + Vector3(0, 2.0, 0)


func heal_partial(amount: int) -> void:
	health = mini(max_health, health + amount)
	health_changed.emit(health)


func _on_melee_hit(body):
	if body == self or not body is CharacterBody3D:
		return
	if melee_state != MeleeState.LIGHT_ACTIVE and melee_state != MeleeState.HEAVY_ACTIVE:
		return
	var id: int = body.get_instance_id()
	if hit_this_swing.has(id):
		return  # once per swing (Culling)
	hit_this_swing[id] = true

	var is_heavy = active_is_heavy or melee_state == MeleeState.HEAVY_ACTIVE
	var is_judgement := is_heavy and judgement_ready and judgement_chain >= chain_judgement_threshold
	var damage = heavy_attack_damage if is_heavy else light_attack_damage
	if is_judgement:
		damage = int(float(damage) * judgement_damage_mul)
	var kb = hit_knockback_force * (heavy_knockback_multiplier if is_heavy else 1.0)
	if is_judgement:
		kb *= 1.25

	if body is PlayerController:
		body.take_damage(damage, self)
	elif body.has_method("apply_damage"):
		body.apply_damage(damage, self, kb)
	elif body.has_method("take_damage"):
		body.take_damage(damage, self)
	else:
		return

	_build_judgement_chain(is_judgement)
	_apply_hit_feedback(is_heavy, is_judgement)
	_spawn_hit_particles(body.global_position, is_heavy or is_judgement)
	if _combat_audio:
		_combat_audio.play_hit(is_heavy or is_judgement)
	_notify_camera_hit(is_heavy or is_judgement)
	if is_judgement:
		_set_chain(0)  # spend Judgement

func _spawn_hit_particles(world_pos: Vector3, is_heavy: bool):
	var scene := get_tree().current_scene
	if scene == null:
		return
	var particles_instance = HitParticlesScene.instantiate()
	scene.add_child(particles_instance)
	# Chest-height offset applied inside HitParticles.spawn_hit
	particles_instance.spawn_hit(world_pos, Vector3.UP, is_heavy)


func _spawn_kill_particles() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var particles_instance = HitParticlesScene.instantiate()
	scene.add_child(particles_instance)
	particles_instance.spawn_kill(global_position, Vector3.UP)

func _apply_hit_feedback(is_heavy: bool, is_judgement: bool = false):
	# LOCAL hitstop (2P-safe — no global Engine.time_scale). Weightier on heavy/Judgement.
	if is_judgement:
		local_hitstop = 0.155
	elif is_heavy:
		local_hitstop = 0.125
	else:
		local_hitstop = 0.055
	if camera_shake:
		var trauma := 0.38
		if is_judgement:
			trauma = 0.88
		elif is_heavy:
			trauma = 0.72
		camera_shake.add_trauma(trauma)
	print(name, " landed hit! (heavy=", is_heavy, " judgement=", is_judgement, ")")

func take_damage(amount: int, attacker: Node):
	# Dodge i-frames
	if invuln_timer > 0.0 or melee_state == MeleeState.DODGING:
		print(name, " dodged hit (i-frames)")
		return

	# Contested loot: hits interrupt channel
	var parent_scav = get_parent()
	if parent_scav:
		var scav = parent_scav.get_node_or_null("ScavengingSystem")
		if scav and scav.has_method("cancel_for_player") and scav.has_method("is_channeling"):
			if scav.is_channeling(self):
				scav.cancel_for_player(self)

	# Armor DR (Culling-style crafted armor)
	if amount > 0 and parent_scav:
		var craft = parent_scav.get_node_or_null("CraftingSystem")
		if craft and craft.has_method("get_damage_reduction"):
			var dr: float = float(craft.get_damage_reduction(self))
			if dr > 0.0:
				var reduced := int(round(float(amount) * (1.0 - dr)))
				amount = maxi(1, reduced) if amount > 0 else 0

	if is_blocking or melee_state == MeleeState.BLOCKING:
		# Perfect block: first perfect_block_window seconds fully mitigate
		if block_hold_time <= perfect_block_window:
			print("PERFECT BLOCK")
			amount = 0
			if _combat_audio:
				_combat_audio.play_block()
			# Small pushback on attacker only if present
			if attacker and attacker is CharacterBody3D:
				var push_back = (attacker.global_position - global_position).normalized()
				attacker.velocity += push_back * 4.0
			return
		amount = int(amount * (1.0 - block_reduction))

	health = max(health - amount, 0)
	health_changed.emit(health)

	print(name, " took ", amount, " damage (HP left: ", health, ")")

	# Knockback + hit reaction on receiver
	if attacker and attacker is CharacterBody3D:
		var push_dir = (global_position - attacker.global_position).normalized()
		var knockback_force = hit_knockback_force
		if amount > 20:  # heavy hit
			knockback_force *= heavy_knockback_multiplier
		
		# Apply weapon knockback multiplier if attacker has a weapon
		if attacker is PlayerController and attacker.current_weapon:
			knockback_force *= attacker.base_knockback_multiplier
		
		velocity += push_dir * knockback_force + Vector3(0, 2.5, 0)  # slight upward pop

	if _char_anim and health > 0:
		_char_anim.set_pose(CharAnimScript.Pose.HIT, hit_reaction_duration)
	# Flash first BodyMesh / Torso material
	_flash_hit_material()

	if health <= 0:
		die(attacker)


func _flash_hit_material() -> void:
	var rig = get_node_or_null("SkinRig")
	if rig == null:
		return
	var meshes: Array = []
	_collect_mesh_instances(rig, meshes)
	for m in meshes:
		if m is MeshInstance3D and (m as MeshInstance3D).material_override is StandardMaterial3D:
			var mat: StandardMaterial3D = (m as MeshInstance3D).material_override.duplicate()
			(m as MeshInstance3D).material_override = mat
			mat.emission_enabled = true
			mat.emission = Color(1, 0.15, 0.1)
			mat.emission_energy_multiplier = 3.5
			get_tree().create_timer(0.12).timeout.connect(func ():
				if is_instance_valid(mat):
					mat.emission_energy_multiplier = 0.0
			)
			break


func _collect_mesh_instances(node: Node, out: Array) -> void:
	if node is MeshInstance3D:
		out.append(node)
	for c in node.get_children():
		_collect_mesh_instances(c, out)


func _build_judgement_chain(spent_judgement: bool = false) -> void:
	if spent_judgement:
		return
	_set_chain(judgement_chain + 1)
	chain_timer = chain_window


func _set_chain(v: int) -> void:
	judgement_chain = maxi(0, v)
	judgement_ready = judgement_chain >= chain_judgement_threshold
	judgement_chain_changed.emit(judgement_chain, judgement_ready)
	_apply_chain_visual()
	if judgement_ready:
		print(name, " JUDGEMENT READY (chain ", judgement_chain, ")")


func _apply_chain_visual() -> void:
	var rig = get_node_or_null("SkinRig")
	if rig == null:
		return
	var meshes: Array = []
	_collect_mesh_instances(rig, meshes)
	for m in meshes:
		if not (m is MeshInstance3D):
			continue
		var mi := m as MeshInstance3D
		if mi.material_override == null or not (mi.material_override is StandardMaterial3D):
			continue
		var mat: StandardMaterial3D = mi.material_override
		if judgement_ready:
			mat.emission_enabled = true
			mat.emission = Color(1.0, 0.78, 0.2)
			mat.emission_energy_multiplier = 2.4
		elif judgement_chain >= 1:
			mat.emission_enabled = true
			mat.emission = Color(0.75, 0.4, 1.0)
			mat.emission_energy_multiplier = 0.55 + 0.35 * float(judgement_chain)
		else:
			mat.emission_energy_multiplier = 0.0


func die(attacker: Node):
	print(name, " DIED to ", attacker.name if attacker else "unknown")
	_set_chain(0)
	_set_melee_state(MeleeState.DEAD)
	_spawn_kill_particles()
	if _char_anim:
		_char_anim.set_pose(CharAnimScript.Pose.DEAD)
	# Credit killer for finish board
	var parent = get_parent()
	if attacker and parent and parent.get_node_or_null("ArenaManager"):
		var am = parent.get_node("ArenaManager")
		if am.has_method("record_kill"):
			am.record_kill(attacker, self)
	player_died.emit()
	set_physics_process(false)
	# Brief death pose before hide
	get_tree().create_timer(0.45).timeout.connect(func ():
		if is_instance_valid(self):
			visible = false
	)

func _process(delta):
	# Expose stamina for UI
	if stamina_changed.get_connections().size() == 0:  # simple safeguard
		pass
