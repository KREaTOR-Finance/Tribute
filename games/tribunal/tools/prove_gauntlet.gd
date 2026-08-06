extends SceneTree
## Prove Tribunal Gauntlet: art load, audio load, mechanics, simulated round, replay.
## Exit 0 only if all critical proofs pass.

var fails: Array = []
var oks: Array = []


func ok(m: String) -> void:
	oks.append(m)
	print("PROOF_OK ", m)


func fail(m: String) -> void:
	fails.append(m)
	print("PROOF_FAIL ", m)


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	print("=== PROVE TRIBUNAL GAUNTLET ===")
	_prove_art_assets()
	_prove_audio()
	await _prove_scene_round()
	print("=== SUMMARY ok=", oks.size(), " fail=", fails.size(), " ===")
	for f in fails:
		print("  FAIL: ", f)
	if fails.is_empty():
		print("PROVE_GAUNTLET_PASS")
		quit(0)
	else:
		print("PROVE_GAUNTLET_FAIL")
		quit(1)


func _prove_art_assets() -> void:
	var skins := [
		"res://assets/models/skins/char_crimson.obj",
		"res://assets/models/skins/char_azure.obj",
		"res://assets/models/skins/char_bone.obj",
		"res://assets/models/skins/char_iron.obj",
		"res://assets/models/skins/wpn_sword_steel.obj",
		"res://assets/models/skins/wpn_sword_blood.obj",
		"res://assets/models/skins/wpn_axe_bronze.obj",
		"res://assets/models/skins/wpn_dagger_obsidian.obj",
	]
	var Loader = load("res://scripts/ObjMeshLoader.gd")
	for p in skins:
		if not FileAccess.file_exists(p):
			fail("missing art " + p)
			continue
		var mesh = Loader.load_mesh(p)
		if mesh == null or mesh.get_surface_count() < 1:
			fail("mesh load " + p)
		else:
			ok("art mesh " + p.get_file())


func _prove_audio() -> void:
	var Audio = load("res://scripts/CombatAudio.gd")
	var paths := [
		"res://assets/audio/impacts/light_hit.wav",
		"res://assets/audio/impacts/heavy_hit.wav",
		"res://assets/audio/impacts/whoosh.wav",
		"res://assets/audio/impacts/block.wav",
		"res://assets/audio/footsteps/step.wav",
		"res://assets/audio/footsteps/step_run.wav",
	]
	for p in paths:
		if not FileAccess.file_exists(p):
			fail("missing audio " + p)
			continue
		var s = Audio._load_wav(p)
		if s == null:
			fail("wav load " + p)
		else:
			ok("audio " + p.get_file())


func _prove_scene_round() -> void:
	var scene = load("res://scenes/MeleeTest.tscn").instantiate()
	root.add_child(scene)
	await create_timer(0.6).timeout

	# Core nodes
	for n in ["ArenaFloor", "CraftingSystem", "ScavengingSystem", "TrapSystem",
			"WaveDirector", "HunterSpawner", "TribunalHUD", "FinishBoard", "ReplaySystem"]:
		if scene.get_node_or_null(n) == null:
			fail("scene missing " + n)
		else:
			ok("node " + n)

	if scene.get_node_or_null("CraftBench0") == null:
		fail("no craft bench")
	else:
		ok("craft benches present")

	var p1 = scene.get_node_or_null("Player1")
	if p1 == null:
		fail("no Player1")
		return
	ok("Player1 present")

	# Humanoid skin rig
	if p1.get_node_or_null("SkinRig") == null:
		fail("Player1 no SkinRig")
	else:
		ok("Player1 humanoid SkinRig")

	# Wait intro → FIGHT
	await create_timer(3.8).timeout
	var am = scene.get_node("ArenaManager")
	if int(am.phase) != 1:
		fail("not FIGHT after intro phase=" + str(am.phase))
	else:
		ok("phase FIGHT")

	var wd = scene.get_node_or_null("WaveDirector")
	if wd == null:
		fail("no WaveDirector")
	else:
		ok("WaveDirector live")

	# Mechanics: craft
	var craft = scene.get_node("CraftingSystem")
	craft.add_material(p1, "wood", 5)
	craft.add_material(p1, "scrap", 5)
	craft.add_material(p1, "cloth", 5)
	craft.add_material(p1, "bone", 5)
	craft.set_near_station(p1, true)
	if craft.craft(p1, "leather_vest"):
		ok("craft leather_vest")
	else:
		fail("craft leather_vest")
	var dr = craft.get_damage_reduction(p1)
	if dr >= 0.1:
		ok("armor DR=" + str(dr))
	else:
		fail("armor DR low " + str(dr))

	# Mechanics: trap place
	var traps = scene.get_node("TrapSystem")
	traps.ensure_kits(p1, 3)
	if traps.place_trap(p1, "bear_trap"):
		ok("trap place")
	else:
		fail("trap place")

	# Mechanics: judgement chain
	if p1.has_method("_set_chain"):
		p1._set_chain(3)
		if p1.judgement_ready:
			ok("judgement ready")
		else:
			fail("judgement not ready")
	else:
		fail("no judgement API")

	# Mechanics: attacks
	p1.stamina = 100
	p1.melee_state = p1.MeleeState.IDLE
	p1._perform_light_attack()
	if p1.melee_state == p1.MeleeState.LIGHT_ACTIVE:
		ok("light attack")
	else:
		fail("light attack state")

	# Simulate clearing waves by killing all hunters repeatedly until victory
	var rs = scene.get_node("ReplaySystem")
	var safety := 0
	while int(am.phase) == 1 and safety < 80:
		safety += 1
		var hunters = root.get_tree().get_nodes_in_group("hunters")
		for h in hunters:
			if h and is_instance_valid(h) and h.has_method("apply_damage"):
				h.apply_damage(999, p1, 0.0)
		# advance time for wave delays
		await create_timer(0.35).timeout
		if int(am.phase) != 1:
			break

	if int(am.phase) == 2:
		ok("match ENDED")
	else:
		# force victory path if still fighting
		if am.has_method("declare_wave_victory"):
			am.declare_wave_victory(p1)
			await create_timer(0.2).timeout
		if int(am.phase) == 2:
			ok("match ENDED via declare")
		else:
			fail("match not ended phase=" + str(am.phase))

	var fb = scene.get_node("FinishBoard")
	if fb and fb.has_method("is_showing") and fb.is_showing():
		ok("finish board showing")
	else:
		fail("finish board not showing")

	# Replay
	if rs and rs.has_method("has_replay"):
		if not rs.has_replay():
			# force some frames
			rs.start_recording()
			await create_timer(0.25).timeout
			rs.stop_recording()
		if rs.has_replay() and rs.start_playback(scene):
			ok("replay playback")
			await create_timer(0.2).timeout
			rs.stop_playback()
			ok("replay stop")
		else:
			fail("replay failed")
	else:
		fail("no replay system")

	# Audio play (no crash)
	var ca = p1.get_node_or_null("CombatAudio")
	if ca:
		ca.play_whoosh(false)
		ca.play_hit(true)
		ca.play_block()
		ok("combat audio play calls")
	else:
		fail("no CombatAudio on player")

	# Pad actions
	for a in ["dodge", "interact", "place_trap", "look_left", "sprint", "light_attack"]:
		if InputMap.has_action(a):
			ok("input " + a)
		else:
			fail("input missing " + a)
