# TrapSystem.gd
# Traps that completely change fights — core The Culling fantasy
# Bear trap, spike trap, tripwire, etc.

extends Node
class_name TrapSystem

@export var trap_types: Dictionary = {
	"bear_trap": {"damage": 35, "slow": 0.5, "duration": 4.0},
	"spike_trap": {"damage": 55, "bleed": true},
	"tripwire": {"damage": 15, "stun": 1.5}
}

var placed_traps: Array = []

signal trap_triggered(trap_type: String, victim: Node)

func place_trap(player: PlayerController, trap_type: String, position: Vector3):
	if not trap_types.has(trap_type):
		return
	
	var trap = {
		"type": trap_type,
		"position": position,
		"owner": player,
		"armed": true
	}
	
	placed_traps.append(trap)
	print(player.name, " placed ", trap_type, " at ", position)
	
	# TODO: spawn actual 3D trap model + Area3D trigger

func check_traps_for_player(player: PlayerController):
	for trap in placed_traps:
		if not trap["armed"]:
			continue
		var dist = (player.global_position - trap["position"]).length()
		if dist < 1.2:
			trigger_trap(trap, player)

func trigger_trap(trap: Dictionary, victim: PlayerController):
	trap["armed"] = false
	var data = trap_types[trap["type"]]
	
	print("TRAP TRIGGERED: ", trap["type"], " on ", victim.name, " for ", data["damage"], " damage!")
	
	if victim.has_method("take_damage"):
		victim.take_damage(data["damage"], trap["owner"])
	
	trap_triggered.emit(trap["type"], victim)
	
	# Remove after trigger
	placed_traps.erase(trap)

# TODO: Trap placement UI, arming time, disarming, visual/audio feedback
