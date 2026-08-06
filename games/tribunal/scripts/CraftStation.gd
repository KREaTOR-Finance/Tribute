extends Area3D
class_name CraftStation
## World craft bench — stand in volume, press T / craft action.

signal player_entered(player: Node)
signal player_exited(player: Node)

@export var station_name: String = "Craft Bench"


func _ready() -> void:
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	add_to_group("craft_stations")


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("players"):
		return
	var craft := _find_crafting()
	if craft and craft.has_method("set_near_station"):
		craft.set_near_station(body, true)
	player_entered.emit(body)
	print(body.name, " at ", station_name, " — T to craft")


func _on_body_exited(body: Node) -> void:
	if not body.is_in_group("players"):
		return
	var craft := _find_crafting()
	if craft and craft.has_method("set_near_station"):
		craft.set_near_station(body, false)
	player_exited.emit(body)


func _find_crafting() -> Node:
	var p := get_parent()
	if p:
		return p.get_node_or_null("CraftingSystem")
	return null
