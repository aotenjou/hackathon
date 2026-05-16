class_name DialoguePanel
extends CanvasLayer

signal dialogue_closed
signal scene_requested(scene_id: String)

var _panel: PanelContainer
var _speaker_label: Label
var _line_label: Label
var _choices_box: VBoxContainer
var _active_dialogue := {}
var _pending_scene := ""

var COL_PANEL := Color("111820")
var COL_PANEL_DARK := Color("090d12")
var COL_GOLD := Color("d8a13a")
var COL_GOLD_DARK := Color("59472b")
var COL_GOLD_LIGHT := Color("f0c76f")
var COL_TEXT := Color("f6edd8")
var COL_TEXT_DIM := Color("d8caa8")
var COL_AI := Color("8be3ff")

func _ready() -> void:
	layer = 40
	_build_ui()
	hide_dialogue()

func show_dialogue(dialogue_id: String) -> void:
	var dialogue: Dictionary = _chapter_data().get_dialogue(dialogue_id)
	if dialogue.is_empty():
		return
	_active_dialogue = dialogue
	_pending_scene = ""
	_speaker_label.text = str(dialogue.get("speaker", ""))
	_line_label.text = _resolve_line(dialogue)
	_rebuild_choices(dialogue.get("choices", []))
	visible = true

func hide_dialogue() -> void:
	visible = false

func _rebuild_choices(choices: Array) -> void:
	for child in _choices_box.get_children():
		_choices_box.remove_child(child)
		child.queue_free()

	if choices.is_empty():
		var close_button := _choice_button("继续", "safe")
		close_button.pressed.connect(_close_or_advance)
		_choices_box.add_child(close_button)
		return

	for choice in choices:
		var button := _choice_button(str(choice.get("label", "")), str(choice.get("strategy", "safe")))
		button.pressed.connect(func() -> void: _select_choice(choice))
		_choices_box.add_child(button)

func _select_choice(choice: Dictionary) -> void:
	var effects: Dictionary = choice.get("effects", {})
	_game_state().apply_effects(effects)
	_game_state().record_choice(
		str(choice.get("id", "")),
		str(choice.get("strategy", "")),
		str(choice.get("label", "")),
		str(choice.get("result", "")),
	)

	var feedback_title := _strategy_title(str(choice.get("strategy", "safe")))
	_game_state().log_feedback(feedback_title, _effect_summary(effects), str(choice.get("strategy", "safe")))

	_speaker_label.text = feedback_title
	_line_label.text = str(choice.get("result", ""))
	_pending_scene = str(choice.get("next_scene", ""))

	for child in _choices_box.get_children():
		_choices_box.remove_child(child)
		child.queue_free()
	var continue_button := _choice_button("继续", "safe")
	continue_button.pressed.connect(_close_or_advance)
	_choices_box.add_child(continue_button)

func _close_or_advance() -> void:
	visible = false
	if not _pending_scene.is_empty():
		scene_requested.emit(_pending_scene)
	else:
		dialogue_closed.emit()

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	_panel = PanelContainer.new()
	_panel.position = Vector2(230, 612)
	_panel.size = Vector2(1140, 250)
	_panel.add_theme_stylebox_override("panel", _panel_style(_color_alpha("111820", 0.96), COL_GOLD, 5))
	root.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	_panel.add_child(margin)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 18)
	margin.add_child(columns)

	var avatar := PanelContainer.new()
	avatar.custom_minimum_size = Vector2(128, 164)
	avatar.add_theme_stylebox_override("panel", _panel_style(Color("233044"), COL_GOLD_DARK, 4))
	columns.add_child(avatar)

	var avatar_label := _label("许临", 28, COL_TEXT)
	avatar_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar.add_child(avatar_label)

	var text_box := VBoxContainer.new()
	text_box.custom_minimum_size = Vector2(575, 200)
	text_box.add_theme_constant_override("separation", 8)
	columns.add_child(text_box)

	_speaker_label = _label("", 27, COL_GOLD_LIGHT)
	_speaker_label.size = Vector2(550, 34)
	text_box.add_child(_speaker_label)

	_line_label = _label("", 27, COL_TEXT)
	_line_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_line_label.size = Vector2(575, 150)
	text_box.add_child(_line_label)

	_choices_box = VBoxContainer.new()
	_choices_box.custom_minimum_size = Vector2(350, 200)
	_choices_box.add_theme_constant_override("separation", 9)
	columns.add_child(_choices_box)

func _choice_button(text: String, strategy: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(350, 45)
	button.add_theme_font_size_override("font_size", 21)
	button.add_theme_color_override("font_color", COL_TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", COL_GOLD_LIGHT)
	button.add_theme_color_override("font_shadow_color", Color("05070a"))
	button.add_theme_constant_override("shadow_offset_x", 2)
	button.add_theme_constant_override("shadow_offset_y", 2)
	var border := COL_GOLD_DARK
	var bg := Color("1d2630")
	if strategy == "self":
		border = Color("7fb47a")
	elif strategy == "ai":
		border = COL_AI
		bg = Color("0c2433")
	button.add_theme_stylebox_override("normal", _panel_style(bg, border, 3))
	button.add_theme_stylebox_override("hover", _panel_style(Color("273444"), border.lightened(0.18), 3))
	button.add_theme_stylebox_override("pressed", _panel_style(COL_PANEL_DARK, COL_GOLD_LIGHT, 4))
	return button

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color("05070a"))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label

func _panel_style(bg: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(width)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

func _color_alpha(hex: String, alpha: float) -> Color:
	var color := Color(hex)
	color.a = alpha
	return color

func _strategy_title(strategy: String) -> String:
	match strategy:
		"self":
			return "自由探索"
		"ai":
			return "智能优化"
		_:
			return "稳妥执行"

func _effect_summary(effects: Dictionary) -> String:
	var parts: Array[String] = []
	if effects.has("stats"):
		for key in effects["stats"].keys():
			var delta := int(effects["stats"][key])
			if delta == 0:
				continue
			parts.append("%s %+d" % [_stat_name(str(key)), delta])
	if effects.has("items"):
		for item in effects["items"]:
			parts.append("获得 %s" % str(item))
	if parts.is_empty():
		return "选择已记录"
	return _join_limited(parts, " / ", 3)

func _stat_name(key: String) -> String:
	var names := {
		"heart": "心力",
		"sleep": "睡眠",
		"family": "家庭安心",
		"clarity": "自我清晰",
		"ai_dependence": "系统依赖",
		"language_assimilation": "语言同化",
		"ability_exp": "能力",
		"resume_score": "履历",
		"network_score": "人脉",
		"wealth_score": "财富",
		"stability_score": "稳定",
		"success_progress": "成功路径",
	}
	return str(names.get(key, key))

func _resolve_line(dialogue: Dictionary) -> String:
	var dynamic_line := str(dialogue.get("dynamic_line", ""))
	if dynamic_line == "vertical_slice_summary":
		return _vertical_slice_summary()
	if dynamic_line == "graduation_gate_summary":
		return _graduation_gate_summary()
	return str(dialogue.get("line", ""))

func _vertical_slice_summary() -> String:
	var state := _game_state()
	var flags: Dictionary = state.get("flags")
	var stats: Dictionary = state.get("stats")
	var strategy_counts := {"self": 0, "safe": 0, "ai": 0}
	for choice in state.get("choice_history"):
		var strategy := str(choice.get("strategy", ""))
		if strategy_counts.has(strategy):
			strategy_counts[strategy] = int(strategy_counts[strategy]) + 1

	var lines: Array[String] = []
	lines.append("志愿路线：%s；饭桌结果：%s。" % [
		_volunteer_summary(str(flags.get("volunteer_done", ""))),
		_dinner_summary(str(flags.get("family_dinner_done", ""))),
	])
	lines.append("毕业前你留下了%s，也把最后一段时间给了%s。" % [
		_message_summary(str(flags.get("message_done", ""))),
		_friend_summary(str(flags.get("friend_time", ""))),
	])
	lines.append("阶段倾向：自主 %d / 稳妥 %d / AI %d；清晰 %d，家庭安心 %d，系统依赖 %d。" % [
		int(strategy_counts["self"]),
		int(strategy_counts["safe"]),
		int(strategy_counts["ai"]),
		int(stats.get("clarity", 0)),
		int(stats.get("family", 0)),
		int(stats.get("ai_dependence", 0)),
	])
	return "\n".join(lines)

func _graduation_gate_summary() -> String:
	var flags: Dictionary = _game_state().get("flags")
	var missing: Array[String] = []
	if not flags.has("message_done"):
		missing.append("毕业留言")
	if not flags.has("friend_time"):
		missing.append("朋友时间")
	if missing.is_empty():
		return "摄影师已经举起相机。现在可以拍下这张阶段结算照片。"
	return "摄影师已经举起相机，但这个下午还缺少：%s。先完成它们，再让镜头定格。" % _join_limited(missing, "、", 2)

func _volunteer_summary(value: String) -> String:
	match value:
		"self":
			return "保留了不完整但属于自己的草稿"
		"safe":
			return "选择了家里更容易接受的热门路线"
		"ai":
			return "交给 AI 生成就业最大化方案"
		_:
			return "尚未形成清晰志愿"

func _dinner_summary(value: String) -> String:
	match value:
		"success":
			return "父母愿意让你先试一次"
		"failure":
			return "很多话仍停在饭桌上"
		_:
			return "还没有真正解释清楚"

func _message_summary(value: String) -> String:
	match value:
		"self":
			return "一张手写留言"
		"safe":
			return "一句体面的标准留言"
		"ai":
			return "一段完整但有些陌生的 AI 留言"
		_:
			return "空白留言"

func _friend_summary(value: String) -> String:
	match value:
		"linzhou":
			return "林舟未完成的游戏"
		"zhouxiao":
			return "校门口的冰水"
		"heqilang":
			return "优秀毕业生资料"
		"ai":
			return "系统排序后的关系清单"
		_:
			return "尚未选择的人"

func _join_limited(values: Array[String], separator: String, max_count: int) -> String:
	var result := ""
	var count := mini(values.size(), max_count)
	for index in range(count):
		if index > 0:
			result += separator
		result += values[index]
	return result

func _game_state() -> Node:
	return get_node("/root/GameState")

func _chapter_data() -> Node:
	return get_node("/root/ChapterData")
