extends RefCounted
class_name VisualPolish
## Tribunal presentation pass — lighting, fog, glow for console-readable beauty.


static func apply_world(parent: Node3D) -> void:
	var sun := parent.get_node_or_null("DirectionalLight3D")
	if sun and sun is DirectionalLight3D:
		var d := sun as DirectionalLight3D
		d.shadow_enabled = true
		d.light_energy = 1.55
		d.light_color = Color(1.0, 0.94, 0.82)
		d.shadow_blur = 1.35
		# Slight late-afternoon angle for readable silhouettes
		d.rotation_degrees = Vector3(-48, 35, 0)
		d.directional_shadow_max_distance = 48.0

	var we: WorldEnvironment = parent.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if we == null:
		we = WorldEnvironment.new()
		we.name = "WorldEnvironment"
		parent.add_child(we)
	var e: Environment = we.environment if we.environment else Environment.new()
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.tonemap_exposure = 1.12
	e.tonemap_white = 6.0
	e.ssao_enabled = true
	e.ssao_radius = 1.35
	e.ssao_intensity = 2.4
	e.ssao_power = 1.5
	e.glow_enabled = true
	e.glow_intensity = 0.62
	e.glow_bloom = 0.28
	e.glow_hdr_threshold = 0.78
	e.glow_hdr_scale = 1.15
	e.adjustment_enabled = true
	e.adjustment_brightness = 1.02
	e.adjustment_contrast = 1.08
	e.adjustment_saturation = 1.1
	e.fog_enabled = true
	e.fog_light_color = Color(0.52, 0.56, 0.68)
	e.fog_density = 0.0032
	e.fog_aerial_perspective = 0.55
	e.fog_sky_affect = 0.35
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.36, 0.40, 0.52)
	e.ambient_light_energy = 0.58
	# Keep sky if already set
	if e.background_mode == Environment.BG_CLEAR_COLOR or e.sky == null:
		var hdri := "res://assets/hdri/polyhaven/kloppenheim_06_1k.hdr"
		if ResourceLoader.exists(hdri) or FileAccess.file_exists(hdri):
			var img := Image.new()
			if img.load(hdri) == OK:
				var tex := ImageTexture.create_from_image(img)
				e.background_mode = Environment.BG_SKY
				var sky := Sky.new()
				var sm := PanoramaSkyMaterial.new()
				sm.panorama = tex
				sky.sky_material = sm
				e.sky = sky
				e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
				e.ambient_light_energy = 0.78
	we.environment = e
	print("VisualPolish: ACES exposure+fog+sun pass")
