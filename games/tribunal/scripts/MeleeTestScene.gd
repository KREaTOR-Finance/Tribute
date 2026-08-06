# MeleeTestScene.gd — TRIBUNAL mirrors THE CULLING core loop.
# Local 2P hotseat + weapons + hitstop + particles + PBR arena.
# This is the only acceptable spine: PlayerController combat soul.

extends Node3D

const MatFactory = preload("res://scripts/TribunalMaterialFactory.gd")
const Catalog = preload("res://scripts/SkinCatalog.gd")
const PropSkinUtil = preload("res://scripts/PropSkins.gd")
const HunterScript = preload("res://scripts/HunterAI.gd")
const HunterSpawnerScript = preload("res://scripts/HunterSpawner.gd")
const ZoneSystemScript = preload("res://scripts/ZoneSystem.gd")
const TribunalHUDScript = preload("res://scripts/TribunalHUD.gd")
const ScavengingSystemScript = preload("res://scripts/ScavengingSystem.gd")
const TrapSystemScript = preload("res://scripts/TrapSystem.gd")
const ArenaEnvUtil = preload("res://scripts/ArenaEnvironment.gd")
const FinishBoardScript = preload("res://scripts/FinishBoard.gd")
const GamepadBootstrapScript = preload("res://scripts/GamepadBootstrap.gd")
const VisualPolishScript = preload("res://scripts/VisualPolish.gd")
const ReplaySystemScript = preload("res://scripts/ReplaySystem.gd")

@export var use_hotseat: bool = true
@export var capture_mouse_on_start: bool = true
@export var spawn_spar_hunters: bool = true
@export var spar_hunter_count: int = 2
@export var enable_zone: bool = true
@export var scav_loot_count: int = 10
@export var last_stand_mode: bool = true

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
var zone_system = null
var trap_system = null
var scavenging_system = null
var tribunal_hud: CanvasLayer = null
var finish_board = null
var replay_system = null
var _arena_info: Dictionary = {}
var _round_frozen: bool = true  # intro freeze

func _ready():
	print("=== TRIBUNAL — CONSOLE SLICE ===")
	GamepadBootstrapScript.ensure()
	if capture_mouse_on_start:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	_apply_culling_environment()
	VisualPolishScript.apply_world(self)
	# Coherent finished courtyard (floor, walls, designed cover, spawn pads)
	_arena_info = ArenaEnvUtil.build(self)

	_setup_scavenge_and_traps()
	_configure_match_stakes()
	_setup_fighters()
	_place_fighters_on_pads()
	_setup_camera()
	_setup_ui()
	_setup_finish_board()

	if spawn_spar_hunters:
		_spawn_spar_hunters(spar_hunter_count)
	if enable_zone:
		_init_zone()

	# Intro freeze — complete playthrough starts with FIGHT banner then go
	_round_frozen = true
	_set_fighters_frozen(true)
	if arena_manager and arena_manager.has_signal("match_started"):
		if not arena_manager.match_started.is_connected(_on_match_started):
			arena_manager.match_started.connect(_on_match_started)
	print("Tribunal round: INTRO → fight → finish board")


func _setup_fighters() -> void:
	if player1:
		player1.player_id = 1
		var w1 = Weapon.new()
		w1.weapon_type = Weapon.WeaponType.SWORD
		w1._apply_profile()
		player1.equip_weapon(w1)
		if player1.has_method("_apply_weapon_skin_to_hand"):
			player1.weapon_skin_id = "steel"
			player1._apply_weapon_skin_to_hand()
		if not player1.weapon_equipped.is_connected(_on_weapon_equipped.bind(player1, p1_weapon_label)):
			player1.weapon_equipped.connect(_on_weapon_equipped.bind(player1, p1_weapon_label))
		_sync_weapon_visual(player1, 1)
		if not player1.player_died.is_connected(_on_player_died.bind(player1)):
			player1.player_died.connect(_on_player_died.bind(player1))
	if player2:
		player2.player_id = 2
		var w2 = Weapon.new()
		w2.weapon_type = Weapon.WeaponType.AXE
		w2._apply_profile()
		player2.equip_weapon(w2)
		if player2.has_method("_apply_weapon_skin_to_hand"):
			player2.weapon_skin_id = "bronze"
			player2._apply_weapon_skin_to_hand()
		if not player2.weapon_equipped.is_connected(_on_weapon_equipped.bind(player2, p2_weapon_label)):
			player2.weapon_equipped.connect(_on_weapon_equipped.bind(player2, p2_weapon_label))
		_sync_weapon_visual(player2, 2)
		if not player2.player_died.is_connected(_on_player_died.bind(player2)):
			player2.player_died.connect(_on_player_died.bind(player2))

	if arena_manager:
		if player1:
			arena_manager.register_player(player1)
		if player2:
			arena_manager.register_player(player2)
		if not arena_manager.match_ended.is_connected(_on_match_ended):
			arena_manager.match_ended.connect(_on_match_ended)


func _place_fighters_on_pads() -> void:
	if player1 and _arena_info.has("spawn_p1"):
		player1.global_position = _arena_info["spawn_p1"]
	if player2 and _arena_info.has("spawn_p2"):
		player2.global_position = _arena_info["spawn_p2"]


func _setup_camera() -> void:
	if camera:
		camera.current = true
		for p in [player1, player2]:
			if p and p.has_node("Camera3D"):
				(p.get_node("Camera3D") as Camera3D).current = false
	if camera and camera is FollowCamera:
		follow_camera = camera as FollowCamera
		follow_camera.add_to_group("follow_cameras")
		follow_camera.is_follow_mode = true
		follow_camera.start_in_follow = true
		follow_camera.follow_distance = 9.0
		follow_camera.follow_height = 5.5
		if follow_camera and player1:
			follow_camera.set_target(player1)
			if player1.has_method("_resolve_follow_camera"):
				player1._resolve_follow_camera()
			if player2 and player2.has_method("_resolve_follow_camera"):
				player2._resolve_follow_camera()


func _setup_finish_board() -> void:
	finish_board = FinishBoardScript.new()
	finish_board.name = "FinishBoard"
	add_child(finish_board)
	if finish_board.has_signal("rematch_requested"):
		finish_board.rematch_requested.connect(_on_rematch)
	if finish_board.has_signal("replay_requested"):
		finish_board.replay_requested.connect(_on_replay_requested)
	# Replay recorder
	replay_system = ReplaySystemScript.new()
	replay_system.name = "ReplaySystem"
	add_child(replay_system)
	replay_system.bind_subjects([player1, player2], camera if camera else null)


func _set_fighters_frozen(frozen: bool) -> void:
	_round_frozen = frozen
	for p in [player1, player2]:
		if p == null or not is_instance_valid(p):
			continue
		p.set_physics_process(not frozen)
		if frozen and p is CharacterBody3D:
			(p as CharacterBody3D).velocity = Vector3.ZERO


func _on_match_started() -> void:
	_set_fighters_frozen(false)
	if replay_system and replay_system.has_method("start_recording"):
		replay_system.start_recording()
	print("ROUND LIVE · recording replay · Judgement Chain live")


func _on_rematch() -> void:
	get_tree().reload_current_scene()


func _on_replay_requested() -> void:
	if replay_system == null:
		return
	if replay_system.playing:
		replay_system.stop_playback()
		return
	if replay_system.has_method("stop_recording"):
		replay_system.stop_recording()
	if finish_board and finish_board.has_method("set_replay_mode"):
		finish_board.set_replay_mode(true)
	replay_system.start_playback(self)
	if replay_system.has_signal("playback_finished"):
		if not replay_system.playback_finished.is_connected(_on_replay_finished):
			replay_system.playback_finished.connect(_on_replay_finished)


func _on_replay_finished() -> void:
	if finish_board and finish_board.has_method("set_replay_mode"):
		finish_board.set_replay_mode(false)
	print("Replay finished")


func _configure_match_stakes() -> void:
	if arena_manager == null:
		return
	arena_manager.test_mode_respawn = not last_stand_mode
	arena_manager.match_duration = 300.0
	arena_manager.time_remaining = 300.0
	arena_manager.intro_seconds = 1.6
	print("MeleeTest: stakes last_stand=", last_stand_mode, " duration=5:00")


func _setup_scavenge_and_traps() -> void:
	scavenging_system = get_node_or_null("ScavengingSystem") as ScavengingSystem
	if scavenging_system == null:
		scavenging_system = ScavengingSystemScript.new()
		scavenging_system.name = "ScavengingSystem"
		add_child(scavenging_system)

	trap_system = get_node_or_null("TrapSystem") as TrapSystem
	if trap_system == null:
		trap_system = TrapSystemScript.new()
		trap_system.name = "TrapSystem"
		add_child(trap_system)

	if player1:
		trap_system.ensure_kits(player1)
	if player2:
		trap_system.ensure_kits(player2)

	if not scavenging_system.loot_collected.is_connected(_on_loot_collected):
		scavenging_system.loot_collected.connect(_on_loot_collected)
	if not trap_system.trap_triggered.is_connected(_on_trap_triggered):
		trap_system.trap_triggered.connect(_on_trap_triggered)
	if scavenging_system.has_signal("channel_started") and not scavenging_system.channel_started.is_connected(_on_scav_channel_started):
		scavenging_system.channel_started.connect(_on_scav_channel_started)

	var points: Array = _arena_info.get("loot_points", [])
	if points.size() > 0 and scavenging_system.has_method("spawn_loot_at_points"):
		scavenging_system.spawn_loot_at_points(self, points, scav_loot_count)
	else:
		scavenging_system.arena_half_extent = float(_arena_info.get("half", 9.0)) - 2.0
		scavenging_system.spawn_loot_in_arena(self, scav_loot_count)
	print("MeleeTest: scav+traps on finished arena")


func try_scavenge_for(player: PlayerController) -> void:
	if scavenging_system and scavenging_system.has_method("try_begin_scavenge"):
		scavenging_system.try_begin_scavenge(player)


func _on_scav_channel_started(player: Node, _loot: Area3D) -> void:
	if tribunal_hud and tribunal_hud.has_method("push_feed"):
		tribunal_hud.push_feed("%s scavenging…" % player.name)


func _on_loot_collected(item: Dictionary, player: Node) -> void:
	var label := str(item.get("name", item.get("id", "loot")))
	print("MeleeTest scav: ", player.name if player else "?", " got ", label)
	if arena_manager and arena_manager.has_method("record_scavenge"):
		arena_manager.record_scavenge(player)
	if tribunal_hud and tribunal_hud.has_method("push_feed"):
		tribunal_hud.push_feed("%s · %s" % [player.name, label])


func _on_trap_triggered(trap_type: String, victim: Node) -> void:
	print("MeleeTest trap: ", trap_type, " hit ", victim.name if victim else "?")
	# Credit trap owner if recorded on trap meta — TrapSystem emits type+victim only
	if tribunal_hud and tribunal_hud.has_method("push_feed"):
		tribunal_hud.push_feed("TRAP · %s" % trap_type)


func place_trap_for(player: PlayerController, trap_type: String = "bear_trap") -> void:
	if trap_system == null or player == null:
		return
	if trap_system.place_trap(player, trap_type):
		if arena_manager and arena_manager.has_method("record_trap"):
			arena_manager.record_trap(player)


func _init_zone() -> void:
	var half := float(_arena_info.get("half", 12.0))
	zone_system = ZoneSystemScript.new()
	zone_system.name = "ZoneSystem"
	zone_system.center = Vector3.ZERO
	# Start just outside walls, shrink into courtyard
	zone_system.start_radius = half + 4.0
	zone_system.min_radius = 3.5
	zone_system.shrink_duration = 180.0
	zone_system.damage_per_tick = 4
	zone_system.damage_interval = 0.5
	zone_system.auto_start = true
	zone_system.danger_tint_enabled = true
	zone_system.ring_y = 0.12
	add_child(zone_system)
	if arena_manager and arena_manager.has_method("register_zone"):
		arena_manager.register_zone(zone_system)
	print("MeleeTest: zone fits finished arena r0=", zone_system.start_radius)


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


func _spawn_spar_hunters(count: int) -> void:
	# Prefer HunterSpawner (roles round-robin + catalog skins). Create if missing.
	var spawner = get_node_or_null("HunterSpawner")
	if spawner == null:
		spawner = HunterSpawnerScript.new()
		spawner.name = "HunterSpawner"
		add_child(spawner)
	if player1 and spawner.has_method("set_player_target"):
		spawner.set_player_target(player1)
	elif player1 and "player_target" in spawner:
		spawner.player_target = player1
	if spawner.has_method("spawn_wave"):
		var wave = spawner.spawn_wave(count)
		_wire_hunter_kills(wave)
		print("MeleeTest: hunters wave1=", wave.size())
		get_tree().create_timer(45.0).timeout.connect(func ():
			if not is_instance_valid(spawner):
				return
			if arena_manager and "phase" in arena_manager and int(arena_manager.phase) == 2:
				return  # ENDED
			var alive := int(spawner.alive_count()) if spawner.has_method("alive_count") else 0
			var n := 3 if alive == 0 else 2
			var w2 = spawner.spawn_wave(n)
			_wire_hunter_kills(w2)
			print("MeleeTest: hunters wave2=", w2.size())
		)
		return


func _wire_hunter_kills(hunters: Array) -> void:
	for h in hunters:
		if h == null or not is_instance_valid(h):
			continue
		if h.has_signal("died_by") and not h.died_by.is_connected(_on_hunter_killed):
			h.died_by.connect(_on_hunter_killed)


func _on_hunter_killed(killer: Node) -> void:
	if arena_manager and arena_manager.has_method("record_kill") and killer:
		arena_manager.record_kill(killer)
	if tribunal_hud and tribunal_hud.has_method("push_feed") and killer:
		tribunal_hud.push_feed("%s · hunter down" % killer.name)


func _setup_ui():
	# Culling-readable TribunalHUD owns vitals / timer / feed / banners.
	# Legacy labels stay in the tree but are hidden so nothing softlocks.
	if not has_node("TribunalHUD"):
		tribunal_hud = TribunalHUDScript.new()
		tribunal_hud.name = "TribunalHUD"
		add_child(tribunal_hud)
	else:
		tribunal_hud = get_node("TribunalHUD") as CanvasLayer

	if tribunal_hud and tribunal_hud.has_method("bind_fighters"):
		tribunal_hud.bind_fighters(player1, player2)
	if tribunal_hud and tribunal_hud.has_method("bind_arena"):
		tribunal_hud.bind_arena(arena_manager)

	if ui_layer:
		if instructions_label:
			instructions_label.text = """P1: stick/WASD · pad look · X/Y light heavy · LB block · RB shove · B dodge · A scavenge
Judgement Chain: land hits → JUDGEMENT heavy · G replay after match · R rematch"""
			instructions_label.offset_left = 16
			instructions_label.offset_top = 640
			instructions_label.offset_right = 980
			instructions_label.offset_bottom = 710
			instructions_label.modulate = Color(0.75, 0.75, 0.78, 0.7)
			instructions_label.add_theme_font_size_override("font_size", 12)
		for legacy in [p1_status, p2_status, p1_weapon_label, p2_weapon_label]:
			if legacy:
				legacy.visible = false
		if not p1_weapon_label:
			p1_weapon_label = Label.new()
			p1_weapon_label.visible = false
			ui_layer.add_child(p1_weapon_label)
		if not p2_weapon_label:
			p2_weapon_label = Label.new()
			p2_weapon_label.visible = false
			ui_layer.add_child(p2_weapon_label)

	if tribunal_hud and tribunal_hud.has_method("set_weapon_name"):
		if player1 and "current_weapon" in player1 and player1.current_weapon:
			tribunal_hud.set_weapon_name(1, str(player1.current_weapon.weapon_name))
		elif player1:
			tribunal_hud.set_weapon_name(1, "Sword")
		if player2 and "current_weapon" in player2 and player2.current_weapon:
			tribunal_hud.set_weapon_name(2, str(player2.current_weapon.weapon_name))
		elif player2:
			tribunal_hud.set_weapon_name(2, "Axe")


func _process(_delta):
	_update_status()


func _update_status():
	# Legacy text vitals only if HUD missing and labels still visible
	if tribunal_hud:
		return
	var p1_kits: int = trap_system.get_trap_kits(player1) if trap_system and player1 else 0
	var p2_kits: int = trap_system.get_trap_kits(player2) if trap_system and player2 else 0
	if p1_status and player1:
		p1_status.text = "P1 HP: %d  STA: %d  TRAP: %d" % [player1.health, int(player1.stamina), p1_kits]
	if p2_status and player2:
		p2_status.text = "P2 HP: %d  STA: %d  TRAP: %d" % [player2.health, int(player2.stamina), p2_kits]


func _on_weapon_equipped(weapon_name: String, player, label: Label):
	if label:
		label.text = "%s Weapon: %s" % [player.name, weapon_name]
	if tribunal_hud and tribunal_hud.has_method("set_weapon_name") and player:
		var pid := 1
		if "player_id" in player:
			pid = int(player.player_id)
		tribunal_hud.set_weapon_name(pid, weapon_name)
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
			var skin := ""
			if "weapon_skin_id" in player:
				skin = str(player.weapon_skin_id)
			wv.set_weapon_type(wtype, skin)


func _on_player_died(player):
	print(player.name, " eliminated (Culling rules)")
	if player == null or not is_instance_valid(player):
		return
	var pos: Vector3 = player.global_position
	var col := Color(0.8, 0.1, 0.1)
	if "player_id" in player and int(player.player_id) == 2:
		col = Color(0.15, 0.35, 0.9)
	elif "character_skin_id" in player:
		var skins := Catalog.character_skins()
		var sid := str(player.character_skin_id)
		if skins.has(sid):
			col = skins[sid]["body"]
	# Death mark + scav loot drop (Culling fallen-hunter props)
	PropSkinUtil.spawn_death_mark(self, pos, col)
	if scavenging_system:
		scavenging_system.spawn_loot_at(self, pos + Vector3(0.4, 0.0, 0.2))
	else:
		PropSkinUtil.spawn_loot(self, pos + Vector3(0.4, 0.3, 0.2))
	print("MeleeTest: death mark + loot spawned at ", pos)
	# Elim feed + winner banner handled by TribunalHUD signal binds


func _on_match_ended(winner):
	print("MATCH ENDED — Winner:", winner.name if winner else "Draw")
	_set_fighters_frozen(true)
	if replay_system and replay_system.has_method("stop_recording"):
		replay_system.stop_recording()
	# Stop zone damage spam
	if zone_system and zone_system.has_method("stop"):
		zone_system.stop()
	# Full finish board
	if finish_board and arena_manager and arena_manager.has_method("build_results_payload"):
		var payload: Dictionary = arena_manager.build_results_payload(winner)
		payload["has_replay"] = replay_system != null and replay_system.has_replay()
		finish_board.show_results(payload)
	elif tribunal_hud and tribunal_hud.has_method("show_winner_banner"):
		tribunal_hud.show_winner_banner(winner)
	if instructions_label:
		instructions_label.text = "ROUND OVER — R rematch · G replay"


func _unhandled_input(event: InputEvent) -> void:
	# Finish board handles R when showing
	if finish_board and finish_board.has_method("is_showing") and finish_board.is_showing():
		return
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
