extends RefCounted
class_name GamepadBootstrap
## Maps console-style gamepad bindings onto existing Tribunal actions at runtime.
## Device 0 = P1. Deadzones tuned for seamless stick control.

const DEAD := 0.22


static func ensure() -> void:
	_add_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_axis("move_forward", JOY_AXIS_LEFT_Y, -1.0)
	_add_axis("move_backward", JOY_AXIS_LEFT_Y, 1.0)

	_add_btn("light_attack", JOY_BUTTON_X)  # square / X
	_add_btn("heavy_attack", JOY_BUTTON_Y)  # triangle / Y
	_add_btn("block", JOY_BUTTON_LEFT_SHOULDER)
	_add_btn("shove", JOY_BUTTON_RIGHT_SHOULDER)
	_add_btn("dodge", JOY_BUTTON_B)
	_add_btn("interact", JOY_BUTTON_A)
	_add_btn("place_trap", JOY_BUTTON_RIGHT_STICK)
	_add_btn("sprint", JOY_BUTTON_LEFT_STICK)

	# Ensure action names exist for code that uses them
	for a in ["dodge", "interact", "place_trap", "sprint", "look_left", "look_right", "look_up", "look_down"]:
		if not InputMap.has_action(a):
			InputMap.add_action(a, DEAD)

	_add_axis("look_left", JOY_AXIS_RIGHT_X, -1.0)
	_add_axis("look_right", JOY_AXIS_RIGHT_X, 1.0)
	_add_axis("look_up", JOY_AXIS_RIGHT_Y, -1.0)
	_add_axis("look_down", JOY_AXIS_RIGHT_Y, 1.0)

	# Triggers as heavy / block alternate (axis)
	_add_axis_btn("heavy_attack", JOY_AXIS_TRIGGER_RIGHT, 0.45)
	_add_axis_btn("block", JOY_AXIS_TRIGGER_LEFT, 0.45)

	print("GamepadBootstrap: P1 pad mapped (LS move, RS look, X light, Y heavy, LB block, RB shove, B dodge, A scavenge)")


static func _add_btn(action: String, button: int, device: int = 0) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, DEAD)
	var ev := InputEventJoypadButton.new()
	ev.device = device
	ev.button_index = button
	ev.pressed = true
	if not _has_similar(action, ev):
		InputMap.action_add_event(action, ev)


static func _add_axis(action: String, axis: int, axis_value: float, device: int = 0) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, DEAD)
	var ev := InputEventJoypadMotion.new()
	ev.device = device
	ev.axis = axis
	ev.axis_value = axis_value
	if not _has_similar(action, ev):
		InputMap.action_add_event(action, ev)


static func _add_axis_btn(action: String, axis: int, threshold: float, device: int = 0) -> void:
	# Joy motion past threshold counts as pressed via Input.get_action_strength
	_add_axis(action, axis, 1.0 if threshold > 0 else -1.0, device)


static func _has_similar(action: String, ev: InputEvent) -> bool:
	for e in InputMap.action_get_events(action):
		if e is InputEventJoypadButton and ev is InputEventJoypadButton:
			if e.button_index == ev.button_index and e.device == ev.device:
				return true
		if e is InputEventJoypadMotion and ev is InputEventJoypadMotion:
			if e.axis == ev.axis and e.device == ev.device and sign(e.axis_value) == sign(ev.axis_value):
				return true
	return false
