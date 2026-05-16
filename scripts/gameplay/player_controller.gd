class_name PlayerController
extends CharacterBody2D

const HeroSpriteVisualScript := preload("res://scripts/art/components/hero_sprite_visual.gd")

signal moved(position: Vector2)

@export var speed := 270.0
@export_enum("school", "college", "adult") var age_stage := "adult"

var joystick_vector := Vector2.ZERO
var movement_bounds := Rect2(70, 420, 1460, 280)

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
	global_position.x = clampf(global_position.x, movement_bounds.position.x, movement_bounds.position.x + movement_bounds.size.x)
	global_position.y = clampf(global_position.y, movement_bounds.position.y, movement_bounds.position.y + movement_bounds.size.y)

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

func _build_sprite() -> void:
	_hero_visual = HeroSpriteVisualScript.new()
	add_child(_hero_visual)
