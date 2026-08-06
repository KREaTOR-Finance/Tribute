extends RefCounted
class_name ArenaCover
## Procedural denser cover for MeleeTest — lanes, chokes, low walls (Culling spacing).

const Catalog = preload("res://scripts/SkinCatalog.gd")
const MatFactory = preload("res://scripts/TribunalMaterialFactory.gd")


## Spawn extra crates/barrels/walls under parent. Skins via PropSkins materials.
static func spawn_dense_cover(parent: Node3D) -> int:
	var wood := Catalog.make_prop_material(Catalog.PSKIN_CRATE_WOOD)
	var metal := Catalog.make_prop_material(Catalog.PSKIN_BARREL_METAL)
	var stone := MatFactory.load_pbr("rock_face") if ResourceLoader.exists("res://assets/textures/polyhaven/rock_face/Diffuse_1k.jpg") else StandardMaterial3D.new()
	if stone is StandardMaterial3D:
		(stone as StandardMaterial3D).albedo_color = Color(0.45, 0.42, 0.4)
		(stone as StandardMaterial3D).uv1_scale = Vector3(1.2, 1.2, 1.2)

	var count := 0
	# Mid-lane crate clusters (cover for 1v1 + AI)
	var crates := [
		Vector3(-5.5, 0.6, 0.5),
		Vector3(-4.2, 0.6, 1.2),
		Vector3(5.0, 0.6, -1.0),
		Vector3(6.2, 0.6, -0.2),
		Vector3(0.0, 0.6, -6.5),
		Vector3(1.2, 0.6, -5.8),
		Vector3(-1.0, 0.6, 6.0),
		Vector3(0.8, 0.6, 6.8),
	]
	for p in crates:
		_add_box(parent, "CoverCrate%d" % count, p, Vector3(1.1, 1.15, 1.1), wood)
		count += 1

	var barrels := [
		Vector3(-7.0, 0.6, -3.5),
		Vector3(7.0, 0.6, 3.0),
		Vector3(-2.0, 0.6, -7.5),
		Vector3(3.5, 0.6, 7.0),
		Vector3(7.5, 0.6, -6.0),
		Vector3(-6.5, 0.6, 5.5),
	]
	for p in barrels:
		_add_cylinder(parent, "CoverBarrel%d" % count, p, 0.48, 1.15, metal)
		count += 1

	# Low walls — create chokes without full LOS block
	var walls := [
		{"pos": Vector3(-1.5, 0.45, 0.0), "size": Vector3(3.2, 0.9, 0.45)},
		{"pos": Vector3(4.0, 0.45, 2.5), "size": Vector3(0.45, 0.9, 3.5)},
		{"pos": Vector3(-4.5, 0.45, -3.0), "size": Vector3(0.45, 0.95, 2.8)},
		{"pos": Vector3(1.5, 0.55, 4.0), "size": Vector3(2.6, 1.1, 0.4)},
		{"pos": Vector3(-0.5, 0.4, -3.5), "size": Vector3(2.2, 0.8, 0.4)},
	]
	for w in walls:
		_add_box(parent, "CoverWall%d" % count, w["pos"], w["size"], stone)
		count += 1

	print("ArenaCover: spawned ", count, " cover pieces")
	return count


static func _add_box(parent: Node3D, name: String, pos: Vector3, size: Vector3, mat: Material) -> void:
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


static func _add_cylinder(parent: Node3D, name: String, pos: Vector3, radius: float, height: float, mat: Material) -> void:
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
