class_name InteractableMarker
extends Area2D

signal activated(marker: InteractableMarker)

var data := {}

@onready var _label: Label = $Label

func setup(interactable_data: Dictionary) -> void:
	data = interactable_data
	name = str(data.get("id", "interactable"))
	global_position = data.get("position", Vector2.ZERO)
	if is_node_ready():
		_apply_label()

func _ready() -> void:
	input_pickable = true
	_apply_label()

func activate() -> void:
	activated.emit(self)

func get_display_name() -> String:
	return str(data.get("name", data.get("label", name)))

func _apply_label() -> void:
	if data.is_empty() or _label == null:
		return
	_label.text = str(data.get("label", data.get("name", "交互")))

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		activate()
