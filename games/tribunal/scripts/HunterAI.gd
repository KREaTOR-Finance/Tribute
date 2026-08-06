extends CharacterBody3D
class_name HunterAI
## Aggressive sparring hunter for Tribunal — seeks player, light/heavy rhythm.
## First-class SkinCatalog character + weapon skins (OBJ preferred).

signal died

const Catalog = preload("res://scripts/SkinCatalog.gd")
const ObjLoader = preload("res://scripts/ObjMeshLoader.gd")
const PropSkinUtil = preload("res://scripts/PropSkins.gd")

@export var max_health: int = 100
@export var move_speed: float = 4.8
@export var attack_range: float = 2.2
@export var team_color: Color = Color(0.85, 0.15, 0.1)
@export var skin_id: String = ""
@export var weapon_skin_id: String = Catalog.WSKIN_BLOODSTEEL
@export var weapon_type: int = 1  # 1=sword default
@export var drop_loot_on_death: bool = true
@export var drop_death_mark: bool = true

var health: int = 100
var target: Node3D
var _attack_cd: float = 0.0
var _windup: float = 0.0
var _winding: bool = false
var _mesh: MeshInstance3D
var _skin_rig: Node3D
var _alive: bool = true
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Cycle enemy skins for readable variety
const HUNTER_SKINS := [
	Catalog.SKIN_HUNTER_CRIMSON,
	Catalog.SKIN_HUNTER_BONE,
	Catalog.SKIN_HUNTER_IRON,
	Catalog.SKIN_HUNTER_AZURE,
]


func _ready() -> void:
	health = max_health
	collision_layer = 1
	collision_mask = 1
	if skin_id == "":
		skin_id = HUNTER_SKINS[randi() % HUNTER_SKINS.size()]
	_build_body()
	add_to_group("hunters")
	add_to_group("damageable")


func set_skin(new_skin: String) -> void:
	skin_id = new_skin
	# Rebuild visual if already constructed
	if _skin_rig and is_instance_valid(_skin_rig):
		_skin_rig.queue_free()
		_skin_rig = null
	var old_weapon = get_node_or_null("Weapon")
	if old_weapon:
		old_weapon.queue_free()
	_apply_character_skin()
	_build_weapon_visual()


func _build_body() -> void:
	var cap := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.6
	cap.shape = shape
	cap.position.y = 1.0
	add_child(cap)

	_apply_character_skin()
	_build_weapon_visual()


func _apply_character_skin() -> void:
	var old = get_node_or_null("SkinRig")
	if old:
		old.queue_free()
	# Prefer catalog OBJ / procedural character rig
	_skin_rig = Catalog.build_character_rig(self, skin_id)
	# Keep _mesh pointer for hit flash / windup scale
	_mesh = _find_first_mesh(_skin_rig)
	# Sync team_color from skin body for death marks
	var skins := Catalog.character_skins()
	if skins.has(skin_id):
		team_color = skins[skin_id]["body"]
	print("HunterAI: skin=", skin_id, " mesh=", _mesh != null)


func _build_weapon_visual() -> void:
	var old = get_node_or_null("Weapon")
	if old:
		old.queue_free()

	var stick := Node3D.new()
	stick.name = "Weapon"
	stick.position = Vector3(0.45, 1.1, -0.35)
	stick.rotation_degrees = Vector3(80, 0, 0)

	var obj_path := Catalog.weapon_mesh_path(weapon_skin_id, weapon_type)
	var mi: MeshInstance3D = null
	if obj_path != "" and FileAccess.file_exists(obj_path):
		var blade_mat = Catalog.make_weapon_blade_material(weapon_skin_id)
		mi = ObjLoader.make_mesh_instance(obj_path, blade_mat)
		if mi:
			mi.scale = Vector3(0.85, 0.85, 0.85)
			mi.rotation_degrees = Vector3(90, 0, 0)
	if mi == null:
		mi = MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.08, 0.08, 1.1)
		mi.mesh = box
		mi.material_override = Catalog.make_weapon_blade_material(weapon_skin_id)
	stick.add_child(mi)
	add_child(stick)


func _find_first_mesh(node: Node) -> MeshInstance3D:
	if node == null:
		return null
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		return node
	for c in node.get_children():
		var found := _find_first_mesh(c)
		if found:
			return found
	return null


func set_target(t: Node3D) -> void:
	target = t


func apply_damage(amount: int, from: Node3D = null, knockback: float = 0.0) -> void:
	if not _alive:
		return
	health = max(0, health - amount)
	if from and knockback > 0.0:
		var dir := (global_position - from.global_position).normalized()
		velocity += dir * knockback + Vector3.UP * 2.0
	_flash_hit()
	if health <= 0:
		_die()


func _flash_hit() -> void:
	var targets: Array = []
	if _mesh:
		targets.append(_mesh)
	elif _skin_rig:
		_collect_meshes(_skin_rig, targets)
	for m in targets:
		if m is MeshInstance3D and (m as MeshInstance3D).material_override is StandardMaterial3D:
			var mat: StandardMaterial3D = (m as MeshInstance3D).material_override.duplicate()
			(m as MeshInstance3D).material_override = mat
			mat.emission_enabled = true
			mat.emission = Color(1, 0.3, 0.1)
			mat.emission_energy_multiplier = 3.0
			get_tree().create_timer(0.08).timeout.connect(func ():
				if is_instance_valid(mat):
					mat.emission_energy_multiplier = 0.0
			)


func _collect_meshes(node: Node, out: Array) -> void:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		out.append(node)
	for c in node.get_children():
		_collect_meshes(c, out)


func _die() -> void:
	_alive = false
	var death_pos := global_position
	died.emit()
	# Death mark + loot prop skins (Culling fallen-hunter juice)
	var parent = get_parent()
	if parent is Node3D:
		if drop_death_mark:
			PropSkinUtil.spawn_death_mark(parent as Node3D, death_pos, team_color)
		if drop_loot_on_death:
			PropSkinUtil.spawn_loot(parent as Node3D, death_pos + Vector3(0, 0.25, 0.15))
	collision_layer = 0
	var tw := create_tween()
	tw.tween_property(self, "global_position", death_pos + Vector3(0, -2, 0), 0.8)
	tw.tween_callback(queue_free)


func _physics_process(delta: float) -> void:
	if not _alive:
		return
	if not is_on_floor():
		velocity.y -= gravity * delta
	_attack_cd = max(0.0, _attack_cd - delta)
	if _winding:
		_windup -= delta
		if _skin_rig:
			_skin_rig.scale = Vector3(1.15, 1.05, 1.15)
		elif _mesh:
			_mesh.scale = Vector3(1.2, 1.05, 1.2)
		if _windup <= 0.0:
			_winding = false
			_do_attack(true)
			if _skin_rig:
				_skin_rig.scale = Vector3.ONE
			elif _mesh:
				_mesh.scale = Vector3.ONE
		move_and_slide()
		return
	if target == null or not is_instance_valid(target):
		var players := get_tree().get_nodes_in_group("players")
		if players.size() > 0:
			target = players[0]
	if target == null:
		move_and_slide()
		return
	var to := target.global_position - global_position
	to.y = 0
	var dist := to.length()
	if dist > 0.1:
		look_at(global_position + to.normalized(), Vector3.UP)
	if dist > attack_range:
		var dir := to.normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
		if _attack_cd <= 0.0:
			if randf() < 0.28:
				_winding = true
				_windup = 0.55
			else:
				_do_attack(false)
			_attack_cd = 0.9 if _winding else 0.45
	move_and_slide()


func _do_attack(heavy: bool) -> void:
	if target == null:
		return
	var dist := global_position.distance_to(target.global_position)
	if dist > attack_range + 0.4:
		return
	var dmg := 28 if heavy else 12
	var kb := 14.0 if heavy else 8.0
	if target.has_method("apply_damage"):
		target.apply_damage(dmg, self, kb)
	elif target.has_method("take_damage"):
		target.take_damage(dmg)
