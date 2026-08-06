extends RefCounted
class_name ArenaEnvironment
## Finished Tribunal arena: floor, perimeter, designed cover, spawn pads.
## No floating props — every piece sits on the floor plane (y = 0 top of floor).

const Catalog = preload("res://scripts/SkinCatalog.gd")
const MatFactory = preload("res://scripts/TribunalMaterialFactory.gd")

const HALF := 12.0  # playable half-extent
const FLOOR_Y := 0.0  # top of floor surface
const WALL_H := 2.4
const WALL_T := 0.55


static func build(parent: Node3D) -> Dictionary:
	# Remove prototype clutter + prior env pieces only (never ArenaManager / systems)
	var to_kill: Array = []
	for n in ["Crate1", "Crate2", "Barrel1", "Barrel2", "Ground"]:
		var old = parent.get_node_or_null(n)
		if old:
			to_kill.append(old)
	for c in parent.get_children():
		var nm := str(c.name)
		if nm.begins_with("Cover") \
				or nm.begins_with("ArenaFloor") \
				or nm.begins_with("ArenaWall") \
				or nm.begins_with("ArenaPillar") \
				or nm.begins_with("SpawnPad") \
				or nm.begins_with("GatePost"):
			to_kill.append(c)
	for n in to_kill:
		if is_instance_valid(n):
			parent.remove_child(n)
			n.free()

	var wood := Catalog.make_prop_material(Catalog.PSKIN_CRATE_WOOD)
	var metal := Catalog.make_prop_material(Catalog.PSKIN_BARREL_METAL)
	var stone := _stone_mat()
	var floor_mat := _floor_mat()
	var wall_mat := _wall_mat()

	_add_floor(parent, floor_mat)
	_add_perimeter(parent, wall_mat)
	_add_designed_cover(parent, wood, metal, stone)
	_add_spawn_pads(parent, metal)
	_add_ambient_trim(parent, stone)

	print("ArenaEnvironment: finished courtyard half=", HALF)
	return {
		"half": HALF,
		"floor_y": FLOOR_Y,
		"loot_points": _loot_points(),
		"spawn_p1": Vector3(-HALF + 3.5, FLOOR_Y + 1.0, -HALF + 3.5),
		"spawn_p2": Vector3(HALF - 3.5, FLOOR_Y + 1.0, HALF - 3.5),
	}


static func _floor_mat() -> StandardMaterial3D:
	var path := "res://assets/textures/polyhaven/aerial_rocks_02/Diffuse_1k.jpg"
	if ResourceLoader.exists(path):
		var m = MatFactory.load_pbr("aerial_rocks_02")
		m.uv1_scale = Vector3(8, 8, 8)
		return m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.28, 0.27, 0.26)
	mat.roughness = 0.9
	return mat


static func _wall_mat() -> StandardMaterial3D:
	var path := "res://assets/textures/polyhaven/rock_face/Diffuse_1k.jpg"
	if ResourceLoader.exists(path):
		var m = MatFactory.load_pbr("rock_face")
		m.uv1_scale = Vector3(2.5, 1.2, 2.5)
		m.albedo_color = Color(0.55, 0.52, 0.5)
		return m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.34, 0.33)
	mat.roughness = 0.85
	return mat


static func _stone_mat() -> StandardMaterial3D:
	return _wall_mat()


static func _add_floor(parent: Node3D, mat: Material) -> void:
	var body := StaticBody3D.new()
	body.name = "ArenaFloor"
	var size := Vector3(HALF * 2.0 + 2.0, 1.0, HALF * 2.0 + 2.0)
	# Center so top face is at FLOOR_Y
	body.position = Vector3(0, FLOOR_Y - size.y * 0.5, 0)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	var mi := MeshInstance3D.new()
	mi.name = "MeshInstance3D"
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	body.add_child(mi)
	parent.add_child(body)


static func _add_perimeter(parent: Node3D, mat: Material) -> void:
	# Four walls sitting on floor; inner face at ±HALF
	var len := HALF * 2.0 + WALL_T
	# North (+Z), South (-Z)
	_wall(parent, "ArenaWallN", Vector3(0, FLOOR_Y + WALL_H * 0.5, HALF + WALL_T * 0.5), Vector3(len, WALL_H, WALL_T), mat)
	_wall(parent, "ArenaWallS", Vector3(0, FLOOR_Y + WALL_H * 0.5, -HALF - WALL_T * 0.5), Vector3(len, WALL_H, WALL_T), mat)
	# East (+X), West (-X)
	_wall(parent, "ArenaWallE", Vector3(HALF + WALL_T * 0.5, FLOOR_Y + WALL_H * 0.5, 0), Vector3(WALL_T, WALL_H, len), mat)
	_wall(parent, "ArenaWallW", Vector3(-HALF - WALL_T * 0.5, FLOOR_Y + WALL_H * 0.5, 0), Vector3(WALL_T, WALL_H, len), mat)
	# Corner pillars (finish the silhouette)
	for xz in [[HALF, HALF], [HALF, -HALF], [-HALF, HALF], [-HALF, -HALF]]:
		_wall(parent, "ArenaPillar_%d_%d" % [xz[0], xz[1]],
			Vector3(float(xz[0]), FLOOR_Y + 1.5, float(xz[1])),
			Vector3(0.9, 3.0, 0.9), mat)


static func _wall(parent: Node3D, name: String, pos: Vector3, size: Vector3, mat: Material) -> void:
	var body := StaticBody3D.new()
	body.name = name
	body.position = pos
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	var mi := MeshInstance3D.new()
	mi.name = "MeshInstance3D"
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	body.add_child(mi)
	parent.add_child(body)


static func _sit_y(half_height: float) -> float:
	return FLOOR_Y + half_height


static func _add_designed_cover(parent: Node3D, wood: Material, metal: Material, stone: Material) -> void:
	# Symmetric courtyard: mid walls, side caches, corner clusters — no overlaps
	# Center cross low walls
	_box(parent, "CoverMidN", Vector3(0, _sit_y(0.4), 2.8), Vector3(4.5, 0.8, 0.4), stone)
	_box(parent, "CoverMidS", Vector3(0, _sit_y(0.4), -2.8), Vector3(4.5, 0.8, 0.4), stone)
	_box(parent, "CoverMidE", Vector3(3.2, _sit_y(0.45), 0), Vector3(0.4, 0.9, 3.0), stone)
	_box(parent, "CoverMidW", Vector3(-3.2, _sit_y(0.45), 0), Vector3(0.4, 0.9, 3.0), stone)

	# Side lane crates (pairs)
	_box(parent, "CoverCrateNE", Vector3(6.5, _sit_y(0.55), 5.0), Vector3(1.1, 1.1, 1.1), wood)
	_box(parent, "CoverCrateNE2", Vector3(7.4, _sit_y(0.55), 6.0), Vector3(1.0, 1.1, 1.0), wood)
	_box(parent, "CoverCrateSW", Vector3(-6.5, _sit_y(0.55), -5.0), Vector3(1.1, 1.1, 1.1), wood)
	_box(parent, "CoverCrateSW2", Vector3(-7.4, _sit_y(0.55), -6.0), Vector3(1.0, 1.1, 1.0), wood)
	_box(parent, "CoverCrateNW", Vector3(-6.8, _sit_y(0.55), 5.5), Vector3(1.1, 1.1, 1.1), wood)
	_box(parent, "CoverCrateSE", Vector3(6.8, _sit_y(0.55), -5.5), Vector3(1.1, 1.1, 1.1), wood)

	# Barrels along east/west flanks
	_cyl(parent, "CoverBarrelE1", Vector3(8.5, _sit_y(0.55), 1.5), 0.45, 1.1, metal)
	_cyl(parent, "CoverBarrelE2", Vector3(8.5, _sit_y(0.55), -1.5), 0.45, 1.1, metal)
	_cyl(parent, "CoverBarrelW1", Vector3(-8.5, _sit_y(0.55), 1.5), 0.45, 1.1, metal)
	_cyl(parent, "CoverBarrelW2", Vector3(-8.5, _sit_y(0.55), -1.5), 0.45, 1.1, metal)
	_cyl(parent, "CoverBarrelN", Vector3(0, _sit_y(0.55), 8.8), 0.48, 1.1, metal)
	_cyl(parent, "CoverBarrelS", Vector3(0, _sit_y(0.55), -8.8), 0.48, 1.1, metal)

	# Outer low berms for edge fights
	_box(parent, "CoverBermN", Vector3(0, _sit_y(0.35), 10.0), Vector3(8.0, 0.7, 0.5), stone)
	_box(parent, "CoverBermS", Vector3(0, _sit_y(0.35), -10.0), Vector3(8.0, 0.7, 0.5), stone)


static func _add_spawn_pads(parent: Node3D, metal: Material) -> void:
	var pad_mat := metal.duplicate() if metal is StandardMaterial3D else StandardMaterial3D.new()
	if pad_mat is StandardMaterial3D:
		(pad_mat as StandardMaterial3D).albedo_color = Color(0.4, 0.42, 0.48)
		(pad_mat as StandardMaterial3D).emission_enabled = true
		(pad_mat as StandardMaterial3D).emission = Color(0.3, 0.35, 0.5)
		(pad_mat as StandardMaterial3D).emission_energy_multiplier = 0.35
	# Thin pads on floor
	_box(parent, "SpawnPadP1", Vector3(-HALF + 3.5, FLOOR_Y + 0.04, -HALF + 3.5), Vector3(2.2, 0.08, 2.2), pad_mat)
	_box(parent, "SpawnPadP2", Vector3(HALF - 3.5, FLOOR_Y + 0.04, HALF - 3.5), Vector3(2.2, 0.08, 2.2), pad_mat)


static func _add_ambient_trim(parent: Node3D, stone: Material) -> void:
	# Gate posts at mid-walls for "arena" identity
	for x in [-2.4, 2.4]:
		_box(parent, "GatePostN_%d" % int(x), Vector3(x, _sit_y(1.1), HALF - 0.8), Vector3(0.45, 2.2, 0.45), stone)
		_box(parent, "GatePostS_%d" % int(x), Vector3(x, _sit_y(1.1), -HALF + 0.8), Vector3(0.45, 2.2, 0.45), stone)


static func _loot_points() -> Array:
	# Denser contested caches — cover-adjacent + mid lanes
	return [
		Vector3(0, FLOOR_Y + 0.35, 5.5),
		Vector3(0, FLOOR_Y + 0.35, -5.5),
		Vector3(5.5, FLOOR_Y + 0.35, 0),
		Vector3(-5.5, FLOOR_Y + 0.35, 0),
		Vector3(7.0, FLOOR_Y + 0.35, 7.0),
		Vector3(-7.0, FLOOR_Y + 0.35, -7.0),
		Vector3(7.0, FLOOR_Y + 0.35, -7.0),
		Vector3(-7.0, FLOOR_Y + 0.35, 7.0),
		Vector3(4.0, FLOOR_Y + 0.35, -4.0),
		Vector3(-4.0, FLOOR_Y + 0.35, 4.0),
		Vector3(3.2, FLOOR_Y + 0.35, 6.2),
		Vector3(-3.2, FLOOR_Y + 0.35, -6.2),
		Vector3(6.2, FLOOR_Y + 0.35, 3.0),
		Vector3(-6.2, FLOOR_Y + 0.35, -3.0),
	]


static func _box(parent: Node3D, name: String, pos: Vector3, size: Vector3, mat: Material) -> void:
	var body := StaticBody3D.new()
	body.name = name
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 1
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	var mi := MeshInstance3D.new()
	mi.name = "MeshInstance3D"
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	body.add_child(mi)
	parent.add_child(body)


static func _cyl(parent: Node3D, name: String, pos: Vector3, radius: float, height: float, mat: Material) -> void:
	var body := StaticBody3D.new()
	body.name = name
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 1
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	cs.shape = shape
	body.add_child(cs)
	var mi := MeshInstance3D.new()
	mi.name = "MeshInstance3D"
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mi.mesh = mesh
	mi.material_override = mat
	body.add_child(mi)
	parent.add_child(body)
