extends Node

const WorldScenePacked = preload("res://scenes/WorldScene.tscn")
const HUDPacked = preload("res://scenes/ui/HUD.tscn")
const DialoguePacked = preload("res://scenes/ui/DialoguePanel.tscn")
const PressurePacked = preload("res://scenes/ui/PressureEncounter.tscn")
const AlienationVisualFilterScript = preload("res://scripts/ui/alienation_visual_filter.gd")
const BackgroundMusicControllerScript = preload("res://scripts/audio/background_music_controller.gd")

var world: Node
var hud: CanvasLayer
var dialogue: CanvasLayer
var pressure: CanvasLayer
var alienation_filter: CanvasLayer
var background_music: Node

func _ready() -> void:
	_game_state().reset_for_new_game()

	background_music = BackgroundMusicControllerScript.new()
	add_child(background_music)

	world = WorldScenePacked.instantiate()
	add_child(world)

	hud = HUDPacked.instantiate()
	add_child(hud)

	dialogue = DialoguePacked.instantiate()
	add_child(dialogue)

	pressure = PressurePacked.instantiate()
	add_child(pressure)

	alienation_filter = AlienationVisualFilterScript.new()
	add_child(alienation_filter)

	world.connect("interactable_focused", Callable(self, "_on_interactable_focused"))
	world.connect("interactable_unfocused", Callable(self, "_on_interactable_unfocused"))
	world.connect("interactable_activated", Callable(self, "_on_interactable_activated"))
	world.connect("scene_loaded", Callable(self, "_on_scene_loaded"))

	hud.connect("joystick_changed", Callable(self, "_on_joystick_changed"))
	hud.connect("interact_pressed", Callable(self, "_on_interact_pressed"))
	hud.connect("ai_pressed", Callable(self, "_on_ai_pressed"))
	hud.connect("bag_pressed", Callable(self, "_on_bag_pressed"))

	dialogue.connect("scene_requested", Callable(self, "_load_scene"))
	pressure.connect("encounter_finished", Callable(self, "_load_scene"))

	_update_scene_guidance(world.scene_data)
	_update_scene_presentation(world.scene_data)
	_show_scene_narration(world.scene_data)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		world.activate_current()
	elif event.is_action_pressed("ai_assist"):
		hud.show_ai_hint()
	elif event.is_action_pressed("open_bag"):
		hud.show_bag()

func _on_interactable_focused(marker: Area2D) -> void:
	hud.set_focus_text(marker.get_display_name())

func _on_interactable_unfocused() -> void:
	hud.set_focus_text("")

func _on_interactable_activated(data: Dictionary) -> void:
	var kind := str(data.get("kind", ""))
	var gated_dialogue := _gate_dialogue(data)
	if not gated_dialogue.is_empty():
		dialogue.show_dialogue(gated_dialogue)
		return
	if kind == "pressure":
		pressure.start(str(data.get("pressure", "")))
	else:
		dialogue.show_dialogue(str(data.get("dialogue", "")))

func _on_joystick_changed(value: Vector2) -> void:
	world.player.set_joystick_vector(value)

func _on_interact_pressed() -> void:
	world.activate_current()

func _on_ai_pressed() -> void:
	hud.show_ai_hint()

func _on_bag_pressed() -> void:
	hud.show_bag()

func _load_scene(scene_id: String) -> void:
	if scene_id.is_empty():
		return
	world.load_scene(scene_id)
	_update_scene_guidance(world.scene_data)
	hud.set_focus_text("")
	hud.refresh()
	hud.notify_progress_checkpoint()

func _on_scene_loaded(_scene_id: String, scene_data: Dictionary) -> void:
	_update_scene_guidance(scene_data)
	_update_scene_presentation(scene_data)
	if background_music != null and background_music.has_method("set_scene_context"):
		background_music.set_scene_context(_scene_id, str(scene_data.get("chapter", "")))
	_show_scene_narration(scene_data)
	hud.notify_progress_checkpoint()
	if alienation_filter != null and alienation_filter.has_method("refresh_checkpoint_state"):
		alienation_filter.refresh_checkpoint_state()

func _show_scene_narration(scene_data: Dictionary) -> void:
	var narration_id := str(scene_data.get("narration", ""))
	if narration_id.is_empty():
		return
	dialogue.show_dialogue(narration_id)

func _update_scene_guidance(scene_data: Dictionary) -> void:
	if hud == null or not hud.has_method("set_default_focus_hint"):
		return
	hud.set_default_focus_hint(str(scene_data.get("entry_hint", "")))

func _update_scene_presentation(scene_data: Dictionary) -> void:
	if hud != null:
		hud.visible = not bool(scene_data.get("hide_hud", false))
	if alienation_filter != null and alienation_filter.has_method("set_scene_suppressed"):
		alienation_filter.set_scene_suppressed(bool(scene_data.get("suppress_alienation_filter", false)))

func _gate_dialogue(data: Dictionary) -> String:
	var interactable_id := str(data.get("id", ""))
	var flags: Dictionary = _game_state().get("flags")
	if interactable_id == "terminal_exit" and not flags.has("volunteer_done"):
		return "d_gate_volunteer_required"
	if interactable_id == "ending_gate":
		if not flags.has("message_done") or not flags.has("friend_time"):
			return "d_gate_graduation_required"
	return ""

func _game_state() -> Node:
	return get_node("/root/GameState")
