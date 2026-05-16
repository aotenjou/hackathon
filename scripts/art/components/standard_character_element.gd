class_name StandardCharacterElement
extends Node2D

var element_id := ""
var base_position := Vector2.ZERO
var movement_bounds := Rect2(80, 430, 1440, 285)

var _body_root: Node2D
var _head: ColorRect
var _body: ColorRect
var _phone: ColorRect
var _phone_glow: ColorRect
var _time := 0.0

func setup(element_data: Dictionary) -> void:
	element_id = str(element_data.get("id", "standard_character"))
	name = element_id
	position = _array_to_vector2(element_data.get("position", [0, 0]))
	base_position = position
	z_index = int(element_data.get("z_index", 20))
	_build()

func move_by(input_vector: Vector2, speed: float, delta: float) -> void:
	if input_vector.length() <= 0.05:
		return
	var next_position := base_position + input_vector.limit_length(1.0) * speed * delta
	next_position.x = clampf(next_position.x, movement_bounds.position.x, movement_bounds.end.x)
	next_position.y = clampf(next_position.y, movement_bounds.position.y, movement_bounds.end.y)
	base_position = next_position
	if absf(input_vector.x) > 0.05:
		_body_root.scale.x = signf(input_vector.x)

func set_focused(value: bool) -> void:
	modulate = Color("fff7df") if value else Color.WHITE

func play_activate(_effect: String) -> void:
	var tween := create_tween()
	tween.tween_property(_phone_glow, "modulate:a", 0.95, 0.12)
	tween.tween_property(_phone_glow, "modulate:a", 0.35, 0.35)

func _process(delta: float) -> void:
	_time += delta
	position = base_position + Vector2(0, sin(_time * TAU / 1.6) * 3.0)
	_head.position.y = -130 + sin(_time * TAU / 1.6) * 1.4
	_body.position.y = -88 + sin(_time * TAU / 1.6) * 1.1
	_phone.rotation = sin(_time * TAU / 1.4) * 0.05
	_phone_glow.modulate.a = 0.25 + maxf(0, sin(_time * TAU / 1.2)) * 0.28

func _build() -> void:
	_body_root = Node2D.new()
	add_child(_body_root)

	var shadow := Polygon2D.new()
	shadow.color = Color(0, 0, 0, 0.28)
	shadow.polygon = PackedVector2Array([Vector2(-42, 45), Vector2(42, 45), Vector2(58, 56), Vector2(-58, 56)])
	_body_root.add_child(shadow)

	_rect(Vector2(-21, -36), Vector2(18, 84), Color("111820"), _body_root)
	_rect(Vector2(8, -36), Vector2(18, 84), Color("111820"), _body_root)
	_rect(Vector2(-28, 38), Vector2(30, 12), Color("07090c"), _body_root)
	_rect(Vector2(6, 38), Vector2(34, 12), Color("07090c"), _body_root)

	_body = _rect(Vector2(-32, -88), Vector2(64, 82), Color("182536"), _body_root)
	_rect(Vector2(-10, -84), Vector2(20, 76), Color("e7dfd2"), _body_root)
	_rect(Vector2(-8, -104), Vector2(16, 18), Color("d8b18b"), _body_root)

	_head = _rect(Vector2(-24, -130), Vector2(48, 44), Color("d8b18b"), _body_root)
	_rect(Vector2(-28, -138), Vector2(56, 24), Color("151a23"), _body_root)
	_rect(Vector2(11, -111), Vector2(5, 5), Color("080a0d"), _body_root)

	var free_arm := _rect(Vector2(-42, -82), Vector2(16, 76), Color("182536"), _body_root)
	free_arm.rotation = 0.14
	var phone_arm := _rect(Vector2(28, -76), Vector2(16, 62), Color("182536"), _body_root)
	phone_arm.rotation = -0.42
	_phone = _rect(Vector2(50, -74), Vector2(18, 32), Color("05080c"), _body_root)
	_phone.rotation = -0.1
	_phone_glow = _rect(Vector2(53, -70), Vector2(12, 22), Color("8be3ff"), _body_root)
	_phone_glow.modulate.a = 0.35

func _rect(pos: Vector2, size: Vector2, color: Color, parent: Node) -> ColorRect:
	var rect := ColorRect.new()
	rect.position = pos
	rect.size = size
	rect.color = color
	parent.add_child(rect)
	return rect

func _array_to_vector2(value) -> Vector2:
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO
