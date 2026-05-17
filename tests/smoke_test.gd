extends SceneTree

const MainScene = preload("res://scenes/Main.tscn")
const GameStateScript = preload("res://scripts/autoload/game_state.gd")
const ChapterDataScript = preload("res://scripts/data/chapter_data.gd")

func _initialize() -> void:
	var game_state := GameStateScript.new()
	game_state.name = "GameState"
	root.add_child(game_state)

	var chapter_data := ChapterDataScript.new()
	chapter_data.name = "ChapterData"
	root.add_child(chapter_data)
	await process_frame

	var failures: Array[String] = []

	for scene_id in ["cruise_deck", "school_hallway", "computer_room", "dinner_table", "graduation_field", "bridge_sunset_transition"]:
		var scene_data: Dictionary = _chapter_data().get_scene(scene_id)
		if scene_data.is_empty():
			failures.append("missing scene: %s" % scene_id)
			continue
		var narration_id := str(scene_data.get("narration", ""))
		if narration_id.is_empty() or _chapter_data().get_dialogue(narration_id).is_empty():
			failures.append("missing narration %s in %s" % [narration_id, scene_id])
		for interactable in scene_data.get("interactables", []):
			if interactable.has("dialogue") and _chapter_data().get_dialogue(str(interactable["dialogue"])).is_empty():
				failures.append("missing dialogue %s in %s" % [str(interactable["dialogue"]), scene_id])
			if interactable.has("pressure") and _chapter_data().get_pressure(str(interactable["pressure"])).is_empty():
				failures.append("missing pressure %s in %s" % [str(interactable["pressure"]), scene_id])

	for dialogue_id in [
		"d_life_replay",
		"d_volunteer_terminal",
		"d_graduation_message",
		"d_friend_time",
		"d_vertical_slice_ending",
		"n_bridge_sunset_transition",
		"d_bridge_to_campus",
	]:
		var dialogue: Dictionary = _chapter_data().get_dialogue(dialogue_id)
		if dialogue.is_empty():
			failures.append("missing dialogue: %s" % dialogue_id)
			continue
		for choice in dialogue.get("choices", []):
			var next_scene := str(choice.get("next_scene", ""))
			if not next_scene.is_empty() and _chapter_data().get_scene(next_scene).is_empty():
				failures.append("choice %s points to missing scene %s" % [str(choice.get("id", "")), next_scene])

	var main := MainScene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	if main.get("world") == null:
		failures.append("main world not initialized")
	if main.get("hud") == null:
		failures.append("main hud not initialized")

	if failures.is_empty():
		print("SMOKE TEST PASSED")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _chapter_data() -> Node:
	return root.get_node("ChapterData")
