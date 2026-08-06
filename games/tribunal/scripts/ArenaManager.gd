# ArenaManager.gd — full round lifecycle for Tribunal MeleeTest.
# Intro → Fight → End + stats for FinishBoard.

extends Node
class_name ArenaManager

enum Phase { INTRO, FIGHT, ENDED }

@export var match_duration: float = 300.0
@export var max_players: int = 8
@export var test_mode_respawn: bool = false
@export var intro_seconds: float = 1.6

var phase: Phase = Phase.INTRO
var time_remaining: float = match_duration
var match_elapsed: float = 0.0
var players_alive: Array = []
var players: Array = []
var loot_spawned: int = 0
var zone_system: Node = null
var _zone_final_triggered: bool = false
var _intro_left: float = 0.0
var _end_reason: String = "elimination"

# Per-player stats: instance_id -> Dictionary
var _stats: Dictionary = {}

signal match_started
signal match_ended(winner: Node)
signal player_eliminated(player: Node)
signal phase_changed(phase: int)


func _ready():
	phase = Phase.INTRO
	_intro_left = intro_seconds
	time_remaining = match_duration
	match_elapsed = 0.0
	print("ArenaManager: INTRO → fight in ", intro_seconds, "s · duration ", match_duration / 60.0, " min")


func _process(delta: float):
	if phase == Phase.ENDED:
		return

	if phase == Phase.INTRO:
		_intro_left -= delta
		if _intro_left <= 0.0:
			phase = Phase.FIGHT
			phase_changed.emit(phase)
			match_started.emit()
			print("ArenaManager: FIGHT — round live")
		return

	# FIGHT
	time_remaining = maxf(0.0, time_remaining - delta)
	match_elapsed += delta

	if zone_system and not _zone_final_triggered:
		if time_remaining <= 60.0 and players_alive.size() > 1:
			_zone_final_triggered = true
			if zone_system.has_method("force_final_circle"):
				zone_system.force_final_circle(45.0)
				print("ArenaManager: final circle forced")

	if time_remaining <= 0.0 and players_alive.size() > 1:
		_end_by_time()


func register_zone(zone: Node) -> void:
	zone_system = zone


func register_player(player) -> void:
	if player == null or player in players:
		return
	players.append(player)
	players_alive.append(player)
	_ensure_stats(player)
	if player.has_signal("player_died"):
		if not player.player_died.is_connected(_on_player_died.bind(player)):
			player.player_died.connect(_on_player_died.bind(player))


func _ensure_stats(player: Node) -> void:
	var id := player.get_instance_id()
	if not _stats.has(id):
		_stats[id] = {
			"player": player,
			"name": player.name,
			"kills": 0,
			"scavenges": 0,
			"traps": 0,
			"damage_dealt": 0,
		}


func record_kill(attacker: Node, victim: Node = null) -> void:
	if attacker == null or not is_instance_valid(attacker):
		return
	_ensure_stats(attacker)
	_stats[attacker.get_instance_id()]["kills"] = int(_stats[attacker.get_instance_id()]["kills"]) + 1


func record_scavenge(player: Node) -> void:
	if player == null:
		return
	_ensure_stats(player)
	_stats[player.get_instance_id()]["scavenges"] = int(_stats[player.get_instance_id()]["scavenges"]) + 1


func record_trap(owner: Node) -> void:
	if owner == null:
		return
	_ensure_stats(owner)
	_stats[owner.get_instance_id()]["traps"] = int(_stats[owner.get_instance_id()]["traps"]) + 1


func _on_player_died(player):
	if player == null or phase == Phase.ENDED:
		return
	players_alive.erase(player)
	player_eliminated.emit(player)
	print("ELIMINATED: ", player.name, " | Players left: ", players_alive.size())

	if players_alive.size() <= 1:
		_end_reason = "elimination"
		var winner = players_alive[0] if players_alive.size() > 0 else null
		_finish(winner)
		return

	if test_mode_respawn:
		await get_tree().create_timer(2.5).timeout
		if is_instance_valid(player) and player in players and phase == Phase.FIGHT:
			_respawn_player(player)
	else:
		print(player.name, " permanently eliminated (last stand)")


func _end_by_time() -> void:
	_end_reason = "time"
	var best: Node = null
	var best_hp := -1
	for p in players_alive:
		if p == null or not is_instance_valid(p):
			continue
		var hp := int(p.health) if "health" in p else 0
		if hp > best_hp:
			best_hp = hp
			best = p
	_finish(best)


func _finish(winner: Node) -> void:
	if phase == Phase.ENDED:
		return
	phase = Phase.ENDED
	phase_changed.emit(phase)
	# Soft-freeze living fighters
	for p in players:
		if p == null or not is_instance_valid(p):
			continue
		if p is CharacterBody3D:
			(p as CharacterBody3D).velocity = Vector3.ZERO
		if p != winner and p.has_method("set_physics_process"):
			# Keep winner able to look; freeze defeated combat already handled
			pass
	match_ended.emit(winner)
	print("MATCH OVER — Winner:", winner.name if winner else "Draw", " reason=", _end_reason)


func build_results_payload(winner: Node) -> Dictionary:
	var fighters: Array = []
	for p in players:
		if p == null or not is_instance_valid(p):
			continue
		_ensure_stats(p)
		var st: Dictionary = _stats[p.get_instance_id()]
		var pid := 1
		if "player_id" in p:
			pid = int(p.player_id)
		var col := Color(0.9, 0.2, 0.22) if pid == 1 else Color(0.25, 0.5, 1.0)
		fighters.append({
			"name": p.name,
			"color": col,
			"alive": p in players_alive and (not ("melee_state" in p) or int(p.melee_state) != 9),
			"kills": int(st.get("kills", 0)),
			"scavenges": int(st.get("scavenges", 0)),
			"traps": int(st.get("traps", 0)),
			"hp": int(p.health) if "health" in p else 0,
		})
	var draw := winner == null
	var wname := "DRAW"
	var wcol := Color(0.85, 0.85, 0.9)
	if winner and is_instance_valid(winner):
		wname = winner.name
		if "player_id" in winner and int(winner.player_id) == 2:
			wcol = Color(0.25, 0.5, 1.0)
		else:
			wcol = Color(0.9, 0.2, 0.22)
	return {
		"winner_name": wname,
		"winner_color": wcol,
		"draw": draw,
		"duration": match_elapsed,
		"reason": _end_reason,
		"fighters": fighters,
	}


func _respawn_player(player):
	if not is_instance_valid(player):
		return
	player.visible = true
	player.set_physics_process(true)
	player.health = player.max_health
	player.stamina = player.max_stamina
	if player.has_method("_set_melee_state"):
		player._set_melee_state(player.MeleeState.IDLE)
	var spawn_offset = Vector3(randf_range(-2, 2), 1, randf_range(-2, 2))
	var base := Vector3(-8, 1, -8) if int(player.player_id) == 1 else Vector3(8, 1, 8)
	player.global_position = base + spawn_offset
	if player not in players_alive:
		players_alive.append(player)
	if player.has_signal("health_changed"):
		player.health_changed.emit(player.health)
	if player.has_signal("stamina_changed"):
		player.stamina_changed.emit(player.stamina)
	print(player.name, " respawned (training mode)")
