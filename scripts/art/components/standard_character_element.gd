class_name StandardCharacterElement
extends Node2D

const HeroSpriteVisualScript := preload("res://scripts/art/components/hero_sprite_visual.gd")

var element_id := ""
var base_position := Vector2.ZERO
var movement_bounds := Rect2(80, 430, 1440, 285)

var _visual_root: Node2D
var _hero_visual: Node2D
var _time := 0.0

func setup(element_data: Dictionary) -> void:
	element_id = str(element_data.get("id", "standard_character"))
	name = element_id
	position = _array_to_vector2(element_data.get("position", [0, 0]))
	base_position = position
	z_index = int(element_data.get("z_index", 20))
	_build(str(element_data.get("life_stage", "adult")))

func move_by(input_vector: Vector2, speed: float, delta: float) -> void:
	if _hero_visual != null:
		_hero_visual.update_motion(input_vector)
	if input_vector.length() <= 0.05:
		return
	var next_position := base_position + input_vector.limit_length(1.0) * speed * delta
	next_position.x = clampf(next_position.x, movement_bounds.position.x, movement_bounds.end.x)
	next_position.y = clampf(next_position.y, movement_bounds.position.y, movement_bounds.end.y)
	base_position = next_position

func set_focused(value: bool) -> void:
	modulate = Color("fff7df") if value else Color.WHITE

func play_activate(_effect: String) -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.12)
	tween.tween_property(self, "scale", Vector2.ONE, 0.22)
	if _hero_visual != null:
		_hero_visual.flash(Color("8be3ff"))

func _process(delta: float) -> void:
	_time += delta
	position = base_position + Vector2(0, sin(_time * TAU / 1.6) * 3.0)

func _build(life_stage: String) -> void:
	_visual_root = Node2D.new()
	add_child(_visual_root)

	_hero_visual = HeroSpriteVisualScript.new()
	_visual_root.add_child(_hero_visual)
	_hero_visual.configure(life_stage)
	_hero_visual.update_motion(Vector2.ZERO)

func _array_to_vector2(value) -> Vector2:
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO
