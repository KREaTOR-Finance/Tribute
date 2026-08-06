extends RefCounted
class_name SkinCatalog
## Tribunal art/skins registry — character + weapon + arena skins.
## Culling-style identity: readable silhouettes, distinct weapon skins, team colors.

const MatFactory = preload("res://scripts/TribunalMaterialFactory.gd")
const ObjLoader = preload("res://scripts/ObjMeshLoader.gd")

# Character skin ids
const SKIN_HUNTER_CRIMSON := "hunter_crimson"
const SKIN_HUNTER_AZURE := "hunter_azure"
const SKIN_HUNTER_BONE := "hunter_bone"
const SKIN_HUNTER_IRON := "hunter_iron"

# Weapon skin ids
const WSKIN_STEEL := "steel"
const WSKIN_BLOODSTEEL := "bloodsteel"
const WSKIN_BRONZE := "bronze"
const WSKIN_BONE := "bone"
const WSKIN_OBSIDIAN := "obsidian"

# Prop skin ids
const PSKIN_CRATE_WOOD := "crate_wood"
const PSKIN_BARREL_METAL := "barrel_metal"
const PSKIN_LOOT_GOLD := "loot_gold"
const PSKIN_DEATH_MARK := "death_mark"

const SKIN_MESH_DIR := "res://assets/models/skins/"


static func character_skins() -> Dictionary:
	return {
		SKIN_HUNTER_CRIMSON: {
			"name": "Crimson Hunter",
			"body": Color(0.72, 0.14, 0.12),
			"accent": Color(0.95, 0.35, 0.2),
			"metal": Color(0.55, 0.5, 0.45),
			"pbr_armor": "metal_plate",
			"mesh": SKIN_MESH_DIR + "char_crimson.obj",
			"team": 1,
		},
		SKIN_HUNTER_AZURE: {
			"name": "Azure Hunter",
			"body": Color(0.18, 0.35, 0.78),
			"accent": Color(0.35, 0.65, 1.0),
			"metal": Color(0.5, 0.55, 0.65),
			"pbr_armor": "metal_plate",
			"mesh": SKIN_MESH_DIR + "char_azure.obj",
			"team": 2,
		},
		SKIN_HUNTER_BONE: {
			"name": "Bone Ritualist",
			"body": Color(0.85, 0.8, 0.7),
			"accent": Color(0.55, 0.15, 0.15),
			"metal": Color(0.7, 0.65, 0.55),
			"pbr_armor": "rock_face",
			"mesh": SKIN_MESH_DIR + "char_bone.obj",
			"team": 0,
		},
		SKIN_HUNTER_IRON: {
			"name": "Ironclad",
			"body": Color(0.35, 0.36, 0.38),
			"accent": Color(0.9, 0.55, 0.15),
			"metal": Color(0.65, 0.68, 0.72),
			"pbr_armor": "metal_plate",
			"mesh": SKIN_MESH_DIR + "char_iron.obj",
			"team": 0,
		},
	}


static func weapon_skins() -> Dictionary:
	return {
		WSKIN_STEEL: {
			"name": "Steel",
			"blade": Color(0.78, 0.8, 0.85),
			"grip": Color(0.25, 0.15, 0.1),
			"metallic": 0.85,
			"roughness": 0.28,
			"pbr": "metal_plate",
			"mesh_sword": SKIN_MESH_DIR + "wpn_sword_steel.obj",
			"mesh_axe": SKIN_MESH_DIR + "wpn_axe_bronze.obj",
			"mesh_dagger": SKIN_MESH_DIR + "wpn_dagger_obsidian.obj",
		},
		WSKIN_BLOODSTEEL: {
			"name": "Bloodsteel",
			"blade": Color(0.55, 0.12, 0.12),
			"grip": Color(0.15, 0.08, 0.08),
			"metallic": 0.75,
			"roughness": 0.35,
			"pbr": "metal_plate",
			"mesh_sword": SKIN_MESH_DIR + "wpn_sword_blood.obj",
			"mesh_axe": SKIN_MESH_DIR + "wpn_axe_bronze.obj",
			"mesh_dagger": SKIN_MESH_DIR + "wpn_dagger_obsidian.obj",
		},
		WSKIN_BRONZE: {
			"name": "Bronze",
			"blade": Color(0.7, 0.48, 0.22),
			"grip": Color(0.3, 0.18, 0.1),
			"metallic": 0.7,
			"roughness": 0.4,
			"pbr": "metal_plate",
			"mesh_sword": SKIN_MESH_DIR + "wpn_sword_steel.obj",
			"mesh_axe": SKIN_MESH_DIR + "wpn_axe_bronze.obj",
			"mesh_dagger": SKIN_MESH_DIR + "wpn_dagger_obsidian.obj",
		},
		WSKIN_BONE: {
			"name": "Bone",
			"blade": Color(0.9, 0.86, 0.75),
			"grip": Color(0.4, 0.25, 0.15),
			"metallic": 0.15,
			"roughness": 0.7,
			"pbr": "wood_cabinet_worn_long",
			"mesh_sword": SKIN_MESH_DIR + "wpn_sword_blood.obj",
			"mesh_axe": SKIN_MESH_DIR + "wpn_axe_bronze.obj",
			"mesh_dagger": SKIN_MESH_DIR + "wpn_dagger_obsidian.obj",
		},
		WSKIN_OBSIDIAN: {
			"name": "Obsidian",
			"blade": Color(0.08, 0.08, 0.12),
			"grip": Color(0.2, 0.05, 0.15),
			"metallic": 0.4,
			"roughness": 0.2,
			"pbr": "rock_face",
			"mesh_sword": SKIN_MESH_DIR + "wpn_sword_blood.obj",
			"mesh_axe": SKIN_MESH_DIR + "wpn_axe_bronze.obj",
			"mesh_dagger": SKIN_MESH_DIR + "wpn_dagger_obsidian.obj",
		},
	}


static func prop_skins() -> Dictionary:
	return {
		PSKIN_CRATE_WOOD: {
			"name": "Wood Crate",
			"pbr": "wood_cabinet_worn_long",
			"color": Color(0.55, 0.38, 0.22),
			"kind": "crate",
		},
		PSKIN_BARREL_METAL: {
			"name": "Iron Barrel",
			"pbr": "metal_plate",
			"color": Color(0.45, 0.48, 0.5),
			"kind": "barrel",
		},
		PSKIN_LOOT_GOLD: {
			"name": "Scavenge Cache",
			"pbr": "metal_plate",
			"color": Color(1.0, 0.82, 0.25),
			"emissive": 1.4,
			"kind": "loot",
		},
		PSKIN_DEATH_MARK: {
			"name": "Fallen Mark",
			"pbr": "rock_face",
			"color": Color(0.25, 0.05, 0.05),
			"emissive": 0.6,
			"kind": "death",
		},
	}



static func default_character_skin(player_id: int) -> String:
	return SKIN_HUNTER_AZURE if player_id == 2 else SKIN_HUNTER_CRIMSON


static func default_weapon_skin(weapon_type: int) -> String:
	match weapon_type:
		2:  # axe
			return WSKIN_BRONZE
		3:  # dagger
			return WSKIN_OBSIDIAN
		_:
			return WSKIN_STEEL


static func make_body_material(skin_id: String) -> StandardMaterial3D:
	var skins := character_skins()
	var s: Dictionary = skins.get(skin_id, skins[SKIN_HUNTER_CRIMSON])
	var mat := StandardMaterial3D.new()
	mat.albedo_color = s["body"]
	mat.roughness = 0.55
	mat.metallic = 0.15
	# Optional armor PBR overlay tint
	var pbr_path := "res://assets/textures/polyhaven/%s/Diffuse_1k.jpg" % str(s.get("pbr_armor", ""))
	if s.has("pbr_armor") and ResourceLoader.exists(pbr_path):
		var base = MatFactory.load_pbr(str(s["pbr_armor"]))
		base.albedo_color = s["body"]
		base.uv1_scale = Vector3(2, 2, 2)
		return base
	return mat


static func make_accent_material(skin_id: String) -> StandardMaterial3D:
	var skins := character_skins()
	var s: Dictionary = skins.get(skin_id, skins[SKIN_HUNTER_CRIMSON])
	var mat := StandardMaterial3D.new()
	mat.albedo_color = s["accent"]
	mat.emission_enabled = true
	mat.emission = s["accent"]
	mat.emission_energy_multiplier = 0.35
	mat.roughness = 0.4
	return mat


static func make_weapon_blade_material(skin_id: String) -> StandardMaterial3D:
	var skins := weapon_skins()
	var s: Dictionary = skins.get(skin_id, skins[WSKIN_STEEL])
	var pbr_name := str(s.get("pbr", "metal_plate"))
	var pbr_path := "res://assets/textures/polyhaven/%s/Diffuse_1k.jpg" % pbr_name
	if ResourceLoader.exists(pbr_path):
		var mat = MatFactory.load_pbr(pbr_name)
		mat.albedo_color = s["blade"]
		mat.metallic = float(s["metallic"])
		mat.roughness = float(s["roughness"])
		mat.uv1_scale = Vector3(1.5, 1.5, 1.5)
		return mat
	var mat2 := StandardMaterial3D.new()
	mat2.albedo_color = s["blade"]
	mat2.metallic = float(s["metallic"])
	mat2.roughness = float(s["roughness"])
	return mat2


static func make_weapon_grip_material(skin_id: String) -> StandardMaterial3D:
	var skins := weapon_skins()
	var s: Dictionary = skins.get(skin_id, skins[WSKIN_STEEL])
	var mat := StandardMaterial3D.new()
	mat.albedo_color = s["grip"]
	mat.roughness = 0.85
	mat.metallic = 0.05
	return mat


## Builds hunter body: prefers first-class skin OBJ, else procedural rig.
static func build_character_rig(parent: Node3D, skin_id: String) -> Node3D:
	var root := Node3D.new()
	root.name = "SkinRig"
	var body_mat := make_body_material(skin_id)
	var accent_mat := make_accent_material(skin_id)
	var skins := character_skins()
	var s: Dictionary = skins.get(skin_id, skins[SKIN_HUNTER_CRIMSON])
	var mesh_path := str(s.get("mesh", ""))

	# First-class mesh from skin kit OBJ
	if mesh_path != "" and FileAccess.file_exists(mesh_path):
		var mi = ObjLoader.make_mesh_instance(mesh_path, body_mat)
		if mi:
			mi.name = "BodyMesh"
			# Blender exports are ~2m tall; feet near y=0
			mi.scale = Vector3(1.0, 1.0, 1.0)
			mi.position = Vector3(0, 0, 0)
			root.add_child(mi)
			# Accent shoulder orbs for team readability
			for x in [-0.38, 0.38]:
				var pad := MeshInstance3D.new()
				var box := BoxMesh.new()
				box.size = Vector3(0.18, 0.12, 0.22)
				pad.mesh = box
				pad.position = Vector3(x, 1.42, 0.05)
				pad.material_override = accent_mat
				root.add_child(pad)
			parent.add_child(root)
			print("SkinCatalog: OBJ character mesh ", mesh_path)
			return root

	# Procedural fallback
	var torso := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.36
	cap.height = 1.05
	torso.mesh = cap
	torso.position = Vector3(0, 1.05, 0)
	torso.material_override = body_mat
	torso.name = "Torso"
	root.add_child(torso)

	var head := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.22
	head.mesh = sph
	head.position = Vector3(0, 1.78, 0)
	head.material_override = body_mat
	head.name = "Head"
	root.add_child(head)

	for x in [-0.42, 0.42]:
		var pad := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.22, 0.14, 0.28)
		pad.mesh = box
		pad.position = Vector3(x, 1.45, 0)
		pad.material_override = accent_mat
		root.add_child(pad)

	for x in [-0.16, 0.16]:
		var leg := MeshInstance3D.new()
		var lmesh := CapsuleMesh.new()
		lmesh.radius = 0.12
		lmesh.height = 0.7
		leg.mesh = lmesh
		leg.position = Vector3(x, 0.45, 0)
		leg.material_override = body_mat
		root.add_child(leg)

	parent.add_child(root)
	print("SkinCatalog: procedural character fallback ", skin_id)
	return root


static func weapon_mesh_path(skin_id: String, weapon_type: int) -> String:
	var skins := weapon_skins()
	var s: Dictionary = skins.get(skin_id, skins[WSKIN_STEEL])
	match weapon_type:
		2:
			return str(s.get("mesh_axe", ""))
		3:
			return str(s.get("mesh_dagger", ""))
		_:
			return str(s.get("mesh_sword", ""))


static func make_prop_material(prop_skin_id: String) -> StandardMaterial3D:
	var skins := prop_skins()
	var s: Dictionary = skins.get(prop_skin_id, skins[PSKIN_CRATE_WOOD])
	var pbr := str(s.get("pbr", "wood_cabinet_worn_long"))
	var path := "res://assets/textures/polyhaven/%s/Diffuse_1k.jpg" % pbr
	var mat: StandardMaterial3D
	if ResourceLoader.exists(path):
		mat = MatFactory.load_pbr(pbr)
	else:
		mat = StandardMaterial3D.new()
	mat.albedo_color = s.get("color", Color.WHITE)
	if s.has("emissive"):
		mat.emission_enabled = true
		mat.emission = s["color"]
		mat.emission_energy_multiplier = float(s["emissive"])
	mat.uv1_scale = Vector3(1.5, 1.5, 1.5)
	return mat
