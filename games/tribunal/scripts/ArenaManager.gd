# ArenaManager.gd
# Manages a single match: scavenging, trap placement, match timer, win conditions
# Core loop from The Culling: loot -> craft/trap -> fight -> survive
#
# Enhanced for melee focus: Better match flow, death handling, simple respawn stub for testing.

extends Node
class_name ArenaManager

@export var match_duration: float = 20.0 * 60.0  # 20 minutes (shorten for testing)
@export var max_players: int = 8   # MVP: start with 4-8, scale to 16 later
@export var test_mode_respawn: bool = false  # Last-stand default; enable only for training spars

var time_remaining: float = match_duration
var players_alive: Array = []
var players: Array = []  # full list
var loot_spawned: int = 0
var zone_system: Node = null
var _zone_final_triggered: bool = false

signal match_ended(winner: Node)
signal player_eliminated(player: Node)

func _ready():
	print("ArenaManager: Match starting. Duration:", match_duration / 60.0, "minutes")
	print("Core loop: Scavenge → Craft/Trap → Brutal Melee → Emergent stories")
	print("Enhanced: Deaths now trigger elimination. Test respawn available.")

func _process(delta: float):
	time_remaining -= delta
	# Late match / overtime: accelerate the closing ring (Culling tension)
	if zone_system and not _zone_final_triggered:
		if time_remaining <= 60.0 and players_alive.size() > 1:
			_zone_final_triggered = true
			if zone_system.has_method("force_final_circle"):
				zone_system.force_final_circle(45.0)
				print("ArenaManager: final circle forced (timer pressure)")

func register_zone(zone: Node) -> void:
	zone_system = zone

func register_player(player):
	if player == null or player in players:
		return
	players.append(player)
	players_alive.append(player)
	if player.has_signal("player_died"):
		if not player.player_died.is_connected(_on_player_died.bind(player)):
			player.player_died.connect(_on_player_died.bind(player))

func _on_player_died(player):
	if player == null:
		return
	players_alive.erase(player)
	player_eliminated.emit(player)
	
	print("ELIMINATED: ", player.name, " | Players left: ", players_alive.size())
	
	if players_alive.size() <= 1:
		var winner = players_alive[0] if players_alive.size() > 0 else null
		match_ended.emit(winner)
		print("MATCH OVER — Winner:", winner.name if winner else "None (draw)")
		# Freeze survivors physics soft — they can still look; R restarts scene
		if winner and is_instance_valid(winner) and winner is CharacterBody3D:
			(winner as CharacterBody3D).velocity = Vector3.ZERO
	
	if test_mode_respawn:
		await get_tree().create_timer(2.5).timeout
		if is_instance_valid(player) and player in players:
			_respawn_player(player)
	else:
		print(player.name, " permanently eliminated (last stand)")

func _respawn_player(player):
	if not is_instance_valid(player):
		return
	
	player.visible = true
	player.set_physics_process(true)
	player.health = player.max_health
	player.stamina = player.max_stamina
	if player.has_method("_set_melee_state"):
		player._set_melee_state(player.MeleeState.IDLE)
	else:
		player.is_blocking = false
		player.is_winding_heavy = false
	
	# Random-ish spawn near original area (simple for test arena)
	var spawn_offset = Vector3(randf_range(-3, 3), 1, randf_range(-3, 3))
	player.global_position = Vector3(-4, 1, -4) + spawn_offset if player.player_id == 1 else Vector3(4, 1, 4) + spawn_offset
	
	# Re-enter alive set so match flow stays consistent with spar testing
	if player not in players_alive:
		players_alive.append(player)
	# Re-emit for UI
	if player.has_signal("health_changed"):
		player.health_changed.emit(player.health)
	if player.has_signal("stamina_changed"):
		player.stamina_changed.emit(player.stamina)
	
	print(player.name, " respawned for continued melee testing.")

# TODO: Scavenging system (loot tables, high-stakes risk/reward)
# TODO: Trap placement (player places, activates on enemies)
# TODO: Simple crafting (wood + scrap → spear, trap, bandage)
