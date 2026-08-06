# WeaponVisual.gd
# Handles swapping visual 3D models for equipped weapons.
# Supports both real imported glTF/glb and procedural placeholders.
# Attach this as a child of Player (e.g. under a "Hand" Node3D or directly).

extends Node3D

@export var weapon_type: int = 0  # 0=None, 1=Sword, 2=Axe, 3=Dagger (matches Weapon.WeaponType)

var current_mesh: Node3D = null
var mesh_instance: MeshInstance3D = null

# Paths to real assets (will be used if present)
const WEAPON_PATHS = {
	1: "res://assets/models/weapons/sword_simple.glb",   # or sword.glb after conversion
	2: "res://assets/models/weapons/axe_simple.glb",
	3: "res://assets/models/weapons/dagger.obj"   # fallback obj for now
}

func _ready():
	_apply_visual(weapon_type)

func set_weapon_type(new_type: int):
	weapon_type = new_type
	_apply_visual(new_type)

func _apply_visual(type: int):
	# Remove previous visual
	if current_mesh:
		current_mesh.queue_free()
		current_mesh = null
		mesh_instance = null

	var visual_node: Node3D = null

	# Try to load real imported asset first
	var asset_path = WEAPON_PATHS.get(type, "")
	if asset_path != "" and ResourceLoader.exists(asset_path):
		var packed = load(asset_path)
		if packed is PackedScene:
			visual_node = packed.instantiate()
			print("WeaponVisual: Loaded real asset ", asset_path)
		elif packed is Mesh:
			# Direct mesh (for .obj that import as Mesh)
			visual_node = MeshInstance3D.new()
			(visual_node as MeshInstance3D).mesh = packed
			print("WeaponVisual: Loaded mesh asset ", asset_path)
	else:
		# Fallback to procedural primitives (always works for testing)
		visual_node = _create_procedural_weapon(type)

	if visual_node:
		add_child(visual_node)
		current_mesh = visual_node
		
		# Try to find the main mesh for material tweaks
		if visual_node is MeshInstance3D:
			mesh_instance = visual_node
		else:
			mesh_instance = _find_first_mesh(visual_node)
		
		# Apply basic material for nice look
		if mesh_instance and mesh_instance.mesh:
			var mat = StandardMaterial3D.new()
			if type == 2:  # Axe - heavier, bronze-ish
				mat.albedo_color = Color(0.55, 0.45, 0.35)
				mat.metallic = 0.4
			else:  # Sword / Dagger - steel
				mat.albedo_color = Color(0.75, 0.78, 0.82)
				mat.metallic = 0.7
			mat.roughness = 0.25
			mesh_instance.material_override = mat
		
		# Position/rotate for hand (adjust these per model if needed)
		visual_node.position = Vector3(0, 0, -0.6)
		if type == 2:
			visual_node.rotation_degrees = Vector3(0, 0, 90)  # axe head orientation

	print("WeaponVisual: Switched to weapon type ", type, " (", "real asset" if ResourceLoader.exists(asset_path) else "procedural", ")")

func _create_procedural_weapon(type: int) -> Node3D:
	var root = Node3D.new()
	var mi = MeshInstance3D.new()
	root.add_child(mi)
	
	match type:
		1:  # SWORD
			var blade = BoxMesh.new()
			blade.size = Vector3(0.06, 0.06, 1.1)
			mi.mesh = blade
			mi.position = Vector3(0, 0, -0.55)
			
			# Crossguard
			var guard = MeshInstance3D.new()
			guard.mesh = BoxMesh.new()
			(guard.mesh as BoxMesh).size = Vector3(0.32, 0.05, 0.05)
			root.add_child(guard)
			guard.position = Vector3(0, 0, -0.12)
			
			# Handle
			var handle = MeshInstance3D.new()
			handle.mesh = BoxMesh.new()
			(handle.mesh as BoxMesh).size = Vector3(0.04, 0.04, 0.25)
			root.add_child(handle)
			handle.position = Vector3(0, 0, 0.1)
			
		2:  # AXE
			var handle = MeshInstance3D.new()
			handle.mesh = BoxMesh.new()
			(handle.mesh as BoxMesh).size = Vector3(0.05, 0.05, 0.9)
			root.add_child(handle)
			handle.position = Vector3(0, 0, -0.45)
			
			var head = MeshInstance3D.new()
			head.mesh = BoxMesh.new()
			(head.mesh as BoxMesh).size = Vector3(0.5, 0.08, 0.3)
			root.add_child(head)
			head.position = Vector3(0, 0.2, -0.75)
			mi = handle  # track main
			
		3:  # DAGGER
			var blade = BoxMesh.new()
			blade.size = Vector3(0.04, 0.04, 0.55)
			mi.mesh = blade
			mi.position = Vector3(0, 0, -0.28)
			
			var hilt = MeshInstance3D.new()
			hilt.mesh = BoxMesh.new()
			(hilt.mesh as BoxMesh).size = Vector3(0.08, 0.08, 0.12)
			root.add_child(hilt)
			hilt.position = Vector3(0, 0, 0.05)
		_:
			var fist = SphereMesh.new()
			fist.radius = 0.1
			mi.mesh = fist
			mi.position = Vector3(0, 0, -0.15)
	
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
