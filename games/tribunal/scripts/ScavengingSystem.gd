# ScavengingSystem.gd
# High-stakes looting — Culling risk/reward: contested E-channel, not free walk-in.

extends Node
class_name ScavengingSystem

const PropSkinUtil = preload("res://scripts/PropSkins.gd")

@export var loot_table: Array[Dictionary] = [
	{"id": "heal", "name": "Medkit Scrap", "weight": 0.35, "heal": 20},
	{"id": "bandage", "name": "Bandage", "weight": 0.25, "heal": 35},
	{"id": "weapon", "name": "Fallen Weapon", "weight": 0.22},
	{"id": "trap_kit", "name": "Trap Kit", "weight": 0.18},
]

@export var default_count: int = 10
@export var arena_half_extent: float = 9.0
@export var interact_radius: float = 1.35
@export var channel_time: float = 1.05  # vulnerable window while scavenging
@export var channel_move_cancel: float = 0.55  # cancel if player moves too far mid-channel

var spawned_loot: Array = []
# player instance_id -> { "loot": Area3D, "t": float, "start": Vector3 }
var _channels: Dictionary = {}

signal loot_collected(item: Dictionary, player: Node)
signal channel_started(player: Node, loot: Area3D)
signal channel_cancelled(player: Node)
signal channel_progress(player: Node, progress: float)


func _process(delta: float) -> void:
	if _channels.is_empty():
		return
	var done: Array = []
	for pid in _channels.keys():
		var ch: Dictionary = _channels[pid]
		var player: Node = ch.get("player")
		var loot: Area3D = ch.get("loot")
		if player == null or not is_instance_valid(player) or loot == null or not is_instance_valid(loot):
			done.append(pid)
			continue
		if player is PlayerController and player.melee_state == PlayerController.MeleeState.DEAD:
			done.append(pid)
			channel_cancelled.emit(player)
			continue
		# Cancel if moved too far from channel start (contested / panicked)
		var start_pos: Vector3 = ch.get("start", player.global_position)
		if player.global_position.distance_to(start_pos) > channel_move_cancel:
			print(player.name, " scavenge cancelled (moved)")
			channel_cancelled.emit(player)
			done.append(pid)
			continue
		# Cancel if left interact radius
		if player.global_position.distance_to(loot.global_position) > interact_radius + 0.35:
			print(player.name, " scavenge cancelled (left cache)")
			channel_cancelled.emit(player)
			done.append(pid)
			continue
		ch["t"] = float(ch.get("t", 0.0)) + delta
		_channels[pid] = ch
		var prog := clampf(float(ch["t"]) / channel_time, 0.0, 1.0)
		channel_progress.emit(player, prog)
		# Subtle pulse on cache while channeling
		if loot.has_node("LootMesh"):
			var mi = loot.get_node("LootMesh")
			if mi is Node3D:
				var s := 1.0 + 0.08 * sin(Time.get_ticks_msec() * 0.02)
				(mi as Node3D).scale = Vector3(s, s, s)
		if float(ch["t"]) >= channel_time:
			_complete_scavenge(player, loot)
			done.append(pid)
	for pid in done:
		_channels.erase(pid)


func spawn_loot_in_arena(arena: Node3D, count: int = -1) -> void:
	if count < 0:
		count = default_count
	print("ScavengingSystem: spawning %d contested caches (E to scavenge)..." % count)
	for i in count:
		var pos := Vector3(
			randf_range(-arena_half_extent, arena_half_extent),
			0.35,
			randf_range(-arena_half_extent, arena_half_extent)
		)
		if pos.length() < 2.5:
			pos = pos.normalized() * 3.5 if pos.length() > 0.01 else Vector3(3, 0.35, 2)
		_spawn_cache_at(arena, pos)


func spawn_loot_at(arena: Node3D, pos: Vector3) -> void:
	_spawn_cache_at(arena, pos + Vector3(0, 0.35, 0))


func _spawn_cache_at(arena: Node3D, pos: Vector3) -> void:
	var loot: Area3D = PropSkinUtil.spawn_loot(arena, pos, false, 0)
	if loot == null:
		loot = _fallback_cache(arena, pos)
	loot.set_meta("scav_cache", true)
	loot.set_meta("channel_required", true)
	# Track presence only — no free auto-loot
	if not loot.body_entered.is_connected(_on_loot_body_entered):
		loot.body_entered.connect(_on_loot_body_entered.bind(loot))
	if not loot.body_exited.is_connected(_on_loot_body_exited):
		loot.body_exited.connect(_on_loot_body_exited.bind(loot))
	spawned_loot.append(loot)


func _fallback_cache(arena: Node3D, pos: Vector3) -> Area3D:
	var loot := Area3D.new()
	loot.name = "LootCache"
	loot.monitoring = true
	loot.collision_layer = 0
	loot.collision_mask = 1
	loot.add_to_group("loot")
	var cs := CollisionShape3D.new()
	var sp := SphereShape3D.new()
	sp.radius = 0.85
	cs.shape = sp
	loot.add_child(cs)
	var mi := MeshInstance3D.new()
	mi.name = "LootMesh"
	var box := BoxMesh.new()
	box.size = Vector3(0.55, 0.4, 0.7)
	mi.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.7, 0.15)
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.75, 0.2)
	mat.emission_energy_multiplier = 1.2
	mi.material_override = mat
	loot.add_child(mi)
	loot.position = pos
	arena.add_child(loot)
	return loot


func _on_loot_body_entered(body: Node, loot_node: Area3D) -> void:
	if not is_instance_valid(loot_node) or not body.is_in_group("players"):
		return
	# Mark player as near this cache for E interact
	if body is Node:
		body.set_meta("near_loot", loot_node.get_instance_id())
		body.set_meta("near_loot_node", loot_node)


func _on_loot_body_exited(body: Node, loot_node: Area3D) -> void:
	if not body is Node:
		return
	if body.has_meta("near_loot") and int(body.get_meta("near_loot")) == loot_node.get_instance_id():
		body.remove_meta("near_loot")
		if body.has_meta("near_loot_node"):
			body.remove_meta("near_loot_node")
	# Cancel channel if they left
	var pid := body.get_instance_id()
	if _channels.has(pid):
		_channels.erase(pid)
		channel_cancelled.emit(body)


## Called by PlayerController on E / interact.
func try_begin_scavenge(player: Node) -> bool:
	if player == null or not is_instance_valid(player):
		return false
	if player is PlayerController and player.melee_state == PlayerController.MeleeState.DEAD:
		return false
	var pid := player.get_instance_id()
	if _channels.has(pid):
		return false  # already channeling
	var loot: Area3D = _find_nearest_loot(player)
	if loot == null:
		return false
	_channels[pid] = {
		"player": player,
		"loot": loot,
		"t": 0.0,
		"start": player.global_position,
	}
	channel_started.emit(player, loot)
	print(player.name, " scavenging… (", channel_time, "s channel)")
	return true


func is_channeling(player: Node) -> bool:
	return player != null and _channels.has(player.get_instance_id())


func cancel_for_player(player: Node) -> void:
	if player == null:
		return
	var pid := player.get_instance_id()
	if _channels.has(pid):
		_channels.erase(pid)
		channel_cancelled.emit(player)
		print(player.name, " scavenge cancelled (interrupted)")


func get_channel_progress(player: Node) -> float:
	if player == null or not _channels.has(player.get_instance_id()):
		return 0.0
	var ch: Dictionary = _channels[player.get_instance_id()]
	return clampf(float(ch.get("t", 0.0)) / channel_time, 0.0, 1.0)


func _find_nearest_loot(player: Node) -> Area3D:
	# Prefer meta from area overlap
	if player.has_meta("near_loot_node"):
		var n = player.get_meta("near_loot_node")
		if n is Area3D and is_instance_valid(n) and spawned_loot.has(n):
			return n as Area3D
	# Fallback: distance scan
	var best: Area3D = null
	var best_d := interact_radius
	var ppos: Vector3 = player.global_position if player is Node3D else Vector3.ZERO
	for loot in spawned_loot:
		if not is_instance_valid(loot) or not loot is Area3D:
			continue
		var d: float = ppos.distance_to((loot as Area3D).global_position)
		if d <= best_d:
			best_d = d
			best = loot as Area3D
	return best


func _complete_scavenge(player: Node, loot_node: Area3D) -> void:
	if not is_instance_valid(loot_node):
		return
	var item := _roll_item()
	_apply_loot(player, item)
	loot_collected.emit(item, player)
	print(player.name, " scavenged ", item.get("name", item.get("id", "?")), " [", item.get("id", ""), "]")
	spawned_loot.erase(loot_node)
	if player.has_meta("near_loot"):
		player.remove_meta("near_loot")
	if player.has_meta("near_loot_node"):
		player.remove_meta("near_loot_node")
	loot_node.queue_free()


func _roll_item() -> Dictionary:
	var total := 0.0
	for e in loot_table:
		total += float(e.get("weight", 1.0))
	if total <= 0.0:
		return {"id": "heal", "name": "Medkit Scrap", "heal": 15}
	var r := randf() * total
	var acc := 0.0
	for e in loot_table:
		acc += float(e.get("weight", 1.0))
		if r <= acc:
			return e.duplicate()
	return loot_table[loot_table.size() - 1].duplicate()


func _apply_loot(player: Node, item: Dictionary) -> void:
	var id: String = str(item.get("id", "heal"))
	match id:
		"heal", "bandage":
			var amount: int = int(item.get("heal", 20 if id == "heal" else 35))
			if player.has_method("heal_partial"):
				player.heal_partial(amount)
			elif "health" in player and "max_health" in player:
				player.health = mini(int(player.max_health), int(player.health) + amount)
				if player.has_signal("health_changed"):
					player.health_changed.emit(player.health)
			item["applied"] = "heal_%d" % amount
		"weapon":
			_grant_random_weapon(player)
			item["applied"] = "weapon"
		"trap_kit":
			_grant_trap_kit(player)
			item["applied"] = "trap_kit"
		_:
			if player.has_method("heal_partial"):
				player.heal_partial(15)
			item["applied"] = "heal_default"


func _grant_random_weapon(player: Node) -> void:
	if not player is PlayerController:
		return
	var types := [Weapon.WeaponType.SWORD, Weapon.WeaponType.AXE, Weapon.WeaponType.DAGGER]
	var w := Weapon.new()
	w.weapon_type = types[randi() % types.size()]
	w._apply_profile()
	player.equip_weapon(w)
	if player.has_method("_apply_weapon_skin_to_hand"):
		var SkinCat = load("res://scripts/SkinCatalog.gd")
		player.weapon_skin_id = SkinCat.default_weapon_skin(int(w.weapon_type) + 1)
		player._apply_weapon_skin_to_hand()


func _grant_trap_kit(player: Node) -> void:
	var traps := _find_trap_system()
	if traps and traps.has_method("add_trap_kit"):
		traps.add_trap_kit(player, 1)
	elif player.has_meta("trap_kits"):
		player.set_meta("trap_kits", int(player.get_meta("trap_kits")) + 1)
	else:
		player.set_meta("trap_kits", 1)


func _find_trap_system() -> Node:
	var parent := get_parent()
	if parent:
		var t = parent.get_node_or_null("TrapSystem")
		if t:
			return t
	if get_tree():
		var nodes = get_tree().get_nodes_in_group("trap_system")
		if nodes.size() > 0:
			return nodes[0]
	return null
