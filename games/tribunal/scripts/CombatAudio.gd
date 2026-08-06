extends Node
class_name CombatAudio
## Footfalls + hit/whoosh/block SFX for Tribunal melee.
## Loads WAVs at runtime (no editor import required).

const PATH_LIGHT := "res://assets/audio/impacts/light_hit.wav"
const PATH_HEAVY := "res://assets/audio/impacts/heavy_hit.wav"
const PATH_WHOOSH := "res://assets/audio/impacts/whoosh.wav"
const PATH_BLOCK := "res://assets/audio/impacts/block.wav"
const PATH_STEP := "res://assets/audio/footsteps/step.wav"
const PATH_STEP_RUN := "res://assets/audio/footsteps/step_run.wav"

var _players: Dictionary = {}  # key -> AudioStreamPlayer3D
var host: Node3D = null
var _step_cd: float = 0.0
static var _stream_cache: Dictionary = {}  # path -> AudioStreamWAV


func bind(owner: Node3D) -> void:
	host = owner
	_ensure_player("light", PATH_LIGHT)
	_ensure_player("heavy", PATH_HEAVY)
	_ensure_player("whoosh", PATH_WHOOSH)
	_ensure_player("block", PATH_BLOCK)
	_ensure_player("step", PATH_STEP)
	_ensure_player("step_run", PATH_STEP_RUN)


func _ensure_player(key: String, path: String) -> void:
	if _players.has(key):
		return
	var stream := _load_wav(path)
	if stream == null:
		return
	var p := AudioStreamPlayer3D.new()
	p.name = "Sfx_" + key
	p.stream = stream
	p.max_distance = 28.0
	p.unit_size = 2.0
	p.bus = "Master"
	if host:
		host.add_child(p)
	_players[key] = p


## Parse PCM16 mono WAV without editor import.
static func _load_wav(path: String) -> AudioStreamWAV:
	if _stream_cache.has(path):
		return _stream_cache[path]
	if not FileAccess.file_exists(path):
		return null
	# Prefer ResourceLoader if imported
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is AudioStream:
			_stream_cache[path] = res
			return res
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var data := f.get_buffer(f.get_length())
	f.close()
	if data.size() < 44:
		return null
	# Minimal RIFF/WAVE PCM parser
	if data[0] != 0x52 or data[1] != 0x49:  # "RI"
		return null
	var channels := data[22] | (data[23] << 8)
	var rate := data[24] | (data[25] << 8) | (data[26] << 16) | (data[27] << 24)
	var bits := data[34] | (data[35] << 8)
	# Find "data" chunk
	var i := 12
	var pcm := PackedByteArray()
	while i + 8 < data.size():
		var cid := String.chr(data[i]) + String.chr(data[i + 1]) + String.chr(data[i + 2]) + String.chr(data[i + 3])
		var csize := data[i + 4] | (data[i + 5] << 8) | (data[i + 6] << 16) | (data[i + 7] << 24)
		if cid == "data":
			pcm = data.slice(i + 8, i + 8 + csize)
			break
		i += 8 + csize
		if csize % 2 == 1:
			i += 1
	if pcm.is_empty():
		return null
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = channels > 1
	stream.data = pcm
	_stream_cache[path] = stream
	return stream


func _play(key: String, pitch_var: float = 0.08, vol_db: float = 0.0) -> void:
	if not _players.has(key):
		return
	var p: AudioStreamPlayer3D = _players[key]
	if p == null or not is_instance_valid(p):
		return
	p.pitch_scale = clampf(1.0 + randf_range(-pitch_var, pitch_var), 0.75, 1.35)
	p.volume_db = vol_db
	p.play()


func play_whoosh(heavy: bool = false) -> void:
	_play("whoosh", 0.12, -2.0 if heavy else -6.0)


func play_hit(heavy: bool = false) -> void:
	if heavy:
		_play("heavy", 0.06, 0.0)
	else:
		_play("light", 0.1, -2.0)


func play_block() -> void:
	_play("block", 0.05, -1.0)


func tick_footsteps(delta: float, speed: float, sprinting: bool, on_floor: bool) -> void:
	if not on_floor or speed < 0.8:
		_step_cd = maxf(0.0, _step_cd - delta)
		return
	_step_cd -= delta
	if _step_cd > 0.0:
		return
	var interval := 0.42
	if sprinting:
		interval = 0.28
	elif speed > 4.0:
		interval = 0.34
	_step_cd = interval
	if sprinting:
		_play("step_run", 0.08, -8.0)
	else:
		_play("step", 0.1, -12.0)
