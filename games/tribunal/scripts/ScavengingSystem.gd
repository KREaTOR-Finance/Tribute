# ScavengingSystem.gd
# High-stakes looting that feeds the melee/crafting loop
# From The Culling: risk vs reward, limited time, good loot changes fights

extends Node
class_name ScavengingSystem

const PropSkinUtil = preload("res://scripts/PropSkins.gd")

## Weighted pickup outcomes after a player touches a cache.
## "heal" always restores HP; others are rolls with side effects.
@export var loot_table: Array[Dictionary] = [
	{"id": "heal", "name": "Medkit Scrap", "weight": 0.35, "heal": 20},
	{"id": "bandage", "name": "Bandage", "weight": 0.25, "heal": 35},
	{"id": "weapon", "name": "Fallen Weapon", "weight": 0.22},
	{"id": "trap_kit", "name": "Trap Kit", "weight": 0.18},
]

@export var default_count: int = 10
@export var arena_half_extent: float = 8.0

var spawned_loot: Array = []

signal loot_collected(item: Dictionary, player: Node)


func spawn_loot_in_arena(arena: Node3D, count: int = -1) -> void:
	if count < 0:
		count = default_count
	print("ScavengingSystem: spawning %d high-stakes caches..." % count)
	for i in count:
		var pos := Vector3(
			randf_range(-arena_half_extent, arena_half_extent),
			0.35,
			randf_range(-arena_half_extent, arena_half_extent)
		)
		# Keep caches off spawn corners a bit
		if pos.length() < 2.5:
			pos = pos.normalized() * 3.5 if pos.length() > 0.01 else Vector3(3, 0.35, 2)
		_spawn_cache_at(arena, pos)


func spawn_loot_at(arena: Node3D, pos: Vector3) -> void:
	_spawn_cache_at(arena, pos + Vector3(0, 0.35, 0))


func _spawn_cache_at(arena: Node3D, pos: Vector3) -> void:
	# PropSkins gold cache mesh + Area3D; we own pickup (auto_pickup=false)
	var loot: Area3D = PropSkinUtil.spawn_loot(arena, pos, false, 0)
	if loot == null:
		loot = _fallback_cache(arena, pos)
	loot.set_meta("scav_cache", true)
	if not loot.body_entered.is_connected(_on_loot_body_entered):
		loot.body_entered.connect(_on_loot_body_entered.bind(loot))
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
	if not is_instance_valid(loot_node):
		return
	if not body.is_in_group("players"):
		return
	# Only living players
	if body is PlayerController and body.melee_state == PlayerController.MeleeState.DEAD:
		return

	var item := _roll_item()
	_apply_loot(body, item)
	loot_collected.emit(item, body)
	print(body.name, " scavenged ", item.get("name", item.get("id", "?")), " [", item.get("id", ""), "]")

	spawned_loot.erase(loot_node)
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
