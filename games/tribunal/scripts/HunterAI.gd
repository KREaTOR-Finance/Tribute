extends CharacterBody3D
class_name HunterAI
## Aggressive sparring hunter for Tribunal demo — seeks player, light/heavy rhythm.

signal died

@export var max_health: int = 100
@export var move_speed: float = 4.8
@export var attack_range: float = 2.2
@export var team_color: Color = Color(0.85, 0.15, 0.1)

var health: int = 100
var target: Node3D
var _attack_cd: float = 0.0
var _windup: float = 0.0
var _winding: bool = false
var _mesh: MeshInstance3D
var _alive: bool = true
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	health = max_health
	collision_layer = 1
	collision_mask = 1
	_build_body()
	add_to_group("hunters")
	add_to_group("damageable")

func _build_body() -> void:
	var cap := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.6
	cap.shape = shape
	cap.position.y = 1.0
	add_child(cap)
	_mesh = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.45
	sphere.height = 1.7
	_mesh.mesh = sphere
	_mesh.position.y = 1.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = team_color
	mat.roughness = 0.55
	mat.metallic = 0.15
	_mesh.material_override = mat
	add_child(_mesh)
	# Simple weapon stick
	var stick := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.08, 0.08, 1.1)
	stick.mesh = box
	stick.position = Vector3(0.45, 1.1, -0.35)
	stick.rotation_degrees.x = 80
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.7, 0.7, 0.75)
	sm.metallic = 0.8
	sm.roughness = 0.35
	stick.material_override = sm
	stick.name = "Weapon"
	add_child(stick)

func set_target(t: Node3D) -> void:
	target = t

func apply_damage(amount: int, from: Node3D = null, knockback: float = 0.0) -> void:
	if not _alive:
		return
	health = max(0, health - amount)
	if from and knockback > 0.0:
		var dir := (global_position - from.global_position).normalized()
		velocity += dir * knockback + Vector3.UP * 2.0
	# flash
	if _mesh and _mesh.material_override:
		var m: StandardMaterial3D = _mesh.material_override
		m.emission_enabled = true
		m.emission = Color(1, 0.3, 0.1)
		m.emission_energy_multiplier = 3.0
		get_tree().create_timer(0.08).timeout.connect(func ():
			if is_instance_valid(m):
				m.emission_energy_multiplier = 0.0
		)
	if health <= 0:
		_die()

func _die() -> void:
	_alive = false
	died.emit()
	# ragdoll-ish sink
	collision_layer = 0
	var tw := create_tween()
	tw.tween_property(self, "global_position", global_position + Vector3(0, -2, 0), 0.8)
	tw.tween_callback(queue_free)

func _physics_process(delta: float) -> void:
	if not _alive:
		return
	if not is_on_floor():
		velocity.y -= gravity * delta
	_attack_cd = max(0.0, _attack_cd - delta)
	if _winding:
		_windup -= delta
		if _mesh:
			_mesh.scale = Vector3(1.2, 1.05, 1.2)
		if _windup <= 0.0:
			_winding = false
			_do_attack(true)
			if _mesh:
				_mesh.scale = Vector3.ONE
		move_and_slide()
		return
	if target == null or not is_instance_valid(target):
		var players := get_tree().get_nodes_in_group("players")
		if players.size() > 0:
			target = players[0]
	if target == null:
		move_and_slide()
		return
	var to := target.global_position - global_position
	to.y = 0
	var dist := to.length()
	if dist > 0.1:
		look_at(global_position + to.normalized(), Vector3.UP)
	if dist > attack_range:
		var dir := to.normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
		if _attack_cd <= 0.0:
			if randf() < 0.28:
				_winding = true
				_windup = 0.55
			else:
				_do_attack(false)
			_attack_cd = 0.9 if _winding else 0.45
	move_and_slide()

func _do_attack(heavy: bool) -> void:
	if target == null:
		return
	var dist := global_position.distance_to(target.global_position)
	if dist > attack_range + 0.4:
		return
	var dmg := 28 if heavy else 12
	var kb := 14.0 if heavy else 8.0
	if target.has_method("apply_damage"):
		target.apply_damage(dmg, self, kb)
	elif target.has_method("take_damage"):
		target.take_damage(dmg)
