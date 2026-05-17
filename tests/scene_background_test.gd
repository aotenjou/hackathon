extends SceneTree

const WorldSceneScript = preload("res://scripts/gameplay/world_scene.gd")
const GameStateScript = preload("res://scripts/autoload/game_state.gd")
const ChapterDataScript = preload("res://scripts/data/chapter_data.gd")

var _failures: Array[String] = []

func _initialize() -> void:
	var game_state := GameStateScript.new()
	game_state.name = "GameState"
	root.add_child(game_state)
	game_state.reset_for_new_game()

	var chapter_data := ChapterDataScript.new()
	chapter_data.name = "ChapterData"
	root.add_child(chapter_data)

	var world := WorldSceneScript.new()
	root.add_child(world)
	await process_frame

	var expected_paths := {
		"university_campus": WorldSceneScript.UNIVERSITY_CAMPUS_BACKGROUND_PATH,
		"internet_cafe_demo": WorldSceneScript.INTERNET_CAFE_BACKGROUND_PATH,
		"resume_pipeline": WorldSceneScript.RESUME_PIPELINE_BACKGROUND_PATH,
		"offer_arrival": WorldSceneScript.OFFER_ARRIVAL_BACKGROUND_PATH,
		"starloop_lobby": WorldSceneScript.STARLOOP_LOBBY_BACKGROUND_PATH,
		"starloop_office": WorldSceneScript.STARLOOP_OFFICE_BACKGROUND_PATH,
		"model_ops_layer": WorldSceneScript.MODEL_OPS_LAYER_BACKGROUND_PATH,
		"city_demo_center": WorldSceneScript.CITY_DEMO_CENTER_BACKGROUND_PATH,
		"final_overlay": WorldSceneScript.FINAL_OVERLAY_BACKGROUND_PATH,
	}

	for scene_id in expected_paths.keys():
		world.load_scene(scene_id)
		await process_frame
		_expect_fullscreen_background(world, scene_id, str(expected_paths[scene_id]))

	if _failures.is_empty():
		print("SCENE BACKGROUND TEST PASSED")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)

func _expect_fullscreen_background(world: Node, scene_id: String, expected_path: String) -> void:
	var background_root := world.get_node_or_null("Background")
	if background_root == null:
		_failures.append("%s missing Background root" % scene_id)
		return

	var background := background_root.get_node_or_null("FullscreenBackground")
	if background == null:
		_failures.append("%s missing FullscreenBackground sprite" % scene_id)
		return
	if not background is Sprite2D:
		_failures.append("%s FullscreenBackground should be Sprite2D" % scene_id)
		return

	var sprite := background as Sprite2D
	if sprite.texture == null:
		_failures.append("%s FullscreenBackground texture did not load" % scene_id)
	elif sprite.texture.get_size() != Vector2(1600, 900):
		_failures.append("%s FullscreenBackground texture should be 1600x900, got %s" % [scene_id, str(sprite.texture.get_size())])
	if str(sprite.get_meta("source_path", "")) != expected_path:
		_failures.append("%s expected background %s, got %s" % [scene_id, expected_path, str(sprite.get_meta("source_path", ""))])
	if sprite.position != Vector2(800, 450):
		_failures.append("%s FullscreenBackground should be centered in 1600x900 viewport" % scene_id)
	if sprite.scale.x <= 0.0 or sprite.scale.y <= 0.0:
		_failures.append("%s FullscreenBackground should have positive scale" % scene_id)
