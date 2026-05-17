extends SceneTree

const MainScene = preload("res://scenes/Main.tscn")
const HUDPacked = preload("res://scenes/ui/HUD.tscn")
const DialoguePacked = preload("res://scenes/ui/DialoguePanel.tscn")
const PressurePacked = preload("res://scenes/ui/PressureEncounter.tscn")
const AlienationVisualFilterScript = preload("res://scripts/ui/alienation_visual_filter.gd")
const WorldSceneScript = preload("res://scripts/gameplay/world_scene.gd")
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
	await _check_ai_transitions_have_non_ai_path()
	await _check_non_ai_transition_paths()
	await _check_story_alignment_beats()
	await _check_school_hallway_task_cluster_alignment()
	await _check_bridge_sunset_transition()
	await _check_new_state_persistence()
	await _check_route_profile_tracking()
	await _check_self_friction_and_pressure_modifier()
	await _check_final_ending_resolution()
	await _check_expanded_final_branches()
	await _check_auto_final_ending_dialogue()
	await _check_final_field_epilogue()
	await _check_stats_panel_toggle()
	await _check_success_guidance_targets()
	await _check_stat_simplification_and_legacy_migration()
	await _check_success_guidance_hud_modes()
	await _check_scene_entry_guidance()
	await _check_cruise_player_layering()
	await _check_ai_cost_button_labels()
	await _check_alienation_visual_state()
	await _check_alienation_visual_filter()
	await _check_final_field_scene_presentation()
	await _check_ai_dialogue_heart_cost()
	await _check_non_ai_dialogue_does_not_reduce_heart()
	await _check_dialogue_choice_triggers_once()
	await _check_auto_final_ending_triggers_once()
	await _check_ai_pressure_heart_cost()
	await _check_non_ai_pressure_does_not_reduce_heart()
	await _check_pressure_action_triggers_once()
	await _check_pressure_gate()
	await _check_pressure_success()
	await _check_pressure_failure()
	await _check_pressure_actions_exhaust_to_failure()
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
		var narration_id := str(scene.get("narration", ""))
		if narration_id.is_empty():
			_failures.append("scene %s has no narration" % scene_id)
		else:
			var narration: Dictionary = chapter_data.get_dialogue(narration_id)
			if narration.is_empty():
				_failures.append("scene %s has missing narration %s" % [scene_id, narration_id])
			elif not narration.get("choices", []).is_empty():
				_failures.append("scene %s narration %s should not have choices" % [scene_id, narration_id])
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

func _check_school_hallway_task_cluster_alignment() -> void:
	var scene: Dictionary = _chapter_data().get_scene("school_hallway")
	if scene.is_empty():
		_failures.append("school hallway scene missing for alignment check")
		return
		_expect_equal(str(WorldSceneScript.SCHOOL_HALLWAY_BACKGROUND_PATH), "res://assets/storyline/ch01_school_hallway/backgrounds/school_hallway_task_cluster.webp", "school hallway should use task-cluster background")
	_expect_float_near(float(scene.get("character_scale", 0.0)), 0.78, "school hallway character scale mismatch")
	var bounds: Rect2 = scene.get("bounds", Rect2())
	_expect_equal(bounds, Rect2(180, 560, 1240, 160), "school hallway walkable band mismatch")

	for item in scene.get("interactables", []):
		var item_id := str(item.get("id", ""))
		var position: Vector2 = item.get("position", Vector2.ZERO)
		if position.y < 560.0 or position.y > 690.0:
			_failures.append("school hallway interactable %s is outside task-cluster band: %s" % [item_id, str(position)])
	for npc in scene.get("npcs", []):
		var npc_id := str(npc.get("id", ""))
		var position: Vector2 = npc.get("position", Vector2.ZERO)
		if position.y < 630.0 or position.y > 690.0:
			_failures.append("school hallway npc %s is not on the visible floor band: %s" % [npc_id, str(position)])

	var expected_positions := {
		"volunteer_board": Vector2(760, 585),
		"teacher": Vector2(1125, 650),
		"ai_notice": Vector2(1390, 590),
	}
	for item in scene.get("interactables", []):
		var item_id := str(item.get("id", ""))
		if expected_positions.has(item_id):
			_expect_equal(item.get("position", Vector2.ZERO), expected_positions[item_id], "school hallway task anchor mismatch for %s" % item_id)

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

func _check_ai_transitions_have_non_ai_path() -> void:
	var chapter_data := _chapter_data()
	for dialogue_id in chapter_data.dialogue_nodes.keys():
		var dialogue: Dictionary = chapter_data.get_dialogue(str(dialogue_id))
		var choices: Array = dialogue.get("choices", [])
		for choice in choices:
			if str(choice.get("strategy", "")) != "ai":
				continue
			var next_scene := str(choice.get("next_scene", ""))
			if next_scene.is_empty():
				continue
			if not _dialogue_has_non_ai_transition_to(choices, next_scene):
				_failures.append("AI transition has no non-AI path: %s -> %s" % [str(dialogue_id), next_scene])

func _check_non_ai_transition_paths() -> void:
	await _check_non_ai_transition_choice("d_volunteer_board", "board_to_computer_safe", "computer_room")
	await _check_non_ai_transition_choice("d_ai_notice", "notice_walk_to_computer", "computer_room")
	await _check_non_ai_transition_choice("d_reunion_to_resume", "to_resume_pipeline_safe", "resume_pipeline")

func _check_non_ai_transition_choice(dialogue_id: String, choice_id: String, expected_scene: String) -> void:
	_reset_state()
	var dialogue := DialoguePacked.instantiate()
	root.add_child(dialogue)
	await process_frame

	var requested: Array[String] = []
	dialogue.scene_requested.connect(func(scene_id: String) -> void: requested.append(scene_id))
	var node: Dictionary = _chapter_data().get_dialogue(dialogue_id)
	var choice: Dictionary = _find_by_id(node.get("choices", []), choice_id)
	var heart_before := int(_game_state().stats.get("heart", 0))

	dialogue.show_dialogue(dialogue_id)
	dialogue._select_choice(choice)
	await process_frame
	dialogue._close_or_advance()
	await process_frame

	_expect_equal(int(_game_state().stats.get("heart", 0)), heart_before, "%s should not reduce heart" % choice_id)
	_expect_equal(requested.size(), 1, "%s should request one scene" % choice_id)
	if requested.size() == 1:
		_expect_equal(requested[0], expected_scene, "%s scene target mismatch" % choice_id)

	dialogue.queue_free()
	await process_frame

func _check_story_alignment_beats() -> void:
	var chapter_data := _chapter_data()
	var failures_before := _failures.size()

	for scene_id in [
		"ch1_night_settlement",
		"club_recruitment",
		"dorm_schedule_ai",
		"internet_cafe_demo",
		"class_reunion",
		"resume_pipeline",
		"offer_arrival",
		"starloop_lobby",
		"model_ops_layer",
		"school_demo",
	]:
		if chapter_data.get_scene(scene_id).is_empty():
			_failures.append("missing story alignment scene: %s" % scene_id)

	var xl_dialogue: Dictionary = chapter_data.get_dialogue("d_xl0417_sample")
	if xl_dialogue.is_empty() or not str(xl_dialogue.get("line", "")).contains("XL-0417"):
		_failures.append("XL-0417 reveal dialogue missing required sample id")
	else:
		var choice := _find_by_id(xl_dialogue.get("choices", []), "xl0417_open")
		var effects: Dictionary = choice.get("effects", {})
		if str(effects.get("ui_phase", "")) != "profile_system":
			_failures.append("XL-0417 reveal does not switch to profile_system")

	var friend_tags: Dictionary = chapter_data.get_dialogue("d_friend_tag_overlay")
	var friend_tag_line := str(friend_tags.get("line", ""))
	for token in ["林舟", "周骁", "何启朗", "沈柚", "陈望"]:
		if not friend_tag_line.contains(token):
			_failures.append("friend tag overlay missing %s" % token)

	var upload: Dictionary = chapter_data.get_dialogue("d_upload_life_model")
	if upload.is_empty() or not str(upload.get("line", "")).contains("上传你的人生"):
		_failures.append("life model upload prompt missing")
	else:
		var upload_choice := _find_by_id(upload.get("choices", []), "upload_accept")
		var flags: Dictionary = upload_choice.get("effects", {}).get("flags", {})
		if str(flags.get("life_upload", "")) != "uploaded":
			_failures.append("upload accept choice does not persist life_upload flag")

	for pressure_id in ["club_pitch", "class_reunion", "resume_screening", "code_commit", "release_gate"]:
		if chapter_data.get_pressure(pressure_id).is_empty():
			_failures.append("missing planned pressure encounter: %s" % pressure_id)

	if _failures.size() == failures_before:
		print("STORY ALIGNMENT BEATS PASSED")

func _check_new_state_persistence() -> void:
	_reset_state()
	var dialogue := DialoguePacked.instantiate()
	root.add_child(dialogue)
	await process_frame

	var node: Dictionary = _chapter_data().get_dialogue("d_ch1_night_settlement")
	var choice: Dictionary = _find_by_id(node.get("choices", []), "ch1_settlement_ai")
	dialogue.show_dialogue("d_ch1_night_settlement")
	dialogue._select_choice(choice)
	await process_frame

	var game_state := _game_state()
	_expect_equal(str(game_state.wishes.get("current", "")), "写下毕业留言", "wish current was not updated")
	if not game_state.emotion_cards.has("AI 已规划今日"):
		_failures.append("emotion card was not persisted")
	_expect_equal(game_state.settlement_history.size(), 1, "settlement was not logged")

	var save_data: Dictionary = game_state.get_save_data()
	game_state.reset_for_new_game()
	game_state.load_save_data(save_data)
	await process_frame

	_expect_equal(str(game_state.wishes.get("current", "")), "写下毕业留言", "wish current was not restored")
	if not game_state.emotion_cards.has("AI 已规划今日"):
		_failures.append("emotion card was not restored")
	_expect_equal(game_state.settlement_history.size(), 1, "settlement history was not restored")
	_expect_equal(int(game_state.route_weights.get("ai", 0)), 1, "route weight was not restored")

	dialogue.queue_free()
	await process_frame

func _check_route_profile_tracking() -> void:
	_reset_state()
	var game_state := _game_state()

	game_state.record_choice("volunteer_self", "self", "自己写", "result", -1, {"stats": {"clarity": 1}})
	game_state.record_choice("to_reunion", "safe", "去同学聚会", "result", -1, {})
	game_state.record_choice("message_ai", "ai", "AI留言", "result", -1, {"stats": {"ai_dependence": 1}})

	_expect_equal(int(game_state.route_weights.get("self", 0)), 2, "self route weight mismatch")
	_expect_equal(int(game_state.route_weights.get("safe", 0)), 0, "navigation choices should not add safe route weight")
	_expect_equal(int(game_state.route_weights.get("ai", 0)), 2, "ai route weight mismatch")
	_expect_equal(int(game_state.route_counts.get("self", 0)), 1, "self route count mismatch")
	_expect_equal(int(game_state.choice_history[0].get("profile_weight", 0)), 2, "choice history should include profile weight")

func _check_self_friction_and_pressure_modifier() -> void:
	_reset_state()
	var game_state := _game_state()
	game_state.current_chapter_id = "chapter_3"
	game_state.current_scene_id = "club_recruitment"
	for index in range(5):
		game_state.record_choice("campus_project_self_%d" % index, "self", "自主选择", "result", 2, {"stats": {"clarity": 1}})

	_expect_equal(game_state.get_self_friction_tier(), 2, "self-heavy route should reach medium friction")
	if game_state.realistic_losses.is_empty():
		_failures.append("self-heavy route did not log realistic loss")
	if int(game_state.stats.get("resume_score", 0)) >= 92:
		_failures.append("self friction did not reduce external success stat")

	var modifier: Dictionary = game_state.get_pressure_profile_modifier()
	_expect_equal(int(modifier.get("pressure_delta", 0)), 6, "medium self friction pressure delta mismatch")
	_expect_equal(int(modifier.get("preparedness_delta", 0)), -4, "medium self friction preparedness delta mismatch")

	var pressure := PressurePacked.instantiate()
	root.add_child(pressure)
	await process_frame
	pressure.start("team_project")
	await process_frame
	_expect_equal(int(pressure.get("_pressure")), 74, "pressure encounter did not apply self friction pressure")
	_expect_equal(int(pressure.get("_preparedness")), 36, "pressure encounter did not apply self friction preparedness")
	pressure.queue_free()
	await process_frame

	var save_data: Dictionary = game_state.get_save_data()
	game_state.reset_for_new_game()
	game_state.load_save_data(save_data)
	await process_frame
	_expect_equal(game_state.realistic_losses.size(), save_data.get("realistic_losses", []).size(), "realistic losses were not restored")

func _check_final_ending_resolution() -> void:
	_reset_state()
	var game_state := _game_state()

	for index in range(7):
		game_state.record_choice("self_path_%d" % index, "self", "自主", "result", 2, {"stats": {"clarity": 1}})
	game_state.stats["clarity"] = 80
	game_state.inventory.append("林舟的试玩包存档")
	game_state.inventory.append("毕业留言纸条")
	_expect_equal(str(game_state.resolve_final_ending().get("ending", "")), "self_return", "self-heavy ending should resolve to self_return")

	_reset_state()
	game_state = _game_state()
	for index in range(5):
		game_state.record_choice("safe_path_%d" % index, "safe", "规训", "result", 2, {"stats": {"stability_score": 1}})
	game_state.stats["stability_score"] = 96
	game_state.flags["life_summary"] = "annotated"
	_expect_equal(str(game_state.resolve_final_ending().get("ending", "")), "coexistence", "safe-heavy ending should resolve to coexistence")

	_reset_state()
	game_state = _game_state()
	for index in range(5):
		game_state.record_choice("ai_path_%d" % index, "ai", "AI", "result", 2, {"stats": {"ai_dependence": 1}})
	game_state.stats["ai_dependence"] = 75
	_expect_equal(str(game_state.resolve_final_ending().get("ending", "")), "optimized_life", "ai-heavy ending should resolve to optimized_life")

	_reset_state()
	game_state = _game_state()
	for index in range(4):
		game_state.record_choice("outside_path_%d" % index, "self", "样本外", "result", 2, {"stats": {"clarity": 1}})
	game_state.stats["clarity"] = 70
	game_state.flags["outside_model"] = true
	game_state.flags["life_upload"] = "offline"
	game_state.inventory.append("离线人生副本")
	_expect_equal(str(game_state.resolve_final_ending().get("ending", "")), "outside_model", "offline final branch should resolve to outside_model")

	_reset_state()
	game_state = _game_state()
	for index in range(4):
		game_state.record_choice("audit_path_%d" % index, "safe", "审计", "result", 2, {"stats": {"stability_score": 1}})
	game_state.flags["audit_trail"] = true
	game_state.flags["life_summary"] = "audited"
	game_state.flags["life_upload"] = "audit_contract"
	game_state.flags["friend_echoes"] = "audit_samples"
	game_state.flags["city_launch"] = "reviewable"
	_expect_equal(str(game_state.resolve_final_ending().get("ending", "")), "system_steward", "audit-heavy branch should resolve to system_steward")

func _check_expanded_final_branches() -> void:
	var final_echo: Dictionary = _chapter_data().get_dialogue("d_final_linzhou_echo")
	_expect_has_choice(final_echo.get("choices", []), "final_echo_call", "final echo should include phone-call branch")
	var life_summary: Dictionary = _chapter_data().get_dialogue("d_final_life_summary")
	_expect_has_choice(life_summary.get("choices", []), "final_summary_steward", "life summary should include audit branch")
	var friend_echoes: Dictionary = _chapter_data().get_dialogue("d_final_friend_echoes")
	_expect_has_choice(friend_echoes.get("choices", []), "final_echoes_audit", "friend echoes should include audit sample branch")
	var upload: Dictionary = _chapter_data().get_dialogue("d_upload_life_model")
	_expect_has_choice(upload.get("choices", []), "upload_export_offline", "upload should include offline branch")
	_expect_has_choice(upload.get("choices", []), "upload_audit_contract", "upload should include audit contract branch")

func _check_auto_final_ending_dialogue() -> void:
	_reset_state()
	var dialogue := DialoguePacked.instantiate()
	root.add_child(dialogue)
	await process_frame

	var node: Dictionary = _chapter_data().get_dialogue("d_final_three_endings")
	if node.is_empty():
		_failures.append("auto final ending dialogue missing")
		dialogue.queue_free()
		await process_frame
		return
	var choices: Array = node.get("choices", [])
	_expect_equal(choices.size(), 1, "auto final ending should expose one generated ending action")
	var choice: Dictionary = _find_by_id(choices, "ending_auto_resolve")
	if not bool(choice.get("auto_final_ending", false)):
		_failures.append("auto final ending choice missing auto flag")

	dialogue.show_dialogue("d_final_three_endings")
	dialogue._select_choice(choice)
	await process_frame
	if not _game_state().flags.has("final_ending"):
		_failures.append("auto final ending did not persist final_ending")
	if _game_state().settlement_history.is_empty():
		_failures.append("auto final ending did not log settlement")
	if choices.size() > 0:
		_expect_equal(str(choice.get("next_scene", "")), "final_field_epilogue", "auto final ending should continue into field epilogue")

	dialogue.queue_free()
	await process_frame

func _check_final_field_epilogue() -> void:
	_reset_state()
	var scene: Dictionary = _chapter_data().get_scene("final_field_epilogue")
	if scene.is_empty():
		_failures.append("final field epilogue scene missing")
		return
	_expect_equal(str(scene.get("theme", "")), "first_person_field", "final field epilogue theme mismatch")
	if not bool(scene.get("hide_player", false)):
		_failures.append("final field epilogue should hide the third-person player")
	if not bool(scene.get("hide_hud", false)):
		_failures.append("final field epilogue should hide HUD controls")
	if not bool(scene.get("suppress_alienation_filter", false)):
		_failures.append("final field epilogue should suppress grayscale alienation filter")
	var ending_node: Dictionary = _chapter_data().get_dialogue("d_final_three_endings")
	var ending_choice: Dictionary = _find_by_id(ending_node.get("choices", []), "ending_auto_resolve")
	_expect_equal(str(ending_choice.get("next_scene", "")), "final_field_epilogue", "final ending should route to field epilogue")

	var dialogue := DialoguePacked.instantiate()
	root.add_child(dialogue)
	await process_frame

	_game_state().flags["final_ending"] = "self_return"
	dialogue.show_dialogue("n_final_field_epilogue")
	await process_frame
	var line_label: Label = dialogue.get("_line_label")
	if line_label == null or not str(line_label.text).contains("风声没有替你总结什么"):
		_failures.append("self-return field epilogue first page mismatch")
	dialogue._close_or_advance()
	await process_frame
	if line_label == null or not str(line_label.text).contains("完成度报告"):
		_failures.append("field epilogue did not advance to second page")

	_game_state().flags["final_ending"] = "optimized_life"
	dialogue.show_dialogue("n_final_field_epilogue")
	await process_frame
	if line_label == null or not str(line_label.text).contains("没有被上传的数据"):
		_failures.append("optimized-life field epilogue should not claim recovered self")

	_game_state().flags["final_ending"] = "coexistence"
	dialogue.show_dialogue("n_final_field_epilogue")
	await process_frame
	if line_label == null or not str(line_label.text).contains("屏幕没有消失"):
		_failures.append("coexistence field epilogue first page mismatch")

	dialogue.queue_free()
	await process_frame

func _check_bridge_sunset_transition() -> void:
	var chapter_data := _chapter_data()
	var ending: Dictionary = chapter_data.get_dialogue("d_vertical_slice_ending")
	if ending.is_empty():
		_failures.append("vertical slice ending dialogue missing")
		return

	for choice_id in ["slice_to_campus_self", "slice_to_campus_ai"]:
		var choice: Dictionary = _find_by_id(ending.get("choices", []), choice_id)
		_expect_equal(str(choice.get("next_scene", "")), "bridge_sunset_transition", "%s should route through bridge sunset transition" % choice_id)

	var bridge: Dictionary = chapter_data.get_scene("bridge_sunset_transition")
	if bridge.is_empty():
		_failures.append("bridge sunset transition scene missing")
		return

	_expect_equal(str(bridge.get("chapter", "")), "chapter_2", "bridge sunset transition should remain in Chapter 2")
	_expect_equal(str(bridge.get("theme", "")), "bridge_sunset_first_person", "bridge sunset transition theme mismatch")
	_expect_equal(str(bridge.get("narration", "")), "n_bridge_sunset_transition", "bridge sunset transition narration mismatch")
	if not bool(bridge.get("hide_player", false)):
		_failures.append("bridge sunset transition should hide the third-person player")
	if not bool(bridge.get("hide_hud", false)):
		_failures.append("bridge sunset transition should hide HUD controls")

	var routes_to_campus := false
	for interactable in bridge.get("interactables", []):
		if not interactable.has("dialogue"):
			continue
		var dialogue: Dictionary = chapter_data.get_dialogue(str(interactable.get("dialogue", "")))
		for choice in dialogue.get("choices", []):
			if str(choice.get("next_scene", "")) == "university_campus":
				routes_to_campus = true

	if not routes_to_campus:
		_failures.append("bridge sunset transition does not route onward to university_campus")

func _check_success_guidance_targets() -> void:
	_reset_state()
	var game_state := _game_state()
	var targets: Dictionary = game_state.get_success_targets()
	_expect_equal(targets.size(), 3, "success targets should expose only core public metrics")
	if targets.has("ability_exp") or targets.has("wealth_score") or targets.has("success_progress"):
		_failures.append("success targets should not expose deprecated metrics")
	_expect_equal(int(targets.get("resume_score", 0)), 92, "success target resume mismatch")
	_expect_equal(int(targets.get("network_score", 0)), 71, "success target network mismatch")
	_expect_equal(int(targets.get("stability_score", 0)), 96, "success target stability mismatch")

	game_state.stats["resume_score"] = 80
	game_state.stats["network_score"] = 50
	game_state.stats["stability_score"] = 95
	var before_stats: Dictionary = game_state.stats.duplicate(true)
	var gaps: Array[Dictionary] = game_state.get_success_gaps()
	if gaps.size() < 3:
		_failures.append("success guidance did not return expected gaps")
	else:
		_expect_equal(str(gaps[0].get("stat_id", "")), "network_score", "success gaps should sort by largest gap")
		_expect_equal(str(gaps[0].get("severity", "")), "strong", "large success gap should be strong")
		_expect_equal(str(gaps[1].get("stat_id", "")), "resume_score", "second success gap mismatch")
		_expect_equal(str(gaps[1].get("severity", "")), "normal", "medium success gap should be normal")
		_expect_equal(str(gaps[2].get("severity", "")), "minor", "small success gap should be minor")
	_expect_equal(game_state.stats, before_stats, "success guidance query should not mutate stats")

func _check_stat_simplification_and_legacy_migration() -> void:
	_reset_state()
	var game_state := _game_state()
	for deprecated_id in ["sleep", "ability_exp", "wealth_score", "language_assimilation", "success_progress"]:
		if game_state.stats.has(deprecated_id):
			_failures.append("default stats should not include deprecated stat %s" % deprecated_id)

	game_state.stats["resume_score"] = 80
	game_state.adjust_stat("ability_exp", 5)
	_expect_equal(int(game_state.stats.get("resume_score", 0)), 85, "legacy ability should map to career capital")
	game_state.adjust_stat("success_progress", -50)
	if game_state.stats.has("success_progress"):
		_failures.append("derived success_progress write should not create stored stat")
	_expect_equal(game_state.get_stat_value("success_progress"), game_state.get_success_progress(), "legacy success value should be derived")

	var legacy_save: Dictionary = game_state.get_save_data()
	legacy_save["stats"] = {
		"heart": 30,
		"family": 35,
		"clarity": 40,
		"ai_dependence": 20,
		"resume_score": 80,
		"network_score": 60,
		"stability_score": 70,
		"ability_exp": 90,
		"wealth_score": 96,
		"sleep": 10,
		"language_assimilation": 88,
		"success_progress": 33,
	}
	game_state.load_save_data(legacy_save)
	await process_frame
	_expect_equal(int(game_state.stats.get("resume_score", 0)), 82, "legacy ability migration mismatch")
	_expect_equal(int(game_state.stats.get("stability_score", 0)), 72, "legacy wealth migration mismatch")
	for deprecated_id in ["sleep", "ability_exp", "wealth_score", "language_assimilation", "success_progress"]:
		if game_state.stats.has(deprecated_id):
			_failures.append("loaded stats should strip deprecated stat %s" % deprecated_id)

func _check_success_guidance_hud_modes() -> void:
	_reset_state()
	var hud := HUDPacked.instantiate()
	root.add_child(hud)
	await process_frame

	var game_state := _game_state()
	game_state.stats["resume_score"] = 80
	game_state.current_chapter_id = "chapter_3"
	game_state.current_scene_id = "club_recruitment"
	var before_stats: Dictionary = game_state.stats.duplicate(true)
	hud.notify_progress_checkpoint()
	await process_frame
	if not bool(hud.get("_ai_panel").visible):
		_failures.append("success guidance did not auto-open in early chapter")
	if not str(hud.get("_ai_body").text).contains("成功路径校准"):
		_failures.append("success guidance early HUD text missing calibration title")
	if str(hud.get("_ai_close_button").text) != "关闭":
		_failures.append("success guidance early HUD should be closable")
	_expect_equal(game_state.stats, before_stats, "success guidance HUD should not mutate stats")

	hud.get("_ai_panel").visible = false
	game_state.current_chapter_id = "chapter_6"
	game_state.current_scene_id = "starloop_office"
	game_state.stats["network_score"] = 45
	hud.set("_last_guidance_signature", "")
	hud.notify_progress_checkpoint()
	await process_frame
	if not bool(hud.get("_ai_panel").visible):
		_failures.append("success guidance did not auto-open in late chapter")
	if not str(hud.get("_ai_body").text).contains("强制校准"):
		_failures.append("success guidance late HUD text missing strong calibration")
	if str(hud.get("_ai_close_button").text) != "CONTINUE":
		_failures.append("success guidance late HUD should require CONTINUE")

	hud.queue_free()
	await process_frame

func _check_stats_panel_toggle() -> void:
	_reset_state()
	var hud := HUDPacked.instantiate()
	root.add_child(hud)
	await process_frame

	var panel: PanelContainer = hud.get("_stats_panel")
	var toggle: Button = hud.get("_stats_toggle_button")
	if panel == null:
		_failures.append("HUD stats panel missing")
	elif panel.visible:
		_failures.append("HUD stats panel should start collapsed")
	if toggle == null:
		_failures.append("HUD stats toggle missing")
	else:
		if not str(toggle.text).contains("指标"):
			_failures.append("HUD stats toggle should advertise metric panel when collapsed")
		toggle.pressed.emit()
		await process_frame
		if panel != null and not panel.visible:
			_failures.append("HUD stats panel did not open from toggle")
		if not str(toggle.text).contains("收起"):
			_failures.append("HUD stats toggle should switch to collapse text when open")
		hud.refresh()
		await process_frame
		if panel != null and not panel.visible:
			_failures.append("HUD stats panel should stay open after refresh")
		toggle.pressed.emit()
		await process_frame
		if panel != null and panel.visible:
			_failures.append("HUD stats panel did not collapse from toggle")

	hud.queue_free()
	await process_frame

func _check_scene_entry_guidance() -> void:
	_reset_state()
	var main := MainScene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	var hud: Node = main.get("hud")
	if hud == null:
		_failures.append("main HUD missing for scene entry guidance")
		main.queue_free()
		await process_frame
		return

	main._load_scene("school_hallway")
	await process_frame
	var focus_label: Label = hud.get("_focus_label")
	if not str(focus_label.text).contains("志愿填报栏"):
		_failures.append("school hallway entry hint did not point to first objective")

	hud.set_focus_text("林舟")
	await process_frame
	_expect_equal(str(focus_label.text), "可交互：林舟", "focused interactable should override entry hint")

	hud.set_focus_text("")
	await process_frame
	if not str(focus_label.text).contains("志愿填报栏"):
		_failures.append("entry hint did not restore after focus cleared")

	main._load_scene("resume_pipeline")
	await process_frame
	if not str(focus_label.text).contains("简历优化"):
		_failures.append("resume pipeline entry hint did not update after scene load")

	main.queue_free()
	await process_frame

func _check_cruise_player_layering() -> void:
	_reset_state()
	var main := MainScene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	var world: Node = main.get("world")
	if world == null:
		_failures.append("main world missing for cruise layering check")
	else:
		var player: Node2D = world.get("player")
		if player == null:
			_failures.append("world player missing for cruise layering check")
		elif player.z_index <= 6:
			_failures.append("cruise player should render above success panel prop")

	main.queue_free()
	await process_frame

func _check_ai_cost_button_labels() -> void:
	_reset_state()
	var dialogue := DialoguePacked.instantiate()
	root.add_child(dialogue)
	await process_frame

	_game_state().ai_stage = 4
	dialogue.show_dialogue("d_reunion_to_resume")
	await process_frame
	var dialogue_has_cost := false
	for button in _find_buttons(dialogue):
		if button.text.contains("心力 -4"):
			dialogue_has_cost = true
	if not dialogue_has_cost:
		_failures.append("AI dialogue choice did not show current heart cost")

	dialogue.queue_free()
	await process_frame

	_reset_state()
	var pressure := PressurePacked.instantiate()
	root.add_child(pressure)
	await process_frame

	_game_state().ai_stage = 0
	pressure.start("family_dinner")
	await process_frame
	var pressure_has_cost := false
	for button in _find_buttons(pressure):
		if button.text.contains("智能优化") and button.text.contains("心力 -2"):
			pressure_has_cost = true
	if not pressure_has_cost:
		_failures.append("AI pressure action did not show current heart cost")

	pressure.queue_free()
	await process_frame

func _check_alienation_visual_state() -> void:
	_reset_state()
	var game_state := _game_state()
	var before_stats: Dictionary = game_state.stats.duplicate(true)
	var state: Dictionary = game_state.get_alienation_visual_state()
	_expect_equal(str(state.get("mode", "")), "normal", "alienation should start in normal color")
	_expect_equal(float(state.get("intensity", -1.0)), 0.0, "normal alienation intensity mismatch")
	_expect_equal(game_state.stats, before_stats, "alienation state query should not mutate stats")

	game_state.current_chapter_id = "chapter_5"
	state = game_state.get_alienation_visual_state()
	_expect_equal(str(state.get("mode", "")), "gradient", "chapter 5 should start gradual alienation")
	if float(state.get("intensity", 0.0)) <= 0.0 or float(state.get("intensity", 0.0)) >= 1.0:
		_failures.append("chapter 5 alienation should be partial grayscale")

	var chapter_intensity := float(state.get("intensity", 0.0))
	game_state.stats["ai_dependence"] = 55
	state = game_state.get_alienation_visual_state()
	if float(state.get("intensity", 0.0)) <= chapter_intensity:
		_failures.append("AI dependence should increase alienation intensity")

	game_state.current_chapter_id = "chapter_6"
	game_state.stats["heart"] = 25
	game_state.stats["ai_dependence"] = 70
	state = game_state.get_alienation_visual_state()
	_expect_equal(str(state.get("mode", "")), "persistent", "low heart and high AI dependence should force persistent grayscale")

	game_state.current_chapter_id = "chapter_0"
	state = game_state.get_alienation_visual_state()
	_expect_equal(str(state.get("mode", "")), "persistent", "persistent grayscale should not require reversal chapter")

func _check_alienation_visual_filter() -> void:
	_reset_state()
	var filter: CanvasLayer = AlienationVisualFilterScript.new()
	root.add_child(filter)
	await process_frame

	_expect_equal(filter.layer, 90, "alienation filter should cover all UI layers")
	_expect_equal(filter.get_visual_mode(), "normal", "alienation filter initial mode mismatch")
	_expect_float_near(filter.get_filter_amount(), 0.0, "alienation filter should start transparent")

	var game_state := _game_state()
	game_state.current_chapter_id = "chapter_5"
	filter.refresh_from_state(true)
	_expect_equal(filter.get_visual_mode(), "gradient", "alienation filter did not enter gradient mode")
	var chapter_target := float(filter.get_target_filter_amount())
	if chapter_target <= 0.0 or chapter_target >= 1.0:
		_failures.append("gradient target should start as partial grayscale")
	_expect_float_near(filter.get_filter_amount(), chapter_target, "instant gradient refresh should reach target")

	filter.refresh_checkpoint_state()
	_expect_float_near(filter.get_filter_amount(), chapter_target, "checkpoint should not jump to full grayscale")

	game_state.adjust_stat("ai_dependence", 20)
	await process_frame
	var ai_target := float(filter.get_target_filter_amount())
	if ai_target <= chapter_target:
		_failures.append("AI dependence increase should raise grayscale target")
	if filter.get_filter_amount() >= ai_target:
		_failures.append("AI dependence increase should fade gradually instead of jumping to target")
	await create_timer(1.5).timeout
	_expect_float_near(filter.get_filter_amount(), ai_target, "AI dependence increase should settle at raised grayscale target")

	game_state.stats["heart"] = 25
	game_state.stats["ai_dependence"] = 70
	filter.refresh_from_state()
	_expect_equal(filter.get_visual_mode(), "persistent", "alienation filter did not enter persistent mode")
	if filter.get_filter_amount() >= 1.0:
		_failures.append("persistent alienation should fade to full grayscale instead of jumping")
	await create_timer(2.1).timeout
	_expect_float_near(filter.get_filter_amount(), 1.0, "persistent alienation should settle at full grayscale")
	filter.refresh_checkpoint_state()
	_expect_equal(filter.get_visual_mode(), "persistent", "checkpoint should not override persistent mode")
	_expect_float_near(filter.get_filter_amount(), 1.0, "persistent mode should stay fully grayscale")

	game_state.current_chapter_id = "chapter_0"
	game_state.stats["heart"] = 42
	game_state.stats["ai_dependence"] = 12
	filter.refresh_from_state(true)
	_expect_equal(filter.get_visual_mode(), "normal", "alienation filter did not return to normal mode")
	_expect_float_near(filter.get_filter_amount(), 0.0, "normal mode should clear grayscale")

	filter.queue_free()
	await process_frame

func _check_final_field_scene_presentation() -> void:
	_reset_state()
	var main := MainScene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	var world: Node = main.get("world")
	var hud: CanvasLayer = main.get("hud")
	var alienation_filter: CanvasLayer = main.get("alienation_filter")
	if world == null or hud == null or alienation_filter == null:
		_failures.append("final field presentation modules missing")
		main.queue_free()
		await process_frame
		return

	_game_state().current_chapter_id = "chapter_8"
	_game_state().stats["heart"] = 25
	_game_state().stats["ai_dependence"] = 70
	if alienation_filter.has_method("refresh_from_state"):
		alienation_filter.refresh_from_state(true)
	main._load_scene("final_field_epilogue")
	await process_frame

	_expect_equal(str(world.get("current_scene_id")), "final_field_epilogue", "final field scene did not load")
	var player: Node = world.get("player")
	if player == null:
		_failures.append("final field player missing")
	elif bool(player.visible):
		_failures.append("final field scene should hide world player")
	if hud.visible:
		_failures.append("final field scene should hide HUD")
	if alienation_filter.has_method("get_visual_mode"):
		_expect_equal(alienation_filter.get_visual_mode(), "normal", "final field should suppress alienation filter")
	if alienation_filter.has_method("get_filter_amount"):
		_expect_float_near(alienation_filter.get_filter_amount(), 0.0, "final field should clear alienation amount")

	var background_root: Node = world.get_node_or_null("Background")
	if background_root == null or background_root.get_child_count() == 0:
		_failures.append("final field background did not render")

	main.queue_free()
	await process_frame

func _check_ai_dialogue_heart_cost() -> void:
	_reset_state()
	var dialogue := DialoguePacked.instantiate()
	root.add_child(dialogue)
	await process_frame

	var node: Dictionary = _chapter_data().get_dialogue("d_ai_notice")
	var choice: Dictionary = _find_by_id(node.get("choices", []), "notice_open")
	_game_state().ai_stage = 0
	dialogue.show_dialogue("d_ai_notice")
	dialogue._select_choice(choice)
	await process_frame

	_expect_equal(int(_game_state().stats.get("heart", 0)), 40, "AI dialogue should reduce heart by stage cost")
	_expect_equal(int(_game_state().stats.get("ai_dependence", 0)), 17, "AI dialogue old dependence effect should remain")

	dialogue.queue_free()
	await process_frame

func _check_non_ai_dialogue_does_not_reduce_heart() -> void:
	_reset_state()
	var dialogue := DialoguePacked.instantiate()
	root.add_child(dialogue)
	await process_frame

	var node: Dictionary = _chapter_data().get_dialogue("d_friend_time")
	var choice: Dictionary = _find_by_id(node.get("choices", []), "time_zhouxiao")
	dialogue.show_dialogue("d_friend_time")
	dialogue._select_choice(choice)
	await process_frame

	_expect_equal(int(_game_state().stats.get("heart", 0)), 42, "non-AI dialogue should not reduce heart")
	_expect_equal(int(_game_state().stats.get("clarity", 0)), 62, "non-AI dialogue should keep non-heart effects")

	dialogue.queue_free()
	await process_frame

func _check_dialogue_choice_triggers_once() -> void:
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
	var save_data: Dictionary = game_state.get_save_data()
	var clarity_after := int(game_state.stats.get("clarity", 0))
	var warmth_after := int(game_state.relationships["linzhou"].get("warmth", 0))
	var choices_after: int = game_state.choice_history.size()
	var feedback_after: int = game_state.feedback_log.size()

	dialogue._select_choice(choice)
	await process_frame
	_expect_equal(int(game_state.stats.get("clarity", 0)), clarity_after, "dialogue choice should not apply stats twice")
	_expect_equal(int(game_state.relationships["linzhou"].get("warmth", 0)), warmth_after, "dialogue choice should not apply relationship twice")
	_expect_equal(game_state.choice_history.size(), choices_after, "dialogue choice history should not duplicate")
	_expect_equal(game_state.feedback_log.size(), feedback_after, "dialogue feedback should not duplicate")

	dialogue.show_dialogue("d_linzhou_hallway")
	await process_frame
	if _button_text_found(dialogue, "说自己也没想清楚"):
		_failures.append("used dialogue choice should be hidden")

	game_state.reset_for_new_game()
	game_state.load_save_data(save_data)
	await process_frame
	dialogue.show_dialogue("d_linzhou_hallway")
	await process_frame
	if _button_text_found(dialogue, "说自己也没想清楚"):
		_failures.append("used dialogue choice should stay hidden after save load")

	dialogue.queue_free()
	await process_frame

func _check_auto_final_ending_triggers_once() -> void:
	_reset_state()
	var dialogue := DialoguePacked.instantiate()
	root.add_child(dialogue)
	await process_frame

	var node: Dictionary = _chapter_data().get_dialogue("d_final_three_endings")
	var choice: Dictionary = _find_by_id(node.get("choices", []), "ending_auto_resolve")
	dialogue.show_dialogue("d_final_three_endings")
	dialogue._select_choice(choice)
	await process_frame

	var game_state := _game_state()
	var settlement_count: int = game_state.settlement_history.size()
	var choices_after: int = game_state.choice_history.size()
	var final_ending := str(game_state.flags.get("final_ending", ""))
	dialogue._select_choice(choice)
	await process_frame

	_expect_equal(game_state.settlement_history.size(), settlement_count, "auto final ending settlement should not duplicate")
	_expect_equal(game_state.choice_history.size(), choices_after, "auto final ending choice should not duplicate")
	_expect_equal(str(game_state.flags.get("final_ending", "")), final_ending, "auto final ending flag should remain stable")

	dialogue.queue_free()
	await process_frame

func _check_ai_pressure_heart_cost() -> void:
	_reset_state()
	var pressure := PressurePacked.instantiate()
	root.add_child(pressure)
	await process_frame

	var encounter: Dictionary = _chapter_data().get_pressure("family_dinner")
	var action: Dictionary = _find_by_id(encounter.get("actions", []), "dinner_ai")
	_game_state().ai_stage = 0
	pressure.start("family_dinner")
	var local_heart_before := int(pressure.get("_heart"))
	pressure._select_action(action)
	await process_frame

	_expect_equal(int(_game_state().stats.get("heart", 0)), 40, "AI pressure action should reduce global heart by stage cost")
	_expect_equal(int(pressure.get("_heart")), local_heart_before - 2, "AI pressure action should reduce local heart by stage cost")

	pressure.queue_free()
	await process_frame

func _check_non_ai_pressure_does_not_reduce_heart() -> void:
	_reset_state()
	var pressure := PressurePacked.instantiate()
	root.add_child(pressure)
	await process_frame

	var encounter: Dictionary = _chapter_data().get_pressure("family_dinner")
	var action: Dictionary = _find_by_id(encounter.get("actions", []), "dinner_direct")
	pressure.start("family_dinner")
	var local_heart_before := int(pressure.get("_heart"))
	pressure._select_action(action)
	await process_frame

	_expect_equal(int(_game_state().stats.get("heart", 0)), 42, "non-AI pressure action should not reduce global heart")
	_expect_equal(int(pressure.get("_heart")), local_heart_before, "non-AI pressure action should not reduce local heart")

	pressure.queue_free()
	await process_frame

func _check_pressure_action_triggers_once() -> void:
	_reset_state()
	var pressure := PressurePacked.instantiate()
	root.add_child(pressure)
	await process_frame

	var encounter: Dictionary = _chapter_data().get_pressure("family_dinner")
	var action: Dictionary = _find_by_id(encounter.get("actions", []), "dinner_ai")
	_game_state().ai_stage = 0
	pressure.start("family_dinner")
	var pressure_after_start := int(pressure.get("_pressure"))
	pressure._select_action(action)
	await process_frame

	var game_state := _game_state()
	var global_heart_after := int(game_state.stats.get("heart", 0))
	var local_heart_after := int(pressure.get("_heart"))
	var pressure_after := int(pressure.get("_pressure"))
	var choices_after: int = game_state.choice_history.size()
	var feedback_after: int = game_state.feedback_log.size()
	pressure._select_action(action)
	await process_frame

	_expect_equal(int(game_state.stats.get("heart", 0)), global_heart_after, "pressure action should not reduce global heart twice")
	_expect_equal(int(pressure.get("_heart")), local_heart_after, "pressure action should not reduce local heart twice")
	_expect_equal(int(pressure.get("_pressure")), pressure_after, "pressure action should not change pressure twice")
	_expect_equal(game_state.choice_history.size(), choices_after, "pressure action choice history should not duplicate")
	_expect_equal(game_state.feedback_log.size(), feedback_after, "pressure action feedback should not duplicate")
	if pressure_after >= pressure_after_start:
		_failures.append("pressure action did not apply first pressure delta")

	pressure.start("family_dinner")
	await process_frame
	if _button_text_found(pressure, "智能优化"):
		_failures.append("used pressure action should be hidden")

	pressure.queue_free()
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
	var action_ids := ["dinner_ai", "dinner_package", "dinner_direct", "dinner_evidence"]
	pressure.start("family_dinner")
	for action_id in action_ids:
		var action: Dictionary = _find_by_id(encounter.get("actions", []), action_id)
		pressure._select_action(action)
		await process_frame
		if bool(pressure.get("_done")):
			break

	_expect_equal(_game_state().flags.get("family_dinner_done"), "success", "pressure success flag not persisted")
	_expect_equal(int(_game_state().stats.get("family", 0)), 60, "pressure success effects not applied")
	if _game_state().stats.has("success_progress"):
		_failures.append("pressure success should not create deprecated success_progress stat")

	pressure.queue_free()
	await process_frame

func _check_pressure_failure() -> void:
	_reset_state()
	var pressure := PressurePacked.instantiate()
	root.add_child(pressure)
	await process_frame

	var encounter: Dictionary = _chapter_data().get_pressure("family_dinner")
	var action: Dictionary = _find_by_id(encounter.get("actions", []), "dinner_delay")
	pressure.start("family_dinner")
	pressure.set("_rounds", 1)
	pressure._select_action(action)
	await process_frame

	_expect_equal(_game_state().flags.get("family_dinner_done"), "failure", "pressure failure flag not persisted")
	_expect_equal(int(_game_state().stats.get("family", 0)), 35, "pressure failure effects not applied")

	pressure.queue_free()
	await process_frame

func _check_new_pressure_success_failure_branches() -> void:
	var encounter_id := _find_new_pressure_encounter_with_branches()
	if encounter_id.is_empty():
		_failures.append("no Chapter 3-8 pressure encounter exposes success and failure branches")
		return

	await _check_pressure_branch_can_finish(encounter_id, true)
	await _check_pressure_branch_can_finish(encounter_id, false)

func _check_pressure_actions_exhaust_to_failure() -> void:
	_reset_state()
	var pressure := PressurePacked.instantiate()
	root.add_child(pressure)
	await process_frame

	var encounter: Dictionary = _chapter_data().get_pressure("family_dinner")
	pressure.start("family_dinner")
	pressure.set("_pressure", 100)
	pressure.set("_heart", 100)
	pressure.set("_rounds", 10)
	for action in encounter.get("actions", []):
		pressure._select_action(action)
		await process_frame
		if bool(pressure.get("_done")):
			break

	_expect_equal(_game_state().flags.get("family_dinner_done"), "failure", "exhausted pressure actions should fail encounter")

	pressure.queue_free()
	await process_frame

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
	var alienation_filter: Node = main.get("alienation_filter")
	if world == null or dialogue == null or pressure == null or alienation_filter == null:
		_failures.append("main scene modules missing")
		main.queue_free()
		await process_frame
		return
	_expect_equal(alienation_filter.layer, 90, "main alienation filter should cover full screen")

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

func _expect_has_choice(choices: Array, expected_id: String, message: String) -> void:
	for choice in choices:
		if str(choice.get("id", "")) == expected_id:
			return
	_failures.append(message)

func _dialogue_has_non_ai_transition_to(choices: Array, expected_scene: String) -> bool:
	for choice in choices:
		if str(choice.get("strategy", "")) == "ai":
			continue
		if str(choice.get("next_scene", "")) == expected_scene:
			return true
	return false

func _find_buttons(node: Node) -> Array[Button]:
	var buttons: Array[Button] = []
	if node is Button:
		buttons.append(node)
	for child in node.get_children():
		buttons.append_array(_find_buttons(child))
	return buttons

func _button_text_found(node: Node, expected_text: String) -> bool:
	for button in _find_buttons(node):
		if str(button.text).contains(expected_text):
			return true
	return false

func _reset_state() -> void:
	_game_state().reset_for_new_game()

func _expect_equal(actual, expected, message: String) -> void:
	if actual != expected:
		_failures.append("%s: expected %s got %s" % [message, str(expected), str(actual)])

func _expect_float_near(actual: float, expected: float, message: String) -> void:
	if absf(actual - expected) > 0.001:
		_failures.append("%s: expected %.3f got %.3f" % [message, expected, actual])

func _game_state() -> Node:
	return root.get_node("GameState")

func _chapter_data() -> Node:
	return root.get_node("ChapterData")
