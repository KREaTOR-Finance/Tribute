extends RefCounted
class_name TribunalMaterialFactory
## Loads Poly Haven CC0 PBR maps into StandardMaterial3D (production-grade free textures).

static func load_pbr(folder: String, albedo_name := "Diffuse_1k.jpg") -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	var base := "res://assets/textures/polyhaven/%s/" % folder
	var albedo_path := base + albedo_name
	if ResourceLoader.exists(albedo_path):
		mat.albedo_texture = load(albedo_path)
	else:
		# Try common alternates
		for n in ["diff_1k.jpg", "Diffuse_1k.png"]:
			if ResourceLoader.exists(base + n):
				mat.albedo_texture = load(base + n)
				break
	var nrm := base + "nor_gl_1k.jpg"
	if ResourceLoader.exists(nrm):
		mat.normal_enabled = true
		mat.normal_texture = load(nrm)
		mat.normal_scale = 1.0
	var rough := base + "Rough_1k.jpg"
	if ResourceLoader.exists(rough):
		mat.roughness_texture = load(rough)
		mat.roughness = 1.0
	var metal := base + "Metal_1k.jpg"
	if ResourceLoader.exists(metal):
		mat.metallic_texture = load(metal)
		mat.metallic = 1.0
	var ao := base + "AO_1k.jpg"
	if ResourceLoader.exists(ao):
		mat.ao_enabled = true
		mat.ao_texture = load(ao)
	mat.uv1_scale = Vector3(4, 4, 4)
	return mat


static func make_emissive(color: Color, energy: float = 2.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	return mat
