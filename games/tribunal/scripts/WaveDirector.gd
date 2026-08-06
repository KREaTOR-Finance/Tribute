extends Node
class_name WaveDirector
## VS-1 Humanoid Wave Gauntlet — Culling contestant pressure as escalating waves.
## Spec: design/systems/SYS-AI-WAVES.md
## Win: clear all waves. Lose: handled by ArenaManager on player elim.

signal wave_started(wave_index: int, count: int)
signal wave_cleared(wave_index: int)
signal all_waves_cleared
signal reinforce_spawned(count: int)

const HunterSpawnerScript = preload("res://scripts/HunterSpawner.gd")

## Interpreted Culling solo parameters (SYS-AI-WAVES)
@export var wave_counts: Array = [2, 3, 4, 5]
@export var max_alive: int = 6
@export var wave_delay: float = 3.0
@export var reinforce_seconds: float = 45.0
@export var early_refill_after: float = 12.0
@export var spawn_when_alive_le: int = 0
@export var auto_start: bool = false

var player_target: Node3D = null
var _spawner: Node = null
var _wave_i: int = 0  # next wave index to spawn (0-based)
var _active: bool = false
var _between_waves: bool = false
var _wave_time: float = 0.0
var _match_time: float = 0.0
var _completed: bool = false
var _waiting_delay: float = 0.0


func configure(spawner: Node, target: Node3D) -> void:
	_spawner = spawner
	player_target = target
	if _spawner and _spawner.has_method("set_player_target") and target:
		_spawner.set_player_target(target)


func start() -> void:
	if _completed:
		return
	_active = true
	_between_waves = false
	_wave_i = 0
	_wave_time = 0.0
	_match_time = 0.0
	_waiting_delay = 0.0
	_spawn_current_wave()
	print("WaveDirector: VS-1 start schedule=", wave_counts)


func stop() -> void:
	_active = false


func is_complete() -> bool:
	return _completed


func current_wave_display() -> int:
	# 1-based for UI; if between waves show last started
	return mini(_wave_i, wave_counts.size())


func total_waves() -> int:
	return wave_counts.size()


func _process(delta: float) -> void:
	if not _active or _completed:
		return
	_match_time += delta
	_wave_time += delta

	if _waiting_delay > 0.0:
		_waiting_delay -= delta
		if _waiting_delay <= 0.0:
			_between_waves = false
			_spawn_current_wave()
		return

	var alive := _alive()
	# Clear → advance after delay
	if alive <= spawn_when_alive_le and not _between_waves:
		wave_cleared.emit(maxi(0, _wave_i - 1))
		print("WaveDirector: wave ", _wave_i, " cleared")
		if _wave_i >= wave_counts.size():
			_win()
			return
		_between_waves = true
		_waiting_delay = wave_delay
		return

	# Timed reinforce if camping (does not advance wave index permanently beyond schedule)
	if alive > 0 and _wave_time >= reinforce_seconds and _wave_i <= wave_counts.size():
		_wave_time = 0.0
		var room := maxi(0, max_alive - alive)
		var n := mini(2, room)
		if n > 0:
			_spawn_extra(n)
			reinforce_spawned.emit(n)
			print("WaveDirector: reinforce +", n)

	# Early refill if wiped quickly after a wave started
	if alive <= 0 and _wave_time >= early_refill_after and _wave_i < wave_counts.size():
		# handled by clear path; if delay not set yet:
		pass


func _alive() -> int:
	if _spawner and _spawner.has_method("alive_count"):
		return int(_spawner.alive_count())
	return 0


func _spawn_current_wave() -> void:
	if _wave_i >= wave_counts.size():
		_win()
		return
	var count: int = int(wave_counts[_wave_i])
	var alive := _alive()
	count = mini(count, maxi(0, max_alive - alive))
	if count <= 0:
		count = int(wave_counts[_wave_i])
	_do_spawn(count)
	wave_started.emit(_wave_i, count)
	print("WaveDirector: WAVE ", _wave_i + 1, "/", wave_counts.size(), " count=", count)
	_wave_i += 1
	_wave_time = 0.0


func _spawn_extra(count: int) -> void:
	_do_spawn(count)


func _do_spawn(count: int) -> void:
	if _spawner == null:
		return
	if player_target and _spawner.has_method("set_player_target"):
		_spawner.set_player_target(player_target)
	if _spawner.has_method("spawn_wave"):
		_spawner.spawn_wave(count)


func _win() -> void:
	if _completed:
		return
	_completed = true
	_active = false
	all_waves_cleared.emit()
	print("WaveDirector: ALL WAVES CLEARED — victory")
