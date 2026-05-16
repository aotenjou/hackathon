class_name VirtualJoystick
extends Control

signal vector_changed(value: Vector2)

@export var base_radius := 100.0
@export var knob_radius := 30.0

var value := Vector2.ZERO
var _active := false
var _active_index := -1

func _ready() -> void:
	custom_minimum_size = Vector2(base_radius * 2.2, base_radius * 2.2)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and not _active:
			_active = true
			_active_index = event.index
			_set_from_local(event.position)
		elif not event.pressed and event.index == _active_index:
			_release()
	elif event is InputEventScreenDrag and _active and event.index == _active_index:
		_set_from_local(event.position)
	elif event is InputEventMouseButton:
		if event.pressed:
			_active = true
			_active_index = -1
			_set_from_local(event.position)
		else:
			_release()
	elif event is InputEventMouseMotion and _active and _active_index == -1:
		_set_from_local(event.position)

func _draw() -> void:
	var center := size * 0.5
	var knob_center := center + value * (base_radius - knob_radius)
	var dark := Color(0.03, 0.04, 0.05, 0.34)
	var ink := Color(0.02, 0.025, 0.03, 0.52)
	var gold := Color(0.86, 0.64, 0.23, 0.66)
	var cream := Color(0.96, 0.93, 0.84, 0.42)
	var cyan := Color(0.55, 0.89, 1.0, 0.32)

	draw_circle(center, base_radius + 11.0, ink)
	draw_arc(center, base_radius + 11.0, 0.0, TAU, 64, Color(0.0, 0.0, 0.0, 0.36), 8.0)
	draw_circle(center, base_radius, dark)
	draw_arc(center, base_radius, 0.0, TAU, 64, gold, 6.0)
	draw_arc(center, base_radius - 12.0, 0.0, TAU, 64, cream, 2.0)

	var cross_len := base_radius * 0.62
	var cross_gap := base_radius * 0.24
	var cross_width := 8.0
	draw_line(center + Vector2(-cross_len, 0), center + Vector2(-cross_gap, 0), cream, cross_width)
	draw_line(center + Vector2(cross_gap, 0), center + Vector2(cross_len, 0), cream, cross_width)
	draw_line(center + Vector2(0, -cross_len), center + Vector2(0, -cross_gap), cream, cross_width)
	draw_line(center + Vector2(0, cross_gap), center + Vector2(0, cross_len), cream, cross_width)
	draw_colored_polygon([
		center + Vector2(0, -base_radius * 0.78),
		center + Vector2(-10, -base_radius * 0.58),
		center + Vector2(10, -base_radius * 0.58),
	], cream)
	draw_colored_polygon([
		center + Vector2(base_radius * 0.78, 0),
		center + Vector2(base_radius * 0.58, -10),
		center + Vector2(base_radius * 0.58, 10),
	], cream)
	draw_colored_polygon([
		center + Vector2(0, base_radius * 0.78),
		center + Vector2(-10, base_radius * 0.58),
		center + Vector2(10, base_radius * 0.58),
	], cream)
	draw_colored_polygon([
		center + Vector2(-base_radius * 0.78, 0),
		center + Vector2(-base_radius * 0.58, -10),
		center + Vector2(-base_radius * 0.58, 10),
	], cream)

	draw_circle(center, base_radius * 0.28, Color(0.9, 0.9, 0.86, 0.08))
	draw_arc(center, base_radius * 0.28, 0.0, TAU, 32, Color(0.86, 0.64, 0.23, 0.32), 3.0)
	draw_circle(knob_center, knob_radius + 10.0, Color(0.0, 0.0, 0.0, 0.26))
	draw_circle(knob_center, knob_radius + 4.0, cyan)
	draw_circle(knob_center, knob_radius, Color(0.77, 0.73, 0.62, 0.54))
	draw_arc(knob_center, knob_radius, 0.0, TAU, 32, Color(0.98, 0.92, 0.72, 0.62), 4.0)

func _set_from_local(local_position: Vector2) -> void:
	var center := size * 0.5
	value = (local_position - center) / maxf(base_radius - knob_radius, 1.0)
	value = value.limit_length(1.0)
	vector_changed.emit(value)
	queue_redraw()

func _release() -> void:
	_active = false
	_active_index = -1
	value = Vector2.ZERO
	vector_changed.emit(value)
	queue_redraw()
