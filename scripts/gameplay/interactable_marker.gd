class_name InteractableMarker
extends Area2D

signal activated(marker: InteractableMarker)

var data := {}

@onready var _label: Label = $Label
@onready var _icon: Polygon2D = $Icon

func setup(interactable_data: Dictionary) -> void:
	data = interactable_data
	name = str(data.get("id", "interactable"))
	global_position = data.get("position", Vector2.ZERO)
	if is_node_ready():
		_apply_visuals()

func _ready() -> void:
	input_pickable = true
	_apply_visuals()

func activate() -> void:
	activated.emit(self)

func get_display_name() -> String:
	return str(data.get("name", data.get("label", name)))

func _apply_visuals() -> void:
	if data.is_empty() or _label == null:
		return
	var kind := str(data.get("kind", ""))
	_label.text = _marker_text(kind)
	_label.add_theme_color_override("font_color", Color("f6edd8"))
	if _icon != null:
		_icon.color = _marker_color(kind)
		_icon.scale = Vector2.ONE * (0.92 if kind == "npc" else 1.0)

func _marker_text(kind: String) -> String:
	match kind:
		"ai_panel", "terminal":
			return "◇\n" + str(data.get("label", data.get("name", "AI")))
		"npc":
			return "●\n" + str(data.get("label", data.get("name", "对话")))
		"pressure":
			return "!\n" + str(data.get("label", data.get("name", "压力")))
		"door":
			return "▶\n" + str(data.get("label", data.get("name", "继续")))
		_:
			return "!\n" + str(data.get("label", data.get("name", "交互")))

func _marker_color(kind: String) -> Color:
	match kind:
		"ai_panel", "terminal":
			return Color("22c7ff")
		"npc":
			return Color("f1f2ec")
		"pressure":
			return Color("ffc83d")
		"door":
			return Color("8be3ff")
		_:
			return Color("f0b332")

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		activate()
