# FollowCamera.gd
# Third-person follow + combat framing punch-in on swings (Culling readable melee).
# Attach to a Camera3D. Call set_target(player) from MeleeTestScene.

extends Camera3D
class_name FollowCamera

@export var follow_distance: float = 7.0
@export var follow_height: float = 4.5
@export var follow_speed: float = 9.0
@export var look_at_offset: Vector3 = Vector3(0, 1.35, 0)
@export var combat_distance_mul: float = 0.82
@export var combat_height_mul: float = 0.9
@export var combat_side_bias: float = 0.65
@export var start_in_follow: bool = true

var target: Node3D = null
var is_follow_mode: bool = false

# Combat framing state
var _frame_blend: float = 0.0  # 0 idle → 1 full swing frame
var _frame_target: float = 0.0
var _frame_decay: float = 2.8
var _look_ahead: Vector3 = Vector3.ZERO
var _look_ahead_target: Vector3 = Vector3.ZERO
var _fov_base: float = 75.0
var _fov_punch: float = 0.0


func _ready():
	is_follow_mode = start_in_follow
	_fov_base = fov
	if is_follow_mode:
		print("FollowCamera: FOLLOW MODE (melee framing ready)")


func _process(delta):
	# Blend combat frame in/out
	_frame_blend = move_toward(_frame_blend, _frame_target, delta * (6.0 if _frame_target > _frame_blend else _frame_decay))
	if _frame_target > 0.0:
		_frame_target = max(0.0, _frame_target - delta * _frame_decay)
	_look_ahead = _look_ahead.lerp(_look_ahead_target, clampf(delta * 8.0, 0.0, 1.0))
	_look_ahead_target = _look_ahead_target.lerp(Vector3.ZERO, clampf(delta * 1.8, 0.0, 1.0))
	_fov_punch = move_toward(_fov_punch, 0.0, delta * 18.0)
	fov = _fov_base + _fov_punch * _frame_blend

	if not target or not is_follow_mode:
		return

	var dist := follow_distance * lerpf(1.0, combat_distance_mul, _frame_blend)
	var height := follow_height * lerpf(1.0, combat_height_mul, _frame_blend)

	# Prefer behind player facing; bias slightly toward look-ahead (swing direction)
	var back := Vector3.ZERO
	if target is Node3D:
		back = target.global_transform.basis.z  # Godot -Z is forward, so +Z is back
		# If character faces -Z forward, behind is +basis.z
	var side := target.global_transform.basis.x * combat_side_bias * _frame_blend
	var offset := back * dist + Vector3(0, height, 0) + side * 0.5
	# Pull slightly toward the attack direction so the exchange stays framed
	offset += _look_ahead * (1.2 * _frame_blend)

	var desired_pos = target.global_position + offset
	global_position = global_position.lerp(desired_pos, clampf(follow_speed * delta, 0.0, 1.0))

	var look_pt = target.global_position + look_at_offset + _look_ahead * (0.85 * _frame_blend)
	look_at(look_pt, Vector3.UP)


func set_target(new_target: Node3D):
	target = new_target
	print("FollowCamera: Now targeting ", new_target.name if new_target else "none")
	if is_follow_mode and target:
		# Snap near target so first frame is usable
		var back = target.global_transform.basis.z
		global_position = target.global_position + back * follow_distance + Vector3(0, follow_height, 0)


## Call on light/heavy/shove start — punch-in framing.
func frame_swing(heavy: bool = false, facing: Vector3 = Vector3.ZERO) -> void:
	_frame_target = 1.0 if heavy else 0.72
	_frame_decay = 1.6 if heavy else 2.6
	_fov_punch = -4.5 if heavy else -2.5
	if facing.length_squared() > 0.01:
		_look_ahead_target = facing.normalized() * (1.4 if heavy else 0.9)
	elif target:
		_look_ahead_target = -target.global_transform.basis.z * (1.4 if heavy else 0.9)


## Slight pull on successful hit (exchange focus).
func frame_hit(heavy: bool = false) -> void:
	_frame_target = max(_frame_target, 0.85 if heavy else 0.55)
	_fov_punch = min(_fov_punch, -3.0 if heavy else -1.5)


func toggle_mode():
	is_follow_mode = not is_follow_mode
	if is_follow_mode and target:
		print("FollowCamera: FOLLOW MODE (third-person melee framing)")
	else:
		print("FollowCamera: FIXED OVERVIEW MODE")
		global_position = Vector3(0, 8, 8)
		global_rotation_degrees = Vector3(-45, 0, 0)
		_frame_blend = 0.0
		_frame_target = 0.0


func _unhandled_input(event):
	if event.is_action_pressed("ui_focus_next"):  # Tab
		toggle_mode()
