# TrapSystem.gd
# Traps that completely change fights — core The Culling fantasy
# Bear trap, spike trap, tripwire, etc.

extends Node
class_name TrapSystem

@export var trap_types: Dictionary = {
	"bear_trap": {"damage": 35, "slow": 0.5, "duration": 4.0, "radius": 1.15},
	"spike_trap": {"damage": 55, "bleed": true, "radius": 1.0},
	"tripwire": {"damage": 15, "stun": 1.5, "radius": 1.3},
}

@export var default_kits_per_player: int = 3
@export var place_forward_offset: float = 1.35
@export var arm_delay: float = 0.55

## Runtime trap records: { type, position, owner, armed, node, data }
var placed_traps: Array = []
## instance_id -> kits remaining
var _kits: Dictionary = {}

signal trap_triggered(trap_type: String, victim: Node)
signal trap_placed(trap_type: String, player: Node, position: Vector3)


func _ready() -> void:
	add_to_group("trap_system")


func ensure_kits(player: Node, amount: int = -1) -> void:
	if player == null or not is_instance_valid(player):
		return
	var id := player.get_instance_id()
	if not _kits.has(id):
		_kits[id] = default_kits_per_player if amount < 0 else amount


func add_trap_kit(player: Node, count: int = 1) -> void:
	if player == null:
		return
	ensure_kits(player)
	var id := player.get_instance_id()
	_kits[id] = int(_kits[id]) + count
	print(player.name, " trap kits: ", _kits[id])


func get_trap_kits(player: Node) -> int:
	if player == null:
		return 0
	ensure_kits(player)
	return int(_kits.get(player.get_instance_id(), 0))


func place_trap(player: PlayerController, trap_type: String = "bear_trap", position: Variant = null) -> bool:
	if player == null or not is_instance_valid(player):
		return false
	if player.melee_state == PlayerController.MeleeState.DEAD:
		return false
	if not trap_types.has(trap_type):
		trap_type = "bear_trap"
	if not trap_types.has(trap_type):
		return false

	ensure_kits(player)
	var id := player.get_instance_id()
	if int(_kits.get(id, 0)) <= 0:
		print(player.name, " has no trap kits")
		return false

	var place_pos: Vector3
	if position == null or not (position is Vector3) or not (position as Vector3).is_finite():
		var fwd := -player.global_transform.basis.z
		fwd.y = 0.0
		if fwd.length_squared() < 0.001:
			fwd = Vector3.FORWARD
		else:
			fwd = fwd.normalized()
		place_pos = player.global_position + Vector3(0, 0.08, 0) + fwd * place_forward_offset
	else:
		place_pos = position as Vector3

	_kits[id] = int(_kits[id]) - 1

	var data: Dictionary = (trap_types[trap_type] as Dictionary).duplicate()
	var radius: float = float(data.get("radius", 1.15))

	# Real Area3D + mesh at feet+forward
	var trap_node := Area3D.new()
	trap_node.name = "Trap_%s" % trap_type
	trap_node.monitoring = true
	trap_node.monitorable = false
	trap_node.collision_layer = 0
	trap_node.collision_mask = 1
	trap_node.add_to_group("traps")

	var cs := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = radius
	cs.shape = shape
	trap_node.add_child(cs)

	_build_trap_visual(trap_node, trap_type)

	var parent_node: Node = get_parent() if get_parent() else self
	parent_node.add_child(trap_node)
	trap_node.global_position = place_pos

	var trap := {
		"type": trap_type,
		"position": place_pos,
		"owner": player,
		"armed": false,
		"node": trap_node,
		"data": data,
	}
	placed_traps.append(trap)

	# Arm after delay so placer doesn't instantly trigger
	var arm_timer := get_tree().create_timer(arm_delay)
	arm_timer.timeout.connect(func ():
		if is_instance_valid(trap_node) and trap in placed_traps:
			trap["armed"] = true
			_set_trap_armed_visual(trap_node, true)
			print(trap_type, " armed at ", place_pos)
	)

	trap_node.body_entered.connect(_on_trap_body_entered.bind(trap))

	trap_placed.emit(trap_type, player, place_pos)
	print(player.name, " placed ", trap_type, " at ", place_pos, " (kits left: ", _kits[id], ")")
	return true


func _build_trap_visual(trap_node: Area3D, trap_type: String) -> void:
	match trap_type:
		"bear_trap":
			# Two jaw plates + center pin
			var base := MeshInstance3D.new()
			base.name = "TrapMesh"
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.55
			cyl.bottom_radius = 0.6
			cyl.height = 0.08
			base.mesh = cyl
			base.position.y = 0.04
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.35, 0.32, 0.3)
			mat.metallic = 0.7
			mat.roughness = 0.4
			mat.emission_enabled = true
			mat.emission = Color(0.5, 0.08, 0.05)
			mat.emission_energy_multiplier = 0.35
			base.material_override = mat
			trap_node.add_child(base)

			var jaw_l := MeshInstance3D.new()
			jaw_l.name = "JawL"
			var box := BoxMesh.new()
			box.size = Vector3(0.55, 0.12, 0.18)
			jaw_l.mesh = box
			jaw_l.position = Vector3(-0.22, 0.12, 0)
			jaw_l.rotation_degrees = Vector3(0, 0, -25)
			jaw_l.material_override = mat.duplicate()
			trap_node.add_child(jaw_l)

			var jaw_r := MeshInstance3D.new()
			jaw_r.name = "JawR"
			jaw_r.mesh = box.duplicate()
			jaw_r.position = Vector3(0.22, 0.12, 0)
			jaw_r.rotation_degrees = Vector3(0, 0, 25)
			jaw_r.material_override = mat.duplicate()
			trap_node.add_child(jaw_r)
		"spike_trap":
			var mi := MeshInstance3D.new()
			mi.name = "TrapMesh"
			var pr := PrismMesh.new()
			pr.size = Vector3(0.7, 0.45, 0.7)
			mi.mesh = pr
			mi.position.y = 0.2
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.55, 0.5, 0.45)
			mat.metallic = 0.6
			mat.emission_enabled = true
			mat.emission = Color(0.8, 0.2, 0.05)
			mat.emission_energy_multiplier = 0.5
			mi.material_override = mat
			trap_node.add_child(mi)
		_:
			var mi := MeshInstance3D.new()
			mi.name = "TrapMesh"
			var box := BoxMesh.new()
			box.size = Vector3(0.9, 0.12, 0.15)
			mi.mesh = box
			mi.position.y = 0.06
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.7, 0.65, 0.2)
			mat.emission_enabled = true
			mat.emission = Color(0.9, 0.8, 0.1)
			mat.emission_energy_multiplier = 0.6
			mi.material_override = mat
			trap_node.add_child(mi)


func _set_trap_armed_visual(trap_node: Area3D, armed: bool) -> void:
	if not is_instance_valid(trap_node):
		return
	var mi = trap_node.get_node_or_null("TrapMesh")
	if mi and mi is MeshInstance3D and (mi as MeshInstance3D).material_override is StandardMaterial3D:
		var mat: StandardMaterial3D = (mi as MeshInstance3D).material_override
		mat.emission_energy_multiplier = 1.1 if armed else 0.25


func _on_trap_body_entered(body: Node, trap: Dictionary) -> void:
	if not trap.get("armed", false):
		return
	if body == null or not is_instance_valid(body):
		return
	# Owner never snags their own trap
	if body == trap.get("owner"):
		return
	# Trigger on damageable / players / hunters
	var valid := body.is_in_group("damageable") \
		or body.is_in_group("players") \
		or body.is_in_group("hunters")
	if not valid:
		return
	if not (body is CharacterBody3D):
		return
	trigger_trap(trap, body)


func check_traps_for_player(player: PlayerController) -> void:
	for trap in placed_traps.duplicate():
		if not trap.get("armed", false):
			continue
		if player == trap.get("owner"):
			continue
		var pos: Vector3 = trap["position"]
		var dist := (player.global_position - pos).length()
		var rad := float(trap.get("data", {}).get("radius", 1.2))
		if dist < rad:
			trigger_trap(trap, player)


func trigger_trap(trap: Dictionary, victim: Node) -> void:
	if not trap.get("armed", false):
		return
	trap["armed"] = false
	var ttype: String = str(trap.get("type", "bear_trap"))
	var data: Dictionary = trap.get("data", trap_types.get(ttype, {}))
	var dmg: int = int(data.get("damage", 35))
	var owner = trap.get("owner")

	print("TRAP TRIGGERED: ", ttype, " on ", victim.name if victim else "?", " for ", dmg, " damage!")

	# Snap jaws visual
	var node = trap.get("node")
	if node and is_instance_valid(node):
		_play_trigger_visual(node as Node3D, ttype)

	if victim.has_method("take_damage"):
		victim.take_damage(dmg, owner)
	elif victim.has_method("apply_damage"):
		victim.apply_damage(dmg, owner, 8.0)

	# Soft slow for bear_trap if victim has velocity
	if ttype == "bear_trap" and victim is CharacterBody3D:
		var slow: float = float(data.get("slow", 0.5))
		(victim as CharacterBody3D).velocity *= slow

	trap_triggered.emit(ttype, victim)

	# Remove after brief flash
	placed_traps.erase(trap)
	if node and is_instance_valid(node):
		if get_tree():
			get_tree().create_timer(0.35).timeout.connect(func ():
				if is_instance_valid(node):
					node.queue_free()
			)
		else:
			node.queue_free()


func _play_trigger_visual(node: Node3D, trap_type: String) -> void:
	var jaw_l = node.get_node_or_null("JawL")
	var jaw_r = node.get_node_or_null("JawR")
	if jaw_l:
		jaw_l.rotation_degrees = Vector3(0, 0, 0)
		jaw_l.position = Vector3(-0.12, 0.1, 0)
	if jaw_r:
		jaw_r.rotation_degrees = Vector3(0, 0, 0)
		jaw_r.position = Vector3(0.12, 0.1, 0)
	var mi = node.get_node_or_null("TrapMesh")
	if mi and mi is MeshInstance3D and (mi as MeshInstance3D).material_override is StandardMaterial3D:
		var mat: StandardMaterial3D = (mi as MeshInstance3D).material_override.duplicate()
		(mi as MeshInstance3D).material_override = mat
		mat.emission = Color(1.0, 0.15, 0.05)
		mat.emission_energy_multiplier = 4.0
	# Scale punch
	if node.is_inside_tree():
		var tw := node.create_tween()
		tw.tween_property(node, "scale", Vector3(1.25, 0.7, 1.25), 0.08)
		tw.tween_property(node, "scale", Vector3(0.2, 0.2, 0.2), 0.25)
	print("Trap visual snap: ", trap_type)
