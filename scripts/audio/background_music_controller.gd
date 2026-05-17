extends Node

const TRACK_VOLUME_DB := -12.0
const STAGE_TRACKS := {
	"school": "res://assets/bgm/Isaac Shepard - Felicity.mp3",
	"college": "res://assets/bgm/mj apanay,aren park - time machine (feat. aren park).mp3",
	"work": "res://assets/bgm/dont be so serious.mp3",
	"final": "res://assets/bgm/give up.mp3",
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
	if stage == _current_stage:
		return
	_current_stage = stage
	_play_stage(stage)

func get_current_stage() -> String:
	return _current_stage

func get_current_track_path() -> String:
	return str(STAGE_TRACKS.get(_current_stage, ""))

func _play_stage(stage: String) -> void:
	var track_path := str(STAGE_TRACKS.get(stage, ""))
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
	if ClassDB.class_exists("AudioStreamMP3") and ClassDB.class_has_method("AudioStreamMP3", "load_from_file"):
		var mp3_stream := AudioStreamMP3.load_from_file(track_path)
		if mp3_stream != null:
			return mp3_stream
	return load(track_path)

func _game_state() -> Node:
	var tree := get_tree()
	if tree == null or not tree.root.has_node("GameState"):
		return null
	return tree.root.get_node("GameState")
