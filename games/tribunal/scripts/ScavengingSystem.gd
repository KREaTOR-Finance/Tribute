# ScavengingSystem.gd
# High-stakes looting that feeds the melee/crafting loop
# From The Culling: risk vs reward, limited time, good loot changes fights

extends Node
class_name ScavengingSystem

@export var loot_table: Array[Dictionary] = [
	{"name": "Scrap Metal", "rarity": 0.4, "value": 2},
	{"name": "Wood", "rarity": 0.35, "value": 1},
	{"name": "Bandage", "rarity": 0.15, "value": 10},
	{"name": "Spear Tip", "rarity": 0.08, "value": 25},
	{"name": "Trap Kit", "rarity": 0.02, "value": 40}
]

var spawned_loot: Array = []

signal loot_collected(item: Dictionary, player: Node)

func spawn_loot_in_arena(arena: Node3D, count: int = 12):
	print("Spawning high-stakes scavenging loot...")
	for i in count:
		var item = loot_table[randi() % loot_table.size()]
		var pos = Vector3(randf_range(-8, 8), 0.5, randf_range(-8, 8))
		
		var loot_node = Node3D.new()
		loot_node.name = item["name"]
		loot_node.position = pos
		
		# Simple visual (replace with real mesh later)
		var mesh = MeshInstance3D.new()
		mesh.mesh = BoxMesh.new()
		mesh.mesh.size = Vector3(0.4, 0.4, 0.4)
		loot_node.add_child(mesh)
		
		var area = Area3D.new()
		var shape = CollisionShape3D.new()
		shape.shape = BoxShape3D.new()
		area.add_child(shape)
		loot_node.add_child(area)
		
		area.body_entered.connect(_on_loot_picked.bind(loot_node, item))
		
		arena.add_child(loot_node)
		spawned_loot.append(loot_node)

func _on_loot_picked(body: Node, loot_node: Node3D, item: Dictionary):
	if body is PlayerController:
		loot_collected.emit(item, body)
		print(body.name, " scavenged ", item["name"])
		loot_node.queue_free()
		spawned_loot.erase(loot_node)

# TODO: Add risk (noise when looting, limited time windows, contested loot)
