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
var _page_lines: Array[String] = []
var _page_index := 0

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
	_page_lines = _resolve_pages(dialogue)
	_page_index = 0
	_speaker_label.text = str(dialogue.get("speaker", ""))
	_line_label.text = _current_page_text()
	_rebuild_choices(dialogue.get("choices", []))
	visible = true

func hide_dialogue() -> void:
	visible = false

func _rebuild_choices(choices: Array) -> void:
	for child in _choices_box.get_children():
		_choices_box.remove_child(child)
		child.queue_free()

	if choices.is_empty():
		var close_button := _choice_button("CONTINUE", "safe")
		close_button.pressed.connect(_close_or_advance)
		_choices_box.add_child(close_button)
		return

	for choice in choices:
		if _choice_is_used(choice):
			continue
		var strategy := str(choice.get("strategy", "safe"))
		var button := _choice_button(_choice_label(str(choice.get("label", "")), strategy), strategy)
		button.pressed.connect(func() -> void: _select_choice(choice))
		_choices_box.add_child(button)

	if _choices_box.get_child_count() == 0:
		var close_button := _choice_button("CONTINUE", "safe")
		close_button.pressed.connect(_close_or_advance)
		_choices_box.add_child(close_button)

func _select_choice(choice: Dictionary) -> void:
	if bool(choice.get("auto_final_ending", false)):
		_select_auto_final_ending(choice)
		return
	if _choice_is_used(choice):
		return
	if _game_state().choice_affects_values(choice):
		var key := _choice_interaction_key(choice)
		if not _game_state().try_mark_value_interaction(key, {
			"kind": "dialogue_choice",
			"id": str(choice.get("id", "")),
			"label": str(choice.get("label", "")),
		}):
			return

	var strategy := str(choice.get("strategy", "safe"))
	var effects: Dictionary = choice.get("effects", {})
	var normalized_effects: Dictionary = _game_state().normalized_effects_for_strategy(effects, strategy)
	_game_state().apply_effects(normalized_effects)
	var heart_cost: int = int(_game_state().apply_ai_heart_cost(strategy))
	var choice_result: Dictionary = _game_state().record_choice(
		str(choice.get("id", "")),
		strategy,
		str(choice.get("label", "")),
		str(choice.get("result", "")),
		int(choice.get("profile_weight", -1)),
		effects,
	)

	var feedback_title := _strategy_title(strategy)
	_game_state().log_feedback(feedback_title, _effect_summary(normalized_effects, heart_cost, choice_result), strategy)

	_speaker_label.text = feedback_title
	_line_label.text = str(choice.get("result", ""))
	_pending_scene = str(choice.get("next_scene", ""))

	for child in _choices_box.get_children():
		_choices_box.remove_child(child)
		child.queue_free()
	var continue_button := _choice_button("CONTINUE", "safe")
	continue_button.pressed.connect(_close_or_advance)
	_choices_box.add_child(continue_button)

func _select_auto_final_ending(choice: Dictionary) -> void:
	if _choice_is_used(choice):
		return
	var key := _choice_interaction_key(choice)
	if not _game_state().try_mark_value_interaction(key, {
		"kind": "dialogue_choice",
		"id": str(choice.get("id", "ending_auto_resolve")),
		"label": str(choice.get("label", "生成最终结局")),
	}):
		return
	var ending_data: Dictionary = _game_state().apply_final_ending()
	var strategy := str(ending_data.get("strategy", "safe"))
	var result_text := str(ending_data.get("result", ""))
	_game_state().record_choice(
		str(choice.get("id", "ending_auto_resolve")),
		strategy,
		str(choice.get("label", "生成最终结局")),
		result_text,
		0,
		{},
	)
	_game_state().log_feedback(_strategy_title(strategy), str(ending_data.get("title", "结局已生成")), strategy)

	_speaker_label.text = str(ending_data.get("title", _strategy_title(strategy)))
	_line_label.text = result_text
	_pending_scene = str(choice.get("next_scene", ""))

	for child in _choices_box.get_children():
		_choices_box.remove_child(child)
		child.queue_free()
	var continue_button := _choice_button("CONTINUE", "safe")
	continue_button.pressed.connect(_close_or_advance)
	_choices_box.add_child(continue_button)

func _close_or_advance() -> void:
	if _advance_page():
		return
	visible = false
	if not _pending_scene.is_empty():
		scene_requested.emit(_pending_scene)
	else:
		dialogue_closed.emit()

func _advance_page() -> bool:
	if _page_index + 1 >= _page_lines.size():
		return false
	_page_index += 1
	_line_label.text = _current_page_text()
	return true

func _current_page_text() -> String:
	if _page_lines.is_empty():
		return ""
	return _page_lines[clampi(_page_index, 0, _page_lines.size() - 1)]

func _choice_is_used(choice: Dictionary) -> bool:
	if not _game_state().choice_affects_values(choice):
		return false
	return _game_state().has_used_value_interaction(_choice_interaction_key(choice))

func _choice_interaction_key(choice: Dictionary) -> String:
	return _game_state().value_interaction_key("dialogue_choice", str(choice.get("id", "")))

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

func _choice_label(label: String, strategy: String) -> String:
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
		"family": "家庭安心",
		"clarity": "自我清晰",
		"ai_dependence": "AI依赖",
		"resume_score": "职业资本",
		"network_score": "人脉资源",
		"stability_score": "稳定适配",
	}
	return str(names.get(key, key))

func _resolve_line(dialogue: Dictionary) -> String:
	var dynamic_line := str(dialogue.get("dynamic_line", ""))
	if dynamic_line == "vertical_slice_summary":
		return _vertical_slice_summary()
	if dynamic_line == "graduation_gate_summary":
		return _graduation_gate_summary()
	if dynamic_line == "friend_tag_overlay":
		return _friend_tag_overlay()
	if dynamic_line == "final_friend_echoes":
		return _final_friend_echoes()
	if dynamic_line == "final_life_summary":
		return _final_life_summary()
	if dynamic_line == "final_auto_ending":
		return _final_auto_ending()
	if dynamic_line == "final_field_epilogue":
		return "\n".join(_final_field_epilogue_pages())
	return str(dialogue.get("line", ""))

func _resolve_pages(dialogue: Dictionary) -> Array[String]:
	var dynamic_line := str(dialogue.get("dynamic_line", ""))
	if dynamic_line == "final_field_epilogue":
		return _final_field_epilogue_pages()
	var pages: Array[String] = []
	for page in dialogue.get("pages", []):
		var page_text := str(page)
		if not page_text.is_empty():
			pages.append(page_text)
	if pages.is_empty():
		pages.append(_resolve_line(dialogue))
	return pages

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
	lines.append("阶段倾向：自主 %d / 稳妥 %d / AI %d；清晰 %d，家庭安心 %d，AI依赖 %d。" % [
		int(strategy_counts["self"]),
		int(strategy_counts["safe"]),
		int(strategy_counts["ai"]),
		int(stats.get("clarity", 0)),
		int(stats.get("family", 0)),
		int(stats.get("ai_dependence", 0)),
	])
	var profile: Dictionary = state.get_route_profile()
	var percents: Dictionary = profile.get("percents", {})
	lines.append("路径权重：自我 %d / 规训 %d / AI %d；%s" % [
		int(percents.get("self", 0)),
		int(percents.get("safe", 0)),
		int(percents.get("ai", 0)),
		state.get_realistic_loss_summary(),
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

func _friend_tag_overlay() -> String:
	var relationships: Dictionary = _game_state().get("relationships")
	var flags: Dictionary = _game_state().get("flags")
	var lines: Array[String] = []
	lines.append("标签覆盖已启用。现实对话被压缩成系统摘要：")
	lines.append(_tag_line("linzhou", "林舟", "收益路径不稳定", "试玩包记忆闪回", relationships, flags.has("friend_samples_seen")))
	lines.append(_tag_line("zhouxiao", "周骁", "履约风险偏高", "校门口冰水闪回", relationships, flags.has("friend_time") and str(flags.get("friend_time", "")) == "zhouxiao"))
	lines.append(_tag_line("heqilang", "何启朗", "高适配推广对象", "内推链接闪回", relationships, flags.has("ready_for_interview")))
	lines.append(_tag_line("shenyou", "沈柚", "机构协同关键人", "留言墙胶带闪回", relationships, int(relationships.get("shenyou", {}).get("warmth", 0)) >= 50))
	lines.append(_tag_line("chenwang", "陈望", "家庭责任负载较高", "普通生活照片闪回", relationships, int(relationships.get("chenwang", {}).get("warmth", 0)) >= 40))
	return "\n".join(lines)

func _final_friend_echoes() -> String:
	var relationships: Dictionary = _game_state().get("relationships")
	var lines: Array[String] = []
	lines.append("朋友回声不是评分项，它们只要求你重新面对关系。")
	lines.append(_echo_line("linzhou", "林舟", "还没回复的试玩包", relationships))
	lines.append(_echo_line("zhouxiao", "周骁", "凌晨两点维修摊语音", relationships))
	lines.append(_echo_line("heqilang", "何启朗", "非常得体的祝贺", relationships))
	lines.append(_echo_line("shenyou", "沈柚", "被系统润色过的风险说明", relationships))
	lines.append(_echo_line("chenwang", "陈望", "一张普通生活照片", relationships))
	return "\n".join(lines)

func _final_life_summary() -> String:
	var state := _game_state()
	var profile: Dictionary = state.get_route_profile()
	var percents: Dictionary = profile.get("percents", {})
	var resolved: Dictionary = state.resolve_final_ending()
	var scores: Dictionary = resolved.get("scores", {})
	var lines: Array[String] = []
	lines.append("系统已生成成功人生总结：选择稳健、表达成熟、关系高效、风险可控。")
	lines.append("路径权重：自我 %d / 社会规训 %d / AI %d。" % [
		int(percents.get("self", 0)),
		int(percents.get("safe", 0)),
		int(percents.get("ai", 0)),
	])
	lines.append("%s" % state.get_realistic_loss_summary())
	lines.append("结局倾向评分：自我 %.1f / 规训 %.1f / AI %.1f。" % [
		float(scores.get("self", 0.0)),
		float(scores.get("safe", 0.0)),
		float(scores.get("ai", 0.0)),
	])
	return "\n".join(lines)

func _final_auto_ending() -> String:
	var resolved: Dictionary = _game_state().resolve_final_ending()
	var profile: Dictionary = resolved.get("profile", {})
	var percents: Dictionary = profile.get("percents", {})
	var ending := str(resolved.get("ending", "coexistence"))
	var ending_name := "保留人工复核"
	if ending == "self_return":
		ending_name = "亲自到场"
	elif ending == "optimized_life":
		ending_name = "接受最优人生"
	return "最终结局将由全程路径自动生成。\n路径权重：自我 %d / 社会规训 %d / AI %d。\n当前判定倾向：%s。" % [
		int(percents.get("self", 0)),
		int(percents.get("safe", 0)),
		int(percents.get("ai", 0)),
		ending_name,
	]

func _final_field_epilogue_pages() -> Array[String]:
	var ending := str(_game_state().flags.get("final_ending", "coexistence"))
	match ending:
		"self_return":
			return [
				"风声没有替你总结什么。",
				"你看见一片田野，才想起自己不是一份完成度报告。",
				"有些话迟到了很多年，仍然可以由你亲口说出。",
				"我不知道这是不是正确选择，但这是我说的。",
			]
		"optimized_life":
			return [
				"田野安静得像一段没有被上传的数据。",
				"系统已经替你保留了最优路径，也替你省去了许多犹豫。",
				"可风仍然吹过来，像一个没有收益的问题。",
				"如果有一天你想回答，它还会在这里。",
			]
		_:
			return [
				"风从田野上过来，屏幕没有消失，只是退远了一点。",
				"你还会使用系统，也还会被它影响。",
				"但这一次，你把没有把握的部分留给了自己。",
				"自我不是完全正确，而是愿意亲自承担。",
			]

func _tag_line(friend_id: String, friend_name: String, tag: String, memory: String, relationships: Dictionary, has_memory: bool) -> String:
	var relation: Dictionary = relationships.get(friend_id, {})
	var warmth := int(relation.get("warmth", 0))
	if has_memory or warmth >= 55:
		return "%s：%s；%s。" % [friend_name, tag, memory]
	return "%s：%s；无可用具体记忆。" % [friend_name, tag]

func _echo_line(friend_id: String, friend_name: String, echo_text: String, relationships: Dictionary) -> String:
	var relation: Dictionary = relationships.get(friend_id, {})
	var warmth := int(relation.get("warmth", 0))
	var utility := int(relation.get("utility", 0))
	if warmth > utility + 18:
		return "%s：%s，仍带着具体的声音。" % [friend_name, echo_text]
	if utility > warmth:
		return "%s：%s，被系统摘要为待处理关系。" % [friend_name, echo_text]
	return "%s：%s，停在总结边缘。" % [friend_name, echo_text]

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
