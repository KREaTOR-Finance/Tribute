# MeleeTestScene.gd — TRIBUNAL mirrors THE CULLING core loop.
# Local 2P hotseat + weapons + hitstop + particles + PBR arena.
# This is the only acceptable spine: PlayerController combat soul.

extends Node3D

const MatFactory = preload("res://scripts/TribunalMaterialFactory.gd")

@export var use_hotseat: bool = true
@export var capture_mouse_on_start: bool = true

@onready var player1 = $Player1
@onready var player2 = $Player2
@onready var arena_manager = $ArenaManager
@onready var ui_layer: CanvasLayer = $UI
@onready var instructions_label: Label = $UI/InstructionsLabel
@onready var p1_status: Label = $UI/P1Status
@onready var p2_status: Label = $UI/P2Status
@onready var p1_weapon_label: Label = $UI/P1Weapon
@onready var p2_weapon_label: Label = $UI/P2Weapon
@onready var camera: Camera3D = $Camera3D
var follow_camera = null

func _ready():
	print("=== TRIBUNAL — CULLING MELEE CORE ===")
	print("Mirror of The Culling: weighty melee, 2P hotseat, weapons, scav/trap ready.")
	if capture_mouse_on_start:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	_apply_culling_environment()
	_apply_pbr_to_arena()

	if player1:
		player1.player_id = 1
		var w1 = Weapon.new()
		w1.weapon_type = Weapon.WeaponType.SWORD
		w1._apply_profile()
		player1.equip_weapon(w1)
		if not player1.weapon_equipped.is_connected(_on_weapon_equipped.bind(player1, p1_weapon_label)):
			player1.weapon_equipped.connect(_on_weapon_equipped.bind(player1, p1_weapon_label))
		_sync_weapon_visual(player1, 1)
		player1.player_died.connect(_on_player_died.bind(player1))
	if player2:
		player2.player_id = 2
		var w2 = Weapon.new()
		w2.weapon_type = Weapon.WeaponType.AXE
		w2._apply_profile()
		player2.equip_weapon(w2)
		if not player2.weapon_equipped.is_connected(_on_weapon_equipped.bind(player2, p2_weapon_label)):
			player2.weapon_equipped.connect(_on_weapon_equipped.bind(player2, p2_weapon_label))
		_sync_weapon_visual(player2, 2)
		player2.player_died.connect(_on_player_died.bind(player2))

	if arena_manager:
		if player1:
			arena_manager.register_player(player1)
		if player2:
			arena_manager.register_player(player2)
		if not arena_manager.match_ended.is_connected(_on_match_ended):
			arena_manager.match_ended.connect(_on_match_ended)

	if camera and camera is FollowCamera:
		follow_camera = camera as FollowCamera
		if follow_camera and player1:
			follow_camera.set_target(player1)

	_setup_ui()
	print("Fight. Mirror Culling. Prove the loop.")


func _apply_culling_environment() -> void:
	var sun := get_node_or_null("DirectionalLight3D")
	if sun and sun is DirectionalLight3D:
		(sun as DirectionalLight3D).shadow_enabled = true
		(sun as DirectionalLight3D).light_energy = 1.2
	# WorldEnvironment with HDRI if available
	if not has_node("WorldEnvironment"):
		var we := WorldEnvironment.new()
		we.name = "WorldEnvironment"
		var e := Environment.new()
		e.tonemap_mode = Environment.TONE_MAPPER_ACES
		e.ssao_enabled = true
		e.glow_enabled = true
		e.glow_intensity = 0.3
		e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		e.ambient_light_color = Color(0.4, 0.42, 0.5)
		e.ambient_light_energy = 0.55
		var hdri := "res://assets/hdri/polyhaven/kloppenheim_06_1k.hdr"
		if ResourceLoader.exists(hdri):
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
		else:
			e.background_mode = Environment.BG_COLOR
			e.background_color = Color(0.1, 0.11, 0.14)
		we.environment = e
		add_child(we)


func _apply_pbr_to_arena() -> void:
	var ground = get_node_or_null("Ground/MeshInstance3D")
	if ground and ground is MeshInstance3D:
		var mat = MatFactory.load_pbr("aerial_rocks_02")
		mat.uv1_scale = Vector3(6, 6, 6)
		(ground as MeshInstance3D).material_override = mat
	for n in ["Crate1", "Crate2", "Barrel1", "Barrel2"]:
		var node = get_node_or_null(n + "/MeshInstance3D")
		if node and node is MeshInstance3D:
			var folder := "wood_cabinet_worn_long" if n.begins_with("Crate") else "metal_plate"
			var m = MatFactory.load_pbr(folder)
			m.uv1_scale = Vector3(1.2, 1.2, 1.2)
			(node as MeshInstance3D).material_override = m
	# Scale ground mesh if tiny unit box
	if ground and ground is MeshInstance3D:
		(ground as MeshInstance3D).scale = Vector3(20, 1, 20)
		(ground as MeshInstance3D).position.y = -0.5


func _setup_ui():
	if not ui_layer:
		return
	if instructions_label:
		instructions_label.text = """TRIBUNAL — THE CULLING MIRROR
Melee soul only. Local 2P hotseat.

P1 RED: WASD + Mouse | LMB Light | RMB Heavy windup | Space Block | F Shove | 1/2/3 Sword/Axe/Dagger
P2 BLUE: IJKL | U Light | O Heavy | P Block | ; Shove | 4/5/6 weapons

TAB follow cam · ESC mouse · Prove the loop before scope.
Hitstop · knockback · particles · weapon profiles · PBR arena LIVE."""
	if not p1_weapon_label:
		p1_weapon_label = Label.new()
		p1_weapon_label.position = Vector2(20, 260)
		ui_layer.add_child(p1_weapon_label)
	if not p2_weapon_label:
		p2_weapon_label = Label.new()
		p2_weapon_label.position = Vector2(20, 285)
		ui_layer.add_child(p2_weapon_label)
	if p1_weapon_label:
		p1_weapon_label.modulate = Color(1, 0.4, 0.4, 1)
	if p2_weapon_label:
		p2_weapon_label.modulate = Color(0.4, 0.6, 1, 1)


func _process(_delta):
	_update_status()


func _update_status():
	if p1_status and player1:
		p1_status.text = "P1 HP: %d  STA: %d" % [player1.health, int(player1.stamina)]
	if p2_status and player2:
		p2_status.text = "P2 HP: %d  STA: %d" % [player2.health, int(player2.stamina)]


func _on_weapon_equipped(weapon_name: String, player, label: Label):
	if label:
		label.text = "%s Weapon: %s" % [player.name, weapon_name]
	var wtype = 1
	if "Axe" in weapon_name or "axe" in weapon_name.to_lower():
		wtype = 2
	elif "Dagger" in weapon_name or "dagger" in weapon_name.to_lower():
		wtype = 3
	elif "Sword" in weapon_name or "sword" in weapon_name.to_lower():
		wtype = 1
	_sync_weapon_visual(player, wtype)


func _sync_weapon_visual(player, wtype: int):
	if not player:
		return
	var hand = player.get_node_or_null("Hand")
	if hand:
		var wv = hand.get_node_or_null("WeaponVisual")
		if wv and wv.has_method("set_weapon_type"):
			wv.set_weapon_type(wtype)


func _on_player_died(player):
	print(player.name, " eliminated (Culling rules)")


func _on_match_ended(winner):
	print("MATCH ENDED — Winner:", winner.name if winner else "Draw")
	if instructions_label:
		instructions_label.text = "MATCH OVER — Winner: %s\nR to restart" % (winner.name if winner else "Draw")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		get_tree().reload_current_scene()
	if event.is_action_pressed("ui_focus_next"):  # Tab
		if follow_camera and player1:
			if follow_camera.target == player1:
				follow_camera.set_target(player2 if player2 else player1)
			else:
				follow_camera.set_target(player1)
