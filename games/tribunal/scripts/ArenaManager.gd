# ArenaManager.gd
# Manages a single match: scavenging, trap placement, match timer, win conditions
# Core loop from The Culling: loot -> craft/trap -> fight -> survive
#
# Enhanced for melee focus: Better match flow, death handling, simple respawn stub for testing.

extends Node
class_name ArenaManager

@export var match_duration: float = 20.0 * 60.0  # 20 minutes (shorten for testing)
@export var max_players: int = 8   # MVP: start with 4-8, scale to 16 later
@export var test_mode_respawn: bool = true  # For rapid melee testing: auto-respawn after death

var time_remaining: float = match_duration
var players_alive: Array = []
var players: Array = []  # full list
var loot_spawned: int = 0

signal match_ended(winner: Node)
signal player_eliminated(player: Node)

func _ready():
	print("ArenaManager: Match starting. Duration:", match_duration / 60.0, "minutes")
	print("Core loop: Scavenge → Craft/Trap → Brutal Melee → Emergent stories")
	print("Enhanced: Deaths now trigger elimination. Test respawn available.")

func _process(delta: float):
	time_remaining -= delta
	if time_remaining <= 0 and players_alive.size() > 1:
		# Sudden death or shrink zone later
		pass

func register_player(player: PlayerController):
	if player == null or player in players:
		return
	players.append(player)
	players_alive.append(player)
	# player_died has no args — bind the player ref
	if not player.player_died.is_connected(_on_player_died.bind(player)):
		player.player_died.connect(_on_player_died.bind(player))

func _on_player_died(player: PlayerController):
	if player == null:
		return
	players_alive.erase(player)
	player_eliminated.emit(player)
	
	print("ELIMINATED: ", player.name, " | Players left: ", players_alive.size())
	
	if players_alive.size() <= 1:
		var winner = players_alive[0] if players_alive.size() > 0 else null
		match_ended.emit(winner)
		print("MATCH OVER — Winner:", winner.name if winner else "None (draw)")
	
	# Test-mode respawn for rapid melee iteration (remove for real matches)
	if test_mode_respawn:
		await get_tree().create_timer(2.5).timeout
		if is_instance_valid(player) and player in players:
			_respawn_player(player)

func _respawn_player(player: PlayerController):
	if not is_instance_valid(player):
		return
	
	player.visible = true
	player.set_physics_process(true)
	player.health = player.max_health
	player.stamina = player.max_stamina
	player.is_blocking = false
	player.is_winding_heavy = false
	
	# Random-ish spawn near original area (simple for test arena)
	var spawn_offset = Vector3(randf_range(-3, 3), 1, randf_range(-3, 3))
	player.global_position = Vector3(-4, 1, -4) + spawn_offset if player.player_id == 1 else Vector3(4, 1, 4) + spawn_offset
	
	# Re-emit for UI
	player.health_changed.emit(player.health)
	player.stamina_changed.emit(player.stamina)
	
	print(player.name, " respawned for continued melee testing.")

# TODO: Scavenging system (loot tables, high-stakes risk/reward)
# TODO: Trap placement (player places, activates on enemies)
# TODO: Zone shrink for tension in longer matches
# TODO: Simple crafting (wood + scrap → spear, trap, bandage)
