# ZoneSystem.gd
# Culling-style closing ring: large start radius, shrinks over match,
# damages players/hunters outside every damage_interval.

extends Node3D
class_name ZoneSystem

@export var center: Vector3 = Vector3.ZERO
@export var start_radius: float = 22.0
@export var min_radius: float = 4.0
@export var shrink_duration: float = 180.0  # seconds to reach min_radius
@export var damage_per_tick: int = 4
@export var damage_interval: float = 0.5
@export var auto_start: bool = true
@export var danger_tint_enabled: bool = true
@export var ring_y: float = 0.18
@export var wall_height: float = 2.8

var radius: float = 22.0
var _elapsed: float = 0.0
var _damage_timer: float = 0.0
var _active: bool = false
var _shrink_mul: float = 1.0

var _ring: MeshInstance3D
var _wall: MeshInstance3D
var _torus: TorusMesh
var _danger_layer: CanvasLayer
var _danger_rect: ColorRect

signal radius_changed(new_radius: float)
signal damage_ticked(victim: Node, amount: int)


func _ready() -> void:
	radius = start_radius
	global_position = Vector3(center.x, 0.0, center.z)
	_build_visuals()
	if danger_tint_enabled:
		_build_danger_tint()
	if auto_start:
		start()
	print("ZoneSystem: ready radius=%.1f shrink=%.0fs dmg=%d/%.1fs" % [
		start_radius, shrink_duration, damage_per_tick, damage_interval
	])


func start() -> void:
	_active = true
	_elapsed = 0.0
	_damage_timer = 0.0
	radius = start_radius
	_update_visuals()


func stop() -> void:
	_active = false


## ArenaManager sudden-death: accelerate shrink toward min circle.
func force_final_circle(duration: float = 30.0) -> void:
	if not _active:
		start()
	if radius <= min_radius + 0.05:
		return
	# Re-map elapsed so remaining distance finishes in `duration` seconds
	var span := maxf(0.001, start_radius - min_radius)
	var progress := clampf((start_radius - radius) / span, 0.0, 1.0)
	var remaining_frac := 1.0 - progress
	if remaining_frac <= 0.001:
		return
	shrink_duration = maxf(1.0, duration / remaining_frac)
	_elapsed = progress * shrink_duration
	_shrink_mul = 1.0
	print("ZoneSystem: force_final_circle duration=%.1fs radius=%.1f" % [duration, radius])


func set_center(c: Vector3) -> void:
	center = c
	global_position = Vector3(c.x, 0.0, c.z)


func is_inside(world_pos: Vector3) -> bool:
	var dx := world_pos.x - center.x
	var dz := world_pos.z - center.z
	return (dx * dx + dz * dz) <= radius * radius


func _process(delta: float) -> void:
	if not _active:
		return

	_elapsed += delta * _shrink_mul
	var t := clampf(_elapsed / maxf(0.001, shrink_duration), 0.0, 1.0)
	var new_r := lerpf(start_radius, min_radius, t)
	if absf(new_r - radius) > 0.001:
		radius = new_r
		_update_visuals()
		radius_changed.emit(radius)

	_damage_timer += delta
	if _damage_timer >= damage_interval:
		_damage_timer = 0.0
		_tick_damage()

	if danger_tint_enabled:
		_update_danger_tint(delta)


func _build_visuals() -> void:
	# Ground ring (torus) — semi-transparent cyan
	_ring = MeshInstance3D.new()
	_ring.name = "ZoneRing"
	_torus = TorusMesh.new()
	_torus.inner_radius = maxf(0.12, radius - 0.45)
	_torus.outer_radius = radius
	_torus.rings = 64
	_torus.ring_segments = 16
	_ring.mesh = _torus
	_ring.position.y = ring_y
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(0.15, 0.85, 1.0, 0.55)
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_mat.emission_enabled = true
	ring_mat.emission = Color(0.2, 0.75, 1.0)
	ring_mat.emission_energy_multiplier = 1.6
	ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ring_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_ring.material_override = ring_mat
	add_child(_ring)

	# Tall boundary: thin torus tube raised + taller duplicate for wall-like read
	_wall = MeshInstance3D.new()
	_wall.name = "ZoneWall"
	var wall_torus := TorusMesh.new()
	wall_torus.inner_radius = maxf(0.05, radius - 0.12)
	wall_torus.outer_radius = radius + 0.08
	wall_torus.rings = 48
	wall_torus.ring_segments = 8
	_wall.mesh = wall_torus
	_wall.position.y = wall_height * 0.35
	_wall.scale = Vector3(1.0, wall_height * 1.4, 1.0)
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.1, 0.7, 1.0, 0.18)
	wall_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wall_mat.emission_enabled = true
	wall_mat.emission = Color(0.15, 0.6, 0.95)
	wall_mat.emission_energy_multiplier = 0.8
	wall_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wall_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_wall.material_override = wall_mat
	add_child(_wall)


func _update_visuals() -> void:
	if _torus:
		_torus.inner_radius = maxf(0.12, radius - 0.45)
		_torus.outer_radius = maxf(0.2, radius)
	if _wall and _wall.mesh is TorusMesh:
		var wt: TorusMesh = _wall.mesh
		wt.inner_radius = maxf(0.05, radius - 0.12)
		wt.outer_radius = maxf(0.15, radius + 0.08)
	# Shift color toward red as circle tightens
	if _ring and _ring.material_override is StandardMaterial3D:
		var mat: StandardMaterial3D = _ring.material_override
		var tight := 1.0 - clampf((radius - min_radius) / maxf(0.001, start_radius - min_radius), 0.0, 1.0)
		var col := Color(0.15 + tight * 0.75, 0.85 - tight * 0.7, 1.0 - tight * 0.85, 0.55)
		mat.albedo_color = col
		mat.emission = col
	if _wall and _wall.material_override is StandardMaterial3D:
		var wmat: StandardMaterial3D = _wall.material_override
		var tight2 := 1.0 - clampf((radius - min_radius) / maxf(0.001, start_radius - min_radius), 0.0, 1.0)
		var wcol := Color(0.1 + tight2 * 0.7, 0.7 - tight2 * 0.6, 1.0 - tight2 * 0.9, 0.18)
		wmat.albedo_color = wcol
		wmat.emission = wcol


func _tick_damage() -> void:
	if not is_inside_tree() or get_tree() == null:
		return
	var victims: Array = []
	victims.append_array(get_tree().get_nodes_in_group("players"))
	victims.append_array(get_tree().get_nodes_in_group("hunters"))
	for v in victims:
		if v == null or not is_instance_valid(v):
			continue
		if not (v is Node3D):
			continue
		if not _is_damageable_alive(v):
			continue
		var pos: Vector3 = (v as Node3D).global_position
		if is_inside(pos):
			continue
		_apply_zone_damage(v)


func _is_damageable_alive(node: Node) -> bool:
	if "health" in node and int(node.health) <= 0:
		return false
	if node.get("_alive") == false:
		return false
	return true


func _apply_zone_damage(victim: Node) -> void:
	var amount := damage_per_tick
	if victim.has_method("apply_damage"):
		victim.apply_damage(amount, null, 0.0)
	elif victim.has_method("take_damage"):
		victim.take_damage(amount, null)
	else:
		return
	damage_ticked.emit(victim, amount)


func _build_danger_tint() -> void:
	_danger_layer = CanvasLayer.new()
	_danger_layer.name = "ZoneDangerTint"
	_danger_layer.layer = 8
	_danger_rect = ColorRect.new()
	_danger_rect.name = "Tint"
	_danger_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_danger_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_danger_rect.color = Color(0.7, 0.05, 0.08, 0.0)
	_danger_layer.add_child(_danger_rect)
	add_child(_danger_layer)


func _update_danger_tint(delta: float) -> void:
	if _danger_rect == null:
		return
	# Prefer tint when a player (not only hunters) is outside
	var player_outside := false
	if is_inside_tree() and get_tree():
		for p in get_tree().get_nodes_in_group("players"):
			if p == null or not is_instance_valid(p) or not (p is Node3D):
				continue
			if not _is_damageable_alive(p):
				continue
			if not is_inside((p as Node3D).global_position):
				player_outside = true
				break
	var target_a := 0.28 if player_outside else 0.0
	var c := _danger_rect.color
	# Cyan edge when barely outside radius feel, red when deep outside / tight circle
	if player_outside:
		var tight := 1.0 - clampf((radius - min_radius) / maxf(0.001, start_radius - min_radius), 0.0, 1.0)
		c.r = lerpf(0.15, 0.85, tight)
		c.g = lerpf(0.55, 0.05, tight)
		c.b = lerpf(0.85, 0.08, tight)
	c.a = move_toward(c.a, target_a, delta * 2.5)
	_danger_rect.color = c
