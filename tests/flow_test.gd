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

	var main := MainScene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame

	var failures: Array[String] = []
	var world: Node = main.get("world")
	var dialogue: Node = main.get("dialogue")
	var pressure: Node = main.get("pressure")
	var hud: Node = main.get("hud")

	if world == null or dialogue == null or pressure == null or hud == null:
		failures.append("main modules missing")
	else:
		world.load_scene("school_hallway")
		await process_frame
		if _game_state().current_scene_id != "school_hallway":
			failures.append("school_hallway did not load")

		dialogue.show_dialogue("d_life_replay")
		await process_frame
		if not dialogue.visible:
			failures.append("dialogue panel did not open")

		pressure.start("family_dinner")
		await process_frame
		if not pressure.visible:
			failures.append("pressure encounter did not open")

		hud.show_ai_hint()
		hud.show_bag()
		await process_frame

	if failures.is_empty():
		print("FLOW TEST PASSED")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _game_state() -> Node:
	return root.get_node("GameState")
