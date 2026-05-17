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
var _settlement_panel: PanelContainer
var _settlement_title: Label
var _settlement_body: Label
var _ai_panel: PanelContainer
var _ai_body: Label
var _ai_close_button: Button
var _bag_panel: PanelContainer
var _bag_body: Label
var _stats_panel: PanelContainer
var _stats_toggle_button: Button
var _joystick: Control
var _last_guidance_signature := ""
var _default_focus_hint := ""
var _focus_text_active := false
var _stats_panel_expanded := false

const VirtualJoystickScript = preload("res://scripts/ui/virtual_joystick.gd")
var COL_PANEL := Color("0d151f")
var COL_PANEL_DARK := Color("070b10")
var COL_PANEL_MID := Color("172536")
var COL_FRAME := Color("314962")
var COL_GOLD := Color("d8a13a")
var COL_GOLD_LIGHT := Color("f0c76f")
var COL_TEXT := Color("f6edd8")
var COL_TEXT_DIM := Color("c7d4df")
var COL_AI := Color("7be3ff")

func _ready() -> void:
	layer = 20
	_build_ui()
	_game_state().stats_changed.connect(refresh)
	_game_state().inventory_changed.connect(refresh)
	_game_state().objective_changed.connect(refresh)
	_game_state().ui_phase_changed.connect(func(_phase: String) -> void: refresh())
	_game_state().settlement_logged.connect(_on_settlement_logged)
	_game_state().feedback_logged.connect(_on_feedback_logged)
	_game_state().route_profile_changed.connect(refresh)
	refresh()

func set_focus_text(text: String) -> void:
	if text.is_empty():
		_focus_text_active = false
		_focus_label.text = _fallback_focus_text()
	else:
		_focus_text_active = true
		_focus_label.text = "可交互：" + text

func set_default_focus_hint(text: String) -> void:
	_default_focus_hint = text
	if not _focus_text_active:
		_focus_label.text = _fallback_focus_text()

func show_ai_hint(manual := true) -> void:
	_update_ai_body(manual, _is_strong_guidance_phase())
	_ai_panel.visible = not _ai_panel.visible if manual else true

func notify_progress_checkpoint() -> void:
	maybe_show_ai_guidance(false)

func maybe_show_ai_guidance(force := false) -> void:
	var relevant_gaps: Array[Dictionary] = _guidance_gaps()
	if relevant_gaps.is_empty():
		return
	var signature := _guidance_signature(relevant_gaps)
	if not force and signature == _last_guidance_signature:
		return
	_last_guidance_signature = signature
	_update_ai_body(false, _is_strong_guidance_phase())
	_ai_panel.visible = true

func _update_ai_body(manual: bool, strong_mode: bool) -> void:
	var stage_text := "辅助层"
	if _game_state().ai_stage == 1:
		stage_text = "解释层"
	elif _game_state().ai_stage >= 2:
		stage_text = "排序层"
	var dependence := int(_game_state().stats.get("ai_dependence", 0))
	var clarity := int(_game_state().stats.get("clarity", 0))
	var heart_cost := int(_game_state().get_ai_heart_cost())
	var gaps: Array[Dictionary] = _game_state().get_success_gaps()
	var mode_text := "强制校准" if strong_mode and not manual else "成功路径校准"
	var lines: Array[String] = []
	lines.append("AI 助手 / %s / %s" % [stage_text, mode_text])
	lines.append("")
	lines.append("目标：贴近开场成功人生指标。")
	lines.append("依赖 %02d  自我清晰 %02d  单次 AI 心力成本 %d" % [dependence, clarity, heart_cost])
	if gaps.is_empty():
		lines.append("")
		lines.append("当前成功路径核心指标已达到目标线。建议继续推进当前目标。")
	else:
		lines.append("")
		lines.append("指标差距：")
		for gap in gaps.slice(0, mini(3, gaps.size())):
			lines.append("%s %02d/%02d，差距 %d" % [
				str(gap.get("label", "")),
				int(gap.get("current", 0)),
				int(gap.get("target", 0)),
				int(gap.get("gap", 0)),
			])
		var primary: Dictionary = gaps[0]
		lines.append("")
		lines.append(str(primary.get("message", "")))
		if strong_mode and not manual:
			lines.append("系统建议：先完成校准，再继续偏离成功路径。")
	_ai_body.text = "\n".join(lines)
	_ai_close_button.text = "CONTINUE" if strong_mode and not manual else "关闭"

func show_bag() -> void:
	_update_bag_text()
	_bag_panel.visible = not _bag_panel.visible

func refresh() -> void:
	_location_label.text = _game_state().current_location
	_objective_label.text = "目标：" + _game_state().current_objective
	_time_label.text = _game_state().current_time
	var success_value := _derived_success_value()
	_bottom_label.text = "心力 %02d  /  成功评级 %s  /  依赖 %02d" % [
		int(_game_state().stats.get("heart", 0)),
		_grade(success_value),
		int(_game_state().stats.get("ai_dependence", 0)),
	]
	if _game_state().ui_phase in ["profile_system", "tag_overlay", "final_summary"]:
		_bottom_label.text = "心力 %02d  /  适配评级 %s  /  依赖 %02d" % [
			int(_game_state().stats.get("heart", 0)),
			_grade(success_value),
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

	var top_scrim := ColorRect.new()
	top_scrim.color = _color_alpha("06101a", 0.54)
	top_scrim.position = Vector2(0, 0)
	top_scrim.size = Vector2(1600, 92)
	root.add_child(top_scrim)

	var bottom_scrim := ColorRect.new()
	bottom_scrim.color = _color_alpha("06101a", 0.28)
	bottom_scrim.position = Vector2(0, 748)
	bottom_scrim.size = Vector2(1600, 152)
	root.add_child(bottom_scrim)

	_location_label = _pixel_label("邮轮甲板", 27, COL_TEXT)
	_location_label.position = Vector2(20, 18)
	_location_label.size = Vector2(315, 54)
	_location_label.text = "◆  邮轮甲板"
	_style_chip(_location_label, COL_PANEL)
	root.add_child(_location_label)

	_objective_label = _pixel_label("目标：找到想回去的理由", 28, COL_TEXT)
	_objective_label.position = Vector2(520, 18)
	_objective_label.size = Vector2(610, 54)
	_objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_chip(_objective_label, COL_PANEL)
	root.add_child(_objective_label)

	_time_label = _pixel_label("22:40", 34, COL_TEXT)
	_time_label.position = Vector2(1378, 18)
	_time_label.size = Vector2(190, 54)
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_chip(_time_label, COL_PANEL)
	root.add_child(_time_label)

	_focus_label = _pixel_label("靠近目标后点击交互", 21, COL_TEXT_DIM)
	_focus_label.position = Vector2(638, 746)
	_focus_label.size = Vector2(324, 34)
	_focus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_chip(_focus_label, _color_alpha("0d151f", 0.76))
	root.add_child(_focus_label)

	_bottom_label = _pixel_label("", 28, COL_TEXT)
	_bottom_label.position = Vector2(472, 820)
	_bottom_label.size = Vector2(656, 48)
	_bottom_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_chip(_bottom_label, _color_alpha("0d151f", 0.88))
	root.add_child(_bottom_label)

	_joystick = VirtualJoystickScript.new()
	_joystick.position = Vector2(58, 610)
	_joystick.size = Vector2(220, 220)
	_joystick.vector_changed.connect(func(value: Vector2) -> void: joystick_changed.emit(value))
	root.add_child(_joystick)

	var interact := _action_button("☝", "交互", Vector2(1088, 730), _color_alpha("101723", 0.88), COL_GOLD)
	interact.pressed.connect(func() -> void: interact_pressed.emit())
	root.add_child(interact)

	var ai := _action_button("◉", "AI", Vector2(1240, 708), _color_alpha("0a2030", 0.9), COL_AI)
	ai.pressed.connect(func() -> void: ai_pressed.emit())
	root.add_child(ai)

	var bag := _action_button("▣", "背包", Vector2(1392, 730), _color_alpha("101723", 0.88), COL_GOLD)
	bag.pressed.connect(func() -> void: bag_pressed.emit())
	root.add_child(bag)

	_stats_panel = PanelContainer.new()
	_stats_panel.position = Vector2(1230, 318)
	_stats_panel.size = Vector2(300, 318)
	_stats_panel.visible = false
	_stats_panel.add_theme_stylebox_override("panel", _panel_style(_color_alpha("08111a", 0.82), _color_alpha("3d5972", 0.92), 3, 4))
	root.add_child(_stats_panel)

	_stats_toggle_button = _stats_toggle_control()
	_stats_toggle_button.pressed.connect(_toggle_stats_panel)
	root.add_child(_stats_toggle_button)
	_update_stats_toggle_button()

	_ai_panel = PanelContainer.new()
	_ai_panel.position = Vector2(1060, 150)
	_ai_panel.size = Vector2(430, 320)
	_ai_panel.visible = false
	_ai_panel.add_theme_stylebox_override("panel", _panel_style(_color_alpha("071927", 0.92), COL_AI, 4, 4))
	var ai_box := VBoxContainer.new()
	ai_box.add_theme_constant_override("separation", 10)
	_ai_panel.add_child(ai_box)
	_ai_body = _pixel_label("", 23, Color("bdefff"))
	_ai_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ai_body.custom_minimum_size = Vector2(390, 250)
	ai_box.add_child(_ai_body)
	_ai_close_button = Button.new()
	_ai_close_button.text = "关闭"
	_ai_close_button.custom_minimum_size = Vector2(390, 42)
	_ai_close_button.add_theme_font_size_override("font_size", 22)
	_ai_close_button.add_theme_color_override("font_color", COL_TEXT)
	_ai_close_button.add_theme_color_override("font_hover_color", Color.WHITE)
	_ai_close_button.add_theme_stylebox_override("normal", _panel_style(Color("0d2432"), COL_AI, 3, 3))
	_ai_close_button.add_theme_stylebox_override("hover", _panel_style(Color("17384a"), COL_AI.lightened(0.18), 3, 3))
	_ai_close_button.pressed.connect(func() -> void: _ai_panel.visible = false)
	ai_box.add_child(_ai_close_button)
	root.add_child(_ai_panel)

	_bag_panel = PanelContainer.new()
	_bag_panel.position = Vector2(1085, 300)
	_bag_panel.size = Vector2(370, 260)
	_bag_panel.visible = false
	_bag_panel.add_theme_stylebox_override("panel", _panel_style(_color_alpha("13100c", 0.92), COL_GOLD, 4, 4))
	_bag_body = _pixel_label("", 24, COL_TEXT)
	_bag_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bag_body.size = Vector2(330, 230)
	_bag_panel.add_child(_bag_body)
	root.add_child(_bag_panel)

	_toast_label = _pixel_label("", 22, COL_TEXT)
	_toast_label.position = Vector2(535, 104)
	_toast_label.size = Vector2(530, 38)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.visible = false
	_style_chip(_toast_label, _color_alpha("162233", 0.84))
	root.add_child(_toast_label)

	_settlement_panel = PanelContainer.new()
	_settlement_panel.position = Vector2(430, 150)
	_settlement_panel.size = Vector2(740, 230)
	_settlement_panel.visible = false
	_settlement_panel.add_theme_stylebox_override("panel", _panel_style(_color_alpha("101820", 0.94), COL_GOLD_LIGHT, 4, 4))
	root.add_child(_settlement_panel)

	var settlement_box := VBoxContainer.new()
	settlement_box.add_theme_constant_override("separation", 10)
	_settlement_panel.add_child(settlement_box)

	_settlement_title = _pixel_label("阶段结算", 30, COL_GOLD_LIGHT)
	_settlement_title.size = Vector2(700, 40)
	settlement_box.add_child(_settlement_title)

	_settlement_body = _pixel_label("", 24, COL_TEXT)
	_settlement_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_settlement_body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_settlement_body.custom_minimum_size = Vector2(700, 120)
	settlement_box.add_child(_settlement_body)

	var settlement_close := Button.new()
	settlement_close.text = "CONTINUE"
	settlement_close.custom_minimum_size = Vector2(700, 42)
	settlement_close.add_theme_font_size_override("font_size", 23)
	settlement_close.add_theme_color_override("font_color", COL_TEXT)
	settlement_close.add_theme_stylebox_override("normal", _panel_style(Color("1d2630"), COL_GOLD, 3, 3))
	settlement_close.pressed.connect(func() -> void: _settlement_panel.visible = false)
	settlement_box.add_child(settlement_close)

func _rebuild_stats_panel() -> void:
	for child in _stats_panel.get_children():
		_stats_panel.remove_child(child)
		child.queue_free()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	_stats_panel.add_child(box)

	var title := _pixel_label("◇  " + _stats_title(), 24, COL_AI)
	title.size = Vector2(285, 34)
	box.add_child(title)

	var lines := _stats_lines()
	for row in lines:
		box.add_child(_metric_row(str(row[0]), int(_game_state().stats.get(row[1], 0))))

	var wish := _pixel_label("愿望：" + str(_game_state().wishes.get("current", "")), 20, COL_TEXT_DIM)
	wish.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	wish.size = Vector2(285, 44)
	box.add_child(wish)

	var cards_text := "状态：无"
	if not _game_state().emotion_cards.is_empty():
		cards_text = "状态：" + _join_limited(_game_state().emotion_cards, " / ", 2)
	var cards := _pixel_label(cards_text, 20, COL_TEXT_DIM)
	cards.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cards.size = Vector2(285, 44)
	box.add_child(cards)

	var route := _pixel_label(_route_profile_text(), 19, COL_TEXT_DIM)
	route.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	route.size = Vector2(285, 52)
	box.add_child(route)
	_update_stats_toggle_button()

func _toggle_stats_panel() -> void:
	_stats_panel_expanded = not _stats_panel_expanded
	_stats_panel.visible = _stats_panel_expanded
	_update_stats_toggle_button()

func _update_stats_toggle_button() -> void:
	if _stats_toggle_button == null:
		return
	if _stats_panel != null:
		_stats_panel.visible = _stats_panel_expanded
	_stats_toggle_button.text = "◇\n收起" if _stats_panel_expanded else "◇\n指标"
	_stats_toggle_button.tooltip_text = "隐藏右侧指标面板" if _stats_panel_expanded else "显示右侧指标面板"
	_stats_toggle_button.position = Vector2(1138, 318) if _stats_panel_expanded else Vector2(1492, 318)

func _stats_title() -> String:
	match _game_state().ui_phase:
		"profile_system":
			return "人格画像"
		"tag_overlay":
			return "标签覆盖"
		"final_summary":
			return "人生总结"
		_:
			return "成功路径"

func _stats_lines() -> Array:
	match _game_state().ui_phase:
		"profile_system":
			return [
				["职业画像", "resume_score"],
				["人脉样本", "network_score"],
				["稳定画像", "stability_score"],
				["自我清晰", "clarity"],
				["AI依赖", "ai_dependence"],
			]
		"tag_overlay":
			return [
				["职业标签", "resume_score"],
				["人脉标签", "network_score"],
				["稳定标签", "stability_score"],
				["自我信号", "clarity"],
				["AI依赖", "ai_dependence"],
			]
		"final_summary":
			return [
				["职业资本", "resume_score"],
				["人脉资源", "network_score"],
				["稳定适配", "stability_score"],
				["自我清晰", "clarity"],
				["AI依赖", "ai_dependence"],
			]
		_:
			return [
				["职业资本", "resume_score"],
				["人脉资源", "network_score"],
				["稳定适配", "stability_score"],
				["自我清晰", "clarity"],
				["AI依赖", "ai_dependence"],
			]

func _route_profile_text() -> String:
	var profile: Dictionary = _game_state().get_route_profile()
	var percents: Dictionary = profile.get("percents", {})
	var prefix := "倾向"
	if _game_state().ui_phase in ["profile_system", "tag_overlay", "final_summary"]:
		prefix = "样本倾向"
	return "%s 自我 %d / 规训 %d / AI %d" % [
		prefix,
		int(percents.get("self", 0)),
		int(percents.get("safe", 0)),
		int(percents.get("ai", 0)),
	]

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
	notify_progress_checkpoint()

func _on_settlement_logged(entry: Dictionary) -> void:
	_settlement_title.text = str(entry.get("title", "阶段结算"))
	_settlement_body.text = str(entry.get("body", ""))
	_settlement_panel.visible = true
	notify_progress_checkpoint()

func _action_button(icon: String, label: String, pos: Vector2, color: Color, accent: Color) -> Button:
	var button := Button.new()
	button.text = icon + "\n" + label
	button.position = pos
	button.size = Vector2(108, 108)
	button.add_theme_font_size_override("font_size", 25)
	button.add_theme_color_override("font_color", COL_TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", accent)
	button.add_theme_color_override("font_shadow_color", Color("05070a"))
	button.add_theme_constant_override("shadow_offset_x", 2)
	button.add_theme_constant_override("shadow_offset_y", 2)
	button.add_theme_stylebox_override("normal", _round_button_style(color, accent, 4))
	button.add_theme_stylebox_override("hover", _round_button_style(Color("1f3042"), accent.lightened(0.2), 4))
	button.add_theme_stylebox_override("pressed", _round_button_style(COL_PANEL_DARK, COL_AI, 5))
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	return button

func _stats_toggle_control() -> Button:
	var button := Button.new()
	button.size = Vector2(74, 72)
	button.add_theme_font_size_override("font_size", 19)
	button.add_theme_color_override("font_color", COL_TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", COL_AI)
	button.add_theme_color_override("font_shadow_color", Color("05070a"))
	button.add_theme_constant_override("shadow_offset_x", 2)
	button.add_theme_constant_override("shadow_offset_y", 2)
	button.add_theme_stylebox_override("normal", _panel_style(_color_alpha("08111a", 0.86), _color_alpha("3d5972", 0.92), 3, 4))
	button.add_theme_stylebox_override("hover", _panel_style(Color("122436"), COL_AI, 3, 4))
	button.add_theme_stylebox_override("pressed", _panel_style(COL_PANEL_DARK, COL_AI, 4, 4))
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
	label.add_theme_stylebox_override("normal", _panel_style(color, COL_FRAME, 3, 4))

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

func _metric_row(label_text: String, value: int) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(270, 24)
	row.add_theme_constant_override("separation", 8)

	var label := _pixel_label(label_text, 19, Color("d6e7ef"))
	label.custom_minimum_size = Vector2(74, 24)
	row.add_child(label)

	var bar_back := ColorRect.new()
	bar_back.color = _color_alpha("263747", 0.74)
	bar_back.custom_minimum_size = Vector2(118, 12)
	row.add_child(bar_back)

	var bar := ColorRect.new()
	bar.color = COL_AI if value < 90 else COL_GOLD_LIGHT
	bar.position = Vector2(0, 0)
	bar.size = Vector2(clampf(value, 0, 100) * 1.18, 12)
	bar_back.add_child(bar)

	var value_label := _pixel_label("%02d" % value, 19, COL_TEXT)
	value_label.custom_minimum_size = Vector2(42, 24)
	row.add_child(value_label)
	return row

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

func _derived_success_value() -> int:
	var state := _game_state()
	var stats: Dictionary = state.get("stats")
	for method_name in ["get_success_progress", "get_success_value", "get_derived_success_value", "get_success_rating_value"]:
		if state.has_method(method_name):
			return clampi(int(state.call(method_name)), 0, 100)

	var keys := ["resume_score", "network_score", "stability_score"]
	var total := 0
	for key in keys:
		total += int(stats.get(key, 0))
	return int(round(float(total) / float(keys.size())))

func _fallback_focus_text() -> String:
	if _default_focus_hint.is_empty():
		return "靠近目标后点击交互"
	return _default_focus_hint

func _guidance_gaps() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for gap in _game_state().get_success_gaps():
		if _guidance_gap_relevant(gap):
			result.append(gap)
	return result

func _guidance_gap_relevant(gap: Dictionary) -> bool:
	if _is_strong_guidance_phase():
		return int(gap.get("gap", 0)) >= 8
	return str(gap.get("severity", "")) in ["normal", "strong"]

func _guidance_signature(gaps: Array[Dictionary]) -> String:
	var parts: Array[String] = [str(_game_state().current_scene_id), str(_game_state().current_chapter_id)]
	for gap in gaps.slice(0, mini(3, gaps.size())):
		parts.append("%s:%d" % [str(gap.get("stat_id", "")), int(gap.get("gap", 0))])
	return _join_limited(parts, "|", parts.size())

func _is_strong_guidance_phase() -> bool:
	return _chapter_index() >= 6

func _chapter_index() -> int:
	var chapter_id := str(_game_state().current_chapter_id)
	var marker := "chapter_"
	if not chapter_id.begins_with(marker):
		return 0
	return int(chapter_id.substr(marker.length()))

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

func _join_limited(values: Array, separator: String, max_count: int) -> String:
	var result := ""
	var count := mini(values.size(), max_count)
	for index in range(count):
		if index > 0:
			result += separator
		result += str(values[index])
	if values.size() > max_count:
		result += " ..."
	return result

func _game_state() -> Node:
	return get_node("/root/GameState")
