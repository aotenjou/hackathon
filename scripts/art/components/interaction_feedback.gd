class_name InteractionFeedback
extends CanvasLayer

var effect_root: Node2D

var _focus_label: Label
var _message_panel: PanelContainer
var _message_label: Label
var _message_tween: Tween

func setup(world_effect_root: Node2D) -> void:
	effect_root = world_effect_root
	layer = 30
	_build_ui()
	set_focus_text("")

func set_focus_text(text: String) -> void:
	if _focus_label == null:
		return
	if text.is_empty():
		_focus_label.text = "靠近目标后点击或按 E"
	else:
		_focus_label.text = "可交互：" + text

func show_message(text: String) -> void:
	_message_label.text = text
	_message_panel.visible = true
	if _message_tween != null:
		_message_tween.kill()
	_message_tween = create_tween()
	_message_tween.tween_interval(2.3)
	_message_tween.tween_callback(func() -> void: _message_panel.visible = false)

func spawn_ring(position: Vector2, color: Color) -> void:
	if effect_root == null:
		return
	var ring := Line2D.new()
	ring.width = 4.0
	ring.default_color = color
	ring.closed = true
	ring.z_index = 80
	for i in range(32):
		var angle := TAU * float(i) / 32.0
		ring.add_point(Vector2(cos(angle), sin(angle)) * 38.0)
	ring.position = position
	effect_root.add_child(ring)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector2(1.8, 1.8), 0.45)
	tween.tween_property(ring, "modulate:a", 0.0, 0.45)
	tween.set_parallel(false)
	tween.tween_callback(ring.queue_free)

func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var title := _label("邮轮甲板资产拆分试点", 30, Color("f6edd8"))
	title.position = Vector2(22, 18)
	title.size = Vector2(390, 52)
	title.add_theme_stylebox_override("normal", _panel_style(Color("111820", 0.92), Color("d8a13a"), 4))
	root.add_child(title)

	var objective := _label("组件化元素：靠近热点，点击或按 E 交互", 27, Color("f6edd8"))
	objective.position = Vector2(500, 18)
	objective.size = Vector2(600, 52)
	objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective.add_theme_stylebox_override("normal", _panel_style(Color("111820", 0.92), Color("d8a13a"), 4))
	root.add_child(objective)

	_focus_label = _label("", 24, Color("d8caa8"))
	_focus_label.position = Vector2(585, 790)
	_focus_label.size = Vector2(430, 45)
	_focus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_focus_label.add_theme_stylebox_override("normal", _panel_style(Color("1d2630", 0.9), Color("59472b"), 3))
	root.add_child(_focus_label)

	_message_panel = PanelContainer.new()
	_message_panel.position = Vector2(480, 655)
	_message_panel.size = Vector2(640, 100)
	_message_panel.visible = false
	_message_panel.add_theme_stylebox_override("panel", _panel_style(Color("101820", 0.96), Color("d8a13a"), 4))
	root.add_child(_message_panel)

	_message_label = _label("", 25, Color("f6edd8"))
	_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message_label.size = Vector2(610, 76)
	_message_panel.add_child(_message_label)

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color("05070a"))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label

func _panel_style(bg: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style
