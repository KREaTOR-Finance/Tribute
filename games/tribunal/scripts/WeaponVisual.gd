# WeaponVisual.gd — Tribunal weapon skins (Culling-readable tools)
# Prefers first-class skin kit OBJs, then glb/obj fallbacks, then procedural.
extends Node3D

const Catalog = preload("res://scripts/SkinCatalog.gd")
const ObjLoader = preload("res://scripts/ObjMeshLoader.gd")

@export var weapon_type: int = 0  # 0=None, 1=Sword, 2=Axe, 3=Dagger
@export var skin_id: String = ""

var current_mesh: Node3D = null
var mesh_instance: MeshInstance3D = null

# Legacy mesh assets (used if skin kit OBJ missing)
const WEAPON_PATHS = {
	1: "res://assets/models/weapons/sword_simple.glb",
	2: "res://assets/models/weapons/axe_simple.glb",
	3: "res://assets/models/weapons/dagger.obj",
}


func _ready():
	if skin_id == "":
		skin_id = Catalog.default_weapon_skin(weapon_type)
	_apply_visual(weapon_type)


func set_weapon_type(new_type: int, new_skin: String = ""):
	weapon_type = new_type
	if new_skin != "":
		skin_id = new_skin
	else:
		skin_id = Catalog.default_weapon_skin(weapon_type)
	_apply_visual(weapon_type)


func set_skin(new_skin: String):
	skin_id = new_skin
	_apply_visual(weapon_type)


func cycle_skin() -> String:
	var keys: Array = Catalog.weapon_skins().keys()
	var idx := keys.find(skin_id)
	idx = (idx + 1) % keys.size()
	set_skin(str(keys[idx]))
	return skin_id


func _apply_visual(type: int):
	if current_mesh:
		current_mesh.queue_free()
		current_mesh = null
		mesh_instance = null

	if skin_id == "":
		skin_id = Catalog.default_weapon_skin(type)

	var visual_node: Node3D = null
	var source := "procedural"

	# 1) First-class skin kit OBJ (Blender export via build_skin_kit)
	var obj_path := Catalog.weapon_mesh_path(skin_id, type)
	if obj_path != "" and FileAccess.file_exists(obj_path):
		var blade_mat = Catalog.make_weapon_blade_material(skin_id)
		var mi = ObjLoader.make_mesh_instance(obj_path, blade_mat)
		if mi:
			# Skin kit weapons are authored blade-forward along +Y in Blender; orient to hand -Z
			mi.name = "SkinKitWeapon"
			mi.rotation_degrees = Vector3(90, 0, 0)
			mi.position = Vector3(0, 0, -0.15)
			visual_node = mi
			source = "skin_obj"

	# 2) Legacy packed/mesh assets
	if visual_node == null:
		var asset_path = WEAPON_PATHS.get(type, "")
		if asset_path != "" and ResourceLoader.exists(asset_path):
			var packed = load(asset_path)
			if packed is PackedScene:
				visual_node = packed.instantiate()
				source = "glb"
			elif packed is Mesh:
				visual_node = MeshInstance3D.new()
				(visual_node as MeshInstance3D).mesh = packed
				source = "mesh_res"

	# 3) Procedural fallback
	if visual_node == null:
		visual_node = _create_procedural_weapon(type)
		source = "procedural"

	if visual_node:
		add_child(visual_node)
		current_mesh = visual_node
		if visual_node is MeshInstance3D:
			mesh_instance = visual_node
		else:
			mesh_instance = _find_first_mesh(visual_node)
		if source != "skin_obj":
			_paint_skin(visual_node, type)
			visual_node.position = Vector3(0, 0, -0.55)
			if type == 2:
				visual_node.rotation_degrees = Vector3(0, 0, 15)
		print("WeaponVisual: type=", type, " skin=", skin_id, " src=", source)


func _paint_skin(root: Node, type: int) -> void:
	var blade_mat = Catalog.make_weapon_blade_material(skin_id)
	var grip_mat = Catalog.make_weapon_grip_material(skin_id)
	var meshes: Array = []
	_collect_meshes(root, meshes)
	for i in meshes.size():
		var mi: MeshInstance3D = meshes[i]
		# First mesh = blade/head, others grip-ish
		mi.material_override = blade_mat if i == 0 else grip_mat


func _collect_meshes(node: Node, out: Array) -> void:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		out.append(node)
	for c in node.get_children():
		_collect_meshes(c, out)


func _create_procedural_weapon(type: int) -> Node3D:
	var root = Node3D.new()
	match type:
		1:  # SWORD
			var blade = MeshInstance3D.new()
			var bm = BoxMesh.new()
			bm.size = Vector3(0.07, 0.035, 1.15)
			blade.mesh = bm
			blade.position = Vector3(0, 0, -0.55)
			blade.name = "Blade"
			root.add_child(blade)
			var guard = MeshInstance3D.new()
			var gm = BoxMesh.new()
			gm.size = Vector3(0.34, 0.06, 0.06)
			guard.mesh = gm
			guard.position = Vector3(0, 0, -0.1)
			guard.name = "Guard"
			root.add_child(guard)
			var handle = MeshInstance3D.new()
			var hm = BoxMesh.new()
			hm.size = Vector3(0.05, 0.05, 0.28)
			handle.mesh = hm
			handle.position = Vector3(0, 0, 0.12)
			handle.name = "Grip"
			root.add_child(handle)
		2:  # AXE
			var handle = MeshInstance3D.new()
			var hm = BoxMesh.new()
			hm.size = Vector3(0.06, 0.06, 0.95)
			handle.mesh = hm
			handle.position = Vector3(0, 0, -0.4)
			handle.name = "Grip"
			root.add_child(handle)
			var head = MeshInstance3D.new()
			var xm = BoxMesh.new()
			xm.size = Vector3(0.52, 0.1, 0.32)
			head.mesh = xm
			head.position = Vector3(0.18, 0.05, -0.78)
			head.name = "Blade"
			root.add_child(head)
		3:  # DAGGER
			var blade = MeshInstance3D.new()
			var bm = BoxMesh.new()
			bm.size = Vector3(0.045, 0.03, 0.58)
			blade.mesh = bm
			blade.position = Vector3(0, 0, -0.28)
			blade.name = "Blade"
			root.add_child(blade)
			var hilt = MeshInstance3D.new()
			var hm = BoxMesh.new()
			hm.size = Vector3(0.09, 0.09, 0.14)
			hilt.mesh = hm
			hilt.position = Vector3(0, 0, 0.06)
			hilt.name = "Grip"
			root.add_child(hilt)
		_:
			var fist = MeshInstance3D.new()
			var sm = SphereMesh.new()
			sm.radius = 0.1
			fist.mesh = sm
			fist.position = Vector3(0, 0, -0.15)
			root.add_child(fist)
	return root


func _find_first_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var found = _find_first_mesh(child)
		if found:
			return found
	return null


func get_current_mesh() -> MeshInstance3D:
	return mesh_instance
