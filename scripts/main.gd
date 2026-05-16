extends Node

const WorldScenePacked = preload("res://scenes/WorldScene.tscn")
const HUDPacked = preload("res://scenes/ui/HUD.tscn")
const DialoguePacked = preload("res://scenes/ui/DialoguePanel.tscn")
const PressurePacked = preload("res://scenes/ui/PressureEncounter.tscn")

var world: Node
var hud: CanvasLayer
var dialogue: CanvasLayer
var pressure: CanvasLayer

func _ready() -> void:
	_game_state().reset_for_new_game()

	world = WorldScenePacked.instantiate()
	add_child(world)

	hud = HUDPacked.instantiate()
	add_child(hud)

	dialogue = DialoguePacked.instantiate()
	add_child(dialogue)

	pressure = PressurePacked.instantiate()
	add_child(pressure)

	world.connect("interactable_focused", Callable(self, "_on_interactable_focused"))
	world.connect("interactable_unfocused", Callable(self, "_on_interactable_unfocused"))
	world.connect("interactable_activated", Callable(self, "_on_interactable_activated"))

	hud.connect("joystick_changed", Callable(self, "_on_joystick_changed"))
	hud.connect("interact_pressed", Callable(self, "_on_interact_pressed"))
	hud.connect("ai_pressed", Callable(self, "_on_ai_pressed"))
	hud.connect("bag_pressed", Callable(self, "_on_bag_pressed"))

	dialogue.connect("scene_requested", Callable(self, "_load_scene"))
	pressure.connect("encounter_finished", Callable(self, "_load_scene"))

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
	hud.set_focus_text("")
	hud.refresh()

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
