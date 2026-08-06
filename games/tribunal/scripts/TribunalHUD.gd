# TribunalHUD.gd — Culling-readable combat HUD for MeleeTest.
# Health/stamina bars (crimson P1 / azure P2), weapons, match timer, elim feed, fight/winner banner.

extends CanvasLayer
class_name TribunalHUD

const CRIMSON := Color(0.85, 0.12, 0.15, 1.0)
const AZURE := Color(0.18, 0.42, 0.95, 1.0)
const STA_FILL := Color(0.95, 0.82, 0.22, 1.0)
const BAR_BG := Color(0.08, 0.08, 0.1, 0.82)
const PANEL_BG := Color(0.05, 0.05, 0.07, 0.72)
const FEED_MAX := 4

var _p1: Node = null
var _p2: Node = null
var _arena: Node = null
var _feed_lines: PackedStringArray = PackedStringArray()

var _timer_label: Label
var _banner: Label
var _feed_label: Label

var _p1_hp: ProgressBar
var _p1_sta: ProgressBar
var _p1_weapon: Label
var _p1_name: Label
var _p1_hp_text: Label

var _p2_hp: ProgressBar
var _p2_sta: ProgressBar
var _p2_weapon: Label
var _p2_name: Label
var _p2_hp_text: Label

var _banner_tween: Tween
var _chain_label: Label


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	show_fight_banner()


func _process(_delta: float) -> void:
	_update_timer()
	_poll_vitals()


func bind_fighters(p1: Node, p2: Node) -> void:
	_disconnect_fighter(_p1)
	_disconnect_fighter(_p2)
	_p1 = p1
	_p2 = p2
	_connect_fighter(_p1, 1)
	_connect_fighter(_p2, 2)
	_refresh_all()


func bind_arena(arena: Node) -> void:
	if _arena and is_instance_valid(_arena):
		if _arena.has_signal("match_ended") and _arena.match_ended.is_connected(_on_match_ended):
			_arena.match_ended.disconnect(_on_match_ended)
		if _arena.has_signal("player_eliminated") and _arena.player_eliminated.is_connected(_on_player_eliminated):
			_arena.player_eliminated.disconnect(_on_player_eliminated)
	_arena = arena
	if _arena == null:
		return
	if _arena.has_signal("match_ended") and not _arena.match_ended.is_connected(_on_match_ended):
		_arena.match_ended.connect(_on_match_ended)
	if _arena.has_signal("player_eliminated") and not _arena.player_eliminated.is_connected(_on_player_eliminated):
		_arena.player_eliminated.connect(_on_player_eliminated)
	_update_timer()


func set_weapon_name(player_id: int, weapon_name: String) -> void:
	var label := _p1_weapon if player_id == 1 else _p2_weapon
	if label:
		label.text = weapon_name if weapon_name != "" else "—"


func push_feed(line: String) -> void:
	_feed_lines.append(line)
	while _feed_lines.size() > FEED_MAX:
		_feed_lines.remove_at(0)
	if _feed_label:
		_feed_label.text = "\n".join(_feed_lines)


func show_fight_banner() -> void:
	if not _banner:
		return
	_banner.text = "FIGHT"
	_banner.modulate = Color(1, 1, 1, 1)
	_banner.visible = true
	if _banner_tween and _banner_tween.is_valid():
		_banner_tween.kill()
	_banner_tween = create_tween()
	_banner_tween.tween_interval(1.1)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, 0.55)
	_banner_tween.tween_callback(func():
		if _banner:
			_banner.visible = false
	)


func show_winner_banner(winner: Node) -> void:
	if not _banner:
		return
	if winner and is_instance_valid(winner):
		_banner.text = "%s WINS" % winner.name
	else:
		_banner.text = "DRAW"
	_banner.modulate = Color(1, 0.92, 0.55, 1)
	_banner.visible = true
	if _banner_tween and _banner_tween.is_valid():
		_banner_tween.kill()


# --- internal ---

func _connect_fighter(fighter: Node, slot: int) -> void:
	if fighter == null:
		return
	if fighter.has_signal("health_changed"):
		if not fighter.health_changed.is_connected(_on_health.bind(slot)):
			fighter.health_changed.connect(_on_health.bind(slot))
	if fighter.has_signal("stamina_changed"):
		if not fighter.stamina_changed.is_connected(_on_stamina.bind(slot)):
			fighter.stamina_changed.connect(_on_stamina.bind(slot))
	if fighter.has_signal("weapon_equipped"):
		if not fighter.weapon_equipped.is_connected(_on_weapon.bind(slot)):
			fighter.weapon_equipped.connect(_on_weapon.bind(slot))
	if fighter.has_signal("player_died"):
		if not fighter.player_died.is_connected(_on_fighter_died.bind(fighter)):
			fighter.player_died.connect(_on_fighter_died.bind(fighter))
	if slot == 1 and fighter.has_signal("judgement_chain_changed"):
		if not fighter.judgement_chain_changed.is_connected(_on_chain):
			fighter.judgement_chain_changed.connect(_on_chain)


func _on_chain(chain: int, ready: bool) -> void:
	if _chain_label == null:
		return
	if chain <= 0:
		_chain_label.text = ""
		_chain_label.visible = false
		return
	_chain_label.visible = true
	if ready:
		_chain_label.text = "JUDGEMENT ×%d" % chain
		_chain_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.25))
	else:
		_chain_label.text = "CHAIN %d" % chain
		_chain_label.add_theme_color_override("font_color", Color(0.85, 0.55, 1.0))


func _disconnect_fighter(fighter: Node) -> void:
	if fighter == null or not is_instance_valid(fighter):
		return
	# Bound callables differ per reconnect; only disconnect if still connected via stored slots is fragile.
	# Safe: leave connections if fighter is freed; rebinding uses fresh fighters.


func _on_health(new_health: int, slot: int) -> void:
	_apply_health(slot, new_health)


func _on_stamina(new_stamina: float, slot: int) -> void:
	_apply_stamina(slot, new_stamina)


func _on_weapon(weapon_name: String, slot: int) -> void:
	set_weapon_name(slot, weapon_name)


func _on_fighter_died(fighter: Node) -> void:
	if fighter == null:
		return
	push_feed("ELIM · %s" % fighter.name)


func _on_player_eliminated(player: Node) -> void:
	# Prefer arena signal if fighter died signal was not available
	if player == null:
		return
	var line := "ELIM · %s" % player.name
	if _feed_lines.is_empty() or _feed_lines[_feed_lines.size() - 1] != line:
		push_feed(line)


func _on_match_ended(winner: Node) -> void:
	show_winner_banner(winner)
	if winner and is_instance_valid(winner):
		push_feed("MATCH · %s wins" % winner.name)
	else:
		push_feed("MATCH · draw")


func _apply_health(slot: int, value: int) -> void:
	var bar := _p1_hp if slot == 1 else _p2_hp
	var txt := _p1_hp_text if slot == 1 else _p2_hp_text
	var fighter := _p1 if slot == 1 else _p2
	if bar == null:
		return
	var mx := 100.0
	if fighter and "max_health" in fighter:
		mx = float(fighter.max_health)
	bar.max_value = mx
	bar.value = clampf(float(value), 0.0, mx)
	if txt:
		txt.text = "%d / %d" % [int(value), int(mx)]


func _apply_stamina(slot: int, value: float) -> void:
	var bar := _p1_sta if slot == 1 else _p2_sta
	var fighter := _p1 if slot == 1 else _p2
	if bar == null:
		return
	var mx := 100.0
	if fighter and "max_stamina" in fighter:
		mx = float(fighter.max_stamina)
	bar.max_value = mx
	bar.value = clampf(value, 0.0, mx)


func _poll_vitals() -> void:
	# Keep bars honest even if a signal was missed (respawn, equip edge cases)
	if _p1 and is_instance_valid(_p1):
		if "health" in _p1:
			_apply_health(1, int(_p1.health))
		if "stamina" in _p1:
			_apply_stamina(1, float(_p1.stamina))
	if _p2 and is_instance_valid(_p2):
		if "health" in _p2:
			_apply_health(2, int(_p2.health))
		if "stamina" in _p2:
			_apply_stamina(2, float(_p2.stamina))


func _refresh_all() -> void:
	if _p1 and is_instance_valid(_p1):
		if _p1_name:
			_p1_name.text = "P1 · %s" % _p1.name
		if "health" in _p1:
			_apply_health(1, int(_p1.health))
		if "stamina" in _p1:
			_apply_stamina(1, float(_p1.stamina))
		if "current_weapon" in _p1 and _p1.current_weapon:
			set_weapon_name(1, str(_p1.current_weapon.weapon_name))
		else:
			set_weapon_name(1, "Sword")
	if _p2 and is_instance_valid(_p2):
		if _p2_name:
			_p2_name.text = "P2 · %s" % _p2.name
		if "health" in _p2:
			_apply_health(2, int(_p2.health))
		if "stamina" in _p2:
			_apply_stamina(2, float(_p2.stamina))
		if "current_weapon" in _p2 and _p2.current_weapon:
			set_weapon_name(2, str(_p2.current_weapon.weapon_name))
		else:
			set_weapon_name(2, "Axe")


func _update_timer() -> void:
	if _timer_label == null:
		return
	if _arena and is_instance_valid(_arena) and "time_remaining" in _arena:
		var t: float = float(_arena.time_remaining)
		t = maxf(0.0, t)
		var m := int(t) / 60
		var s := int(t) % 60
		_timer_label.text = "%02d:%02d" % [m, s]
	else:
		_timer_label.text = "--:--"


func _build_ui() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# Match timer — top center
	_timer_label = Label.new()
	_timer_label.name = "MatchTimer"
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_timer_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_timer_label.offset_left = -80
	_timer_label.offset_right = 80
	_timer_label.offset_top = 12
	_timer_label.offset_bottom = 48
	_timer_label.add_theme_font_size_override("font_size", 28)
	_timer_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.92))
	_timer_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_timer_label.add_theme_constant_override("outline_size", 4)
	_timer_label.text = "05:00"
	root.add_child(_timer_label)

	# P1 panel — top left (crimson)
	var p1_panel := _make_fighter_panel(true)
	root.add_child(p1_panel)

	# P2 panel — top right (azure)
	var p2_panel := _make_fighter_panel(false)
	root.add_child(p2_panel)

	# Kill / elim feed — bottom left
	_feed_label = Label.new()
	_feed_label.name = "ElimFeed"
	_feed_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_feed_label.offset_left = 16
	_feed_label.offset_top = -140
	_feed_label.offset_right = 420
	_feed_label.offset_bottom = -16
	_feed_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_feed_label.add_theme_font_size_override("font_size", 16)
	_feed_label.add_theme_color_override("font_color", Color(0.92, 0.88, 0.8, 0.95))
	_feed_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_feed_label.add_theme_constant_override("outline_size", 3)
	_feed_label.text = ""
	root.add_child(_feed_label)

	# Center banner
	_banner = Label.new()
	_banner.name = "Banner"
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.set_anchors_preset(Control.PRESET_CENTER)
	_banner.offset_left = -280
	_banner.offset_right = 280
	_banner.offset_top = -48
	_banner.offset_bottom = 48
	_banner.add_theme_font_size_override("font_size", 64)
	_banner.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_banner.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	_banner.add_theme_constant_override("outline_size", 8)
	_banner.text = "FIGHT"
	_banner.visible = false
	root.add_child(_banner)

	# Judgement Chain readout (Tribunal unique)
	_chain_label = Label.new()
	_chain_label.name = "JudgementChain"
	_chain_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chain_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_chain_label.offset_left = -160
	_chain_label.offset_right = 160
	_chain_label.offset_top = -72
	_chain_label.offset_bottom = -40
	_chain_label.add_theme_font_size_override("font_size", 22)
	_chain_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	_chain_label.add_theme_constant_override("outline_size", 5)
	_chain_label.visible = false
	root.add_child(_chain_label)


func _make_fighter_panel(is_p1: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "P1Panel" if is_p1 else "P2Panel"
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 10
	var accent := CRIMSON if is_p1 else AZURE
	style.border_color = accent
	style.border_width_left = 3 if is_p1 else 0
	style.border_width_right = 0 if is_p1 else 3
	style.border_width_top = 0
	style.border_width_bottom = 0
	panel.add_theme_stylebox_override("panel", style)

	panel.set_anchors_preset(Control.PRESET_TOP_LEFT if is_p1 else Control.PRESET_TOP_RIGHT)
	if is_p1:
		panel.offset_left = 16
		panel.offset_top = 56
		panel.offset_right = 300
		panel.offset_bottom = 168
	else:
		panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		panel.offset_left = -300
		panel.offset_top = 56
		panel.offset_right = -16
		panel.offset_bottom = 168

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var name_lbl := Label.new()
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.add_theme_color_override("font_color", accent)
	name_lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	name_lbl.add_theme_constant_override("outline_size", 3)
	name_lbl.text = "P1" if is_p1 else "P2"
	if not is_p1:
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(name_lbl)

	var hp_row := HBoxContainer.new()
	hp_row.add_theme_constant_override("separation", 6)
	vbox.add_child(hp_row)

	var hp_tag := Label.new()
	hp_tag.text = "HP"
	hp_tag.add_theme_font_size_override("font_size", 12)
	hp_tag.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	hp_tag.custom_minimum_size = Vector2(28, 0)
	hp_row.add_child(hp_tag)

	var hp_bar := _make_bar(accent)
	hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_bar.custom_minimum_size = Vector2(0, 18)
	hp_row.add_child(hp_bar)

	var hp_txt := Label.new()
	hp_txt.add_theme_font_size_override("font_size", 12)
	hp_txt.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	hp_txt.custom_minimum_size = Vector2(64, 0)
	hp_txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hp_txt.text = "100 / 100"
	hp_row.add_child(hp_txt)

	var sta_row := HBoxContainer.new()
	sta_row.add_theme_constant_override("separation", 6)
	vbox.add_child(sta_row)

	var sta_tag := Label.new()
	sta_tag.text = "STA"
	sta_tag.add_theme_font_size_override("font_size", 12)
	sta_tag.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	sta_tag.custom_minimum_size = Vector2(28, 0)
	sta_row.add_child(sta_tag)

	var sta_bar := _make_bar(STA_FILL)
	sta_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sta_bar.custom_minimum_size = Vector2(0, 12)
	sta_row.add_child(sta_bar)

	var wpn := Label.new()
	wpn.add_theme_font_size_override("font_size", 14)
	wpn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.88))
	wpn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	wpn.add_theme_constant_override("outline_size", 2)
	wpn.text = "—"
	if not is_p1:
		wpn.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(wpn)

	if is_p1:
		_p1_name = name_lbl
		_p1_hp = hp_bar
		_p1_sta = sta_bar
		_p1_weapon = wpn
		_p1_hp_text = hp_txt
	else:
		_p2_name = name_lbl
		_p2_hp = hp_bar
		_p2_sta = sta_bar
		_p2_weapon = wpn
		_p2_hp_text = hp_txt

	return panel


func _make_bar(fill: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = 100
	bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = BAR_BG
	bg.corner_radius_top_left = 3
	bg.corner_radius_top_right = 3
	bg.corner_radius_bottom_left = 3
	bg.corner_radius_bottom_right = 3
	var fg := StyleBoxFlat.new()
	fg.bg_color = fill
	fg.corner_radius_top_left = 3
	fg.corner_radius_top_right = 3
	fg.corner_radius_bottom_left = 3
	fg.corner_radius_bottom_right = 3
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)
	return bar
