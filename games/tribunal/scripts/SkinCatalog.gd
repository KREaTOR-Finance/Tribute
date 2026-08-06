extends RefCounted
class_name SkinCatalog
## Tribunal art/skins registry — character + weapon + arena skins.
## Culling-style identity: readable silhouettes, distinct weapon skins, team colors.

const MatFactory = preload("res://scripts/TribunalMaterialFactory.gd")

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

static func character_skins() -> Dictionary:
	return {
		SKIN_HUNTER_CRIMSON: {
			"name": "Crimson Hunter",
			"body": Color(0.72, 0.14, 0.12),
			"accent": Color(0.95, 0.35, 0.2),
			"metal": Color(0.55, 0.5, 0.45),
			"pbr_armor": "metal_plate",
			"team": 1,
		},
		SKIN_HUNTER_AZURE: {
			"name": "Azure Hunter",
			"body": Color(0.18, 0.35, 0.78),
			"accent": Color(0.35, 0.65, 1.0),
			"metal": Color(0.5, 0.55, 0.65),
			"pbr_armor": "metal_plate",
			"team": 2,
		},
		SKIN_HUNTER_BONE: {
			"name": "Bone Ritualist",
			"body": Color(0.85, 0.8, 0.7),
			"accent": Color(0.55, 0.15, 0.15),
			"metal": Color(0.7, 0.65, 0.55),
			"pbr_armor": "rock_face",
			"team": 0,
		},
		SKIN_HUNTER_IRON: {
			"name": "Ironclad",
			"body": Color(0.35, 0.36, 0.38),
			"accent": Color(0.9, 0.55, 0.15),
			"metal": Color(0.65, 0.68, 0.72),
			"pbr_armor": "metal_plate",
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
		},
		WSKIN_BLOODSTEEL: {
			"name": "Bloodsteel",
			"blade": Color(0.55, 0.12, 0.12),
			"grip": Color(0.15, 0.08, 0.08),
			"metallic": 0.75,
			"roughness": 0.35,
			"pbr": "metal_plate",
		},
		WSKIN_BRONZE: {
			"name": "Bronze",
			"blade": Color(0.7, 0.48, 0.22),
			"grip": Color(0.3, 0.18, 0.1),
			"metallic": 0.7,
			"roughness": 0.4,
			"pbr": "metal_plate",
		},
		WSKIN_BONE: {
			"name": "Bone",
			"blade": Color(0.9, 0.86, 0.75),
			"grip": Color(0.4, 0.25, 0.15),
			"metallic": 0.15,
			"roughness": 0.7,
			"pbr": "wood_cabinet_worn_long",
		},
		WSKIN_OBSIDIAN: {
			"name": "Obsidian",
			"blade": Color(0.08, 0.08, 0.12),
			"grip": Color(0.2, 0.05, 0.15),
			"metallic": 0.4,
			"roughness": 0.2,
			"pbr": "rock_face",
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


## Builds a multi-mesh Culling-readable hunter body under parent.
static func build_character_rig(parent: Node3D, skin_id: String) -> Node3D:
	var root := Node3D.new()
	root.name = "SkinRig"
	var body_mat := make_body_material(skin_id)
	var accent_mat := make_accent_material(skin_id)

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

	# Shoulder pads (accent)
	for x in [-0.42, 0.42]:
		var pad := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.22, 0.14, 0.28)
		pad.mesh = box
		pad.position = Vector3(x, 1.45, 0)
		pad.material_override = accent_mat
		root.add_child(pad)

	# Legs
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
	return root
