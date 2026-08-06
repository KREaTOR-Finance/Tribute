# HitParticles.gd
# Readable Culling-style melee impact juice: brief sparks + heavy blood mist + kill burst.
# Instantiate once per event; call spawn_hit() or spawn_kill(), then auto-frees.

extends Node3D
class_name HitParticles

@export var light_spark_count: int = 10
@export var heavy_spark_count: int = 22
@export var kill_spark_count: int = 18
@export var light_blood_count: int = 0
@export var heavy_blood_count: int = 36
@export var kill_blood_count: int = 64

@export var spark_lifetime: float = 0.18
@export var blood_lifetime: float = 0.42
@export var kill_lifetime: float = 0.55
@export var spark_speed: float = 9.0
@export var blood_speed: float = 4.5
@export var chest_height: float = 1.05

var _sparks: CPUParticles3D
var _blood: CPUParticles3D


func _ready() -> void:
	_sparks = get_node_or_null("Sparks") as CPUParticles3D
	_blood = get_node_or_null("BloodMist") as CPUParticles3D
	if _sparks == null or _blood == null:
		_ensure_layers()


func _ensure_layers() -> void:
	if _sparks == null:
		_sparks = get_node_or_null("CPUParticles3D") as CPUParticles3D
	if _sparks == null:
		_sparks = _make_particles("Sparks")
		add_child(_sparks)
	else:
		_sparks.name = "Sparks"
	if _blood == null:
		_blood = _make_particles("BloodMist")
		add_child(_blood)
	_configure_spark_defaults(_sparks)
	_configure_blood_defaults(_blood)


func _make_particles(p_name: String) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.name = p_name
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 0.95
	p.local_coords = false
	p.direction = Vector3(0, 1, 0)
	p.spread = 180.0
	return p


func _configure_spark_defaults(p: CPUParticles3D) -> void:
	p.lifetime = spark_lifetime
	p.amount = heavy_spark_count
	p.explosiveness = 0.98
	p.randomness = 0.35
	p.gravity = Vector3(0, -4.0, 0)
	p.damping_min = 2.0
	p.damping_max = 6.0
	p.scale_amount_min = 0.05
	p.scale_amount_max = 0.12
	# Brief white-gold spark (reads as impact flash, not mud)
	p.color = Color(1.0, 0.95, 0.55, 1.0)
	_apply_fade_ramp(p, Color(1.0, 0.98, 0.75, 1.0), Color(1.0, 0.55, 0.15, 0.0))


func _configure_blood_defaults(p: CPUParticles3D) -> void:
	p.lifetime = blood_lifetime
	p.amount = heavy_blood_count
	p.explosiveness = 0.88
	p.randomness = 0.45
	p.gravity = Vector3(0, -11.0, 0)
	p.damping_min = 1.5
	p.damping_max = 4.0
	p.scale_amount_min = 0.08
	p.scale_amount_max = 0.2
	# Blood-ish red mist
	p.color = Color(0.62, 0.06, 0.08, 0.9)
	_apply_fade_ramp(p, Color(0.75, 0.08, 0.1, 0.95), Color(0.25, 0.02, 0.04, 0.0))


func _apply_fade_ramp(p: CPUParticles3D, c0: Color, c1: Color) -> void:
	var g := Gradient.new()
	g.colors = PackedColorArray([c0, c1])
	g.offsets = PackedFloat32Array([0.0, 1.0])
	p.color_ramp = g


## Light: short gold sparks. Heavy: more sparks + red mist. Optional kill flag stacks burst.
func spawn_hit(world_pos: Vector3, normal: Vector3 = Vector3.UP, is_heavy: bool = false, is_kill: bool = false) -> void:
	if _sparks == null or _blood == null:
		_ensure_layers()

	global_position = world_pos + Vector3(0.0, chest_height, 0.0)
	_orient_to_normal(normal)

	if is_kill:
		_fire_kill()
	else:
		_fire_hit(is_heavy)

	var life := kill_lifetime if is_kill else (blood_lifetime if is_heavy else spark_lifetime)
	await _await_free(life + 0.55)


## Extra death burst — call from die() / _die().
func spawn_kill(world_pos: Vector3, normal: Vector3 = Vector3.UP) -> void:
	await spawn_hit(world_pos, normal, true, true)


func _await_free(delay: float) -> void:
	var tree := get_tree()
	if tree == null:
		var ml := Engine.get_main_loop()
		if ml is SceneTree:
			tree = ml as SceneTree
	if tree:
		await tree.create_timer(delay).timeout
	if is_instance_valid(self):
		queue_free()


func _orient_to_normal(normal: Vector3) -> void:
	var n := normal.normalized() if normal.length_squared() > 0.0001 else Vector3.UP
	# Avoid look_at singularity when normal is nearly world-up
	if absf(n.dot(Vector3.UP)) > 0.95:
		global_rotation = Vector3.ZERO
		return
	look_at(global_position + n, Vector3.UP)


func _fire_hit(is_heavy: bool) -> void:
	# Sparks — always, brief readable flash
	var spark_n: int = heavy_spark_count if is_heavy else light_spark_count
	var spark_spd: float = spark_speed * (1.25 if is_heavy else 1.0)
	_sparks.amount = maxi(spark_n, 1)
	_sparks.lifetime = spark_lifetime * (1.15 if is_heavy else 1.0)
	_sparks.initial_velocity_min = spark_spd * 0.75
	_sparks.initial_velocity_max = spark_spd * 1.45
	_sparks.scale_amount_min = 0.06 if is_heavy else 0.04
	_sparks.scale_amount_max = 0.16 if is_heavy else 0.1
	_sparks.color = Color(1.0, 0.92, 0.45, 1.0) if is_heavy else Color(1.0, 0.96, 0.7, 0.95)
	_apply_fade_ramp(
		_sparks,
		Color(1.0, 0.98, 0.8, 1.0),
		Color(1.0, 0.4, 0.1, 0.0) if is_heavy else Color(1.0, 0.75, 0.35, 0.0)
	)
	_sparks.restart()
	_sparks.emitting = true

	# Blood mist — heavy only (readable wound, not spam on jabs)
	var blood_n: int = heavy_blood_count if is_heavy else light_blood_count
	if blood_n <= 0:
		_blood.emitting = false
		return
	_blood.amount = blood_n
	_blood.lifetime = blood_lifetime
	_blood.initial_velocity_min = blood_speed * 0.55
	_blood.initial_velocity_max = blood_speed * 1.35
	_blood.scale_amount_min = 0.1
	_blood.scale_amount_max = 0.24
	_blood.color = Color(0.58, 0.05, 0.07, 0.92)
	_apply_fade_ramp(_blood, Color(0.7, 0.08, 0.1, 0.95), Color(0.2, 0.02, 0.03, 0.0))
	_blood.restart()
	_blood.emitting = true


func _fire_kill() -> void:
	# Sparks linger slightly so death reads over blood plume
	_sparks.amount = maxi(kill_spark_count, 1)
	_sparks.lifetime = spark_lifetime * 1.4
	_sparks.initial_velocity_min = spark_speed * 0.9
	_sparks.initial_velocity_max = spark_speed * 1.7
	_sparks.scale_amount_min = 0.07
	_sparks.scale_amount_max = 0.18
	_sparks.color = Color(1.0, 0.85, 0.35, 1.0)
	_apply_fade_ramp(_sparks, Color(1.0, 0.95, 0.7, 1.0), Color(0.9, 0.25, 0.08, 0.0))
	_sparks.restart()
	_sparks.emitting = true

	# Large red mist plume
	_blood.amount = maxi(kill_blood_count, 1)
	_blood.lifetime = kill_lifetime
	_blood.initial_velocity_min = blood_speed * 0.7
	_blood.initial_velocity_max = blood_speed * 1.85
	_blood.scale_amount_min = 0.12
	_blood.scale_amount_max = 0.32
	_blood.gravity = Vector3(0, -9.5, 0)
	_blood.color = Color(0.55, 0.04, 0.06, 0.95)
	_apply_fade_ramp(_blood, Color(0.72, 0.06, 0.08, 0.98), Color(0.15, 0.01, 0.02, 0.0))
	_blood.restart()
	_blood.emitting = true
