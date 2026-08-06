extends CharacterBody3D
class_name TribunalPlayer
## Full melee player for Tribunal demo — no external glb required.

signal player_died
signal health_changed(new_health: int)
signal stamina_changed(new_stamina: float)

@export var move_speed: float = 6.2
@export var acceleration: float = 42.0
@export var friction: float = 28.0
@export var max_health: int = 100
@export var max_stamina: float = 100.0
@export var stamina_regen: float = 24.0

var health: int = 100
var stamina: float = 100.0
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var yaw: float = 0.0
var pitch: float = 0.0

var _atk_cd: float = 0.0
var _shove_cd: float = 0.0
var _blocking: bool = false
var _winding: bool = false
var _windup_t: float = 0.0
var _mesh: MeshInstance3D
var _weapon: MeshInstance3D
var _tele_light: OmniLight3D
var _alive: bool = true
var mouse_sens: float = 0.0022

# Weapon profiles: name, light_dmg, heavy_dmg, windup, range, color
var weapons: Array = [
	["Fist", 10, 22, 0.35, 1.8, Color(0.85, 0.75, 0.55)],
	["Sword", 14, 34, 0.48, 2.4, Color(0.7, 0.72, 0.8)],
	["Axe", 16, 42, 0.62, 2.1, Color(0.45, 0.35, 0.28)],
]
var weapon_i: int = 1

func _ready() -> void:
	health = max_health
	stamina = max_stamina
	add_to_group("players")
	add_to_group("damageable")
	collision_layer = 1
	collision_mask = 1
	_build_visual()
	_select_weapon(1)

func _build_visual() -> void:
	var cap := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.5
	cap.shape = shape
	cap.position.y = 1.0
	add_child(cap)
	_mesh = MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.42
	sph.height = 1.65
	_mesh.mesh = sph
	_mesh.position.y = 1.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.42, 0.7)
	mat.roughness = 0.5
	mat.metallic = 0.1
	_mesh.material_override = mat
	add_child(_mesh)
	_weapon = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.08, 0.08, 1.0)
	_weapon.mesh = box
	_weapon.position = Vector3(0.5, 1.15, -0.25)
	_weapon.rotation_degrees = Vector3(75, 0, 0)
	var wm := StandardMaterial3D.new()
	wm.metallic = 0.85
	wm.roughness = 0.3
	_weapon.material_override = wm
	add_child(_weapon)
	_tele_light = OmniLight3D.new()
	_tele_light.light_energy = 0.0
	_tele_light.omni_range = 3.5
	_tele_light.position = Vector3(0, 1.8, 0)
	add_child(_tele_light)

func _select_weapon(i: int) -> void:
	weapon_i = clampi(i, 0, weapons.size() - 1)
	var w = weapons[weapon_i]
	if _weapon and _weapon.material_override:
		(_weapon.material_override as StandardMaterial3D).albedo_color = w[5]
	var len_scale := 0.7 if weapon_i == 0 else (1.15 if weapon_i == 1 else 0.95)
	_weapon.scale = Vector3(1.0 if weapon_i != 2 else 1.4, 1.0, len_scale)

func _unhandled_input(event: InputEvent) -> void:
	if not _alive:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw -= event.relative.x * mouse_sens
		pitch = clampf(pitch - event.relative.y * mouse_sens, deg_to_rad(-55), deg_to_rad(35))
		rotation.y = yaw
	if event.is_action_pressed("light_attack"):
		_light()
	if event.is_action_pressed("heavy_attack"):
		_start_heavy()
	if event.is_action_pressed("block"):
		_blocking = true
	if event.is_action_released("block"):
		_blocking = false
		_tele_light.light_energy = 0.0
	if event.is_action_pressed("shove"):
		_shove()
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1: _select_weapon(0)
		elif event.keycode == KEY_2: _select_weapon(1)
		elif event.keycode == KEY_3: _select_weapon(2)

func _physics_process(delta: float) -> void:
	if not _alive:
		return
	if not is_on_floor():
		velocity.y -= gravity * delta
	_atk_cd = max(0.0, _atk_cd - delta)
	_shove_cd = max(0.0, _shove_cd - delta)
	var input := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	)
	var basis_yaw := Basis(Vector3.UP, yaw)
	var dir := (basis_yaw * Vector3(input.x, 0, input.y)).normalized()
	var speed := move_speed * (0.55 if _blocking else 1.0) * (0.4 if _winding else 1.0)
	if dir != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, dir.x * speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, dir.z * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.z = move_toward(velocity.z, 0, friction * delta)
	if _winding:
		_windup_t -= delta
		_tele_light.light_color = Color(1.0, 0.45, 0.05)
		_tele_light.light_energy = 6.0
		_mesh.scale = Vector3(1.2, 0.85, 1.2)
		if _windup_t <= 0.0:
			_winding = false
			_mesh.scale = Vector3.ONE
			_tele_light.light_energy = 0.0
			_heavy_strike()
	if _blocking:
		_tele_light.light_color = Color(0.3, 0.55, 1.0)
		_tele_light.light_energy = 2.5
		stamina = max(0.0, stamina - 12.0 * delta)
		stamina_changed.emit(stamina)
	elif stamina < max_stamina and not _winding:
		stamina = min(max_stamina, stamina + stamina_regen * delta)
		stamina_changed.emit(stamina)
	move_and_slide()

func _light() -> void:
	if _atk_cd > 0.0 or _winding:
		return
	var w = weapons[weapon_i]
	if stamina < 6:
		return
	stamina -= 6
	stamina_changed.emit(stamina)
	_atk_cd = 0.32
	_strike(int(w[1]), float(w[4]), false)

func _start_heavy() -> void:
	if _atk_cd > 0.0 or _winding or stamina < 20:
		return
	var w = weapons[weapon_i]
	stamina -= 20
	stamina_changed.emit(stamina)
	_winding = true
	_windup_t = float(w[3])

func _heavy_strike() -> void:
	var w = weapons[weapon_i]
	_atk_cd = 0.55
	_strike(int(w[2]), float(w[4]) + 0.2, true)

func _strike(damage: int, reach: float, heavy: bool) -> void:
	# Hitstop juice
	Engine.time_scale = 0.18 if heavy else 0.25
	get_tree().create_timer(0.07 if heavy else 0.04, true, false, true).timeout.connect(func ():
		Engine.time_scale = 1.0
	)
	var space := get_world_3d().direct_space_state
	var q := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.55 if heavy else 0.4
	q.shape = sphere
	q.transform = Transform3D(Basis(), global_position + Vector3(0, 1.1, 0) + (-global_transform.basis.z) * reach * 0.55)
	q.collision_mask = 0xFFFFFFFF
	q.exclude = [get_rid()]
	var hits := space.intersect_shape(q, 8)
	for h in hits:
		var col = h.get("collider")
		if col == null or col == self:
			continue
		if col.has_method("apply_damage"):
			col.apply_damage(damage, self, 12.0 if heavy else 7.0)
		elif col.has_method("take_damage"):
			col.take_damage(damage, self)

func _shove() -> void:
	if _shove_cd > 0.0 or stamina < 15:
		return
	stamina -= 15
	stamina_changed.emit(stamina)
	_shove_cd = 0.85
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(
		global_position + Vector3(0, 1, 0),
		global_position + Vector3(0, 1, 0) + (-global_transform.basis.z) * 2.2
	)
	q.exclude = [get_rid()]
	var hit := space.intersect_ray(q)
	if hit and hit.collider:
		var c = hit.collider
		if c is CharacterBody3D:
			c.velocity += (-global_transform.basis.z) * 16.0 + Vector3.UP * 3.0
		if c.has_method("apply_damage"):
			c.apply_damage(4, self, 10.0)

func apply_damage(amount: int, from: Node = null, knockback: float = 0.0) -> void:
	if not _alive:
		return
	if _blocking:
		amount = int(amount * 0.35)
		stamina = max(0.0, stamina - 10)
		stamina_changed.emit(stamina)
	health = max(0, health - amount)
	health_changed.emit(health)
	if from is Node3D and knockback > 0.0:
		var attacker := from as Node3D
		var push := (global_position - attacker.global_position).normalized()
		velocity += push * knockback + Vector3.UP * 2.0
	if _mesh and _mesh.material_override:
		var m: StandardMaterial3D = _mesh.material_override
		m.emission_enabled = true
		m.emission = Color(1, 0.2, 0.15)
		m.emission_energy_multiplier = 4.0
		get_tree().create_timer(0.1).timeout.connect(func ():
			if is_instance_valid(m):
				m.emission_energy_multiplier = 0.0
		)
	if health <= 0:
		_alive = false
		player_died.emit()
		visible = false
		set_physics_process(false)

func heal_partial(amount: int) -> void:
	health = mini(max_health, health + amount)
	health_changed.emit(health)
