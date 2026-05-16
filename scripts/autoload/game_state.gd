extends Node

signal stats_changed
signal relationship_changed(friend_id: String)
signal inventory_changed
signal objective_changed
signal chapter_changed(chapter_id: String)
signal feedback_logged(entry: Dictionary)

var current_chapter_id := "chapter_0"
var current_scene_id := "cruise_deck"
var current_objective := "打开人生回放，回到高三关键节点"
var current_time := "22:40"
var current_location := "邮轮甲板"
var ai_stage := 0

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
var choice_history: Array[Dictionary] = []
var feedback_log: Array[Dictionary] = []

func reset_for_new_game() -> void:
	current_chapter_id = "chapter_0"
	current_scene_id = "cruise_deck"
	current_objective = "打开人生回放，回到高三关键节点"
	current_time = "22:40"
	current_location = "邮轮甲板"
	ai_stage = 0
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
	choice_history.clear()
	feedback_log.clear()
	stats_changed.emit()
	inventory_changed.emit()
	objective_changed.emit()
	chapter_changed.emit(current_chapter_id)

func set_context(chapter_id: String, scene_id: String, location: String, time_label: String, objective: String) -> void:
	current_chapter_id = chapter_id
	current_scene_id = scene_id
	current_location = location
	current_time = time_label
	current_objective = objective
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

func record_choice(choice_id: String, strategy: String, label: String, result_text: String) -> void:
	choice_history.append({
		"id": choice_id,
		"strategy": strategy,
		"label": label,
		"result": result_text,
		"chapter": current_chapter_id,
		"scene": current_scene_id,
	})

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
		"stats": stats,
		"skills": skills,
		"relationships": relationships,
		"inventory": inventory,
		"flags": flags,
		"choice_history": choice_history,
		"feedback_log": feedback_log,
	}

func load_save_data(data: Dictionary) -> void:
	current_chapter_id = str(data.get("current_chapter_id", current_chapter_id))
	current_scene_id = str(data.get("current_scene_id", current_scene_id))
	current_objective = str(data.get("current_objective", current_objective))
	current_time = str(data.get("current_time", current_time))
	current_location = str(data.get("current_location", current_location))
	ai_stage = int(data.get("ai_stage", ai_stage))
	stats = data.get("stats", stats)
	skills = data.get("skills", skills)
	relationships = data.get("relationships", relationships)
	inventory.clear()
	for item in data.get("inventory", inventory):
		inventory.append(str(item))
	flags = data.get("flags", flags)
	choice_history.clear()
	for choice in data.get("choice_history", choice_history):
		choice_history.append(choice)
	feedback_log.clear()
	for entry in data.get("feedback_log", feedback_log):
		feedback_log.append(entry)
	stats_changed.emit()
	inventory_changed.emit()
	objective_changed.emit()
	chapter_changed.emit(current_chapter_id)
