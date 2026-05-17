extends SceneTree

const BackgroundMusicControllerScript = preload("res://scripts/audio/background_music_controller.gd")
const GameStateScript = preload("res://scripts/autoload/game_state.gd")

var _failures: Array[String] = []

func _initialize() -> void:
	var game_state := GameStateScript.new()
	game_state.name = "GameState"
	root.add_child(game_state)
	game_state.reset_for_new_game()

	var controller := BackgroundMusicControllerScript.new()
	root.add_child(controller)
	await process_frame

	_expect_track(controller, "chapter_0", "school", "Isaac Shepard - Felicity.mp3")
	_expect_track(controller, "chapter_3", "college", "time machine")
	_expect_track(controller, "chapter_5", "work", "dont be so serious.mp3")
	_expect_track(controller, "chapter_7", "final", "give up.mp3")
	controller.set_scene_context("final_field_epilogue", "chapter_8")
	_expect_current_track(controller, "final", "Youzee Music - Tyndall.mp3")

	if _failures.is_empty():
		print("BACKGROUND MUSIC TEST PASSED")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)

func _expect_track(controller: Node, chapter_id: String, expected_stage: String, expected_track_part: String) -> void:
	_game_state().chapter_changed.emit(chapter_id)
	_expect_current_track(controller, expected_stage, expected_track_part)

func _expect_current_track(controller: Node, expected_stage: String, expected_track_part: String) -> void:
	if str(controller.get_current_stage()) != expected_stage:
		_failures.append("current context should map to %s stage, got %s" % [expected_stage, str(controller.get_current_stage())])
	if not str(controller.get_current_track_path()).contains(expected_track_part):
		_failures.append("current context should play track containing %s, got %s" % [expected_track_part, str(controller.get_current_track_path())])
	var player := controller.get_node_or_null("BGMPlayer") as AudioStreamPlayer
	if player == null:
		_failures.append("background music player missing")
	elif player.stream == null:
		_failures.append("current context should load an audio stream for %s" % expected_track_part)

func _game_state() -> Node:
	return root.get_node("GameState")
