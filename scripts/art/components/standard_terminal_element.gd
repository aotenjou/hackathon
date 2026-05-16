class_name StandardTerminalElement
extends Node2D

var element_id := ""
var variant := "success"

var _screen: ColorRect
var _glow: ColorRect
var _score_lines: Array[ColorRect] = []
var _time := 0.0
var _focused := false

func setup(element_data: Dictionary) -> void:
	element_id = str(element_data.get("id", "standard_terminal"))
	name = element_id
	position = _array_to_vector2(element_data.get("position", [0, 0]))
	z_index = int(element_data.get("z_index", 8))
	variant = str(element_data.get("variant", "success"))
	_build()

func set_focused(value: bool) -> void:
	_focused = value
	scale = Vector2(1.045, 1.045) if value else Vector2.ONE

func play_activate(effect: String) -> void:
	var tint := Color("f0c76f")
	if effect == "blue_terminal_scan":
		tint = Color("8be3ff")
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_screen, "color", tint.darkened(0.35), 0.12)
	tween.tween_property(_glow, "modulate:a", 0.95, 0.12)
	tween.set_parallel(false)
	tween.tween_interval(0.2)
	tween.set_parallel(true)
	tween.tween_property(_screen, "color", Color("08263a"), 0.25)
	tween.tween_property(_glow, "modulate:a", 0.34, 0.25)

func _process(delta: float) -> void:
	_time += delta
	_glow.modulate.a = (0.42 if _focused else 0.24) + maxf(0, sin(_time * TAU / 1.3)) * 0.22
	for i in range(_score_lines.size()):
		_score_lines[i].modulate.a = 0.55 + maxf(0, sin(_time * TAU / 0.9 + i * 0.8)) * 0.38

func _build() -> void:
	var width := 190.0
	var height := 360.0
	if variant == "badge":
		width = 160
		height = 300
	var body := Polygon2D.new()
	body.color = Color("101820")
	body.polygon = PackedVector2Array([
		Vector2(-width * 0.42, -height),
		Vector2(width * 0.42, -height),
		Vector2(width * 0.5, -height + 35),
		Vector2(width * 0.46, 0),
		Vector2(-width * 0.46, 0),
		Vector2(-width * 0.5, -height + 35),
	])
	add_child(body)
	_rect(Vector2(-width * 0.36, -height + 42), Vector2(width * 0.72, height * 0.48), Color("07131d"), self)
	_screen = _rect(Vector2(-width * 0.31, -height + 52), Vector2(width * 0.62, height * 0.38), Color("08263a"), self)
	_glow = _rect(Vector2(-width * 0.34, -height + 46), Vector2(width * 0.68, height * 0.42), Color("8be3ff"), self)
	_glow.modulate.a = 0.28

	if variant == "badge":
		_label("星环科技\nXINGHUAN", Vector2(-58, -height + 65), Vector2(116, 80), 20, Color("8be3ff"))
		_add_line(Vector2(-42, -height + 158), width * 0.48)
		_add_line(Vector2(-42, -height + 196), width * 0.48)
	else:
		_label("成功面板", Vector2(-64, -height - 48), Vector2(128, 38), 26, Color("f6edd8"))
		_label("资产      S\n履历      S\n影响力    S\n生活满意度 S", Vector2(-58, -height + 70), Vector2(116, 130), 21, Color("8be3ff"))
		for i in range(4):
			_add_line(Vector2(-50, -height + 104 + i * 38), width * 0.48)
		_label("S", Vector2(42, -height + 80), Vector2(30, 140), 30, Color("f0c76f"))

	_rect(Vector2(-width * 0.26, -34), Vector2(width * 0.52, 18), Color("06080b"), self)
	_rect(Vector2(-width * 0.16, -24), Vector2(width * 0.32, 6), Color("8be3ff"), self).modulate.a = 0.55

func _add_line(pos: Vector2, width: float) -> void:
	var line := _rect(pos, Vector2(width, 5), Color("45b6e6"), self)
	line.modulate.a = 0.75
	_score_lines.append(line)

func _rect(pos: Vector2, size: Vector2, color: Color, parent: Node) -> ColorRect:
	var rect := ColorRect.new()
	rect.position = pos
	rect.size = size
	rect.color = color
	parent.add_child(rect)
	return rect

func _label(text: String, pos: Vector2, size: Vector2, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color("05070a"))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(label)

func _array_to_vector2(value) -> Vector2:
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO
