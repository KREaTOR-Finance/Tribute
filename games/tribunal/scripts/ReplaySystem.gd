extends Node
class_name ReplaySystem
## Tribunal gameplay replay — records fighter transforms during FIGHT, plays ghost path after.

signal playback_started
signal playback_finished

@export var sample_hz: float = 20.0
@export var max_seconds: float = 180.0

var recording: bool = false
var playing: bool = false
var _acc: float = 0.0
var _sample_dt: float = 0.05
var _t: float = 0.0
var _tracks: Dictionary = {}  # id -> { "name": String, "frames": Array of {t,pos,yaw,state,chain} }
var _subjects: Array = []  # Node3D fighters
var _ghosts: Dictionary = {}
var _play_t: float = 0.0
var _play_end: float = 0.0
var _camera: Camera3D = null


func _ready() -> void:
	_sample_dt = 1.0 / maxf(sample_hz, 5.0)
	set_process(true)
	set_physics_process(false)


func bind_subjects(fighters: Array, camera: Camera3D = null) -> void:
	_subjects = []
	for f in fighters:
		if f is Node3D:
			_subjects.append(f)
	_camera = camera


func start_recording() -> void:
	_tracks.clear()
	_t = 0.0
	_acc = 0.0
	recording = true
	playing = false
	_clear_ghosts()
	for s in _subjects:
		if s == null or not is_instance_valid(s):
			continue
		_tracks[s.get_instance_id()] = {"name": s.name, "frames": []}
	print("ReplaySystem: recording")


func stop_recording() -> void:
	recording = false
	print("ReplaySystem: stopped · tracks=", _tracks.size(), " duration=", snappedf(_t, 0.01))


func has_replay() -> bool:
	for k in _tracks:
		if (_tracks[k]["frames"] as Array).size() > 2:
			return true
	return false


func start_playback(parent: Node3D) -> bool:
	if not has_replay():
		return false
	stop_recording()
	playing = true
	_play_t = 0.0
	_play_end = 0.0
	_clear_ghosts()
	for id in _tracks:
		var tr: Dictionary = _tracks[id]
		var frames: Array = tr["frames"]
		if frames.is_empty():
			continue
		_play_end = maxf(_play_end, float(frames[frames.size() - 1]["t"]))
		var ghost := _make_ghost(str(tr.get("name", "Ghost")))
		parent.add_child(ghost)
		_ghosts[id] = {"node": ghost, "frames": frames, "i": 0}
	# Hide live fighters during replay
	for s in _subjects:
		if is_instance_valid(s):
			s.visible = false
			s.set_physics_process(false)
	playback_started.emit()
	print("ReplaySystem: playback ", snappedf(_play_end, 0.01), "s")
	return true


func stop_playback() -> void:
	if not playing:
		return
	playing = false
	_clear_ghosts()
	for s in _subjects:
		if is_instance_valid(s):
			# Keep hidden if dead
			if "melee_state" in s and int(s.melee_state) == 9:
				s.visible = false
			else:
				s.visible = true
	playback_finished.emit()


func _process(delta: float) -> void:
	if recording:
		_t += delta
		if _t > max_seconds:
			stop_recording()
			return
		_acc += delta
		if _acc >= _sample_dt:
			_acc = 0.0
			_sample()
	elif playing:
		_play_t += delta
		_apply_playback()
		if _play_t >= _play_end + 0.35:
			stop_playback()


func _sample() -> void:
	for s in _subjects:
		if s == null or not is_instance_valid(s):
			continue
		var id: int = s.get_instance_id()
		if not _tracks.has(id):
			_tracks[id] = {"name": s.name, "frames": []}
		var st: int = 0
		var chain: int = 0
		if "melee_state" in s:
			st = int(s.melee_state)
		if "judgement_chain" in s:
			chain = int(s.judgement_chain)
		var frames: Array = _tracks[id]["frames"]
		frames.append({
			"t": _t,
			"pos": s.global_position,
			"yaw": s.rotation.y,
			"state": st,
			"chain": chain,
		})


func _apply_playback() -> void:
	var follow_pos := Vector3.ZERO
	var n_follow := 0
	for id in _ghosts:
		var g: Dictionary = _ghosts[id]
		var node: Node3D = g["node"]
		var frames: Array = g["frames"]
		if frames.is_empty() or not is_instance_valid(node):
			continue
		var a: Dictionary = frames[0]
		var b: Dictionary = frames[frames.size() - 1]
		for i in range(frames.size() - 1):
			if float(frames[i]["t"]) <= _play_t and float(frames[i + 1]["t"]) >= _play_t:
				a = frames[i]
				b = frames[i + 1]
				break
			if float(frames[i]["t"]) > _play_t:
				a = frames[maxi(0, i - 1)]
				b = frames[i]
				break
		var t0 := float(a["t"])
		var t1 := float(b["t"])
		var u := 0.0 if t1 <= t0 else clampf((_play_t - t0) / (t1 - t0), 0.0, 1.0)
		var pa: Vector3 = a["pos"]
		var pb: Vector3 = b["pos"]
		node.global_position = pa.lerp(pb, u)
		node.rotation.y = lerp_angle(float(a["yaw"]), float(b["yaw"]), u)
		# Chain glow on ghost
		var ch := int(b.get("chain", 0))
		_tint_ghost(node, ch)
		follow_pos += node.global_position
		n_follow += 1
	if _camera and n_follow > 0 and _camera is FollowCamera:
		# Soft follow mid-point of ghosts
		var mid := follow_pos / float(n_follow)
		_camera.global_position = _camera.global_position.lerp(mid + Vector3(0, 6, 8), clampf(0.08, 0, 1))
		_camera.look_at(mid + Vector3(0, 1.2, 0), Vector3.UP)


func _make_ghost(nm: String) -> Node3D:
	var root := Node3D.new()
	root.name = "ReplayGhost_%s" % nm
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.35
	cap.height = 1.1
	body.mesh = cap
	body.position.y = 1.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.75, 1.0, 0.45)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.6, 1.0)
	mat.emission_energy_multiplier = 1.2
	body.material_override = mat
	root.add_child(body)
	var head := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 0.2
	head.mesh = sph
	head.position.y = 1.75
	head.material_override = mat
	root.add_child(head)
	return root


func _tint_ghost(node: Node3D, chain: int) -> void:
	var col := Color(0.55, 0.75, 1.0, 0.45)
	if chain >= 3:
		col = Color(1.0, 0.82, 0.25, 0.55)
	elif chain >= 1:
		col = Color(0.85, 0.55, 1.0, 0.5)
	for c in node.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).material_override is StandardMaterial3D:
			var m: StandardMaterial3D = (c as MeshInstance3D).material_override
			m.albedo_color = col
			m.emission = col


func _clear_ghosts() -> void:
	for id in _ghosts:
		var n = _ghosts[id].get("node")
		if n and is_instance_valid(n):
			n.queue_free()
	_ghosts.clear()
