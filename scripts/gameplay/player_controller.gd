class_name PlayerController
extends CharacterBody2D

const HeroSpriteVisualScript := preload("res://scripts/art/components/hero_sprite_visual.gd")

signal moved(position: Vector2)

@export var speed := 270.0
@export_enum("school", "college", "adult") var age_stage := "adult"

var joystick_vector := Vector2.ZERO
var movement_bounds := Rect2(70, 420, 1460, 280)
var movement_regions: Array[Rect2] = []

var _facing := 1.0
var _hero_visual: Node2D

func _ready() -> void:
	_build_sprite()
	set_age_stage(age_stage)

func _physics_process(_delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if joystick_vector.length() > 0.08:
		input_vector = joystick_vector

	velocity = input_vector.limit_length(1.0) * speed
	move_and_slide()
	global_position = _constrain_position(global_position)

	if _hero_visual != null:
		_hero_visual.update_motion(input_vector)
	if absf(input_vector.x) > 0.05:
		_facing = signf(input_vector.x)
		if _hero_visual != null:
			_hero_visual.set_facing(_facing)

	if velocity.length() > 1.0:
		moved.emit(global_position)

func set_joystick_vector(value: Vector2) -> void:
	joystick_vector = value.limit_length(1.0)

func set_age_stage(value: String) -> void:
	age_stage = value
	if _hero_visual != null:
		_hero_visual.configure(age_stage)
		_hero_visual.set_facing(_facing)

func set_movement_regions(regions: Array) -> void:
	movement_regions.clear()
	for region in regions:
		if region is Rect2:
			movement_regions.append(region)

func _build_sprite() -> void:
	_hero_visual = HeroSpriteVisualScript.new()
	add_child(_hero_visual)

func _constrain_position(target: Vector2) -> Vector2:
	if movement_regions.is_empty():
		return Vector2(
			clampf(target.x, movement_bounds.position.x, movement_bounds.position.x + movement_bounds.size.x),
			clampf(target.y, movement_bounds.position.y, movement_bounds.position.y + movement_bounds.size.y)
		)

	var closest_point := target
	var closest_distance := INF
	for region in movement_regions:
		if region.has_point(target):
			return target
		var candidate := Vector2(
			clampf(target.x, region.position.x, region.position.x + region.size.x),
			clampf(target.y, region.position.y, region.position.y + region.size.y)
		)
		var distance := target.distance_squared_to(candidate)
		if distance < closest_distance:
			closest_distance = distance
			closest_point = candidate
	return closest_point
