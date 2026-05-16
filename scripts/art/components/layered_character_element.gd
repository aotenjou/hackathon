class_name LayeredCharacterElement
extends "res://scripts/art/components/art_sprite_element.gd"

var base_position := Vector2.ZERO
var movement_bounds := Rect2(80, 430, 1440, 285)

func setup(element_data: Dictionary) -> void:
	super.setup(element_data)
	base_position = position

func move_by(input_vector: Vector2, speed: float, delta: float) -> void:
	if input_vector.length() <= 0.05:
		return
	var next_position := base_position + input_vector.limit_length(1.0) * speed * delta
	next_position.x = clampf(next_position.x, movement_bounds.position.x, movement_bounds.end.x)
	next_position.y = clampf(next_position.y, movement_bounds.position.y, movement_bounds.end.y)
	base_position = next_position
	if absf(input_vector.x) > 0.05:
		scale.x = signf(input_vector.x) * absf(scale.x)

func _process(delta: float) -> void:
	super._process(delta)
	var float_offset := sin(_time * TAU / 1.6) * 3.0
	position = base_position + Vector2(0, float_offset)
	for layer_id in layers.keys():
		var sprite: Sprite2D = layers[layer_id]
		var animation := str(sprite.get_meta("animation", ""))
		var base_pos: Vector2 = _layer_base_positions.get(layer_id, Vector2.ZERO)
		match animation:
			"breath":
				sprite.position = base_pos + Vector2(0, sin(_time * TAU / 1.6) * 1.6)
			"phone_focus":
				sprite.position = base_pos + Vector2(sin(_time * TAU / 1.2) * 1.4, sin(_time * TAU / 1.6) * 1.2)
				sprite.rotation = sin(_time * TAU / 1.8) * 0.012
			"walk_shift":
				sprite.position = base_pos + Vector2(sin(_time * TAU / 1.3) * 0.8, 0)
