# CameraShake.gd
# Reusable screenshake helper for juicy melee feedback.
# Attach as child of the Camera3D in the player or arena.
# Call add_trauma(0.4) on hits.

extends Node
class_name CameraShake

@export var decay_rate: float = 0.8
@export var max_offset: float = 0.25
@export var max_roll: float = 0.1

var trauma: float = 0.0
var trauma_power: int = 2
var camera: Camera3D

func _ready():
	if get_parent() is Camera3D:
		camera = get_parent()
	else:
		# Try to find camera in siblings/parent
		var parent = get_parent()
		if parent and parent.has_node("Camera3D"):
			camera = parent.get_node("Camera3D")

func add_trauma(amount: float):
	trauma = min(trauma + amount, 1.0)

func _process(delta: float):
	if not camera or trauma <= 0.0:
		if camera:
			camera.h_offset = 0.0
			camera.v_offset = 0.0
			camera.rotation.z = 0.0
		return

	trauma = max(trauma - decay_rate * delta, 0.0)

	var amount = pow(trauma, trauma_power)
	var offset_x = randf_range(-max_offset, max_offset) * amount
	var offset_y = randf_range(-max_offset, max_offset) * amount
	var roll = randf_range(-max_roll, max_roll) * amount

	camera.h_offset = offset_x
	camera.v_offset = offset_y
	camera.rotation.z = roll
