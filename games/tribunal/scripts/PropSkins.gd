extends RefCounted
class_name PropSkins
## Death marks + loot caches + arena prop re-skins.
## First-class prop identity for Tribunal (Culling scavenge / fallen marks).

const Catalog = preload("res://scripts/SkinCatalog.gd")
const ObjLoader = preload("res://scripts/ObjMeshLoader.gd")


## Spawn a gold scavenge cache. If auto_pickup, heals players on body_entered.
static func spawn_loot(parent: Node3D, pos: Vector3, auto_pickup: bool = true, heal_amount: int = 15) -> Area3D:
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
	mi.material_override = Catalog.make_prop_material(Catalog.PSKIN_LOOT_GOLD)
	mi.name = "LootMesh"
	loot.add_child(mi)

	# Small accent gem
	var gem := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.12
	gem.mesh = sph
	gem.position = Vector3(0, 0.35, 0)
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.2, 0.9, 1.0)
	gm.emission_enabled = true
	gm.emission = Color(0.2, 0.8, 1.0)
	gm.emission_energy_multiplier = 2.0
	gem.material_override = gm
	loot.add_child(gem)

	loot.position = pos
	parent.add_child(loot)

	if auto_pickup:
		loot.body_entered.connect(func(b: Node):
			if not is_instance_valid(loot):
				return
			if b.is_in_group("players") or b is CharacterBody3D:
				if b.has_method("heal_partial"):
					b.heal_partial(heal_amount)
				elif "health" in b and "max_health" in b:
					b.health = mini(int(b.max_health), int(b.health) + heal_amount)
					if b.has_signal("health_changed"):
						b.health_changed.emit(b.health)
				print("PropSkins: loot claimed by ", b.name)
				loot.queue_free()
		)
	return loot


static func spawn_death_mark(parent: Node3D, pos: Vector3, team_color: Color = Color(0.8, 0.1, 0.1)) -> Node3D:
	var root := Node3D.new()
	root.name = "DeathMark"
	root.add_to_group("death_marks")
	root.position = pos

	var stain := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.7
	cyl.bottom_radius = 0.9
	cyl.height = 0.06
	stain.mesh = cyl
	stain.position.y = 0.03
	var mat := Catalog.make_prop_material(Catalog.PSKIN_DEATH_MARK)
	mat.albedo_color = team_color.darkened(0.35)
	mat.emission = team_color
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.5
	stain.material_override = mat
	root.add_child(stain)

	# Fallen weapon token
	var blade := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.08, 0.04, 0.7)
	blade.mesh = box
	blade.position = Vector3(0.2, 0.12, 0.1)
	blade.rotation_degrees = Vector3(0, 35, 70)
	blade.material_override = Catalog.make_weapon_blade_material(Catalog.WSKIN_BLOODSTEEL)
	root.add_child(blade)

	parent.add_child(root)
	# Fade out after a while but leave a short memorial (only if in tree)
	if root.is_inside_tree() and root.get_tree():
		var tw := root.create_tween()
		tw.tween_interval(8.0)
		tw.tween_property(root, "scale", Vector3(0.1, 0.1, 0.1), 1.2)
		tw.tween_callback(root.queue_free)
	return root


static func reskin_static_prop(node: Node3D, prop_skin_id: String) -> void:
	var mi = node.get_node_or_null("MeshInstance3D")
	if mi and mi is MeshInstance3D:
		(mi as MeshInstance3D).material_override = Catalog.make_prop_material(prop_skin_id)
