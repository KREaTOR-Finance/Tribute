extends Node
class_name CharacterSkin
## Applies a SkinCatalog character skin to a PlayerController-like host.

const Catalog = preload("res://scripts/SkinCatalog.gd")

@export var skin_id: String = ""
var rig: Node3D = null


func apply_to_player(player: Node3D, preferred_skin: String = "") -> void:
	if preferred_skin != "":
		skin_id = preferred_skin
	elif skin_id == "":
		var pid := 1
		if "player_id" in player:
			pid = int(player.player_id)
		skin_id = Catalog.default_character_skin(pid)

	# Hide default single mesh if present
	var mi = player.get_node_or_null("MeshInstance3D")
	if mi and mi is MeshInstance3D:
		(mi as MeshInstance3D).visible = false

	# Remove old rig
	var old = player.get_node_or_null("SkinRig")
	if old:
		old.queue_free()

	rig = Catalog.build_character_rig(player, skin_id)
	print("CharacterSkin: applied ", skin_id, " to ", player.name)


func cycle_skin(player: Node3D) -> String:
	var keys: Array = Catalog.character_skins().keys()
	if keys.is_empty():
		return skin_id
	var idx := keys.find(skin_id)
	idx = (idx + 1) % keys.size()
	apply_to_player(player, str(keys[idx]))
	return skin_id
