class_name StandardCruiseBackground
extends Node2D

var element_id := ""
var _time := 0.0
var _water_lines: Array[ColorRect] = []
var _city_lights: Array[ColorRect] = []

func setup(element_data: Dictionary) -> void:
	element_id = str(element_data.get("id", "standard_background"))
	name = element_id
	position = Vector2.ZERO
	z_index = int(element_data.get("z_index", -100))
	_build()

func set_focused(_value: bool) -> void:
	pass

func play_activate(_effect: String) -> void:
	pass

func _process(delta: float) -> void:
	_time += delta
	for i in range(_water_lines.size()):
		var line := _water_lines[i]
		line.modulate.a = 0.28 + sin(_time * 1.6 + float(i) * 0.7) * 0.12
	for i in range(_city_lights.size()):
		var light := _city_lights[i]
		light.modulate.a = 0.55 + sin(_time * 2.1 + float(i) * 0.9) * 0.22

func _build() -> void:
	_rect(Vector2.ZERO, Vector2(1600, 900), Color("081221"), self)
	_rect(Vector2(0, 0), Vector2(1600, 420), Color("111d31"), self)
	_draw_skyline()
	_draw_water()
	_draw_ship()
	_draw_deck()

func _draw_skyline() -> void:
	var colors := [Color("17243a"), Color("20304c"), Color("121a2c")]
	for i in range(28):
		var width := 34 + (i % 4) * 12
		var height := 90 + (i * 37) % 190
		var x := 620 + i * 36
		var y := 370 - height
		_rect(Vector2(x, y), Vector2(width, height), colors[i % colors.size()], self)
		for j in range(4):
			if (i + j) % 2 == 0:
				var light := _rect(Vector2(x + 8 + j * 9, y + 18 + (j % 3) * 28), Vector2(5, 8), Color("f0a94b"), self)
				_city_lights.append(light)
	_rect(Vector2(0, 370), Vector2(1600, 56), Color("162338"), self)

func _draw_water() -> void:
	_rect(Vector2(0, 405), Vector2(1600, 150), Color("0b2135"), self)
	for i in range(18):
		var line := _rect(Vector2(550 + (i % 3) * 18, 425 + i * 7), Vector2(940 - i * 12, 3), Color("2e7fa6"), self)
		line.modulate.a = 0.24
		_water_lines.append(line)
	for i in range(12):
		var warm := _rect(Vector2(930 + i * 42, 438 + (i % 4) * 16), Vector2(46, 3), Color("d8a13a"), self)
		warm.modulate.a = 0.28
		_water_lines.append(warm)

func _draw_ship() -> void:
	_rect(Vector2(0, 70), Vector2(610, 420), Color("302923"), self)
	_rect(Vector2(0, 116), Vector2(600, 92), Color("1c1714"), self)
	_label("行业晚宴", Vector2(150, 145), Vector2(220, 60), 42, Color("f0c76f"))
	_rect(Vector2(72, 238), Vector2(360, 218), Color("17130f"), self)
	_rect(Vector2(95, 260), Vector2(300, 150), Color("5e3b22"), self)
	for i in range(6):
		_rect(Vector2(118 + i * 44, 282 + (i % 2) * 16), Vector2(16, 70), Color("1a1110"), self)
		_rect(Vector2(122 + i * 44, 296 + (i % 2) * 16), Vector2(8, 40), Color("f0a94b"), self)
	for i in range(9):
		_rect(Vector2(42 + i * 76, 98), Vector2(16, 10), Color("ffc46b"), self)
		_rect(Vector2(44 + i * 76, 108), Vector2(10, 22), Color("6b3d24"), self)
	_rect(Vector2(452, 220), Vector2(120, 240), Color("182233"), self)
	_label("星环科技\n年度合作伙伴\n欢迎晚宴", Vector2(474, 260), Vector2(82, 126), 22, Color("f0c76f"))

func _draw_deck() -> void:
	_rect(Vector2(0, 520), Vector2(1600, 380), Color("2d1c16"), self)
	for i in range(26):
		var y := 540 + i * 16
		_line(Vector2(0, y), Vector2(1600, y + 70), Color("56301e"), 3)
	for i in range(10):
		var x := 1000 + i * 60
		_rect(Vector2(x, 440), Vector2(10, 180), Color("3d312a"), self)
	_rect(Vector2(580, 512), Vector2(980, 10), Color("5b4233"), self)
	_rect(Vector2(580, 590), Vector2(980, 10), Color("5b4233"), self)
	for i in range(12):
		_rect(Vector2(590 + i * 78, 598), Vector2(12, 26), Color("f1c06b"), self)

func _rect(pos: Vector2, size: Vector2, color: Color, parent: Node) -> ColorRect:
	var rect := ColorRect.new()
	rect.position = pos
	rect.size = size
	rect.color = color
	parent.add_child(rect)
	return rect

func _line(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	var line := Line2D.new()
	line.width = width
	line.default_color = color
	line.add_point(from)
	line.add_point(to)
	add_child(line)

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
