class_name PressureEncounter
extends CanvasLayer

signal encounter_finished(next_scene: String)

var _encounter := {}
var _pressure := 0
var _heart := 0
var _preparedness := 0
var _rounds := 0
var _done := false

var _title: Label
var _body: Label
var _stats: Label
var _actions_box: VBoxContainer

var COL_PANEL := Color("111820")
var COL_PANEL_DARK := Color("090d12")
var COL_GOLD := Color("d8a13a")
var COL_GOLD_DARK := Color("59472b")
var COL_GOLD_LIGHT := Color("f0c76f")
var COL_TEXT := Color("f6edd8")
var COL_AI := Color("8be3ff")

func _ready() -> void:
	layer = 45
	_build_ui()
	visible = false

func start(encounter_id: String) -> void:
	_encounter = _chapter_data().get_pressure(encounter_id)
	if _encounter.is_empty():
		return
	_pressure = int(_encounter.get("pressure", 60))
	_heart = int(_encounter.get("heart", 50))
	_preparedness = int(_encounter.get("preparedness", 20))
	_rounds = int(_encounter.get("rounds", 4))
	_done = false
	var route_note := _apply_route_modifiers(encounter_id)
	_title.text = "%s  /  %s" % [str(_encounter.get("title", "")), str(_encounter.get("goal", ""))]
	_body.text = str(_encounter.get("opening", ""))
	if not route_note.is_empty():
		_body.text += "\n\n" + route_note
	visible = true
	_refresh()

func _refresh() -> void:
	_stats.text = "压力 %02d   心力 %02d   准备度 %02d   回合 %d" % [_pressure, _heart, _preparedness, _rounds]
	for child in _actions_box.get_children():
		_actions_box.remove_child(child)
		child.queue_free()

	if _done:
		var continue_button := _action_button("CONTINUE", "safe")
		continue_button.pressed.connect(func() -> void:
			visible = false
			encounter_finished.emit(str(_encounter.get("next_scene", "")))
		)
		_actions_box.add_child(continue_button)
		return

	for action in _encounter.get("actions", []):
		var strategy := str(action.get("strategy", "safe"))
		var button := _action_button(_action_label(str(action.get("label", "")), strategy), strategy)
		var required := int(action.get("requires_preparedness", 0))
		var relationship_requirement: Dictionary = action.get("requires_relationship", {})
		if required > _preparedness:
			button.disabled = true
			button.text += "（准备不足）"
		elif not _relationship_requirement_met(relationship_requirement):
			button.disabled = true
			button.text += "（关系不足）"
		if bool(action.get("ai_recommended", false)):
			button.text = "AI推荐：" + button.text
		button.pressed.connect(func() -> void: _select_action(action))
		_actions_box.add_child(button)

func _select_action(action: Dictionary) -> void:
	var strategy := str(action.get("strategy", "safe"))
	_pressure = clampi(_pressure + int(action.get("pressure_delta", 0)), 0, 100)
	var heart_delta := int(action.get("heart_delta", 0))
	if strategy == "ai":
		heart_delta = -_game_state().get_ai_heart_cost()
	elif heart_delta < 0:
		heart_delta = 0
	_heart = clampi(_heart + heart_delta, 0, 100)
	_preparedness = clampi(_preparedness + int(action.get("preparedness_delta", 0)), 0, 100)
	_rounds -= 1

	var effects: Dictionary = action.get("effects", {})
	var normalized_effects: Dictionary = _game_state().normalized_effects_for_strategy(effects, strategy)
	_game_state().apply_effects(normalized_effects)
	var heart_cost: int = int(_game_state().apply_ai_heart_cost(strategy))
	var choice_result: Dictionary = _game_state().record_choice(
		str(action.get("id", "")),
		strategy,
		str(action.get("label", "")),
		str(action.get("result", "")),
		int(action.get("profile_weight", -1)),
		effects,
	)
	_game_state().log_feedback(_strategy_title(strategy), _effect_summary(normalized_effects, heart_cost, choice_result), strategy)
	_body.text = str(action.get("result", ""))

	if _pressure <= 0:
		_done = true
		var success_effects: Dictionary = _game_state().normalized_effects_for_strategy(_encounter.get("success_effects", {}), "safe")
		_game_state().apply_effects(success_effects)
		_body.text += "\n\n" + str(_encounter.get("success_text", ""))
	elif _heart <= 0 or _rounds <= 0:
		_done = true
		var failure_effects: Dictionary = _game_state().normalized_effects_for_strategy(_encounter.get("failure_effects", {}), "safe")
		_game_state().apply_effects(failure_effects)
		_body.text += "\n\n" + str(_encounter.get("failure_text", ""))

	_refresh()

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.34)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)

	var panel := PanelContainer.new()
	panel.position = Vector2(300, 118)
	panel.size = Vector2(1000, 612)
	panel.add_theme_stylebox_override("panel", _panel_style(_color_alpha("101820", 0.96), COL_GOLD, 5))
	root.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 13)
	margin.add_child(layout)

	_title = _label("", 32, COL_GOLD_LIGHT)
	_title.size = Vector2(940, 46)
	layout.add_child(_title)

	_stats = _label("", 27, COL_AI)
	_stats.size = Vector2(940, 40)
	layout.add_child(_stats)

	_body = _label("", 28, COL_TEXT)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_body.custom_minimum_size = Vector2(940, 245)
	layout.add_child(_body)

	_actions_box = VBoxContainer.new()
	_actions_box.add_theme_constant_override("separation", 10)
	layout.add_child(_actions_box)

func _action_button(text: String, strategy: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(940, 47)
	button.add_theme_font_size_override("font_size", 24)
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

func _action_label(label: String, strategy: String) -> String:
	if strategy != "ai":
		return label
	return "%s（心力 -%d）" % [label, int(_game_state().get_ai_heart_cost())]

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
			return "社会规训"

func _effect_summary(effects: Dictionary, heart_cost: int = 0, choice_result: Dictionary = {}) -> String:
	var parts: Array[String] = []
	if heart_cost > 0:
		parts.append("心力 -%d" % heart_cost)
	var loss: Dictionary = choice_result.get("loss", {})
	if not loss.is_empty():
		parts.append(str(loss.get("summary", "现实代价出现")))
	if effects.has("stats"):
		for key in effects["stats"].keys():
			var delta := int(effects["stats"][key])
			if delta != 0:
				parts.append("%s %+d" % [_stat_name(str(key)), delta])
	if not parts.is_empty():
		return _join_limited(parts, " / ", 3)
	return "压力行动已结算"

func _stat_name(key: String) -> String:
	var names := {
		"heart": "心力",
		"family": "家庭安心",
		"clarity": "自我清晰",
		"ai_dependence": "系统依赖",
		"language_assimilation": "语言同化",
		"resume_score": "履历",
		"stability_score": "稳定",
		"success_progress": "成功路径",
	}
	return str(names.get(key, key))

func _apply_route_modifiers(encounter_id: String) -> String:
	var flags: Dictionary = _game_state().get("flags")
	var notes: Array[String] = []
	if encounter_id == "family_dinner":
		if flags.has("read_board"):
			_preparedness += 8
			notes.append("你读过填报说明，准备度 +8")
		if flags.has("teacher_prepared"):
			_preparedness += 10
			_pressure -= 6
			notes.append("班主任帮你预演过解释，准备度 +10，压力 -6")
		if flags.has("parent_script"):
			_preparedness += 12
			notes.append("家长沟通版说明放在书包里，准备度 +12")

		match str(flags.get("volunteer_done", "")):
			"self":
				_preparedness -= 4
				_pressure += 8
				_heart += 6
				notes.append("手写志愿草稿更难解释，但你知道自己为什么要试：压力 +8，心力 +6")
			"safe":
				_preparedness += 8
				_pressure -= 8
				notes.append("热门计算机路线让父母更容易进入讨论：准备度 +8，压力 -8")
			"ai":
				_preparedness += 14
				_pressure -= 12
				notes.append("AI 方案非常完整，让父母更容易进入讨论：准备度 +14，压力 -12")

	var profile_modifier: Dictionary = _game_state().get_pressure_profile_modifier()
	if not profile_modifier.is_empty():
		_pressure += int(profile_modifier.get("pressure_delta", 0))
		_preparedness += int(profile_modifier.get("preparedness_delta", 0))
		notes.append(str(profile_modifier.get("note", "")))

	_pressure = clampi(_pressure, 0, 100)
	_heart = clampi(_heart, 0, 100)
	_preparedness = clampi(_preparedness, 0, 100)

	if notes.is_empty():
		return ""
	return "前置选择影响：" + _join_limited(notes, "；", 4)

func _relationship_requirement_met(requirement: Dictionary) -> bool:
	if requirement.is_empty():
		return true
	var friend_id := str(requirement.get("friend_id", ""))
	var min_warmth := int(requirement.get("warmth", 0))
	if friend_id.is_empty():
		return true
	var relationships: Dictionary = _game_state().get("relationships")
	if not relationships.has(friend_id):
		return false
	var relation: Dictionary = relationships[friend_id]
	return int(relation.get("warmth", 0)) >= min_warmth

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
