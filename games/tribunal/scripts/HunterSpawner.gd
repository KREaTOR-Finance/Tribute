extends Node3D
class_name HunterSpawner
## Wave spawner for Culling-pressure hunters.
## Assigns roles round-robin, skins from SkinCatalog, targets player1 by default.

const HunterScript = preload("res://scripts/HunterAI.gd")
const Catalog = preload("res://scripts/SkinCatalog.gd")

@export var default_count: int = 2
@export var spawn_y: float = 1.2
@export var drop_loot_on_death: bool = true
@export var drop_death_mark: bool = true

## Optional explicit player target; if null, uses group "players"[0].
var player_target: Node3D = null

var _wave_index: int = 0
var _role_cursor: int = 0
var _spawned: Array = []

signal hunters_spawned(wave: Array)

# Round-robin: RUSHER → BAITER → SCAVENGER (ints match HunterAI.Role)
const ROLE_ORDER: Array = [0, 1, 2]

const DEFAULT_OFFSETS: Array = [
	Vector3(6, 0, -4),
	Vector3(-6, 0, -5),
	Vector3(0, 0, 8),
	Vector3(8, 0, 3),
	Vector3(-8, 0, 4),
	Vector3(4, 0, -8),
]


func set_player_target(t: Node3D) -> void:
	player_target = t


func _resolve_target() -> Node3D:
	if player_target != null and is_instance_valid(player_target):
		return player_target
	var players := get_tree().get_nodes_in_group("players")
	if players.size() > 0 and players[0] is Node3D:
		return players[0] as Node3D
	return null


func _parent_for_hunters() -> Node:
	# Prefer scene root (spawner's parent) so hunters sit beside arena props.
	if get_parent() != null:
		return get_parent()
	return self


func spawn_wave(count: int = -1) -> Array:
	if count < 0:
		count = default_count
	var parent := _parent_for_hunters()
	var target := _resolve_target()
	var skins: Array = Catalog.character_skins().keys()
	if skins.is_empty():
		skins = [
			Catalog.SKIN_HUNTER_CRIMSON,
			Catalog.SKIN_HUNTER_BONE,
			Catalog.SKIN_HUNTER_IRON,
			Catalog.SKIN_HUNTER_AZURE,
		]
	var wave: Array = []
	var base_i := _wave_index * 17
	for i in count:
		var h = HunterScript.new()
		var off: Vector3 = DEFAULT_OFFSETS[(base_i + i) % DEFAULT_OFFSETS.size()]
		# Slight radial jitter so multi-wave stacks don't stack perfectly
		var jitter := Vector3(randf_range(-0.6, 0.6), 0, randf_range(-0.6, 0.6))
		h.position = Vector3(off.x + jitter.x, spawn_y, off.z + jitter.z)

		var role_val: int = int(ROLE_ORDER[_role_cursor % ROLE_ORDER.size()])
		_role_cursor += 1
		h.role = role_val
		if h.has_method("apply_role_profile"):
			h.apply_role_profile(role_val)

		h.skin_id = str(skins[(base_i + i) % skins.size()])
		h.weapon_type = 1 + ((base_i + i) % 3)
		h.weapon_skin_id = Catalog.default_weapon_skin(h.weapon_type)
		h.drop_loot_on_death = drop_loot_on_death
		h.drop_death_mark = drop_death_mark

		if target:
			h.set_target(target)

		parent.add_child(h)
		wave.append(h)
		_spawned.append(h)
		var role_name := "RUSHER"
		match role_val:
			1:
				role_name = "BAITER"
			2:
				role_name = "SCAVENGER"
		print(
			"HunterSpawner: wave=", _wave_index,
			" hunter=", i,
			" role=", role_name,
			" skin=", h.skin_id,
			" spd=", h.move_speed,
			" range=", h.attack_range
		)
	_wave_index += 1
	hunters_spawned.emit(wave)
	return wave


func clear_spawned() -> void:
	for h in _spawned:
		if h != null and is_instance_valid(h):
			h.queue_free()
	_spawned.clear()


func alive_count() -> int:
	var n := 0
	for h in _spawned:
		if h != null and is_instance_valid(h):
			if "_alive" in h and h._alive:
				n += 1
			elif not ("_alive" in h):
				n += 1
	return n
