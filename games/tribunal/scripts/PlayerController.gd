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
@export var shove_force: float = 18.0
@export var shove_cooldown: float = 1.0

# === RESOURCES (added in task 3 & 4) ===
@export var max_health: int = 100
@export var max_stamina: float = 100.0
@export var stamina_regen: float = 22.0

# === MELEE REACTION TUNING (new for knockback + juice) ===
@export var hit_knockback_force: float = 12.0
@export var hit_reaction_duration: float = 0.18
@export var heavy_knockback_multiplier: float = 1.6

var health: int = 100
var stamina: float = 100.0
var is_exhausted: bool = false

# === CULLING MELEE STATE MACHINE ===
enum MeleeState { IDLE, LIGHT_ACTIVE, LIGHT_RECOVERY, HEAVY_WINDUP, HEAVY_ACTIVE, HEAVY_RECOVERY, BLOCKING, SHOVING, DEAD }
var melee_state: MeleeState = MeleeState.IDLE
var state_time: float = 0.0
var hit_this_swing: Dictionary = {}  # instance_id -> true, once per swing
var active_is_heavy: bool = false
var local_hitstop: float = 0.0  # local slow (not global Engine.time_scale)

# legacy flags kept in sync for any external reads
var is_blocking: bool = false
var is_winding_heavy: bool = false
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

# Preload for particles (will be instantiated on hits)
const HitParticlesScene = preload("res://scripts/HitParticles.tscn")
const SkinCat = preload("res://scripts/SkinCatalog.gd")
const CharSkinScript = preload("res://scripts/CharacterSkin.gd")
const CharAnimScript = preload("res://scripts/CharacterAnimator.gd")

var character_skin_id: String = ""
var weapon_skin_id: String = ""
var _char_skin = null
var _char_anim = null
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

	weapon_equipped.emit(weapon.weapon_name)
	print(name, " equipped ", weapon.weapon_name)

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
		MeleeState.LIGHT_RECOVERY, MeleeState.HEAVY_RECOVERY:
			speed_mul = 0.88
		_:
			speed_mul = 1.0

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

	# Feed locomotion to character art
	if _char_anim:
		var hspd := Vector2(velocity.x, velocity.z).length()
		_char_anim.set_move_blend(hspd, sprint_speed, _is_sprinting)
		# Keep walk/idle pose when not in special combat pose
		if melee_state in [MeleeState.IDLE, MeleeState.LIGHT_RECOVERY, MeleeState.HEAVY_RECOVERY]:
			if _is_sprinting and hspd > 0.4:
				_char_anim.set_pose(CharAnimScript.Pose.SPRINT)
			elif hspd > 0.35:
				_char_anim.set_pose(CharAnimScript.Pose.WALK)
			else:
				_char_anim.set_pose(CharAnimScript.Pose.IDLE)

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

	# Stamina
	if melee_state == MeleeState.BLOCKING and stamina > 0:
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
		_:
			_set_melee_state(MeleeState.IDLE)

func _get_movement_input() -> Vector2:
	var input = Vector2.ZERO

	if player_id == 1:
		if Input.is_action_pressed("move_forward"):  input.y -= 1
		if Input.is_action_pressed("move_backward"): input.y += 1
		if Input.is_action_pressed("move_left"):     input.x -= 1
		if Input.is_action_pressed("move_right"):    input.x += 1
	else:
		# Player 2 hotseat keys
		if Input.is_action_pressed("p2_move_forward"):  input.y -= 1
		if Input.is_action_pressed("p2_move_backward"): input.y += 1
		if Input.is_action_pressed("p2_move_left"):     input.x -= 1
		if Input.is_action_pressed("p2_move_right"):    input.x += 1

	return input

func _handle_combat_input(event):
	if (player_id == 1 and event.is_action_pressed("light_attack")) or (player_id == 2 and event.is_action_pressed("p2_light_attack")):
		_perform_light_attack()
	if (player_id == 1 and event.is_action_pressed("heavy_attack")) or (player_id == 2 and event.is_action_pressed("p2_heavy_attack")):
		start_heavy_windup()
	if (player_id == 1 and event.is_action_pressed("block")) or (player_id == 2 and event.is_action_pressed("p2_block")):
		start_block()
	elif (player_id == 1 and event.is_action_released("block")) or (player_id == 2 and event.is_action_released("p2_block")):
		end_block()
	if (player_id == 1 and event.is_action_pressed("shove")) or (player_id == 2 and event.is_action_pressed("p2_shove")):
		_perform_shove()

	# Weapon swap (Culling tool fantasy)
	if player_id == 1:
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_1:
				_equip_test_weapon(Weapon.WeaponType.SWORD)
			elif event.keycode == KEY_2:
				_equip_test_weapon(Weapon.WeaponType.AXE)
			elif event.keycode == KEY_3:
				_equip_test_weapon(Weapon.WeaponType.DAGGER)
			elif event.keycode == KEY_BRACKETLEFT:  # [
				_cycle_character_skin()
			elif event.keycode == KEY_BRACKETRIGHT:  # ]
				_cycle_weapon_skin()
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
			elif event.keycode == KEY_SEMICOLON:
				# keep shove on ; for p2 — use KEY_PERIOD for weapon skin
				pass
			elif event.keycode == KEY_PERIOD:
				_cycle_weapon_skin()

func _equip_test_weapon(weapon_type: int):
	var w = Weapon.new()
	w.weapon_type = weapon_type
	w._apply_profile()
	equip_weapon(w)
	weapon_skin_id = SkinCat.default_weapon_skin(int(weapon_type) + 1)
	_apply_weapon_skin_to_hand()


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
	if not _can_act() or stamina < 25:
		return
	stamina -= 25
	stamina_changed.emit(stamina)
	_set_melee_state(MeleeState.HEAVY_WINDUP, heavy_attack_windup)
	print(name, " winding heavy (readable commit)...")

func _melee_shape_query(heavy: bool) -> void:
	var space := get_world_3d().direct_space_state
	var q := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.7 if heavy else 0.55
	q.shape = sphere
	var reach := 1.65 if heavy else 1.35
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
	print(name, " light jab!")

func start_block():
	if not _can_act() or stamina < block_stamina_cost * 0.5:
		return
	_set_melee_state(MeleeState.BLOCKING)
	print(name, " blocking")

func end_block():
	if melee_state == MeleeState.BLOCKING:
		_set_melee_state(MeleeState.IDLE)

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
	var damage = heavy_attack_damage if is_heavy else light_attack_damage
	var kb = hit_knockback_force * (heavy_knockback_multiplier if is_heavy else 1.0)

	if body is PlayerController:
		body.take_damage(damage, self)
	elif body.has_method("apply_damage"):
		body.apply_damage(damage, self, kb)
	elif body.has_method("take_damage"):
		body.take_damage(damage, self)
	else:
		return

	_apply_hit_feedback(is_heavy)
	_spawn_hit_particles(body.global_position, is_heavy)

func _spawn_hit_particles(world_pos: Vector3, is_heavy: bool):
	var particles_instance = HitParticlesScene.instantiate()
	get_tree().current_scene.add_child(particles_instance)
	particles_instance.global_position = world_pos + Vector3(0, 1.0, 0)  # chest height
	particles_instance.spawn_hit(world_pos, Vector3.UP, is_heavy)

func _apply_hit_feedback(is_heavy: bool):
	# LOCAL hitstop (Culling-safe for 2P — no global Engine.time_scale)
	local_hitstop = 0.09 if is_heavy else 0.05
	if camera_shake:
		camera_shake.add_trauma(0.65 if is_heavy else 0.35)
	if mesh_instance:
		var tween = create_tween()
		tween.tween_property(mesh_instance, "scale", Vector3(0.95, 1.1, 0.95), 0.04)
		tween.tween_property(mesh_instance, "scale", Vector3(1, 1, 1), 0.12)
	print(name, " landed hit! (heavy=", is_heavy, ")")

func take_damage(amount: int, attacker: Node):
	if is_blocking:
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


func die(attacker: Node):
	print(name, " DIED to ", attacker.name if attacker else "unknown")
	_set_melee_state(MeleeState.DEAD)
	if _char_anim:
		_char_anim.set_pose(CharAnimScript.Pose.DEAD)
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
