extends Node

signal stats_changed
signal relationship_changed(friend_id: String)
signal inventory_changed
signal objective_changed
signal chapter_changed(chapter_id: String)
signal ui_phase_changed(phase: String)
signal settlement_logged(entry: Dictionary)
signal feedback_logged(entry: Dictionary)
signal route_profile_changed

const STRATEGY_SELF := "self"
const STRATEGY_SAFE := "safe"
const STRATEGY_AI := "ai"
const STAT_HEART := "heart"
const ALIENATION_MODE_NORMAL := "normal"
const ALIENATION_MODE_FLICKER := "flicker"
const ALIENATION_MODE_PERSISTENT := "persistent"
const ALIENATION_PERSISTENT_HEART_MAX := 25
const ALIENATION_PERSISTENT_AI_MIN := 70
const ALIENATION_FLICKER_START_CHAPTER := 5
const ALIENATION_FLICKER_END_CHAPTER := 8
const ROUTE_KEYS := [STRATEGY_SELF, STRATEGY_SAFE, STRATEGY_AI]
const ROUTE_LABELS := {
	"self": "自我选择",
	"safe": "社会规训",
	"ai": "AI提醒",
}
const SUCCESS_TARGETS := {
	"ability_exp": 82,
	"resume_score": 92,
	"network_score": 71,
	"wealth_score": 88,
	"stability_score": 96,
	"success_progress": 100,
}
const SUCCESS_LABELS := {
	"ability_exp": "能力",
	"resume_score": "履历",
	"network_score": "人脉",
	"wealth_score": "财富",
	"stability_score": "稳定",
	"success_progress": "成功路径",
}

var current_chapter_id := "chapter_0"
var current_scene_id := "cruise_deck"
var current_objective := "打开人生回放，回到高三关键节点"
var current_time := "22:40"
var current_location := "邮轮甲板"
var ai_stage := 0
var ui_phase := "success_path"

var stats := {
	"heart": 42,
	"sleep": 72,
	"family": 40,
	"clarity": 58,
	"ai_dependence": 12,
	"language_assimilation": 4,
	"ability_exp": 82,
	"resume_score": 92,
	"network_score": 71,
	"wealth_score": 88,
	"stability_score": 96,
	"success_progress": 100,
}

var skills := {
	"programming": 1,
	"expression": 1,
	"resume_packaging": 1,
	"social": 1,
	"ai_collaboration": 1,
}

var relationships := {
	"linzhou": {"name": "林舟", "warmth": 48, "utility": 12},
	"zhouxiao": {"name": "周骁", "warmth": 36, "utility": 8},
	"heqilang": {"name": "何启朗", "warmth": 38, "utility": 30},
	"shenyou": {"name": "沈柚", "warmth": 44, "utility": 16},
	"chenwang": {"name": "陈望", "warmth": 34, "utility": 6},
}

var inventory: Array[String] = []
var flags := {}
var wishes := {
	"current": "打开人生回放",
	"completed": [],
}
var emotion_cards: Array[String] = []
var settlement_history: Array[Dictionary] = []
var choice_history: Array[Dictionary] = []
var feedback_log: Array[Dictionary] = []
var route_counts := {"self": 0, "safe": 0, "ai": 0}
var route_weights := {"self": 0, "safe": 0, "ai": 0}
var realistic_losses: Array[Dictionary] = []

func reset_for_new_game() -> void:
	current_chapter_id = "chapter_0"
	current_scene_id = "cruise_deck"
	current_objective = "打开人生回放，回到高三关键节点"
	current_time = "22:40"
	current_location = "邮轮甲板"
	ai_stage = 0
	ui_phase = "success_path"
	stats = {
		"heart": 42,
		"sleep": 72,
		"family": 40,
		"clarity": 58,
		"ai_dependence": 12,
		"language_assimilation": 4,
		"ability_exp": 82,
		"resume_score": 92,
		"network_score": 71,
		"wealth_score": 88,
		"stability_score": 96,
		"success_progress": 100,
	}
	relationships = {
		"linzhou": {"name": "林舟", "warmth": 48, "utility": 12},
		"zhouxiao": {"name": "周骁", "warmth": 36, "utility": 8},
		"heqilang": {"name": "何启朗", "warmth": 38, "utility": 30},
		"shenyou": {"name": "沈柚", "warmth": 44, "utility": 16},
		"chenwang": {"name": "陈望", "warmth": 34, "utility": 6},
	}
	inventory.clear()
	flags.clear()
	wishes = {
		"current": "打开人生回放",
		"completed": [],
	}
	emotion_cards.clear()
	settlement_history.clear()
	choice_history.clear()
	feedback_log.clear()
	route_counts = {"self": 0, "safe": 0, "ai": 0}
	route_weights = {"self": 0, "safe": 0, "ai": 0}
	realistic_losses.clear()
	stats_changed.emit()
	inventory_changed.emit()
	objective_changed.emit()
	ui_phase_changed.emit(ui_phase)
	route_profile_changed.emit()
	chapter_changed.emit(current_chapter_id)

func set_context(chapter_id: String, scene_id: String, location: String, time_label: String, objective: String, phase_override: String = "") -> void:
	current_chapter_id = chapter_id
	current_scene_id = scene_id
	current_location = location
	current_time = time_label
	current_objective = objective
	if not phase_override.is_empty():
		set_ui_phase(phase_override)
	objective_changed.emit()
	chapter_changed.emit(chapter_id)

func apply_effects(effects: Dictionary) -> void:
	if effects.has("stats"):
		for key in effects["stats"].keys():
			adjust_stat(key, int(effects["stats"][key]), false)
		stats_changed.emit()

	if effects.has("skills"):
		for key in effects["skills"].keys():
			skills[key] = max(0, int(skills.get(key, 0)) + int(effects["skills"][key]))

	if effects.has("relationships"):
		for friend_id in effects["relationships"].keys():
			var relation_effect: Dictionary = effects["relationships"][friend_id]
			adjust_relationship(friend_id, int(relation_effect.get("warmth", 0)), int(relation_effect.get("utility", 0)), false)
			relationship_changed.emit(friend_id)

	if effects.has("items"):
		for item in effects["items"]:
			add_item(str(item), false)
		inventory_changed.emit()

	if effects.has("flags"):
		for key in effects["flags"].keys():
			flags[key] = effects["flags"][key]

	if effects.has("ai_stage"):
		ai_stage = max(ai_stage, int(effects["ai_stage"]))

	if effects.has("ui_phase"):
		set_ui_phase(str(effects["ui_phase"]))

	if effects.has("wishes"):
		_apply_wish_effects(effects["wishes"])
		objective_changed.emit()

	if effects.has("emotion_cards"):
		_apply_emotion_card_effects(effects["emotion_cards"])
		objective_changed.emit()

	if effects.has("settlement"):
		var settlement_data: Dictionary = effects["settlement"]
		record_settlement(
			str(settlement_data.get("id", "")),
			str(settlement_data.get("title", "阶段结算")),
			str(settlement_data.get("body", "")),
			str(settlement_data.get("kind", "info"))
		)

func normalized_effects_for_strategy(effects: Dictionary, strategy: String) -> Dictionary:
	var normalized := effects.duplicate(true)
	if not normalized.has("stats"):
		return normalized

	var stat_effects: Dictionary = normalized["stats"].duplicate(true)
	if stat_effects.has(STAT_HEART):
		var heart_delta := int(stat_effects[STAT_HEART])
		if strategy == STRATEGY_AI or heart_delta < 0:
			stat_effects.erase(STAT_HEART)

	if stat_effects.is_empty():
		normalized.erase("stats")
	else:
		normalized["stats"] = stat_effects
	return normalized

func get_ai_heart_cost() -> int:
	if ai_stage >= 8:
		return 6
	if ai_stage >= 6:
		return 5
	if ai_stage >= 4:
		return 4
	if ai_stage >= 2:
		return 3
	return 2

func apply_ai_heart_cost(strategy: String, emit_signal: bool = true) -> int:
	if strategy != STRATEGY_AI:
		return 0
	var before := int(stats.get(STAT_HEART, 0))
	adjust_stat(STAT_HEART, -get_ai_heart_cost(), emit_signal)
	return before - int(stats.get(STAT_HEART, 0))

func get_route_profile() -> Dictionary:
	var total_weight := 0
	for key in ROUTE_KEYS:
		total_weight += int(route_weights.get(key, 0))

	var ratios := {}
	var percents := {}
	var dominant := STRATEGY_SAFE
	var dominant_weight := -1
	for key in ROUTE_KEYS:
		var weight := int(route_weights.get(key, 0))
		var ratio := 0.0
		if total_weight > 0:
			ratio = float(weight) / float(total_weight)
		ratios[key] = ratio
		percents[key] = int(round(ratio * 100.0))
		if weight > dominant_weight:
			dominant = key
			dominant_weight = weight

	return {
		"counts": route_counts.duplicate(true),
		"weights": route_weights.duplicate(true),
		"ratios": ratios,
		"percents": percents,
		"total_weight": total_weight,
		"dominant": dominant,
		"dominant_label": str(ROUTE_LABELS.get(dominant, dominant)),
		"self_friction_tier": get_self_friction_tier(),
	}

func get_self_friction_tier() -> int:
	var total_weight := _total_route_weight()
	if total_weight <= 0:
		return 0
	var self_weight := int(route_weights.get(STRATEGY_SELF, 0))
	var self_ratio := float(self_weight) / float(total_weight)
	if self_weight >= 14 and self_ratio >= 0.65:
		return 3
	if self_weight >= 10 and self_ratio >= 0.55:
		return 2
	if self_weight >= 6 and self_ratio >= 0.45:
		return 1
	return 0

func get_realistic_loss_summary() -> String:
	if realistic_losses.is_empty():
		return "现实代价：暂未形成明显失利。"
	var latest: Dictionary = realistic_losses[realistic_losses.size() - 1]
	return "现实代价：已记录 %d 次；最近一次是%s。" % [
		realistic_losses.size(),
		str(latest.get("summary", "某个机会被推远")),
	]

func get_pressure_profile_modifier() -> Dictionary:
	var profile := get_route_profile()
	var total_weight := int(profile.get("total_weight", 0))
	if total_weight < 4:
		return {}

	var dominant := str(profile.get("dominant", ""))
	var ratios: Dictionary = profile.get("ratios", {})
	if dominant == STRATEGY_SELF:
		var tier := get_self_friction_tier()
		if tier >= 3:
			return {
				"pressure_delta": 10,
				"preparedness_delta": -8,
				"note": "你已经多次按自己的想法行动，现实评价系统更难配合你：压力 +10，准备度 -8",
			}
		if tier >= 2:
			return {
				"pressure_delta": 6,
				"preparedness_delta": -4,
				"note": "自主选择留下了具体记忆，也让当前场面更难解释：压力 +6，准备度 -4",
			}
	elif dominant == STRATEGY_SAFE and float(ratios.get(STRATEGY_SAFE, 0.0)) >= 0.55:
		return {
			"pressure_delta": -3,
			"preparedness_delta": 3,
			"note": "社会规训让场面更可控：压力 -3，准备度 +3",
		}
	elif dominant == STRATEGY_AI and float(ratios.get(STRATEGY_AI, 0.0)) >= 0.55:
		return {
			"pressure_delta": -4,
			"preparedness_delta": 5,
			"note": "AI 提醒降低了执行难度：压力 -4，准备度 +5",
		}
	return {}

func resolve_final_ending() -> Dictionary:
	var profile := get_route_profile()
	var ratios: Dictionary = profile.get("ratios", {})
	var clarity := int(stats.get("clarity", 0))
	var ai_dependence := int(stats.get("ai_dependence", 0))
	var language_assimilation := int(stats.get("language_assimilation", 0))
	var stability := int(stats.get("stability_score", 0))
	var success_progress := int(stats.get("success_progress", 0))
	var memory_count := _memory_anchor_count()
	var guardrail_count := _guardrail_count()
	var success_gap := _total_success_gap()

	var self_score := float(ratios.get(STRATEGY_SELF, 0.0)) * 100.0 + float(clarity) * 0.35 + float(memory_count) * 5.0 - float(success_gap) * 0.25
	var safe_score := float(ratios.get(STRATEGY_SAFE, 0.0)) * 100.0 + float(stability) * 0.3 + float(guardrail_count) * 5.0
	var ai_score := float(ratios.get(STRATEGY_AI, 0.0)) * 100.0 + float(ai_dependence) * 0.35 + float(language_assimilation) * 0.35 + float(success_progress) * 0.15

	var ending := "coexistence"
	if str(flags.get("life_upload", "")) == "uploaded" or str(flags.get("life_summary", "")) == "accepted":
		ending = "optimized_life"
	elif ai_score >= self_score and ai_score >= safe_score:
		ending = "optimized_life"
	elif ai_dependence >= 70:
		ending = "optimized_life"
	elif self_score >= safe_score and self_score >= ai_score and clarity >= 55 and memory_count >= 2:
		ending = "self_return"

	return {
		"ending": ending,
		"scores": {
			"self": self_score,
			"safe": safe_score,
			"ai": ai_score,
		},
		"memory_count": memory_count,
		"guardrail_count": guardrail_count,
		"success_gap": success_gap,
		"profile": profile,
	}

func apply_final_ending() -> Dictionary:
	var resolved := resolve_final_ending()
	var ending := str(resolved.get("ending", "coexistence"))
	var result := _final_ending_result_text(ending, resolved)
	var effects := _final_ending_effects(ending, result)
	apply_effects(effects)
	return {
		"ending": ending,
		"strategy": _strategy_for_ending(ending),
		"title": _final_ending_title(ending),
		"result": result,
		"effects": effects,
		"resolved": resolved,
	}

func get_success_targets() -> Dictionary:
	return SUCCESS_TARGETS.duplicate(true)

func get_success_gaps() -> Array[Dictionary]:
	var gaps: Array[Dictionary] = []
	for stat_id in SUCCESS_TARGETS.keys():
		var target := int(SUCCESS_TARGETS[stat_id])
		var current := int(stats.get(stat_id, 0))
		var gap := target - current
		if gap <= 0:
			continue
		gaps.append({
			"stat_id": str(stat_id),
			"label": str(SUCCESS_LABELS.get(stat_id, stat_id)),
			"current": current,
			"target": target,
			"gap": gap,
			"severity": _success_gap_severity(gap),
			"message": _success_gap_message(str(stat_id), gap),
		})
	gaps.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("gap", 0)) > int(b.get("gap", 0))
	)
	return gaps

func get_primary_success_gap() -> Dictionary:
	var gaps: Array[Dictionary] = get_success_gaps()
	if gaps.is_empty():
		return {}
	return gaps[0]

func get_alienation_visual_state() -> Dictionary:
	var heart := int(stats.get(STAT_HEART, 0))
	var ai_dependence := int(stats.get("ai_dependence", 0))
	if heart <= ALIENATION_PERSISTENT_HEART_MAX and ai_dependence >= ALIENATION_PERSISTENT_AI_MIN:
		return {
			"mode": ALIENATION_MODE_PERSISTENT,
			"intensity": 1.0,
			"reason": "heart_ai_dependence_threshold",
		}

	var chapter := _chapter_index()
	if chapter >= ALIENATION_FLICKER_START_CHAPTER and chapter <= ALIENATION_FLICKER_END_CHAPTER:
		return {
			"mode": ALIENATION_MODE_FLICKER,
			"intensity": 1.0,
			"reason": "reversal_chapter_%d" % chapter,
		}

	return {
		"mode": ALIENATION_MODE_NORMAL,
		"intensity": 0.0,
		"reason": "before_reversal",
	}

func _success_gap_severity(gap: int) -> String:
	if gap >= 15:
		return "strong"
	if gap >= 8:
		return "normal"
	return "minor"

func _success_gap_message(stat_id: String, _gap: int) -> String:
	match stat_id:
		"ability_exp":
			return "建议优先处理项目、竞赛、代码或表达训练。"
		"resume_score":
			return "建议优先补足项目结果、履历包装和面试材料。"
		"network_score":
			return "建议维护高协同关系、内推入口和正式场合连接。"
		"wealth_score":
			return "建议靠近高回报城市、岗位、平台或可变现机会。"
		"stability_score":
			return "建议选择可解释、可交付、低风险路线。"
		"success_progress":
			return "建议推进当前主目标，减少低收益停留。"
		_:
			return "建议优先修正该指标，贴近成功路径目标线。"

func set_ui_phase(phase: String) -> void:
	if phase.is_empty() or ui_phase == phase:
		return
	ui_phase = phase
	ui_phase_changed.emit(ui_phase)

func adjust_stat(key: String, delta: int, emit_signal: bool = true) -> void:
	stats[key] = clampi(int(stats.get(key, 0)) + delta, 0, 100)
	if emit_signal:
		stats_changed.emit()

func adjust_relationship(friend_id: String, warmth_delta: int, utility_delta: int, emit_signal: bool = true) -> void:
	if not relationships.has(friend_id):
		return
	var relation: Dictionary = relationships[friend_id]
	relation["warmth"] = clampi(int(relation.get("warmth", 0)) + warmth_delta, 0, 100)
	relation["utility"] = clampi(int(relation.get("utility", 0)) + utility_delta, 0, 100)
	relationships[friend_id] = relation
	if emit_signal:
		relationship_changed.emit(friend_id)

func add_item(item_name: String, emit_signal: bool = true) -> void:
	if inventory.has(item_name):
		return
	inventory.append(item_name)
	if emit_signal:
		inventory_changed.emit()

func record_settlement(settlement_id: String, title: String, body: String, kind: String = "info") -> void:
	var entry := {
		"id": settlement_id,
		"title": title,
		"body": body,
		"kind": kind,
		"chapter": current_chapter_id,
		"scene": current_scene_id,
	}
	settlement_history.append(entry)
	settlement_logged.emit(entry)

func _apply_wish_effects(wish_effects: Dictionary) -> void:
	if wish_effects.has("current"):
		wishes["current"] = str(wish_effects["current"])
	if wish_effects.has("complete"):
		var completed: Array = wishes.get("completed", [])
		for item in wish_effects["complete"]:
			var wish_name := str(item)
			if not completed.has(wish_name):
				completed.append(wish_name)
		wishes["completed"] = completed

func _apply_emotion_card_effects(card_effects: Dictionary) -> void:
	for card in card_effects.get("add", []):
		var card_name := str(card)
		if not emotion_cards.has(card_name):
			emotion_cards.append(card_name)
	for card in card_effects.get("remove", []):
		emotion_cards.erase(str(card))

func record_choice(choice_id: String, strategy: String, label: String, result_text: String, profile_weight: int = -1, effects: Dictionary = {}) -> Dictionary:
	var resolved_weight := _resolved_profile_weight(choice_id, effects, profile_weight)
	var loss := {}
	if _is_route_strategy(strategy) and resolved_weight > 0:
		route_counts[strategy] = int(route_counts.get(strategy, 0)) + 1
		route_weights[strategy] = int(route_weights.get(strategy, 0)) + resolved_weight
		loss = _apply_route_consequence(strategy, resolved_weight, choice_id, label)
		route_profile_changed.emit()

	choice_history.append({
		"id": choice_id,
		"strategy": strategy,
		"label": label,
		"result": result_text,
		"chapter": current_chapter_id,
		"scene": current_scene_id,
		"profile_weight": resolved_weight,
		"route_snapshot": get_route_profile(),
		"loss": loss,
	})
	return {
		"profile_weight": resolved_weight,
		"loss": loss,
		"profile": get_route_profile(),
	}

func log_feedback(title: String, body: String, kind: String = "info") -> void:
	var entry := {
		"title": title,
		"body": body,
		"kind": kind,
		"chapter": current_chapter_id,
		"scene": current_scene_id,
	}
	feedback_log.append(entry)
	feedback_logged.emit(entry)

func get_save_data() -> Dictionary:
	return {
		"current_chapter_id": current_chapter_id,
		"current_scene_id": current_scene_id,
		"current_objective": current_objective,
		"current_time": current_time,
		"current_location": current_location,
		"ai_stage": ai_stage,
		"ui_phase": ui_phase,
		"stats": stats.duplicate(true),
		"skills": skills.duplicate(true),
		"relationships": relationships.duplicate(true),
		"inventory": inventory.duplicate(true),
		"flags": flags.duplicate(true),
		"wishes": wishes.duplicate(true),
		"emotion_cards": emotion_cards.duplicate(true),
		"settlement_history": settlement_history.duplicate(true),
		"choice_history": choice_history.duplicate(true),
		"feedback_log": feedback_log.duplicate(true),
		"route_counts": route_counts.duplicate(true),
		"route_weights": route_weights.duplicate(true),
		"realistic_losses": realistic_losses.duplicate(true),
	}

func load_save_data(data: Dictionary) -> void:
	current_chapter_id = str(data.get("current_chapter_id", current_chapter_id))
	current_scene_id = str(data.get("current_scene_id", current_scene_id))
	current_objective = str(data.get("current_objective", current_objective))
	current_time = str(data.get("current_time", current_time))
	current_location = str(data.get("current_location", current_location))
	ai_stage = int(data.get("ai_stage", ai_stage))
	ui_phase = str(data.get("ui_phase", ui_phase))
	stats = data.get("stats", stats)
	skills = data.get("skills", skills)
	relationships = data.get("relationships", relationships)
	inventory.clear()
	for item in data.get("inventory", inventory):
		inventory.append(str(item))
	flags = data.get("flags", flags)
	wishes = data.get("wishes", wishes)
	emotion_cards.clear()
	for card in data.get("emotion_cards", emotion_cards):
		emotion_cards.append(str(card))
	settlement_history.clear()
	for entry in data.get("settlement_history", settlement_history):
		settlement_history.append(entry)
	choice_history.clear()
	for choice in data.get("choice_history", choice_history):
		choice_history.append(choice)
	feedback_log.clear()
	for entry in data.get("feedback_log", feedback_log):
		feedback_log.append(entry)
	route_counts = data.get("route_counts", {"self": 0, "safe": 0, "ai": 0})
	route_weights = data.get("route_weights", {"self": 0, "safe": 0, "ai": 0})
	realistic_losses.clear()
	for loss in data.get("realistic_losses", realistic_losses):
		realistic_losses.append(loss)
	stats_changed.emit()
	inventory_changed.emit()
	objective_changed.emit()
	ui_phase_changed.emit(ui_phase)
	route_profile_changed.emit()
	chapter_changed.emit(current_chapter_id)

func _resolved_profile_weight(choice_id: String, effects: Dictionary, explicit_weight: int) -> int:
	if explicit_weight >= 0:
		return explicit_weight
	if choice_id.begins_with("gate_") or choice_id.begins_with("to_"):
		return 0
	if choice_id in ["start_replay", "delay_replay", "slice_summary", "ending_auto_resolve"]:
		return 0
	if effects.is_empty():
		return 0
	for prefix in [
		"volunteer_",
		"message_",
		"time_",
		"campus_project_",
		"dropout_",
		"resume_",
		"interview_",
		"office_",
		"review_",
		"city_",
		"final_",
		"upload_",
		"release_",
	]:
		if choice_id.begins_with(prefix):
			return 2
	return 1

func _apply_route_consequence(strategy: String, profile_weight: int, choice_id: String, label: String) -> Dictionary:
	if strategy != STRATEGY_SELF:
		return {}
	var tier := get_self_friction_tier()
	if tier <= 0 or _chapter_index() >= 8:
		return {}

	var stat_deltas := _self_friction_stat_deltas(tier, profile_weight)
	if stat_deltas.is_empty():
		return {}
	for key in stat_deltas.keys():
		adjust_stat(str(key), int(stat_deltas[key]), false)
	stats_changed.emit()

	var loss := {
		"id": "%s_%s_%d" % [current_chapter_id, choice_id, realistic_losses.size() + 1],
		"choice_id": choice_id,
		"label": label,
		"tier": tier,
		"stats": stat_deltas,
		"chapter": current_chapter_id,
		"scene": current_scene_id,
		"summary": _self_friction_summary(tier),
	}
	realistic_losses.append(loss)
	return loss

func _self_friction_stat_deltas(tier: int, profile_weight: int) -> Dictionary:
	var scale := 1
	if profile_weight >= 2:
		scale = 2
	var chapter := _chapter_index()
	if chapter <= 0:
		return {}
	if chapter <= 2:
		if tier >= 3:
			return {"family": -3, "stability_score": -2, "success_progress": -1}
		if tier >= 2:
			return {"family": -2, "stability_score": -1}
		return {"family": -scale}
	if chapter <= 5:
		if tier >= 3:
			return {"resume_score": -3, "network_score": -2, "success_progress": -1}
		if tier >= 2:
			return {"resume_score": -2, "network_score": -1}
		return {"resume_score": -scale}
	if chapter <= 7:
		if tier >= 3:
			return {"resume_score": -3, "stability_score": -3, "success_progress": -2}
		if tier >= 2:
			return {"resume_score": -2, "stability_score": -2}
		return {"stability_score": -scale}
	return {}

func _self_friction_summary(tier: int) -> String:
	if tier >= 3:
		return "关键机会被明显推远"
	if tier >= 2:
		return "现实评价开始不配合"
	return "外部指标轻微下滑"

func _final_ending_effects(ending: String, result_text: String) -> Dictionary:
	match ending:
		"self_return":
			return {"stats": {"clarity": 20, "ai_dependence": -8}, "flags": {"ending": "self_return", "final_ending": "self_return"}, "settlement": {"id": "ending_self", "title": "微弱反抗结局", "body": result_text}, "ai_stage": 8}
		"optimized_life":
			return {"stats": {"success_progress": 15, "resume_score": 8, "ai_dependence": 12, "language_assimilation": 12, "clarity": -12}, "flags": {"ending": "optimized_life", "final_ending": "optimized_life"}, "settlement": {"id": "ending_ai", "title": "顺从结局", "body": result_text}, "ai_stage": 9}
		_:
			return {"stats": {"stability_score": 8, "clarity": 6, "success_progress": 4}, "flags": {"ending": "coexistence", "final_ending": "coexistence"}, "settlement": {"id": "ending_safe", "title": "共存结局", "body": result_text}, "ai_stage": 8}

func _final_ending_result_text(ending: String, resolved: Dictionary) -> String:
	var profile: Dictionary = resolved.get("profile", {})
	var percents: Dictionary = profile.get("percents", {})
	var route_line := "路径权重：自我 %d / 规训 %d / AI %d。" % [
		int(percents.get(STRATEGY_SELF, 0)),
		int(percents.get(STRATEGY_SAFE, 0)),
		int(percents.get(STRATEGY_AI, 0)),
	]
	match ending:
		"self_return":
			return "%s\n许临没有摧毁 AI，也没有救世。他承认自己为自我选择付出了 %d 次现实代价，然后打开林舟的试玩版，亲自写下一段不保证正确的反馈。" % [route_line, realistic_losses.size()]
		"optimized_life":
			return "%s\n许临成为人格协同系统的优秀样本和负责人。生活稳定、高效、无人责怪，系统比他自己更擅长继续他的人生。" % route_line
		_:
			return "%s\n系统仍在，但它不再被允许完全闭合。人工复核入口、延迟按钮和被保留的具体记忆，成为许临能留下的裂缝。" % route_line

func _final_ending_title(ending: String) -> String:
	match ending:
		"self_return":
			return "亲自到场"
		"optimized_life":
			return "接受最优人生"
		_:
			return "保留人工复核"

func _strategy_for_ending(ending: String) -> String:
	match ending:
		"self_return":
			return STRATEGY_SELF
		"optimized_life":
			return STRATEGY_AI
		_:
			return STRATEGY_SAFE

func _memory_anchor_count() -> int:
	var count := 0
	for item in inventory:
		var item_text := str(item)
		for token in ["试玩", "留言", "旧手机", "冰水", "夜景", "退学", "回复", "总结", "记忆", "胶带"]:
			if item_text.contains(token):
				count += 1
				break
	for key in ["final_echo", "friend_echoes", "linzhou_game_reopened", "friend_samples_seen", "friend_tags_seen"]:
		if flags.has(key):
			count += 1
	return count

func _guardrail_count() -> int:
	var count := 0
	for key in ["blocked_sensitive_field", "human_story_in_review", "human_story_in_code", "commit_scope_limited", "release_risk_note"]:
		if flags.has(key):
			count += 1
	for key in ["city_launch", "city_rollout_done", "tag_policy", "life_upload", "life_summary", "review_position"]:
		var value := str(flags.get(key, ""))
		if value in ["limited", "reviewable", "review_note", "delayed", "annotated", "mitigated"]:
			count += 1
	return count

func _total_success_gap() -> int:
	var total := 0
	for gap in get_success_gaps():
		total += int(gap.get("gap", 0))
	return total

func _total_route_weight() -> int:
	var total := 0
	for key in ROUTE_KEYS:
		total += int(route_weights.get(key, 0))
	return total

func _is_route_strategy(strategy: String) -> bool:
	return ROUTE_KEYS.has(strategy)

func _chapter_index() -> int:
	var marker := "chapter_"
	if not current_chapter_id.begins_with(marker):
		return 0
	return int(current_chapter_id.substr(marker.length()))
