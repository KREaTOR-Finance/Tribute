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

# === MOVEMENT (weighty but responsive) ===
@export var move_speed: float = 6.0
@export var acceleration: float = 40.0
@export var friction: float = 25.0
@export var jump_velocity: float = 6.0

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

# === INTERNAL STATE ===
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_blocking: bool = false
var is_winding_heavy: bool = false
var windup_timer: float = 0.0

var attack_cooldown_timer: float = 0.0
var shove_cooldown_timer: float = 0.0

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

	if has_node("CameraShake"):
		camera_shake = $CameraShake
	else:
		var parent = get_parent()
		if parent and parent.has_node("CameraShake"):
			camera_shake = parent.get_node("CameraShake")

	health = max_health
	stamina = max_stamina
	base_light_damage = light_attack_damage
	base_light_cooldown = light_attack_cooldown
	base_heavy_damage = heavy_attack_damage
	base_heavy_windup = heavy_attack_windup
	base_heavy_cooldown = heavy_attack_cooldown

	_load_humanoid_visual()

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


func _physics_process(delta: float):
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Movement input (supports player 1 + player 2 hotseat keys)
	var input_dir = _get_movement_input()
	var speed_mul := 0.55 if is_blocking else (0.4 if is_winding_heavy else 1.0)
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = move_toward(velocity.x, direction.x * move_speed * speed_mul, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * move_speed * speed_mul, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.z = move_toward(velocity.z, 0, friction * delta)

	move_and_slide()

	# Timers
	if attack_cooldown_timer > 0:
		attack_cooldown_timer -= delta
	if shove_cooldown_timer > 0:
		shove_cooldown_timer -= delta

	# Windup logic
	if is_winding_heavy:
		windup_timer += delta
		if windup_timer >= heavy_attack_windup:
			_perform_heavy_attack()

	# Stamina regen (simple)
	if not is_blocking and not is_winding_heavy and stamina < max_stamina:
		stamina = min(stamina + stamina_regen * delta, max_stamina)
		stamina_changed.emit(stamina)

	# Block drain
	if is_blocking and stamina > 0:
		stamina -= block_stamina_cost * delta * 0.5  # slow drain while holding

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
	if attack_cooldown_timer > 0 and not (event.is_action_released("block") or event.is_action_released("p2_block")):
		# still allow block release / weapon swap while recovering
		pass

	# Light attack
	if attack_cooldown_timer <= 0:
		if (player_id == 1 and event.is_action_pressed("light_attack")) or (player_id == 2 and event.is_action_pressed("p2_light_attack")):
			_perform_light_attack()
		if (player_id == 1 and event.is_action_pressed("heavy_attack")) or (player_id == 2 and event.is_action_pressed("p2_heavy_attack")):
			if stamina >= 25:
				start_heavy_windup()

	# Block
	if (player_id == 1 and event.is_action_pressed("block")) or (player_id == 2 and event.is_action_pressed("p2_block")):
		start_block()
	elif (player_id == 1 and event.is_action_released("block")) or (player_id == 2 and event.is_action_released("p2_block")):
		end_block()

	# Shove
	if attack_cooldown_timer <= 0:
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
	elif player_id == 2:
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_4:
				_equip_test_weapon(Weapon.WeaponType.SWORD)
			elif event.keycode == KEY_5:
				_equip_test_weapon(Weapon.WeaponType.AXE)
			elif event.keycode == KEY_6:
				_equip_test_weapon(Weapon.WeaponType.DAGGER)

func _equip_test_weapon(weapon_type: int):
	var w = Weapon.new()
	w.weapon_type = weapon_type
	w._apply_profile()  # force apply
	equip_weapon(w)
	# Note: In real game we would instance a proper scene with visuals

func start_heavy_windup():
	if is_winding_heavy or attack_cooldown_timer > 0:
		return
	is_winding_heavy = true
	windup_timer = 0.0
	stamina -= 25  # upfront cost
	stamina_changed.emit(stamina)
	print(name, " winding heavy attack...")

	# Improved windup visual feedback (squash + slight rotation for commitment)
	if mesh_instance:
		var tween = create_tween()
		tween.tween_property(mesh_instance, "scale", Vector3(1.2, 0.7, 1.2), heavy_attack_windup * 0.7)
		tween.parallel().tween_property(mesh_instance, "rotation_degrees:y", 25.0 if player_id == 1 else -25.0, heavy_attack_windup * 0.7)

func _perform_heavy_attack():
	is_winding_heavy = false
	windup_timer = 0.0

	if melee_hitbox:
		melee_hitbox.monitoring = true

	if mesh_instance:
		var tween = create_tween()
		tween.tween_property(mesh_instance, "scale", Vector3(1.15, 0.85, 1.15), 0.08)
		tween.tween_property(mesh_instance, "scale", Vector3(1, 1, 1), 0.18)
		tween.parallel().tween_property(mesh_instance, "rotation_degrees:y", 0.0, 0.2)

	await get_tree().create_timer(0.08).timeout
	_melee_shape_query(true)
	await get_tree().create_timer(0.08).timeout

	if melee_hitbox:
		melee_hitbox.monitoring = false

	attack_cooldown_timer = heavy_attack_cooldown
	print(name, " heavy attack released!")

func _melee_shape_query(heavy: bool) -> void:
	## Reliable hit detect (Culling: hits must land) — complements Area hitbox
	var space := get_world_3d().direct_space_state
	var q := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.7 if heavy else 0.55
	q.shape = sphere
	var reach := 1.6 if heavy else 1.35
	q.transform = Transform3D(Basis(), global_position + Vector3(0, 1.0, 0) + (-global_transform.basis.z) * reach)
	q.exclude = [get_rid()]
	q.collision_mask = 0xFFFFFFFF
	for h in space.intersect_shape(q, 12):
		var col = h.get("collider")
		if col and col is CharacterBody3D:
			_on_melee_hit(col)


func _perform_light_attack():
	if is_winding_heavy:
		return
	if stamina < 6:
		return
	stamina -= 6
	stamina_changed.emit(stamina)

	if melee_hitbox:
		melee_hitbox.monitoring = true

	if mesh_instance:
		var tween = create_tween()
		tween.tween_property(mesh_instance, "scale", Vector3(1.08, 1.08, 1.08), 0.03)
		tween.tween_property(mesh_instance, "scale", Vector3(1, 1, 1), 0.1)

	await get_tree().create_timer(0.06).timeout
	_melee_shape_query(false)
	await get_tree().create_timer(0.04).timeout

	if melee_hitbox:
		melee_hitbox.monitoring = false

	attack_cooldown_timer = light_attack_cooldown
	print(name, " light jab!")

func start_block():
	if is_blocking or stamina < block_stamina_cost:
		return
	is_blocking = true
	print(name, " blocking (", block_reduction * 100, "% reduction)")

	# Visual block stance
	if mesh_instance:
		var tween = create_tween()
		tween.tween_property(mesh_instance, "scale", Vector3(0.95, 1.15, 0.95), 0.1)

func end_block():
	is_blocking = false
	print(name, " stopped blocking")

	# Reset stance
	if mesh_instance:
		var tween = create_tween()
		tween.tween_property(mesh_instance, "scale", Vector3(1, 1, 1), 0.12)

func _perform_shove():
	if shove_cooldown_timer > 0 or stamina < 12:
		return

	shove_cooldown_timer = shove_cooldown
	stamina -= 12
	stamina_changed.emit(stamina)

	# Push away nearby bodies (existing shove knockback)
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = $CollisionShape3D.shape
	query.transform = global_transform
	query.exclude = [self]

	var results = space_state.intersect_shape(query)
	for result in results:
		var body = result.collider
		if body and body is CharacterBody3D and body != self:
			var push_dir = (body.global_position - global_position).normalized()
			if push_dir.length() > 0:
				body.velocity += push_dir * shove_force + Vector3(0, 3, 0)
			print(name, " shoved ", body.name)

	print(name, " shoved!")

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

	var damage = light_attack_damage
	var is_heavy = is_winding_heavy or (attack_cooldown_timer > heavy_attack_cooldown - 0.3)
	if is_heavy:
		damage = heavy_attack_damage
	var kb = hit_knockback_force * (heavy_knockback_multiplier if is_heavy else 1.0)

	# Hit players, hunters, any damageable CharacterBody3D
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

	if melee_hitbox:
		melee_hitbox.monitoring = false

func _spawn_hit_particles(world_pos: Vector3, is_heavy: bool):
	var particles_instance = HitParticlesScene.instantiate()
	get_tree().current_scene.add_child(particles_instance)
	particles_instance.global_position = world_pos + Vector3(0, 1.0, 0)  # chest height
	particles_instance.spawn_hit(world_pos, Vector3.UP, is_heavy)

func _apply_hit_feedback(is_heavy: bool):
	# Hitstop (brief time slow)
	var hitstop_duration = 0.09 if is_heavy else 0.05
	Engine.time_scale = 0.15
	await get_tree().create_timer(hitstop_duration, false, false, true).timeout  # ignore time scale
	Engine.time_scale = 1.0

	# Screenshake on the camera
	if camera_shake:
		camera_shake.add_trauma(0.65 if is_heavy else 0.35)

	# Visual punch on attacker
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

	# === NEW: Knockback + hit reaction on receiver ===
	if attacker and attacker is CharacterBody3D:
		var push_dir = (global_position - attacker.global_position).normalized()
		var knockback_force = hit_knockback_force
		if amount > 20:  # heavy hit
			knockback_force *= heavy_knockback_multiplier
		
		# Apply weapon knockback multiplier if attacker has a weapon
		if attacker is PlayerController and attacker.current_weapon:
			knockback_force *= attacker.base_knockback_multiplier
		
		velocity += push_dir * knockback_force + Vector3(0, 2.5, 0)  # slight upward pop

	if mesh_instance:
		var tween = create_tween()
		tween.tween_property(mesh_instance, "scale", Vector3(0.9, 1.15, 0.9), hit_reaction_duration * 0.4)
		tween.tween_property(mesh_instance, "scale", Vector3(1, 1, 1), hit_reaction_duration * 0.6)
		if mesh_instance.material_override is StandardMaterial3D:
			var mat: StandardMaterial3D = mesh_instance.material_override
			mat.emission_enabled = true
			mat.emission = Color(1, 0.15, 0.1)
			mat.emission_energy_multiplier = 4.0
			get_tree().create_timer(0.12).timeout.connect(func ():
				if is_instance_valid(mat):
					mat.emission_energy_multiplier = 0.0
			)

	if health <= 0:
		die(attacker)

func die(attacker: Node):
	print(name, " DIED to ", attacker.name if attacker else "unknown")
	player_died.emit()
	set_physics_process(false)
	visible = false
	# In a full game we would queue_free or respawn here

func _process(delta):
	# Expose stamina for UI
	if stamina_changed.get_connections().size() == 0:  # simple safeguard
		pass
