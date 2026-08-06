extends Node
class_name CharacterAnimator
## Drives SkinRig multipart poses for walk + Culling melee actions.
## Attach under a player/hunter that owns a SkinRig child.

const Catalog = preload("res://scripts/SkinCatalog.gd")

enum Pose {
	IDLE,
	WALK,
	SPRINT,
	LIGHT_SWING,
	HEAVY_WINDUP,
	HEAVY_SWING,
	BLOCK,
	SHOVE,
	HIT,
	DEAD,
}

@export var walk_bob_speed: float = 10.0
@export var walk_bob_amount: float = 0.04
@export var arm_swing: float = 0.55
@export var leg_swing: float = 0.7

var host: Node3D = null
var rig: Node3D = null
var pose: Pose = Pose.IDLE
var pose_time: float = 0.0
var move_blend: float = 0.0  # 0 idle → 1 full run
var sprinting: bool = false

# Cached parts
var _hip: Node3D
var _torso: Node3D
var _head: Node3D
var _arm_l: Node3D
var _arm_r: Node3D
var _leg_l: Node3D
var _leg_r: Node3D
var _hand_ref: Node3D  # external Hand on player

var _base_hand_pos: Vector3 = Vector3(-0.42, 1.05, 0.25)
var _base_hand_rot: Vector3 = Vector3(0, 30, 0)
var _hit_flash: float = 0.0


func bind(player: Node3D) -> void:
	host = player
	_refresh_rig()
	_hand_ref = player.get_node_or_null("Hand") as Node3D
	if _hand_ref:
		_base_hand_pos = _hand_ref.position
		_base_hand_rot = _hand_ref.rotation_degrees


func _refresh_rig() -> void:
	if host == null:
		return
	rig = host.get_node_or_null("SkinRig") as Node3D
	if rig == null:
		_hip = null
		return
	_hip = rig.get_node_or_null("Hip") as Node3D
	_torso = rig.get_node_or_null("Hip/Torso") as Node3D
	_head = rig.get_node_or_null("Hip/Torso/Head") as Node3D
	_arm_l = rig.get_node_or_null("Hip/Torso/ArmL") as Node3D
	_arm_r = rig.get_node_or_null("Hip/Torso/ArmR") as Node3D
	_leg_l = rig.get_node_or_null("Hip/LegL") as Node3D
	_leg_r = rig.get_node_or_null("Hip/LegR") as Node3D


func set_pose(p: Pose, duration: float = 0.0) -> void:
	pose = p
	pose_time = duration
	if p == Pose.HIT:
		_hit_flash = 0.14


func set_move_blend(horizontal_speed: float, max_speed: float, is_sprint: bool) -> void:
	sprinting = is_sprint
	var target := 0.0
	if max_speed > 0.01:
		target = clampf(horizontal_speed / max_speed, 0.0, 1.2)
	move_blend = lerpf(move_blend, target, 0.25)


func _process(delta: float) -> void:
	if host == null:
		return
	if rig == null or not is_instance_valid(rig):
		_refresh_rig()
	if rig == null:
		return
	if pose_time > 0.0:
		pose_time = max(0.0, pose_time - delta)
	if _hit_flash > 0.0:
		_hit_flash = max(0.0, _hit_flash - delta)
	_apply_pose(delta)


func _apply_pose(delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	var bob := 0.0
	var leg_phase := 0.0
	var arm_phase := 0.0

	# Locomotion under combat overlays
	var loco := move_blend
	if pose in [Pose.LIGHT_SWING, Pose.HEAVY_WINDUP, Pose.HEAVY_SWING, Pose.BLOCK, Pose.SHOVE, Pose.HIT, Pose.DEAD]:
		loco *= 0.35

	if loco > 0.05:
		var rate := walk_bob_speed * (1.35 if sprinting else 1.0)
		bob = sin(t * rate) * walk_bob_amount * loco
		leg_phase = sin(t * rate) * leg_swing * loco
		arm_phase = sin(t * rate + PI) * arm_swing * loco

	# Defaults (idle rest)
	var hip_y := 0.0 + bob
	var hip_rot := Vector3.ZERO
	var torso_rot := Vector3.ZERO
	var head_rot := Vector3.ZERO
	var arm_l_rot := Vector3(arm_phase * 35.0, 0, 8)
	var arm_r_rot := Vector3(-arm_phase * 35.0, 0, -8)
	var leg_l_rot := Vector3(leg_phase * 40.0, 0, 0)
	var leg_r_rot := Vector3(-leg_phase * 40.0, 0, 0)
	var hand_pos := _base_hand_pos
	var hand_rot := _base_hand_rot

	match pose:
		Pose.IDLE:
			torso_rot = Vector3(2, 0, 0)
			arm_l_rot = Vector3(8, 0, 12)
			arm_r_rot = Vector3(8, 0, -12)
		Pose.WALK, Pose.SPRINT:
			torso_rot = Vector3(6 if sprinting else 3, 0, 0)
			if sprinting:
				arm_l_rot.x *= 1.25
				arm_r_rot.x *= 1.25
				leg_l_rot.x *= 1.2
				leg_r_rot.x *= 1.2
		Pose.LIGHT_SWING:
			# Fast jab — right arm forward slash
			var k := _pose_k(0.10)
			torso_rot = Vector3(5, lerpf(25, -35, k), 0)
			arm_r_rot = Vector3(lerpf(-20, 70, k), lerpf(10, -50, k), lerpf(-10, 20, k))
			arm_l_rot = Vector3(-15, 20, 25)
			hand_pos = _base_hand_pos + Vector3(lerpf(0.1, -0.15, k), 0.05, lerpf(0.05, -0.45, k))
			hand_rot = Vector3(lerpf(0, 70, k), lerpf(30, -40, k), lerpf(0, 25, k))
			hip_rot = Vector3(0, lerpf(12, -18, k), 0)
		Pose.HEAVY_WINDUP:
			# Readable commit crouch + raise
			var k := 1.0 - clampf(pose_time / max(0.01, 0.55), 0.0, 1.0)
			hip_y = -0.08 - k * 0.06
			torso_rot = Vector3(lerpf(5, 18, k), 15, 0)
			arm_r_rot = Vector3(lerpf(10, -100, k), lerpf(0, 40, k), -20)
			arm_l_rot = Vector3(-30, 30, 30)
			leg_l_rot = Vector3(15, 0, 0)
			leg_r_rot = Vector3(-5, 0, 0)
			hand_pos = _base_hand_pos + Vector3(0.05, lerpf(0.0, 0.35, k), 0.1)
			hand_rot = Vector3(lerpf(0, -50, k), 20, -15)
		Pose.HEAVY_SWING:
			var k := _pose_k(0.14)
			hip_y = -0.04
			torso_rot = Vector3(lerpf(18, -10, k), lerpf(15, -50, k), 0)
			arm_r_rot = Vector3(lerpf(-100, 80, k), lerpf(40, -60, k), lerpf(-20, 15, k))
			arm_l_rot = Vector3(-40, 10, 20)
			hand_pos = _base_hand_pos + Vector3(lerpf(0.05, -0.2, k), lerpf(0.35, -0.05, k), lerpf(0.1, -0.55, k))
			hand_rot = Vector3(lerpf(-50, 90, k), lerpf(20, -60, k), 0)
			hip_rot = Vector3(0, lerpf(10, -35, k), 0)
		Pose.BLOCK:
			torso_rot = Vector3(8, 0, 0)
			arm_l_rot = Vector3(-50, 40, 50)
			arm_r_rot = Vector3(-55, -35, -40)
			hand_pos = _base_hand_pos + Vector3(0.15, 0.2, -0.25)
			hand_rot = Vector3(-20, 0, 70)
			hip_y = -0.03
			leg_l_rot = Vector3(8, 0, 0)
			leg_r_rot = Vector3(-4, 0, 0)
		Pose.SHOVE:
			var k := _pose_k(0.18)
			torso_rot = Vector3(lerpf(5, 25, k), 0, 0)
			arm_l_rot = Vector3(lerpf(0, 60, k), 0, 20)
			arm_r_rot = Vector3(lerpf(0, 70, k), 0, -20)
			hand_pos = _base_hand_pos + Vector3(0, 0.1, lerpf(0.0, -0.5, k))
			hip_y = lerpf(0, -0.05, k)
		Pose.HIT:
			var k := clampf(_hit_flash / 0.14, 0.0, 1.0)
			torso_rot = Vector3(-12 * k, 25 * k, 8 * k)
			head_rot = Vector3(-15 * k, -20 * k, 0)
			arm_l_rot = Vector3(20 * k, -15, 20)
			arm_r_rot = Vector3(25 * k, 15, -20)
			hip_rot = Vector3(0, 15 * k, 0)
		Pose.DEAD:
			hip_y = -0.9
			torso_rot = Vector3(70, 0, 25)
			arm_l_rot = Vector3(40, 0, 60)
			arm_r_rot = Vector3(30, 0, -50)
			leg_l_rot = Vector3(20, 0, 10)
			leg_r_rot = Vector3(-10, 0, -15)
		_:
			pass

	_set_local(_hip, Vector3(0, hip_y, 0), hip_rot)
	_set_local(_torso, Vector3.ZERO, torso_rot)
	_set_local(_head, Vector3(0, 0.42, 0), head_rot)
	_set_local(_arm_l, Vector3(-0.38, 0.28, 0), arm_l_rot)
	_set_local(_arm_r, Vector3(0.38, 0.28, 0), arm_r_rot)
	_set_local(_leg_l, Vector3(-0.14, 0, 0), leg_l_rot)
	_set_local(_leg_r, Vector3(0.14, 0, 0), leg_r_rot)

	if _hand_ref and is_instance_valid(_hand_ref):
		_hand_ref.position = hand_pos
		_hand_ref.rotation_degrees = hand_rot


func _pose_k(default_dur: float) -> float:
	# 0 at start of pose, 1 at end
	if pose_time <= 0.0:
		return 1.0
	var total: float = maxf(default_dur, pose_time + 0.001)
	# When set_pose is called with duration, pose_time counts down
	return 1.0 - clampf(pose_time / total, 0.0, 1.0)


func _set_local(n: Node3D, pos: Vector3, rot_deg: Vector3) -> void:
	if n == null or not is_instance_valid(n):
		return
	# Keep authored rest offsets for limbs that store them in metadata
	var rest := pos
	if n.has_meta("rest_pos"):
		var meta_val = n.get_meta("rest_pos")
		if meta_val is Vector3:
			rest = meta_val as Vector3
		n.position = Vector3(rest.x, rest.y, rest.z)
		if n == _hip:
			n.position.y = rest.y + pos.y
	else:
		n.position = pos
	n.rotation_degrees = rot_deg
