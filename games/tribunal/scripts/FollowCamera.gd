# FollowCamera.gd
# Simple third-person follow camera for better melee feel during testing.
# Attach to a Camera3D. Call set_target(player) from MeleeTestScene.
# Toggle between fixed overview and follow with a key (e.g. C).

extends Camera3D
class_name FollowCamera

@export var follow_distance: float = 8.0
@export var follow_height: float = 5.0
@export var follow_speed: float = 8.0
@export var look_at_offset: Vector3 = Vector3(0, 1.5, 0)

var target: Node3D = null
var is_follow_mode: bool = false

func _ready():
	# Start in fixed mode (current scene setup)
	is_follow_mode = false

func _process(delta):
	if not target or not is_follow_mode:
		return
	
	var desired_pos = target.global_position + Vector3(0, follow_height, follow_distance)
	global_position = global_position.lerp(desired_pos, follow_speed * delta)
	
	look_at(target.global_position + look_at_offset, Vector3.UP)

func set_target(new_target: Node3D):
	target = new_target
	print("FollowCamera: Now targeting ", new_target.name if new_target else "none")

func toggle_mode():
	is_follow_mode = not is_follow_mode
	if is_follow_mode and target:
		print("FollowCamera: FOLLOW MODE (third-person feel for melee)")
	else:
		print("FollowCamera: FIXED OVERVIEW MODE")
		# Reset to original test position when switching back (approximate)
		global_position = Vector3(0, 8, 8)
		global_rotation_degrees = Vector3(-45, 0, 0)  # rough match to original

func _unhandled_input(event):
	if event.is_action_pressed("ui_focus_next"):  # Tab or C if remapped
		toggle_mode()
