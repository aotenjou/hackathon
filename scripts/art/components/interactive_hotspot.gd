class_name InteractiveHotspot
extends Area2D

signal focused(hotspot_id: String)
signal activated(hotspot_id: String)

const ArtTextureLoaderScript := preload("res://scripts/art/components/art_texture_loader.gd")
const HOTSPOT_BADGE_PATH := "res://assets/storyline/ch00_cruise_success/ui/ui_hotspot_badge.png"

var data := {}
var hotspot_id := ""

var _badge: Sprite2D
var _label: Label

func setup(hotspot_data: Dictionary) -> void:
	data = hotspot_data
	hotspot_id = str(data.get("id", "hotspot"))
	name = hotspot_id
	position = _array_to_vector2(data.get("position", [0, 0]))
	z_index = 50
	input_pickable = true

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = float(data.get("radius", 90))
	shape.shape = circle
	add_child(shape)

	_badge = Sprite2D.new()
	_badge.name = "Badge"
	_badge.texture = ArtTextureLoaderScript.load_png_texture(HOTSPOT_BADGE_PATH)
	_badge.scale = Vector2(0.48, 0.48)
	_badge.position = Vector2(0, -70)
	add_child(_badge)

	_label = Label.new()
	_label.name = "Label"
	_label.text = str(data.get("name", "交互"))
	_label.position = Vector2(-70, -44)
	_label.size = Vector2(140, 34)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 22)
	_label.add_theme_color_override("font_color", Color("f6edd8"))
	_label.add_theme_color_override("font_shadow_color", Color("05070a"))
	_label.add_theme_constant_override("shadow_offset_x", 2)
	_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(_label)

	input_event.connect(_on_input_event)

func set_focused(value: bool) -> void:
	scale = Vector2(1.15, 1.15) if value else Vector2.ONE
	_badge.modulate = Color("fff0b8") if value else Color.WHITE

func trigger() -> void:
	activated.emit(hotspot_id)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		focused.emit(hotspot_id)
		activated.emit(hotspot_id)

func _array_to_vector2(value) -> Vector2:
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO
