class_name StandardTableElement
extends Node2D

var element_id := ""
var _glass_left: ColorRect
var _glass_right: ColorRect
var _glow: ColorRect
var _time := 0.0
var _focused := false

func setup(element_data: Dictionary) -> void:
	element_id = str(element_data.get("id", "standard_table"))
	name = element_id
	position = _array_to_vector2(element_data.get("position", [0, 0]))
	z_index = int(element_data.get("z_index", 10))
	_build()

func set_focused(value: bool) -> void:
	_focused = value
	scale = Vector2(1.04, 1.04) if value else Vector2.ONE

func play_activate(_effect: String) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_glass_left, "modulate", Color("fff0b8"), 0.1)
	tween.tween_property(_glass_right, "modulate", Color("fff0b8"), 0.1)
	tween.tween_property(_glow, "modulate:a", 0.9, 0.1)
	tween.set_parallel(false)
	tween.tween_interval(0.18)
	tween.set_parallel(true)
	tween.tween_property(_glass_left, "modulate", Color.WHITE, 0.25)
	tween.tween_property(_glass_right, "modulate", Color.WHITE, 0.25)
	tween.tween_property(_glow, "modulate:a", 0.35, 0.25)

func _process(delta: float) -> void:
	_time += delta
	_glow.modulate.a = (0.46 if _focused else 0.28) + maxf(0, sin(_time * TAU / 1.1)) * 0.22
	_glass_left.position.y = -106 + sin(_time * TAU / 1.8) * 1.2
	_glass_right.position.y = -108 + sin(_time * TAU / 1.7 + 0.5) * 1.2

func _build() -> void:
	var cloth := Polygon2D.new()
	cloth.color = Color("c9b5a4")
	cloth.polygon = PackedVector2Array([Vector2(-145, -120), Vector2(145, -120), Vector2(122, 0), Vector2(-122, 0)])
	add_child(cloth)
	_rect(Vector2(-132, -120), Vector2(264, 18), Color("e7d8ca"), self)
	for i in range(8):
		_rect(Vector2(-116 + i * 32, -100), Vector2(18, 96), Color("bba797"), self).modulate.a = 0.35

	var bottle := _rect(Vector2(-68, -196), Vector2(34, 92), Color("123b2a"), self)
	bottle.rotation = -0.08
	_rect(Vector2(-60, -214), Vector2(16, 30), Color("d8a13a"), self)
	_rect(Vector2(-72, -118), Vector2(42, 10), Color("f0c76f"), self)

	_glass_left = _rect(Vector2(28, -106), Vector2(20, 72), Color("f6edd8"), self)
	_glass_left.modulate.a = 0.72
	_glass_right = _rect(Vector2(72, -108), Vector2(20, 74), Color("f6edd8"), self)
	_glass_right.modulate.a = 0.72
	_rect(Vector2(20, -108), Vector2(36, 8), Color("f0c76f"), self)
	_rect(Vector2(64, -110), Vector2(36, 8), Color("f0c76f"), self)

	_glow = _rect(Vector2(104, -112), Vector2(36, 36), Color("ffdd8a"), self)
	_glow.modulate.a = 0.34
	_rect(Vector2(116, -92), Vector2(12, 28), Color("3d241a"), self)

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
