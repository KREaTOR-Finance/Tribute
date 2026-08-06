extends CharacterBody3D
class_name HunterAI
## Culling-pressure hunter AI — role-based aggression for Tribunal.
## Roles: RUSHER (close hard), BAITER (circle then heavy), SCAVENGER (loot then mid).
## First-class SkinCatalog character + weapon skins (OBJ preferred).

signal died

const Catalog = preload("res://scripts/SkinCatalog.gd")
const ObjLoader = preload("res://scripts/ObjMeshLoader.gd")
const PropSkinUtil = preload("res://scripts/PropSkins.gd")
const CharAnimScript = preload("res://scripts/CharacterAnimator.gd")
const CombatAudioScript = preload("res://scripts/CombatAudio.gd")
const HitParticlesScene = preload("res://scripts/HitParticles.tscn")

enum Role {
	RUSHER,     ## Aggressive gap-close, light-heavy rhythm
	BAITER,     ## Circle/strafe then commit heavy
	SCAVENGER,  ## Prefer loot positions if group "loot" exists, else mid aggression
}

@export var max_health: int = 100
@export var move_speed: float = 4.8
@export var attack_range: float = 2.2
@export var role: Role = Role.RUSHER
@export var team_color: Color = Color(0.85, 0.15, 0.1)
@export var skin_id: String = ""
@export var weapon_skin_id: String = Catalog.WSKIN_BLOODSTEEL
@export var weapon_type: int = 1  # 1=sword default
@export var drop_loot_on_death: bool = true
@export var drop_death_mark: bool = true

## Role timing knobs (applied by apply_role_profile / set_role)
@export var light_attack_cd: float = 0.45
@export var heavy_attack_cd: float = 0.9
@export var heavy_chance: float = 0.28
@export var heavy_windup: float = 0.55

var health: int = 100
var target: Node3D
var _attack_cd: float = 0.0
var _windup: float = 0.0
var _winding: bool = false
var _mesh: MeshInstance3D
var _skin_rig: Node3D
var _anim = null
var _audio = null
var _alive: bool = true
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# BAITER orbit state
var _strafe_sign: float = 1.0
var _strafe_timer: float = 0.0
var _orbit_radius: float = 4.5
# SCAVENGER loot target
var _loot_target: Node3D = null
var _loot_abandon_timer: float = 0.0

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
	apply_role_profile(role)
	_build_body()
	add_to_group("hunters")
	add_to_group("damageable")
	_strafe_sign = 1.0 if randf() < 0.5 else -1.0
	_strafe_timer = randf_range(1.2, 2.4)


func set_role(new_role: Role) -> void:
	role = new_role
	apply_role_profile(role)


func apply_role_profile(r: Role) -> void:
	## Tune move_speed / attack_range / attack timing per role.
	match r:
		Role.RUSHER:
			move_speed = 5.9
			attack_range = 2.35
			light_attack_cd = 0.38
			heavy_attack_cd = 0.75
			heavy_chance = 0.18
			heavy_windup = 0.42
			_orbit_radius = 2.8
		Role.BAITER:
			move_speed = 4.4
			attack_range = 2.5
			light_attack_cd = 0.55
			heavy_attack_cd = 1.05
			heavy_chance = 0.55
			heavy_windup = 0.62
			_orbit_radius = 4.6
		Role.SCAVENGER:
			move_speed = 5.1
			attack_range = 2.1
			light_attack_cd = 0.48
			heavy_attack_cd = 0.95
			heavy_chance = 0.30
			heavy_windup = 0.52
			_orbit_radius = 3.5
		_:
			pass


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
	# Poseable multipart rig (+ optional OBJ shell)
	_skin_rig = Catalog.build_character_rig(self, skin_id)
	_mesh = _find_first_mesh(_skin_rig)
	var skins := Catalog.character_skins()
	if skins.has(skin_id):
		team_color = skins[skin_id]["body"]
	if _anim == null:
		_anim = CharAnimScript.new()
		_anim.name = "CharacterAnimator"
		add_child(_anim)
	_anim.bind(self)
	if _audio == null:
		_audio = CombatAudioScript.new()
		_audio.name = "CombatAudio"
		add_child(_audio)
		_audio.bind(self)
	print("HunterAI: role=", Role.keys()[role], " skin=", skin_id, " mesh=", _mesh != null)


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
	if _anim:
		_anim.set_pose(CharAnimScript.Pose.DEAD)
	# Kill particle burst (SYS-JUICE)
	var scene := get_tree().current_scene
	if scene:
		var burst = HitParticlesScene.instantiate()
		scene.add_child(burst)
		burst.spawn_kill(death_pos, Vector3.UP)
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
	tw.tween_interval(0.35)
	tw.tween_property(self, "global_position", death_pos + Vector3(0, -2, 0), 0.8)
	tw.tween_callback(queue_free)


func _resolve_target() -> void:
	if target != null and is_instance_valid(target):
		return
	var players := get_tree().get_nodes_in_group("players")
	if players.size() > 0:
		target = players[0]


func _nearest_loot() -> Node3D:
	var loots := get_tree().get_nodes_in_group("loot")
	var best: Node3D = null
	var best_d := 1e9
	for n in loots:
		if n is Node3D and is_instance_valid(n):
			var d: float = global_position.distance_to((n as Node3D).global_position)
			if d < best_d:
				best_d = d
				best = n as Node3D
	return best


func _move_toward_point(point: Vector3, speed: float, delta: float) -> void:
	var to := point - global_position
	to.y = 0
	var dist := to.length()
	if dist > 0.15:
		var dir := to.normalized()
		look_at(global_position + dir, Vector3.UP)
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		if _anim:
			_anim.set_move_blend(speed, move_speed, false)
			_anim.set_pose(CharAnimScript.Pose.WALK)
		if _audio:
			_audio.tick_footsteps(delta, speed, false, is_on_floor())
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		if _anim and not _winding:
			_anim.set_move_blend(0.0, move_speed, false)
			_anim.set_pose(CharAnimScript.Pose.IDLE)


func _try_attack() -> void:
	if _attack_cd > 0.0:
		return
	var use_heavy := randf() < heavy_chance
	# BAITER commits heavy more when already in range after orbit
	if role == Role.BAITER:
		use_heavy = randf() < heavy_chance
	if use_heavy:
		_winding = true
		_windup = heavy_windup
		if _anim:
			_anim.set_pose(CharAnimScript.Pose.HEAVY_WINDUP, heavy_windup)
		_attack_cd = heavy_attack_cd
	else:
		if _anim:
			_anim.set_pose(CharAnimScript.Pose.LIGHT_SWING, 0.12)
		_do_attack(false)
		_attack_cd = light_attack_cd


func _physics_process(delta: float) -> void:
	if not _alive:
		return
	if not is_on_floor():
		velocity.y -= gravity * delta
	_attack_cd = max(0.0, _attack_cd - delta)
	_strafe_timer = max(0.0, _strafe_timer - delta)

	if _winding:
		_windup -= delta
		if _anim:
			_anim.set_pose(CharAnimScript.Pose.HEAVY_WINDUP, max(_windup, 0.05))
		if _windup <= 0.0:
			_winding = false
			if _anim:
				_anim.set_pose(CharAnimScript.Pose.HEAVY_SWING, 0.14)
			_do_attack(true)
		move_and_slide()
		return

	_resolve_target()
	if target == null:
		move_and_slide()
		return

	match role:
		Role.RUSHER:
			_ai_rusher(delta)
		Role.BAITER:
			_ai_baiter(delta)
		Role.SCAVENGER:
			_ai_scavenger(delta)
		_:
			_ai_rusher(delta)
	move_and_slide()


func _ai_rusher(delta: float) -> void:
	## Aggressive: always close gap, attack ASAP, low heavy chance.
	var to := target.global_position - global_position
	to.y = 0
	var dist := to.length()
	if dist > 0.1:
		look_at(global_position + to.normalized(), Vector3.UP)
	if dist > attack_range * 0.92:
		var dir := to.normalized()
		# Slight sprint bias when far
		var spd := move_speed * (1.12 if dist > 6.0 else 1.0)
		velocity.x = dir.x * spd
		velocity.z = dir.z * spd
		if _anim:
			_anim.set_move_blend(spd, move_speed, dist > 6.0)
			_anim.set_pose(CharAnimScript.Pose.WALK)
		if _audio:
			_audio.tick_footsteps(delta, spd, dist > 6.0, is_on_floor())
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
		if _anim and not _winding:
			_anim.set_move_blend(0.0, move_speed, false)
			_anim.set_pose(CharAnimScript.Pose.IDLE)
		_try_attack()


func _ai_baiter(delta: float) -> void:
	## Circle/strafe at orbit radius, then close for heavy.
	var to := target.global_position - global_position
	to.y = 0
	var dist := to.length()
	if dist > 0.1:
		look_at(global_position + to.normalized(), Vector3.UP)

	if _strafe_timer <= 0.0:
		_strafe_sign *= -1.0
		_strafe_timer = randf_range(1.0, 2.2)

	if dist > _orbit_radius + 1.2:
		# Approach into orbit band
		_move_toward_point(target.global_position, move_speed, delta)
	elif dist > attack_range + 0.15 and dist > _orbit_radius - 0.6:
		# Strafe circle around target
		var radial := to.normalized()
		var tangent := Vector3(-radial.z, 0, radial.x) * _strafe_sign
		# Hold orbit: slight radial correction + strafe
		var hold := Vector3.ZERO
		if dist > _orbit_radius + 0.35:
			hold = radial
		elif dist < _orbit_radius - 0.35:
			hold = -radial
		var dir := (tangent * 0.85 + hold * 0.35).normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
		if _anim:
			_anim.set_move_blend(move_speed, move_speed, false)
			_anim.set_pose(CharAnimScript.Pose.WALK)
		if _audio:
			_audio.tick_footsteps(delta, move_speed, false, is_on_floor())
		# Occasionally step in for a heavy commit
		if _attack_cd <= 0.0 and randf() < 0.35 * delta * 8.0:
			# Burst inward
			velocity += radial * move_speed * 0.8
	else:
		# In attack pocket — prefer heavy
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
		if _anim and not _winding:
			_anim.set_move_blend(0.0, move_speed, false)
			_anim.set_pose(CharAnimScript.Pose.IDLE)
		_try_attack()


func _ai_scavenger(delta: float) -> void:
	## Prefer loot if present; otherwise mid aggression on player.
	var to_player := target.global_position - global_position
	to_player.y = 0
	var player_dist := to_player.length()

	# Abandon loot path if player is very close (forced engage)
	if player_dist < attack_range + 1.2:
		_loot_target = null
		_ai_mid_aggression(delta, player_dist, to_player)
		return

	if _loot_target == null or not is_instance_valid(_loot_target):
		_loot_target = _nearest_loot()
		_loot_abandon_timer = 6.0

	if _loot_target != null and is_instance_valid(_loot_target):
		_loot_abandon_timer -= delta
		var loot_pos: Vector3 = _loot_target.global_position
		var loot_dist := global_position.distance_to(loot_pos)
		if loot_dist > 1.4 and _loot_abandon_timer > 0.0:
			_move_toward_point(loot_pos, move_speed * 1.05, delta)
			return
		# Reached loot area — clear and re-engage player
		_loot_target = null

	_ai_mid_aggression(delta, player_dist, to_player)


func _ai_mid_aggression(delta: float, dist: float, to: Vector3) -> void:
	## SCAVENGER fallback / mid pressure: close steadily, balanced attacks.
	if dist > 0.1:
		look_at(global_position + to.normalized(), Vector3.UP)
	if dist > attack_range:
		var dir := to.normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
		if _anim:
			_anim.set_move_blend(move_speed, move_speed, false)
			_anim.set_pose(CharAnimScript.Pose.WALK)
		if _audio:
			_audio.tick_footsteps(delta, move_speed, false, is_on_floor())
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
		if _anim and not _winding:
			_anim.set_move_blend(0.0, move_speed, false)
			_anim.set_pose(CharAnimScript.Pose.IDLE)
		_try_attack()


func _do_attack(heavy: bool) -> void:
	if target == null:
		return
	var dist := global_position.distance_to(target.global_position)
	if dist > attack_range + 0.4:
		return
	var dmg := 28 if heavy else 12
	var kb := 14.0 if heavy else 8.0
	# Step into the cut
	var fwd := -global_transform.basis.z
	velocity += fwd * (4.5 if heavy else 2.5)
	if _audio:
		_audio.play_whoosh(heavy)
	if target.has_method("apply_damage"):
		target.apply_damage(dmg, self, kb)
		if _audio:
			_audio.play_hit(heavy)
	elif target.has_method("take_damage"):
		target.take_damage(dmg)
		if _audio:
			_audio.play_hit(heavy)
