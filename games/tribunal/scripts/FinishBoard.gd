extends CanvasLayer
class_name FinishBoard
## End-of-round results board — winner, stats, rematch.

signal rematch_requested
signal replay_requested

const CRIMSON := Color(0.9, 0.2, 0.22)
const AZURE := Color(0.25, 0.5, 1.0)
const GOLD := Color(1.0, 0.85, 0.35)

var _root: Control
var _dim: ColorRect
var _panel: PanelContainer
var _title: Label
var _subtitle: Label
var _rows: VBoxContainer
var _hint: Label
var _visible_board: bool = false
var _has_replay: bool = false
var _replay_mode: bool = false


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()


func show_results(payload: Dictionary) -> void:
	visible = true
	_visible_board = true
	var winner_name: String = str(payload.get("winner_name", "DRAW"))
	var is_draw: bool = bool(payload.get("draw", false))
	var duration: float = float(payload.get("duration", 0.0))
	var reason: String = str(payload.get("reason", "elimination"))
	_has_replay = bool(payload.get("has_replay", false))
	_replay_mode = false

	if is_draw:
		_title.text = "DRAW"
		_title.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	else:
		_title.text = "%s WINS" % winner_name
		var accent: Color = payload.get("winner_color", GOLD)
		_title.add_theme_color_override("font_color", accent)

	var m := int(duration) / 60
	var s := int(duration) % 60
	_subtitle.text = "Round complete · %s · %02d:%02d" % [reason, m, s]

	# Clear old rows
	for c in _rows.get_children():
		c.queue_free()

	var fighters: Array = payload.get("fighters", [])
	for f in fighters:
		_rows.add_child(_make_stat_row(f))

	if _has_replay:
		_hint.text = "R  ·  REMATCH     G  ·  REPLAY     ESC  ·  MOUSE"
	else:
		_hint.text = "R  ·  REMATCH          ESC  ·  RELEASE MOUSE"
	# Dim in
	_dim.modulate.a = 0.0
	_panel.modulate.a = 0.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_dim, "modulate:a", 1.0, 0.35)
	tw.tween_property(_panel, "modulate:a", 1.0, 0.45)


func hide_board() -> void:
	_visible_board = false
	visible = false


func is_showing() -> bool:
	return _visible_board


func set_replay_mode(on: bool) -> void:
	_replay_mode = on
	if _panel:
		_panel.visible = not on
	if _dim:
		_dim.modulate.a = 0.25 if on else 1.0
	if _hint:
		_hint.text = "REPLAY…  G skip · R rematch" if on else (
			"R  ·  REMATCH     G  ·  REPLAY" if _has_replay else "R  ·  REMATCH"
		)


func _unhandled_input(event: InputEvent) -> void:
	if not _visible_board:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			rematch_requested.emit()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_G and (_has_replay or _replay_mode):
			replay_requested.emit()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_accept") and _has_replay:
			# Pad A also can start rematch; use Select-style via ui_focus_next? Keep R.
			pass


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	_dim = ColorRect.new()
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.color = Color(0.02, 0.02, 0.04, 0.78)
	_root.add_child(_dim)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -280
	_panel.offset_right = 280
	_panel.offset_top = -220
	_panel.offset_bottom = 220
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.1, 0.96)
	style.border_color = GOLD
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 22
	style.content_margin_bottom = 22
	_panel.add_theme_stylebox_override("panel", style)
	_root.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	_panel.add_child(vbox)

	var brand := Label.new()
	brand.text = "TRIBUNAL"
	brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	brand.add_theme_font_size_override("font_size", 14)
	brand.add_theme_color_override("font_color", Color(0.65, 0.65, 0.7))
	vbox.add_child(brand)

	var ref_line := Label.new()
	ref_line.text = "Melee bar: The Culling · Product: Tribunal"
	ref_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ref_line.add_theme_font_size_override("font_size", 11)
	ref_line.add_theme_color_override("font_color", Color(0.45, 0.45, 0.5))
	vbox.add_child(ref_line)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 42)
	_title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_title.add_theme_constant_override("outline_size", 6)
	_title.text = "—"
	vbox.add_child(_title)

	_subtitle = Label.new()
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.add_theme_font_size_override("font_size", 16)
	_subtitle.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	_subtitle.text = ""
	vbox.add_child(_subtitle)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 10)
	vbox.add_child(_rows)

	var sep2 := HSeparator.new()
	vbox.add_child(sep2)

	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 15)
	_hint.add_theme_color_override("font_color", Color(0.9, 0.85, 0.55))
	_hint.text = "R  ·  REMATCH"
	vbox.add_child(_hint)


func _make_stat_row(f: Dictionary) -> Control:
	var row := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.1, 0.11, 0.14, 0.9)
	st.corner_radius_top_left = 6
	st.corner_radius_top_right = 6
	st.corner_radius_bottom_left = 6
	st.corner_radius_bottom_right = 6
	st.content_margin_left = 12
	st.content_margin_right = 12
	st.content_margin_top = 8
	st.content_margin_bottom = 8
	var accent: Color = f.get("color", Color.WHITE)
	st.border_width_left = 4
	st.border_color = accent
	row.add_theme_stylebox_override("panel", st)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	row.add_child(h)

	var name_l := Label.new()
	name_l.text = str(f.get("name", "?"))
	name_l.add_theme_font_size_override("font_size", 18)
	name_l.add_theme_color_override("font_color", accent)
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(name_l)

	var stats := Label.new()
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stats.add_theme_font_size_override("font_size", 14)
	stats.add_theme_color_override("font_color", Color(0.85, 0.85, 0.88))
	var alive := "ALIVE" if bool(f.get("alive", false)) else "ELIM"
	stats.text = "%s   K %d   SCAV %d   TRAP %d   HP %d" % [
		alive,
		int(f.get("kills", 0)),
		int(f.get("scavenges", 0)),
		int(f.get("traps", 0)),
		int(f.get("hp", 0)),
	]
	h.add_child(stats)
	return row
