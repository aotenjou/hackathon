extends Node

const TRACK_VOLUME_DB := -12.0
const STAGE_TRACKS := {
	"school": "res://assets/bgm/Isaac Shepard - Felicity.mp3",
	"college": "res://assets/bgm/mj apanay,aren park - time machine (feat. aren park).mp3",
	"work": "res://assets/bgm/dont be so serious.mp3",
	"final": "res://assets/bgm/give up.mp3",
}
const SCENE_TRACK_OVERRIDES := {
	"final_field_epilogue": "res://assets/bgm/Youzee Music - Tyndall.mp3",
}
const CHAPTER_STAGE := {
	"chapter_0": "school",
	"chapter_1": "school",
	"chapter_2": "school",
	"chapter_3": "college",
	"chapter_4": "college",
	"chapter_5": "work",
	"chapter_6": "work",
	"chapter_7": "final",
	"chapter_8": "final",
}

var _player: AudioStreamPlayer
var _current_stage := ""
var _current_scene_id := ""
var _current_track_path := ""

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.name = "BGMPlayer"
	_player.volume_db = TRACK_VOLUME_DB
	add_child(_player)

	var game_state := _game_state()
	if game_state != null:
		game_state.chapter_changed.connect(_on_chapter_changed)
		_on_chapter_changed(str(game_state.current_chapter_id))

func _on_chapter_changed(chapter_id: String) -> void:
	var stage := str(CHAPTER_STAGE.get(chapter_id, "school"))
	_apply_context(stage, _current_scene_id)

func set_scene_context(scene_id: String, chapter_id: String = "") -> void:
	var resolved_chapter_id := chapter_id
	if resolved_chapter_id.is_empty():
		var game_state := _game_state()
		if game_state != null:
			resolved_chapter_id = str(game_state.get("current_chapter_id"))
	var stage := str(CHAPTER_STAGE.get(resolved_chapter_id, "school"))
	_apply_context(stage, scene_id)

func get_current_stage() -> String:
	return _current_stage

func get_current_track_path() -> String:
	return _current_track_path

func _apply_context(stage: String, scene_id: String) -> void:
	var track_path := str(SCENE_TRACK_OVERRIDES.get(scene_id, STAGE_TRACKS.get(stage, "")))
	if stage == _current_stage and scene_id == _current_scene_id and track_path == _current_track_path:
		return
	_current_stage = stage
	_current_scene_id = scene_id
	_current_track_path = track_path
	_play_track(track_path)

func _play_track(track_path: String) -> void:
	if track_path.is_empty():
		_player.stop()
		return

	var stream := _load_audio_stream(track_path)
	if stream == null:
		push_warning("BGM track could not be loaded: %s" % track_path)
		_player.stop()
		return

	_configure_loop(stream)
	_player.stop()
	_player.stream = stream
	_player.play()

func _configure_loop(stream: Resource) -> void:
	for property in stream.get_property_list():
		if str(property.get("name", "")) == "loop":
			stream.set("loop", true)
			return

func _load_audio_stream(track_path: String) -> Resource:
	return load(track_path)

func _game_state() -> Node:
	var tree := get_tree()
	if tree == null or not tree.root.has_node("GameState"):
		return null
	return tree.root.get_node("GameState")
