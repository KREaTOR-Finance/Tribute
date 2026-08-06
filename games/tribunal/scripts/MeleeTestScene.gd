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
const ArenaCoverUtil = preload("res://scripts/ArenaCover.gd")

@export var use_hotseat: bool = true
@export var capture_mouse_on_start: bool = true
@export var spawn_spar_hunters: bool = true
@export var spar_hunter_count: int = 2
@export var enable_zone: bool = true
@export var scav_loot_count: int = 10
@export var dense_cover: bool = true
@export var last_stand_mode: bool = true  # no endless respawn — Culling stakes

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
# Wired by W1 scavenge/traps when present; null-safe for headless smoke
var trap_system = null
var scavenging_system = null
var tribunal_hud: CanvasLayer = null

func _ready():
	print("=== TRIBUNAL — CULLING MELEE CORE ===")
	print("Mirror of The Culling: weighty melee, 2P hotseat, weapons, scav/trap ready.")
	if capture_mouse_on_start:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	_apply_culling_environment()
	_apply_pbr_to_arena()
	_apply_prop_skins()
	if dense_cover:
		ArenaCoverUtil.spawn_dense_cover(self)
		_apply_prop_skins()  # re-skin any MeshInstance3D props that match names; dense cover uses materials already
	_setup_scavenge_and_traps()
	_configure_match_stakes()

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
		player2.player_died.connect(_on_player_died.bind(player2))

	if arena_manager:
		if player1:
			arena_manager.register_player(player1)
		if player2:
			arena_manager.register_player(player2)
		if not arena_manager.match_ended.is_connected(_on_match_ended):
			arena_manager.match_ended.connect(_on_match_ended)

	if camera:
		camera.current = true
		# Disable embedded player cameras so arena FollowCamera owns framing
		for p in [player1, player2]:
			if p and p.has_node("Camera3D"):
				(p.get_node("Camera3D") as Camera3D).current = false
	if camera and camera is FollowCamera:
		follow_camera = camera as FollowCamera
		follow_camera.add_to_group("follow_cameras")
		follow_camera.is_follow_mode = true
		follow_camera.start_in_follow = true
		if follow_camera and player1:
			follow_camera.set_target(player1)
			# Re-bind player combat audio/camera after tree is ready
			if player1.has_method("_resolve_follow_camera"):
				player1._resolve_follow_camera()
			if player2 and player2.has_method("_resolve_follow_camera"):
				player2._resolve_follow_camera()

	if spawn_spar_hunters:
		_spawn_spar_hunters(spar_hunter_count)

	if enable_zone:
		_init_zone()

	_setup_ui()
	print("Fight. Mirror Culling. Prove the loop.")


func _configure_match_stakes() -> void:
	if arena_manager == null:
		return
	# Last-stand: elim is permanent (Culling stakes). Toggle last_stand_mode=false for spar training.
	if last_stand_mode:
		arena_manager.test_mode_respawn = false
		if "match_duration" in arena_manager:
			# 5 min micro-match is enough pressure with zone
			if float(arena_manager.match_duration) > 400.0:
				arena_manager.match_duration = 300.0
				arena_manager.time_remaining = 300.0
		print("MeleeTest: LAST STAND — no respawn (R to restart match)")
	else:
		arena_manager.test_mode_respawn = true
		print("MeleeTest: spar training respawn ON")


func _setup_scavenge_and_traps() -> void:
	# Live Culling loop: contested E-channel scavenge + placeable traps
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

	scavenging_system.spawn_loot_in_arena(self, scav_loot_count)
	print("MeleeTest: ScavengingSystem + TrapSystem live (loot=%d, E/H channel)" % scav_loot_count)


func try_scavenge_for(player: PlayerController) -> void:
	if scavenging_system and scavenging_system.has_method("try_begin_scavenge"):
		scavenging_system.try_begin_scavenge(player)


func _on_scav_channel_started(player: Node, _loot: Area3D) -> void:
	if tribunal_hud and tribunal_hud.has_method("push_feed"):
		tribunal_hud.push_feed("%s scavenging…" % player.name)


func _on_loot_collected(item: Dictionary, player: Node) -> void:
	var label := str(item.get("name", item.get("id", "loot")))
	var applied := str(item.get("applied", ""))
	print("MeleeTest scav: ", player.name if player else "?", " got ", label, " (", applied, ")")


func _on_trap_triggered(trap_type: String, victim: Node) -> void:
	print("MeleeTest trap: ", trap_type, " hit ", victim.name if victim else "?")


func place_trap_for(player: PlayerController, trap_type: String = "bear_trap") -> void:
	if trap_system == null or player == null:
		return
	trap_system.place_trap(player, trap_type)


func _init_zone() -> void:
	zone_system = ZoneSystemScript.new()
	zone_system.name = "ZoneSystem"
	zone_system.center = Vector3.ZERO
	zone_system.start_radius = 22.0
	zone_system.min_radius = 4.0
	zone_system.shrink_duration = 180.0
	zone_system.damage_per_tick = 4
	zone_system.damage_interval = 0.5
	zone_system.auto_start = true
	zone_system.danger_tint_enabled = true
	add_child(zone_system)
	if arena_manager and arena_manager.has_method("register_zone"):
		arena_manager.register_zone(zone_system)
	print("MeleeTest: ZoneSystem active (Culling closing ring)")


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
	# Scale ground mesh if tiny unit box
	if ground and ground is MeshInstance3D:
		(ground as MeshInstance3D).scale = Vector3(20, 1, 20)
		(ground as MeshInstance3D).position.y = -0.5


func _apply_prop_skins() -> void:
	# First-class prop skins for arena cover (crate wood / iron barrel)
	for n in ["Crate1", "Crate2"]:
		var crate = get_node_or_null(n)
		if crate and crate is Node3D:
			PropSkinUtil.reskin_static_prop(crate as Node3D, Catalog.PSKIN_CRATE_WOOD)
	for n in ["Barrel1", "Barrel2"]:
		var barrel = get_node_or_null(n)
		if barrel and barrel is Node3D:
			PropSkinUtil.reskin_static_prop(barrel as Node3D, Catalog.PSKIN_BARREL_METAL)
	print("MeleeTest: prop skins applied (crate_wood / barrel_metal)")


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
		print("MeleeTest: spar hunters via HunterSpawner count=", wave.size())
		# Critic residual: second wave so pressure doesn't collapse after first spar dies
		get_tree().create_timer(45.0).timeout.connect(func ():
			if not is_instance_valid(spawner):
				return
			var alive := 0
			if spawner.has_method("alive_count"):
				alive = int(spawner.alive_count())
			var n := 3 if alive == 0 else 2
			var w2 = spawner.spawn_wave(n)
			print("MeleeTest: hunter wave 2 count=", w2.size(), " prior_alive=", alive)
		)
		return
	# Legacy fallback (should not hit if HunterSpawner present)
	var offsets := [
		Vector3(6, 1.2, -4),
		Vector3(-6, 1.2, -5),
		Vector3(0, 1.2, 8),
		Vector3(8, 1.2, 3),
	]
	var skin_ids: Array = Catalog.character_skins().keys()
	for i in count:
		var h = HunterScript.new()
		h.position = offsets[i % offsets.size()]
		h.skin_id = str(skin_ids[i % skin_ids.size()])
		h.weapon_type = 1 + (i % 3)
		h.weapon_skin_id = Catalog.default_weapon_skin(h.weapon_type)
		if player1:
			h.set_target(player1)
		add_child(h)
		print("MeleeTest: spar hunter ", i, " skin=", h.skin_id)


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
			instructions_label.text = """P1: WASD Mouse · Shift sprint · LMB/RMB · Space block · F shove · C dodge · E scavenge · Q trap
P2: IJKL · Ctrl sprint · U/O · P block · ; shove · V dodge · H scavenge · B trap
TAB cam · ESC mouse · R restart match · LAST STAND (no respawn) · zone + hunters"""
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
	# Banner also via TribunalHUD.bind_arena(match_ended); keep fallback if HUD absent
	if tribunal_hud == null and instructions_label:
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
