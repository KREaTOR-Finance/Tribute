extends Node
class_name CraftingSystem
## Tribunal Gauntlet mode — Culling-style materials → craft weapons, armor, traps.
## Materials: wood, scrap, cloth, bone. Armor reduces incoming damage.

signal materials_changed(player: Node, bag: Dictionary)
signal crafted(player: Node, recipe_id: String, result: Dictionary)
signal armor_changed(player: Node, armor: Dictionary)

const MATS := ["wood", "scrap", "cloth", "bone"]

## recipe_id -> { name, cost: {mat: n}, result: {...} }
var recipes: Dictionary = {
	"bandage": {
		"name": "Bandage",
		"cost": {"cloth": 1},
		"result": {"type": "heal", "amount": 40},
	},
	"trap_kit": {
		"name": "Trap Kit",
		"cost": {"wood": 2, "scrap": 1},
		"result": {"type": "trap_kit", "amount": 1},
	},
	"leather_vest": {
		"name": "Leather Vest",
		"cost": {"cloth": 2, "scrap": 1},
		"result": {"type": "armor", "slot": "chest", "tier": 1, "dr": 0.12},
	},
	"iron_plate": {
		"name": "Iron Plate",
		"cost": {"scrap": 3, "wood": 1},
		"result": {"type": "armor", "slot": "chest", "tier": 2, "dr": 0.22},
	},
	"bone_helm": {
		"name": "Bone Helm",
		"cost": {"bone": 2, "cloth": 1},
		"result": {"type": "armor", "slot": "head", "tier": 1, "dr": 0.08},
	},
	"craft_axe": {
		"name": "Crafted Axe",
		"cost": {"wood": 2, "scrap": 2},
		"result": {"type": "weapon", "weapon": 2},  # WeaponType.AXE
	},
	"craft_dagger": {
		"name": "Crafted Dagger",
		"cost": {"scrap": 1, "bone": 1},
		"result": {"type": "weapon", "weapon": 3},
	},
	"craft_sword": {
		"name": "Crafted Sword",
		"cost": {"scrap": 2, "wood": 1, "bone": 1},
		"result": {"type": "weapon", "weapon": 1},
	},
}

# instance_id -> { wood, scrap, cloth, bone }
var _bags: Dictionary = {}
# instance_id -> { head: {tier,dr,name}, chest: {...} }
var _armor: Dictionary = {}
# instance_id near craft station
var _near_station: Dictionary = {}


func ensure_bag(player: Node) -> Dictionary:
	var id := player.get_instance_id()
	if not _bags.has(id):
		_bags[id] = {"wood": 0, "scrap": 0, "cloth": 0, "bone": 0}
	if not _armor.has(id):
		_armor[id] = {}
	return _bags[id]


func get_bag(player: Node) -> Dictionary:
	return ensure_bag(player).duplicate()


func get_armor(player: Node) -> Dictionary:
	ensure_bag(player)
	return (_armor[player.get_instance_id()] as Dictionary).duplicate()


func get_damage_reduction(player: Node) -> float:
	ensure_bag(player)
	var arm: Dictionary = _armor[player.get_instance_id()]
	var dr := 0.0
	for slot in arm:
		var piece: Dictionary = arm[slot]
		dr += float(piece.get("dr", 0.0))
	return clampf(dr, 0.0, 0.55)


func add_material(player: Node, mat: String, amount: int = 1) -> void:
	if player == null or amount <= 0:
		return
	if not MATS.has(mat):
		return
	var bag := ensure_bag(player)
	bag[mat] = int(bag.get(mat, 0)) + amount
	_bags[player.get_instance_id()] = bag
	materials_changed.emit(player, bag.duplicate())
	print(player.name, " +", amount, " ", mat, " → ", bag)


func can_craft(player: Node, recipe_id: String) -> bool:
	if not recipes.has(recipe_id):
		return false
	var bag := ensure_bag(player)
	var cost: Dictionary = recipes[recipe_id]["cost"]
	for m in cost:
		if int(bag.get(m, 0)) < int(cost[m]):
			return false
	return true


func list_craftable(player: Node) -> Array:
	var out: Array = []
	for id in recipes:
		if can_craft(player, str(id)):
			out.append(str(id))
	return out


func craft(player: Node, recipe_id: String) -> bool:
	if player == null or not can_craft(player, recipe_id):
		return false
	var rec: Dictionary = recipes[recipe_id]
	var bag := ensure_bag(player)
	var cost: Dictionary = rec["cost"]
	for m in cost:
		bag[m] = int(bag[m]) - int(cost[m])
	_bags[player.get_instance_id()] = bag
	materials_changed.emit(player, bag.duplicate())

	var result: Dictionary = rec["result"]
	_apply_result(player, recipe_id, result)
	crafted.emit(player, recipe_id, result)
	print(player.name, " crafted ", rec.get("name", recipe_id))
	return true


## Craft first available recipe (for simple T key at station).
func craft_first_available(player: Node) -> bool:
	var list := list_craftable(player)
	if list.is_empty():
		print(player.name, " cannot craft — need materials at station")
		return false
	return craft(player, str(list[0]))


func set_near_station(player: Node, near: bool) -> void:
	if player == null:
		return
	var id := player.get_instance_id()
	if near:
		_near_station[id] = true
	else:
		_near_station.erase(id)


func is_near_station(player: Node) -> bool:
	return player != null and _near_station.has(player.get_instance_id())


func try_craft_at_station(player: Node) -> bool:
	if not is_near_station(player):
		print(player.name, " — approach a Craft Bench (T)")
		return false
	return craft_first_available(player)


func _apply_result(player: Node, recipe_id: String, result: Dictionary) -> void:
	var t: String = str(result.get("type", ""))
	match t:
		"heal":
			var amt := int(result.get("amount", 20))
			if player.has_method("heal_partial"):
				player.heal_partial(amt)
		"trap_kit":
			var parent := get_parent()
			var traps = parent.get_node_or_null("TrapSystem") if parent else null
			if traps and traps.has_method("add_trap_kit"):
				traps.add_trap_kit(player, int(result.get("amount", 1)))
		"armor":
			var slot := str(result.get("slot", "chest"))
			var piece := {
				"name": recipes[recipe_id]["name"],
				"tier": int(result.get("tier", 1)),
				"dr": float(result.get("dr", 0.1)),
			}
			var id := player.get_instance_id()
			ensure_bag(player)
			var arm: Dictionary = _armor[id]
			# Only equip if better or equal tier replace
			var prev: Dictionary = arm.get(slot, {})
			if int(prev.get("tier", 0)) <= int(piece["tier"]):
				arm[slot] = piece
				_armor[id] = arm
				armor_changed.emit(player, arm.duplicate())
				_refresh_armor_visual(player)
		"weapon":
			if player is PlayerController:
				var w := Weapon.new()
				w.weapon_type = int(result.get("weapon", 1))
				w._apply_profile()
				player.equip_weapon(w)
				if player.has_method("_apply_weapon_skin_to_hand"):
					var SkinCat = load("res://scripts/SkinCatalog.gd")
					player.weapon_skin_id = SkinCat.default_weapon_skin(int(w.weapon_type) + 1)
					player._apply_weapon_skin_to_hand()


func _refresh_armor_visual(player: Node) -> void:
	if player == null or not (player is Node3D):
		return
	var rig = player.get_node_or_null("SkinRig")
	if rig == null:
		return
	# Visual plate on torso if chest armor
	var id := player.get_instance_id()
	var arm: Dictionary = _armor.get(id, {})
	var old = rig.get_node_or_null("ArmorPlate")
	if old:
		old.queue_free()
	if arm.has("chest"):
		var plate := MeshInstance3D.new()
		plate.name = "ArmorPlate"
		var box := BoxMesh.new()
		box.size = Vector3(0.52, 0.42, 0.28)
		plate.mesh = box
		var mat := StandardMaterial3D.new()
		var tier := int(arm["chest"].get("tier", 1))
		if tier >= 2:
			mat.albedo_color = Color(0.55, 0.58, 0.62)
			mat.metallic = 0.85
			mat.roughness = 0.3
		else:
			mat.albedo_color = Color(0.45, 0.32, 0.22)
			mat.roughness = 0.75
		plate.material_override = mat
		# Parent under Hip/Torso if present
		var torso = rig.get_node_or_null("Hip/Torso")
		if torso:
			plate.position = Vector3(0, 0.05, 0.12)
			torso.add_child(plate)
		else:
			plate.position = Vector3(0, 1.15, 0.15)
			rig.add_child(plate)
