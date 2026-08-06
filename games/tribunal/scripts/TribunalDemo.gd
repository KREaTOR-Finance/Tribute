extends Node3D
## TRIBUNAL — playable shareable demo.
## Melee-first spiritual successor to The Culling: tutorial → scavenge → hunt → zone → victory.

const MatFactory = preload("res://scripts/TribunalMaterialFactory.gd")
const PlayerScript = preload("res://scripts/TribunalPlayer.gd")
const HunterScript = preload("res://scripts/HunterAI.gd")

enum Phase { TITLE, TUTORIAL, COMBAT, VICTORY, DEFEAT }

var phase: Phase = Phase.TITLE
var player: CharacterBody3D
var camera: Camera3D
var hud: CanvasLayer
var title_label: Label
var prompt_label: Label
var hp_bar: ProgressBar
var sta_bar: ProgressBar
var meta_label: Label
var tutorial_step: int = 0
var tutorial_done_flags: Dictionary = {}
var hunters_alive: int = 0
var kills: int = 0
var zone_radius: float = 40.0
var zone_mesh: MeshInstance3D
var match_time: float = 0.0
var traps_left: int = 2
var loot_remaining: int = 0

const ARENA_HALF := 28.0

func _ready() -> void:
	randomize()
	_build_world()
	_build_player()
	_build_hud()
	_spawn_loot()
	_set_phase(Phase.TITLE)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_world() -> void:
	# Lighting + environment (HDRI if present)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	add_child(sun)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.08, 0.09, 0.12)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.35, 0.38, 0.45)
	e.ambient_light_energy = 0.55
	e.tonemap_mode = Environment.TONE_MAPPER_ACES
	e.ssao_enabled = true
	e.glow_enabled = true
	e.glow_intensity = 0.35
	var hdri_path := "res://assets/hdri/polyhaven/kloppenheim_06_1k.hdr"
	if ResourceLoader.exists(hdri_path):
		var img := Image.new()
		if img.load(hdri_path) == OK:
			var tex := ImageTexture.create_from_image(img)
			e.background_mode = Environment.BG_SKY
			var sky := Sky.new()
			var sky_mat := PanoramaSkyMaterial.new()
			sky_mat.panorama = tex
			sky.sky_material = sky_mat
			e.sky = sky
			e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
			e.ambient_light_energy = 0.7
	env.environment = e
	add_child(env)

	# Floor with rock PBR
	var floor_body := StaticBody3D.new()
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(ARENA_HALF * 2.2, ARENA_HALF * 2.2)
	floor_mesh.mesh = plane
	floor_mesh.material_override = MatFactory.load_pbr("aerial_rocks_02")
	floor_body.add_child(floor_mesh)
	var floor_col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(ARENA_HALF * 2.2, 0.5, ARENA_HALF * 2.2)
	floor_col.shape = box
	floor_col.position.y = -0.25
	floor_body.add_child(floor_col)
	add_child(floor_body)

	# Walls
	_add_wall(Vector3(0, 2, ARENA_HALF), Vector3(ARENA_HALF * 2, 4, 0.4))
	_add_wall(Vector3(0, 2, -ARENA_HALF), Vector3(ARENA_HALF * 2, 4, 0.4))
	_add_wall(Vector3(ARENA_HALF, 2, 0), Vector3(0.4, 4, ARENA_HALF * 2))
	_add_wall(Vector3(-ARENA_HALF, 2, 0), Vector3(0.4, 4, ARENA_HALF * 2))

	# Cover crates (wood PBR)
	var wood = MatFactory.load_pbr("wood_cabinet_worn_long")
	wood.uv1_scale = Vector3(1.5, 1.5, 1.5)
	for p in [
		Vector3(-8, 0.6, -6), Vector3(9, 0.6, 4), Vector3(-4, 0.8, 10),
		Vector3(6, 0.6, -11), Vector3(12, 0.5, -3), Vector3(-12, 0.5, 5),
		Vector3(0, 1.2, 0), Vector3(-15, 0.6, -15), Vector3(14, 0.7, 12)
	]:
		_add_crate(p, wood)

	# Central metal pillar
	var pillar := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.7
	cyl.bottom_radius = 0.9
	cyl.height = 3.5
	pillar.mesh = cyl
	pillar.position = Vector3(0, 1.75, 0)
	pillar.material_override = MatFactory.load_pbr("metal_plate")
	add_child(pillar)
	var pillar_body := StaticBody3D.new()
	var pcs := CollisionShape3D.new()
	var pshape := CylinderShape3D.new()
	pshape.radius = 0.85
	pshape.height = 3.5
	pcs.shape = pshape
	pcs.position = Vector3(0, 1.75, 0)
	pillar_body.add_child(pcs)
	add_child(pillar_body)

	# Zone ring visual
	zone_mesh = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = zone_radius - 0.4
	torus.outer_radius = zone_radius
	zone_mesh.mesh = torus
	zone_mesh.position.y = 0.15
	zone_mesh.material_override = MatFactory.make_emissive(Color(0.2, 0.7, 1.0), 1.5)
	add_child(zone_mesh)

func _add_wall(pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var mat = MatFactory.load_pbr("rock_face")
	mat.uv1_scale = Vector3(size.x * 0.15, size.y * 0.15, 1)
	mi.material_override = mat
	body.position = pos
	body.add_child(mi)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	body.add_child(cs)
	add_child(body)

func _add_crate(pos: Vector3, mat: Material) -> void:
	var body := StaticBody3D.new()
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.4, 1.2, 1.4)
	mi.mesh = bm
	mi.material_override = mat
	body.position = pos
	body.add_child(mi)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = bm.size
	cs.shape = sh
	body.add_child(cs)
	add_child(body)

func _build_player() -> void:
	player = PlayerScript.new()
	player.name = "Player"
	player.position = Vector3(0, 1.2, 18)
	add_child(player)
	camera = Camera3D.new()
	camera.fov = 70
	camera.near = 0.08
	camera.far = 200
	add_child(camera)
	if player.has_signal("player_died"):
		player.player_died.connect(_on_player_died)
	if player.has_signal("health_changed"):
		player.health_changed.connect(_on_hp)
	if player.has_signal("stamina_changed"):
		player.stamina_changed.connect(_on_sta)

func _spawn_loot() -> void:
	loot_remaining = 0
	for i in 6:
		var loot := Area3D.new()
		loot.name = "Loot%d" % i
		loot.monitoring = true
		loot.collision_layer = 0
		loot.collision_mask = 1
		var cs := CollisionShape3D.new()
		var sp := SphereShape3D.new()
		sp.radius = 0.8
		cs.shape = sp
		loot.add_child(cs)
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.5, 0.35, 0.7)
		mi.mesh = bm
		mi.material_override = MatFactory.make_emissive(Color(1.0, 0.85, 0.2), 1.2)
		loot.add_child(mi)
		loot.position = Vector3(randf_range(-20, 20), 0.4, randf_range(-20, 12))
		loot.body_entered.connect(func(b):
			if b.is_in_group("players"):
				loot_remaining = max(0, loot_remaining - 1)
				if b.has_method("heal_partial"):
					b.heal_partial(15)
				elif "health" in b and "max_health" in b:
					b.health = mini(b.max_health, b.health + 15)
					if b.has_signal("health_changed"):
						b.health_changed.emit(b.health)
				_set_prompt("Loot secured. Hunters incoming.")
				loot.queue_free()
		)
		add_child(loot)
		loot_remaining += 1

func _spawn_hunters(count: int) -> void:
	for i in count:
		var h = HunterScript.new()
		h.position = Vector3(randf_range(-18, 18), 1.2, randf_range(-22, -8))
		h.set_target(player)
		h.died.connect(_on_hunter_died)
		add_child(h)
		hunters_alive += 1

func _build_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.add_child(root)

	title_label = Label.new()
	title_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title_label.offset_top = 40
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 42)
	title_label.text = "TRIBUNAL"
	root.add_child(title_label)

	prompt_label = Label.new()
	prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_label.offset_bottom = -48
	prompt_label.offset_top = -120
	prompt_label.offset_left = 80
	prompt_label.offset_right = -80
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt_label.add_theme_font_size_override("font_size", 20)
	root.add_child(prompt_label)

	hp_bar = ProgressBar.new()
	hp_bar.min_value = 0
	hp_bar.max_value = 100
	hp_bar.value = 100
	hp_bar.show_percentage = false
	hp_bar.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	hp_bar.offset_left = 32
	hp_bar.offset_bottom = -64
	hp_bar.offset_right = 280
	hp_bar.offset_top = -88
	hp_bar.modulate = Color(0.9, 0.2, 0.2)
	root.add_child(hp_bar)

	sta_bar = ProgressBar.new()
	sta_bar.min_value = 0
	sta_bar.max_value = 100
	sta_bar.value = 100
	sta_bar.show_percentage = false
	sta_bar.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	sta_bar.offset_left = 32
	sta_bar.offset_bottom = -36
	sta_bar.offset_right = 280
	sta_bar.offset_top = -56
	sta_bar.modulate = Color(0.2, 0.55, 0.95)
	root.add_child(sta_bar)

	meta_label = Label.new()
	meta_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	meta_label.offset_left = -360
	meta_label.offset_right = -24
	meta_label.offset_top = 24
	meta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	meta_label.add_theme_font_size_override("font_size", 16)
	root.add_child(meta_label)

func _set_phase(p: Phase) -> void:
	phase = p
	match p:
		Phase.TITLE:
			title_label.text = "TRIBUNAL"
			_set_prompt("Spiritual successor to The Culling.\n[ENTER] Begin Tutorial  ·  [ESC] Release mouse")
		Phase.TUTORIAL:
			title_label.text = "TRAINING GROUNDS"
			tutorial_step = 0
			tutorial_done_flags.clear()
			_advance_tutorial_prompt()
		Phase.COMBAT:
			title_label.text = "THE HUNT"
			_set_prompt("Eliminate all hunters. Stay inside the zone. Place traps with Q.")
			_spawn_hunters(4)
			match_time = 0.0
		Phase.VICTORY:
			title_label.text = "VICTORY"
			_set_prompt("You claimed the tribunal.\nKills: %d  ·  Time: %.0fs\n[ENTER] Play again" % [kills, match_time])
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		Phase.DEFEAT:
			title_label.text = "ELIMINATED"
			_set_prompt("The arena claims another.\n[ENTER] Retry")
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _advance_tutorial_prompt() -> void:
	var steps := [
		"Move with WASD. Look with mouse.",
		"Light attack: Left Mouse. Defeat the practice dummy.",
		"Heavy attack: Right Mouse (windup glows orange — readable commit). Press [N] when done.",
		"Block with SPACE, shove with F. Press [N] when done.",
		"Walk into glowing loot crates to scavenge.",
		"Press E to finish tutorial and begin THE HUNT."
	]
	if tutorial_step < steps.size():
		_set_prompt("TUTORIAL %d/%d\n%s" % [tutorial_step + 1, steps.size(), steps[tutorial_step]])
	# spawn a practice dummy on step 1
	if tutorial_step == 1 and not tutorial_done_flags.get("dummy", false):
		var practice = HunterScript.new()
		practice.team_color = Color(0.9, 0.5, 0.1)
		practice.move_speed = 0.0
		practice.max_health = 40
		practice.health = 40
		practice.position = Vector3(0, 1.2, 10)
		practice.set_target(player)
		practice.died.connect(func():
			tutorial_done_flags["hit"] = true
			if tutorial_step == 1:
				tutorial_step = 2
				_advance_tutorial_prompt()
		)
		add_child(practice)
		tutorial_done_flags["dummy"] = true

func _set_prompt(t: String) -> void:
	prompt_label.text = t

func _on_hp(v: int) -> void:
	hp_bar.value = v

func _on_sta(v: float) -> void:
	sta_bar.value = v

func _on_player_died() -> void:
	if phase == Phase.COMBAT or phase == Phase.TUTORIAL:
		_set_phase(Phase.DEFEAT)

func _on_hunter_died() -> void:
	hunters_alive = max(0, hunters_alive - 1)
	kills += 1
	if phase == Phase.COMBAT and hunters_alive <= 0:
		_set_phase(Phase.VICTORY)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
		if phase == Phase.TITLE:
			_set_phase(Phase.TUTORIAL)
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif phase == Phase.VICTORY or phase == Phase.DEFEAT:
			get_tree().reload_current_scene()
	if phase == Phase.TUTORIAL and event is InputEventKey and event.pressed:
		# N advances optional tutorial beats so the loop is never softlocked
		if event.keycode == KEY_N and tutorial_step in [2, 3]:
			tutorial_step += 1
			_advance_tutorial_prompt()
		if event.keycode == KEY_E and tutorial_step >= 4:
			_set_phase(Phase.COMBAT)
		# Allow skip entire tutorial for demo: F6
		if event.keycode == KEY_F6:
			_set_phase(Phase.COMBAT)
	if phase == Phase.COMBAT and event is InputEventKey and event.pressed and event.keycode == KEY_Q:
		_place_trap()

func _place_trap() -> void:
	if traps_left <= 0 or player == null:
		return
	traps_left -= 1
	var trap := Area3D.new()
	trap.monitoring = true
	trap.monitorable = false
	trap.collision_layer = 0
	trap.collision_mask = 1  # hunters/player share layer 1
	var cs := CollisionShape3D.new()
	var sp := SphereShape3D.new()
	sp.radius = 1.4
	cs.shape = sp
	trap.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.9, 0.15, 0.9)
	mi.mesh = bm
	mi.material_override = MatFactory.make_emissive(Color(0.9, 0.1, 0.05), 0.8)
	trap.add_child(mi)
	trap.global_position = player.global_position + Vector3(0, 0.1, 0)
	trap.body_entered.connect(func(b):
		if b and b.has_method("apply_damage") and b.is_in_group("hunters"):
			b.apply_damage(40, player, 10.0)
			trap.queue_free()
	)
	add_child(trap)
	_set_prompt("Trap armed. Remaining: %d" % traps_left)

func _process(delta: float) -> void:
	if phase == Phase.COMBAT:
		match_time += delta
		# shrink zone slowly
		zone_radius = max(10.0, zone_radius - delta * 0.35)
		if zone_mesh and zone_mesh.mesh is TorusMesh:
			var t: TorusMesh = zone_mesh.mesh
			t.inner_radius = max(0.2, zone_radius - 0.4)
			t.outer_radius = zone_radius
		if player and player.global_position.length() > zone_radius:
			# soft zone damage
			if player.has_method("apply_damage") and int(match_time * 2) % 2 == 0:
				pass
			if "health" in player and Engine.get_process_frames() % 30 == 0:
				if player.has_method("apply_damage"):
					player.apply_damage(3, null, 0.0)
		meta_label.text = "KILLS %d  ·  HUNTERS %d  ·  ZONE %.0f  ·  TRAPS %d  ·  %.0fs" % [
			kills, hunters_alive, zone_radius, traps_left, match_time
		]
	elif phase == Phase.TUTORIAL:
		meta_label.text = "TUTORIAL  ·  F6 skip to hunt"
		# auto-advance movement step
		if tutorial_step == 0 and player and player.velocity.length() > 0.5:
			tutorial_step = 1
			_advance_tutorial_prompt()
		if tutorial_step == 4 and loot_remaining < 6:
			tutorial_step = 5
			_advance_tutorial_prompt()
		# if player never loots, still allow E after step 4 prompt shown 8s
		if tutorial_step == 4 and not tutorial_done_flags.get("loot_timer", false):
			tutorial_done_flags["loot_timer"] = true
			get_tree().create_timer(12.0).timeout.connect(func ():
				if phase == Phase.TUTORIAL and tutorial_step == 4:
					tutorial_step = 5
					_advance_tutorial_prompt()
			)
	# keep camera third person feel
	if camera and player and is_instance_valid(player):
		var desired := player.global_transform.origin + player.global_transform.basis * Vector3(0.55, 1.65, 3.4)
		camera.global_position = camera.global_position.lerp(desired, clampf(delta * 10.0, 0.0, 1.0))
		camera.look_at(player.global_position + Vector3(0, 1.25, 0))
