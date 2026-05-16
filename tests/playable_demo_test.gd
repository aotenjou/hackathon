extends SceneTree

const MainScene = preload("res://scenes/Main.tscn")
const DialoguePacked = preload("res://scenes/ui/DialoguePanel.tscn")
const PressurePacked = preload("res://scenes/ui/PressureEncounter.tscn")
const GameStateScript = preload("res://scripts/autoload/game_state.gd")
const ChapterDataScript = preload("res://scripts/data/chapter_data.gd")

var _failures: Array[String] = []

func _initialize() -> void:
	_bootstrap_autoloads()
	await process_frame

	_check_data_references()
	_check_mainline_reachability()
	await _check_chapter_3_8_flags_can_be_chosen()
	await _check_dialogue_effect_persistence()
	await _check_dialogue_scene_gate()
	await _check_pressure_gate()
	await _check_pressure_success()
	await _check_pressure_failure()
	await _check_new_pressure_success_failure_branches()
	await _check_main_scene_activation()

	if _failures.is_empty():
		print("PLAYABLE DEMO TEST PASSED")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)

func _bootstrap_autoloads() -> void:
	var game_state := GameStateScript.new()
	game_state.name = "GameState"
	root.add_child(game_state)

	var chapter_data := ChapterDataScript.new()
	chapter_data.name = "ChapterData"
	root.add_child(chapter_data)

func _check_data_references() -> void:
	var chapter_data := _chapter_data()

	for chapter_id in chapter_data.chapters.keys():
		var chapter: Dictionary = chapter_data.get_chapter(str(chapter_id))
		var start_scene := str(chapter.get("start_scene", ""))
		if not start_scene.is_empty() and chapter_data.get_scene(start_scene).is_empty():
			_failures.append("chapter %s has missing start_scene %s" % [chapter_id, start_scene])

	for scene_id in chapter_data.scenes.keys():
		var scene: Dictionary = chapter_data.get_scene(str(scene_id))
		for interactable in scene.get("interactables", []):
			var interactable_id := str(interactable.get("id", ""))
			if interactable.has("dialogue"):
				var dialogue_id := str(interactable.get("dialogue", ""))
				if dialogue_id.is_empty() or chapter_data.get_dialogue(dialogue_id).is_empty():
					_failures.append("interactable %s in %s has missing dialogue %s" % [interactable_id, scene_id, dialogue_id])
			if interactable.has("pressure"):
				var pressure_id := str(interactable.get("pressure", ""))
				if pressure_id.is_empty() or chapter_data.get_pressure(pressure_id).is_empty():
					_failures.append("interactable %s in %s has missing pressure %s" % [interactable_id, scene_id, pressure_id])
			if not interactable.has("dialogue") and not interactable.has("pressure"):
				_failures.append("interactable %s in %s has no dialogue or pressure" % [interactable_id, scene_id])

	for dialogue_id in chapter_data.dialogue_nodes.keys():
		var dialogue: Dictionary = chapter_data.get_dialogue(str(dialogue_id))
		for choice in dialogue.get("choices", []):
			var next_scene := str(choice.get("next_scene", ""))
			if not next_scene.is_empty() and chapter_data.get_scene(next_scene).is_empty():
				_failures.append("dialogue %s choice %s points to missing scene %s" % [dialogue_id, str(choice.get("id", "")), next_scene])
			_check_effect_references(choice.get("effects", {}), "dialogue %s choice %s" % [dialogue_id, str(choice.get("id", ""))])

	for pressure_id in chapter_data.pressure_encounters.keys():
		var encounter: Dictionary = chapter_data.get_pressure(str(pressure_id))
		var next_scene := str(encounter.get("next_scene", ""))
		if not next_scene.is_empty() and chapter_data.get_scene(next_scene).is_empty():
			_failures.append("pressure %s points to missing scene %s" % [pressure_id, next_scene])
		for action in encounter.get("actions", []):
			var effects: Dictionary = action.get("effects", {})
			_check_effect_references(effects, "pressure %s action %s" % [pressure_id, str(action.get("id", ""))])
		_check_effect_references(encounter.get("success_effects", {}), "pressure %s success_effects" % pressure_id)
		_check_effect_references(encounter.get("failure_effects", {}), "pressure %s failure_effects" % pressure_id)

	for preview_id in chapter_data.chapter_previews.keys():
		if not chapter_data.chapters.has(str(preview_id)):
			_failures.append("preview points to missing chapter %s" % preview_id)

func _check_effect_references(effects: Dictionary, owner: String) -> void:
	for stat_id in effects.get("stats", {}).keys():
		if not _game_state().stats.has(str(stat_id)):
			_failures.append("%s references unknown stat %s" % [owner, stat_id])
	for skill_id in effects.get("skills", {}).keys():
		if not _game_state().skills.has(str(skill_id)):
			_failures.append("%s references unknown skill %s" % [owner, skill_id])
	for relation_id in effects.get("relationships", {}).keys():
		if not _game_state().relationships.has(str(relation_id)):
			_failures.append("%s references unknown relationship %s" % [owner, relation_id])

func _check_mainline_reachability() -> void:
	var reachable := _reachable_scenes("cruise_deck")
	var chapter_data := _chapter_data()

	for chapter_index in range(9):
		var chapter_id := "chapter_%d" % chapter_index
		var chapter: Dictionary = chapter_data.get_chapter(chapter_id)
		if chapter.is_empty():
			_failures.append("missing mainline chapter: %s" % chapter_id)
			continue
		var start_scene := str(chapter.get("start_scene", ""))
		if start_scene.is_empty():
			_failures.append("mainline chapter has no start_scene: %s" % chapter_id)
		elif not reachable.has(start_scene):
			_failures.append("chapter start_scene is not reachable from cruise_deck: %s -> %s" % [chapter_id, start_scene])

	for scene_id in ["cruise_deck", "school_hallway", "computer_room", "dinner_table", "graduation_field"]:
		if not reachable.has(scene_id):
			_failures.append("mainline scene is not reachable from cruise_deck: %s" % scene_id)

	for scene_id in chapter_data.scenes.keys():
		if not reachable.has(str(scene_id)):
			_failures.append("scene is not reachable from playable start: %s" % scene_id)

func _reachable_scenes(start_scene: String) -> Dictionary:
	var chapter_data := _chapter_data()
	var visited: Dictionary = {}
	var queue: Array[String] = [start_scene]

	while not queue.is_empty():
		var scene_id: String = queue.pop_front()
		if visited.has(scene_id):
			continue
		visited[scene_id] = true

		var scene: Dictionary = chapter_data.get_scene(scene_id)
		for interactable in scene.get("interactables", []):
			if interactable.has("dialogue"):
				var dialogue: Dictionary = chapter_data.get_dialogue(str(interactable.get("dialogue", "")))
				for choice in dialogue.get("choices", []):
					var next_scene := str(choice.get("next_scene", ""))
					if not next_scene.is_empty() and not visited.has(next_scene):
						queue.append(next_scene)
			if interactable.has("pressure"):
				var pressure: Dictionary = chapter_data.get_pressure(str(interactable.get("pressure", "")))
				var next_scene := str(pressure.get("next_scene", ""))
				if not next_scene.is_empty() and not visited.has(next_scene):
					queue.append(next_scene)

	return visited

func _check_chapter_3_8_flags_can_be_chosen() -> void:
	for flag_id in [
		"project_done",
		"linzhou_dropout_response",
		"interview_done",
		"feature_review_done",
		"city_rollout_done",
		"final_ending",
	]:
		await _check_flag_can_be_chosen(flag_id)

func _check_flag_can_be_chosen(flag_id: String) -> void:
	var match_data := _find_dialogue_choice_setting_flag(flag_id)
	if match_data.is_empty():
		_failures.append("no dialogue choice writes required Chapter 3-8 flag: %s" % flag_id)
		return

	_reset_state()
	var dialogue := DialoguePacked.instantiate()
	root.add_child(dialogue)
	await process_frame

	dialogue.show_dialogue(str(match_data["dialogue_id"]))
	dialogue._select_choice(match_data["choice"])
	await process_frame

	if not _game_state().flags.has(flag_id):
		_failures.append("dialogue choice did not persist required flag: %s" % flag_id)

	dialogue.queue_free()
	await process_frame

func _find_dialogue_choice_setting_flag(flag_id: String) -> Dictionary:
	var chapter_data := _chapter_data()
	for dialogue_id in chapter_data.dialogue_nodes.keys():
		var dialogue: Dictionary = chapter_data.get_dialogue(str(dialogue_id))
		for choice in dialogue.get("choices", []):
			var effects: Dictionary = choice.get("effects", {})
			var flags: Dictionary = effects.get("flags", {})
			if flags.has(flag_id):
				return {"dialogue_id": str(dialogue_id), "choice": choice}
	return {}

func _check_dialogue_effect_persistence() -> void:
	_reset_state()
	var dialogue := DialoguePacked.instantiate()
	root.add_child(dialogue)
	await process_frame

	var node: Dictionary = _chapter_data().get_dialogue("d_linzhou_hallway")
	var choice: Dictionary = _find_by_id(node.get("choices", []), "linzhou_self")
	dialogue.show_dialogue("d_linzhou_hallway")
	dialogue._select_choice(choice)
	await process_frame

	var game_state := _game_state()
	_expect_equal(int(game_state.stats.get("clarity", 0)), 63, "dialogue stat effect was not persisted")
	_expect_equal(game_state.flags.get(""), null, "unused flag check should stay null")
	if not game_state.inventory.has("林舟的试玩包"):
		_failures.append("dialogue item effect was not persisted")
	_expect_equal(int(game_state.relationships["linzhou"].get("warmth", 0)), 56, "dialogue relationship warmth was not persisted")
	_expect_equal(game_state.choice_history.size(), 1, "dialogue choice history not recorded")
	_expect_equal(game_state.feedback_log.size(), 1, "dialogue feedback not logged")

	dialogue.queue_free()
	await process_frame

func _check_dialogue_scene_gate() -> void:
	_reset_state()
	var dialogue := DialoguePacked.instantiate()
	root.add_child(dialogue)
	await process_frame

	var requested: Array[String] = []
	dialogue.scene_requested.connect(func(scene_id: String) -> void: requested.append(scene_id))
	var node: Dictionary = _chapter_data().get_dialogue("d_life_replay")
	var choice: Dictionary = _find_by_id(node.get("choices", []), "start_replay")

	dialogue.show_dialogue("d_life_replay")
	dialogue._select_choice(choice)
	await process_frame
	_expect_equal(requested.size(), 0, "dialogue next_scene emitted before continue gate")

	dialogue._close_or_advance()
	await process_frame
	_expect_equal(requested.size(), 1, "dialogue next_scene did not emit after continue")
	if requested.size() == 1:
		_expect_equal(requested[0], "school_hallway", "dialogue next_scene target mismatch")

	dialogue.queue_free()
	await process_frame

func _check_pressure_gate() -> void:
	_reset_state()
	var pressure := PressurePacked.instantiate()
	root.add_child(pressure)
	await process_frame

	pressure.start("family_dinner")
	pressure.set("_preparedness", 0)
	pressure._refresh()
	await process_frame

	var disabled_found := false
	for button in _find_buttons(pressure):
		if button.text.begins_with("引用证据") and button.disabled:
			disabled_found = true
	if not disabled_found:
		_failures.append("pressure preparedness gate did not disable evidence action")

	pressure.queue_free()
	await process_frame

func _check_pressure_success() -> void:
	_reset_state()
	var pressure := PressurePacked.instantiate()
	root.add_child(pressure)
	await process_frame

	var encounter: Dictionary = _chapter_data().get_pressure("family_dinner")
	var action: Dictionary = _find_by_id(encounter.get("actions", []), "dinner_ai")
	pressure.start("family_dinner")
	for _index in range(3):
		pressure._select_action(action)
		await process_frame

	_expect_equal(_game_state().flags.get("family_dinner_done"), "success", "pressure success flag not persisted")
	_expect_equal(int(_game_state().stats.get("success_progress", 0)), 100, "pressure success effects not applied")

	pressure.queue_free()
	await process_frame

func _check_pressure_failure() -> void:
	_reset_state()
	var pressure := PressurePacked.instantiate()
	root.add_child(pressure)
	await process_frame

	var encounter: Dictionary = _chapter_data().get_pressure("family_dinner")
	var action: Dictionary = _find_by_id(encounter.get("actions", []), "dinner_direct")
	pressure.start("family_dinner")
	for _index in range(4):
		pressure._select_action(action)
		await process_frame

	_expect_equal(_game_state().flags.get("family_dinner_done"), "failure", "pressure failure flag not persisted")
	_expect_equal(int(_game_state().stats.get("family", 0)), 27, "pressure failure effects not applied")

	pressure.queue_free()
	await process_frame

func _check_new_pressure_success_failure_branches() -> void:
	var encounter_id := _find_new_pressure_encounter_with_branches()
	if encounter_id.is_empty():
		_failures.append("no Chapter 3-8 pressure encounter exposes success and failure branches")
		return

	await _check_pressure_branch_can_finish(encounter_id, true)
	await _check_pressure_branch_can_finish(encounter_id, false)

func _find_new_pressure_encounter_with_branches() -> String:
	var chapter_data := _chapter_data()
	for pressure_id in chapter_data.pressure_encounters.keys():
		var encounter_id := str(pressure_id)
		if encounter_id == "family_dinner":
			continue
		var encounter: Dictionary = chapter_data.get_pressure(encounter_id)
		if encounter.get("actions", []).is_empty():
			continue
		if encounter.get("success_effects", {}).is_empty() or encounter.get("failure_effects", {}).is_empty():
			continue
		if not _pressure_has_success_action(encounter) or not _pressure_has_failure_action(encounter):
			continue
		return encounter_id
	return ""

func _pressure_has_success_action(encounter: Dictionary) -> bool:
	for action in encounter.get("actions", []):
		if int(action.get("pressure_delta", 0)) < 0:
			return true
	return false

func _pressure_has_failure_action(encounter: Dictionary) -> bool:
	for action in encounter.get("actions", []):
		if int(action.get("pressure_delta", 0)) >= 0:
			return true
	return not encounter.get("actions", []).is_empty()

func _check_pressure_branch_can_finish(encounter_id: String, expect_success: bool) -> void:
	_reset_state()
	var pressure := PressurePacked.instantiate()
	root.add_child(pressure)
	await process_frame

	var encounter: Dictionary = _chapter_data().get_pressure(encounter_id)
	var action := _find_branch_action(encounter, expect_success)
	if action.is_empty():
		_failures.append("pressure %s has no action for %s branch" % [encounter_id, _branch_name(expect_success)])
		pressure.queue_free()
		await process_frame
		return

	pressure.start(encounter_id)
	if expect_success:
		pressure.set("_pressure", maxi(1, abs(int(action.get("pressure_delta", -1)))))
	else:
		pressure.set("_pressure", 100)
		pressure.set("_heart", 100)
		pressure.set("_rounds", 1)
	pressure._select_action(action)
	await process_frame

	var expected_effects: Dictionary = encounter.get("success_effects" if expect_success else "failure_effects", {})
	var expected_flags: Dictionary = expected_effects.get("flags", {})
	if expected_flags.is_empty():
		_failures.append("pressure %s %s branch has no flag effect" % [encounter_id, _branch_name(expect_success)])
	for flag_id in expected_flags.keys():
		_expect_equal(_game_state().flags.get(str(flag_id)), expected_flags[flag_id], "pressure %s %s flag not persisted" % [encounter_id, _branch_name(expect_success)])

	pressure.queue_free()
	await process_frame

func _find_branch_action(encounter: Dictionary, expect_success: bool) -> Dictionary:
	if expect_success:
		for action in encounter.get("actions", []):
			if int(action.get("pressure_delta", 0)) < 0:
				return action
		return {}

	var fallback: Dictionary = {}
	for action in encounter.get("actions", []):
		if fallback.is_empty():
			fallback = action
		if int(action.get("pressure_delta", 0)) >= 0:
			return action
	return fallback

func _branch_name(expect_success: bool) -> String:
	return "success" if expect_success else "failure"

func _check_main_scene_activation() -> void:
	_reset_state()
	var main := MainScene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	var world: Node = main.get("world")
	var dialogue: Node = main.get("dialogue")
	var pressure: Node = main.get("pressure")
	if world == null or dialogue == null or pressure == null:
		_failures.append("main scene modules missing")
		main.queue_free()
		await process_frame
		return

	main._on_interactable_activated({"kind": "panel", "dialogue": "d_life_replay"})
	await process_frame
	if not dialogue.visible:
		_failures.append("main dialogue interactable did not open dialogue")

	main._on_interactable_activated({"kind": "pressure", "pressure": "family_dinner"})
	await process_frame
	if not pressure.visible:
		_failures.append("main pressure interactable did not open pressure encounter")

	world.load_scene("computer_room")
	await process_frame
	_expect_equal(_game_state().current_scene_id, "computer_room", "world scene load did not update game state")

	main.queue_free()
	await process_frame

func _find_by_id(items: Array, expected_id: String) -> Dictionary:
	for item in items:
		if str(item.get("id", "")) == expected_id:
			return item
	_failures.append("missing item id %s" % expected_id)
	return {}

func _find_buttons(node: Node) -> Array[Button]:
	var buttons: Array[Button] = []
	if node is Button:
		buttons.append(node)
	for child in node.get_children():
		buttons.append_array(_find_buttons(child))
	return buttons

func _reset_state() -> void:
	_game_state().reset_for_new_game()

func _expect_equal(actual, expected, message: String) -> void:
	if actual != expected:
		_failures.append("%s: expected %s got %s" % [message, str(expected), str(actual)])

func _game_state() -> Node:
	return root.get_node("GameState")

func _chapter_data() -> Node:
	return root.get_node("ChapterData")
