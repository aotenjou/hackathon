class_name GameHUD
extends CanvasLayer

signal joystick_changed(value: Vector2)
signal interact_pressed
signal ai_pressed
signal bag_pressed

var _location_label: Label
var _objective_label: Label
var _time_label: Label
var _bottom_label: Label
var _focus_label: Label
var _toast_label: Label
var _ai_panel: PanelContainer
var _ai_body: Label
var _bag_panel: PanelContainer
var _bag_body: Label
var _stats_panel: PanelContainer
var _joystick: Control

const VirtualJoystickScript = preload("res://scripts/ui/virtual_joystick.gd")
var COL_PANEL := Color("111820")
var COL_PANEL_DARK := Color("090d12")
var COL_GOLD := Color("d8a13a")
var COL_GOLD_LIGHT := Color("f0c76f")
var COL_TEXT := Color("f6edd8")
var COL_TEXT_DIM := Color("d8caa8")
var COL_AI := Color("8be3ff")

func _ready() -> void:
	layer = 20
	_build_ui()
	_game_state().stats_changed.connect(refresh)
	_game_state().inventory_changed.connect(refresh)
	_game_state().objective_changed.connect(refresh)
	_game_state().feedback_logged.connect(_on_feedback_logged)
	refresh()

func set_focus_text(text: String) -> void:
	if text.is_empty():
		_focus_label.text = "靠近目标后点击交互"
	else:
		_focus_label.text = "可交互：" + text

func show_ai_hint() -> void:
	var stage_text := "辅助层"
	if _game_state().ai_stage == 1:
		stage_text = "解释层"
	elif _game_state().ai_stage >= 2:
		stage_text = "排序层"
	var dependence := int(_game_state().stats.get("ai_dependence", 0))
	var clarity := int(_game_state().stats.get("clarity", 0))
	_ai_body.text = "AI 助手 / %s\n\n建议：优先处理当前目标。\n系统依赖：%d\n自我清晰：%d\n\n智能优化通常能降低压力、提高成功路径，但会让表达更接近系统语言。" % [stage_text, dependence, clarity]
	_ai_panel.visible = not _ai_panel.visible

func show_bag() -> void:
	_update_bag_text()
	_bag_panel.visible = not _bag_panel.visible

func refresh() -> void:
	_location_label.text = _game_state().current_location
	_objective_label.text = "目标：" + _game_state().current_objective
	_time_label.text = _game_state().current_time
	_bottom_label.text = "心力 %02d  /  成功值 %s  /  依赖 %02d" % [
		int(_game_state().stats.get("heart", 0)),
		_grade(int(_game_state().stats.get("success_progress", 0))),
		int(_game_state().stats.get("ai_dependence", 0)),
	]
	_rebuild_stats_panel()
	if _bag_panel.visible:
		_update_bag_text()

func _build_ui() -> void:
	var root := Control.new()
	root.name = "HUDRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	_location_label = _pixel_label("邮轮甲板", 32, COL_TEXT)
	_location_label.position = Vector2(24, 18)
	_location_label.size = Vector2(330, 66)
	_style_chip(_location_label, COL_PANEL)
	root.add_child(_location_label)

	_objective_label = _pixel_label("目标：找到想回去的理由", 31, COL_TEXT)
	_objective_label.position = Vector2(470, 18)
	_objective_label.size = Vector2(660, 66)
	_objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_chip(_objective_label, COL_PANEL)
	root.add_child(_objective_label)

	_time_label = _pixel_label("22:40", 40, COL_TEXT)
	_time_label.position = Vector2(1360, 18)
	_time_label.size = Vector2(214, 66)
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_chip(_time_label, COL_PANEL)
	root.add_child(_time_label)

	_focus_label = _pixel_label("靠近目标后点击交互", 23, COL_TEXT_DIM)
	_focus_label.position = Vector2(602, 720)
	_focus_label.size = Vector2(396, 42)
	_focus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_chip(_focus_label, _color_alpha("1d2630", 0.9))
	root.add_child(_focus_label)

	_bottom_label = _pixel_label("", 31, COL_TEXT)
	_bottom_label.position = Vector2(436, 818)
	_bottom_label.size = Vector2(728, 58)
	_bottom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_chip(_bottom_label, _color_alpha("111820", 0.92))
	root.add_child(_bottom_label)

	_joystick = VirtualJoystickScript.new()
	_joystick.position = Vector2(54, 596)
	_joystick.size = Vector2(250, 250)
	_joystick.vector_changed.connect(func(value: Vector2) -> void: joystick_changed.emit(value))
	root.add_child(_joystick)

	var interact := _action_button("!", "交互", Vector2(1112, 716), _color_alpha("1a1711", 0.96), COL_GOLD)
	interact.pressed.connect(func() -> void: interact_pressed.emit())
	root.add_child(interact)

	var ai := _action_button("AI", "助手", Vector2(1272, 690), _color_alpha("071927", 0.96), COL_AI)
	ai.pressed.connect(func() -> void: ai_pressed.emit())
	root.add_child(ai)

	var bag := _action_button("▦", "背包", Vector2(1426, 716), _color_alpha("1a1711", 0.96), COL_GOLD)
	bag.pressed.connect(func() -> void: bag_pressed.emit())
	root.add_child(bag)

	_stats_panel = PanelContainer.new()
	_stats_panel.position = Vector2(1210, 280)
	_stats_panel.size = Vector2(320, 270)
	_stats_panel.add_theme_stylebox_override("panel", _panel_style(_color_alpha("0f1720", 0.88), Color("59472b"), 4))
	root.add_child(_stats_panel)

	_ai_panel = PanelContainer.new()
	_ai_panel.position = Vector2(1060, 150)
	_ai_panel.size = Vector2(430, 320)
	_ai_panel.visible = false
	_ai_panel.add_theme_stylebox_override("panel", _panel_style(_color_alpha("071927", 0.95), COL_AI, 5))
	_ai_body = _pixel_label("", 23, Color("bdefff"))
	_ai_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ai_body.size = Vector2(390, 290)
	_ai_panel.add_child(_ai_body)
	root.add_child(_ai_panel)

	_bag_panel = PanelContainer.new()
	_bag_panel.position = Vector2(1085, 300)
	_bag_panel.size = Vector2(370, 260)
	_bag_panel.visible = false
	_bag_panel.add_theme_stylebox_override("panel", _panel_style(_color_alpha("13100c", 0.95), COL_GOLD, 5))
	_bag_body = _pixel_label("", 24, COL_TEXT)
	_bag_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bag_body.size = Vector2(330, 230)
	_bag_panel.add_child(_bag_body)
	root.add_child(_bag_panel)

	_toast_label = _pixel_label("", 25, COL_TEXT)
	_toast_label.position = Vector2(560, 110)
	_toast_label.size = Vector2(500, 44)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.visible = false
	_style_chip(_toast_label, _color_alpha("243044", 0.9))
	root.add_child(_toast_label)

func _rebuild_stats_panel() -> void:
	for child in _stats_panel.get_children():
		_stats_panel.remove_child(child)
		child.queue_free()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_stats_panel.add_child(box)

	var title := _pixel_label("成功路径", 27, COL_AI)
	title.size = Vector2(285, 34)
	box.add_child(title)

	var lines := [
		["能力", "ability_exp"],
		["履历", "resume_score"],
		["人脉", "network_score"],
		["财富", "wealth_score"],
		["稳定", "stability_score"],
		["清晰", "clarity"],
	]
	for row in lines:
		var line := _pixel_label("%s：%02d" % [row[0], int(_game_state().stats.get(row[1], 0))], 23, Color("d6e7ef"))
		line.size = Vector2(285, 28)
		box.add_child(line)

func _update_bag_text() -> void:
	if _game_state().inventory.is_empty():
		_bag_body.text = "背包里还没有记忆物品。"
	else:
		_bag_body.text = "记忆物品\n\n" + _join_strings(_game_state().inventory, "\n")

func _on_feedback_logged(entry: Dictionary) -> void:
	_toast_label.text = str(entry.get("title", "反馈")) + "  " + str(entry.get("body", ""))
	_toast_label.visible = true
	var tween := create_tween()
	tween.tween_interval(2.2)
	tween.tween_callback(func() -> void: _toast_label.visible = false)

func _action_button(icon: String, label: String, pos: Vector2, color: Color, accent: Color) -> Button:
	var button := Button.new()
	button.text = icon + "\n" + label
	button.position = pos
	button.size = Vector2(118, 118)
	button.add_theme_font_size_override("font_size", 27)
	button.add_theme_color_override("font_color", COL_TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", accent)
	button.add_theme_color_override("font_shadow_color", Color("05070a"))
	button.add_theme_constant_override("shadow_offset_x", 2)
	button.add_theme_constant_override("shadow_offset_y", 2)
	button.add_theme_stylebox_override("normal", _round_button_style(color, accent, 5))
	button.add_theme_stylebox_override("hover", _round_button_style(Color("232a31"), COL_GOLD_LIGHT, 5))
	button.add_theme_stylebox_override("pressed", _round_button_style(COL_PANEL_DARK, COL_AI, 6))
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	return button

func _pixel_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color("05070a"))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label

func _style_chip(label: Label, color: Color) -> void:
	label.add_theme_stylebox_override("normal", _panel_style(color, COL_GOLD, 5, 0))

func _panel_style(bg: Color, border: Color, border_width: int = 3, corner_radius: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _round_button_style(bg: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := _panel_style(bg, border, border_width, 60)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 18
	style.content_margin_bottom = 12
	return style

func _grade(value: int) -> String:
	if value >= 95:
		return "S"
	if value >= 82:
		return "A"
	if value >= 68:
		return "B"
	if value >= 50:
		return "C"
	return "D"

func _color_alpha(hex: String, alpha: float) -> Color:
	var color := Color(hex)
	color.a = alpha
	return color

func _join_strings(values: Array, separator: String) -> String:
	var result := ""
	for index in range(values.size()):
		if index > 0:
			result += separator
		result += str(values[index])
	return result

func _game_state() -> Node:
	return get_node("/root/GameState")
