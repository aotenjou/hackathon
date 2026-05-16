class_name PlayerController
extends CharacterBody2D

signal moved(position: Vector2)

@export var speed := 270.0
@export var skin_color := Color("d8b18b")
@export var hair_color := Color("1a1d24")
@export var jacket_color := Color("182536")
@export var pants_color := Color("111820")

var joystick_vector := Vector2.ZERO
var movement_bounds := Rect2(70, 420, 1460, 280)

var _body_root: Node2D
var _facing := 1.0

func _ready() -> void:
	_build_sprite()

func _physics_process(_delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if joystick_vector.length() > 0.08:
		input_vector = joystick_vector

	velocity = input_vector.limit_length(1.0) * speed
	move_and_slide()
	global_position.x = clampf(global_position.x, movement_bounds.position.x, movement_bounds.position.x + movement_bounds.size.x)
	global_position.y = clampf(global_position.y, movement_bounds.position.y, movement_bounds.position.y + movement_bounds.size.y)

	if absf(input_vector.x) > 0.05:
		_facing = signf(input_vector.x)
		_body_root.scale.x = _facing

	if velocity.length() > 1.0:
		moved.emit(global_position)

func set_joystick_vector(value: Vector2) -> void:
	joystick_vector = value.limit_length(1.0)

func _build_sprite() -> void:
	_body_root = Node2D.new()
	add_child(_body_root)

	var shadow := Polygon2D.new()
	shadow.color = Color(0, 0, 0, 0.28)
	shadow.polygon = PackedVector2Array([
		Vector2(-34, 45), Vector2(34, 45), Vector2(46, 55), Vector2(-46, 55),
	])
	_body_root.add_child(shadow)

	var legs := ColorRect.new()
	legs.color = pants_color
	legs.size = Vector2(36, 58)
	legs.position = Vector2(-18, -8)
	_body_root.add_child(legs)

	var shoes := ColorRect.new()
	shoes.color = Color("0b0d10")
	shoes.size = Vector2(46, 12)
	shoes.position = Vector2(-23, 44)
	_body_root.add_child(shoes)

	var jacket := ColorRect.new()
	jacket.color = jacket_color
	jacket.size = Vector2(52, 70)
	jacket.position = Vector2(-26, -72)
	_body_root.add_child(jacket)

	var shirt := ColorRect.new()
	shirt.color = Color("e7dfd2")
	shirt.size = Vector2(18, 64)
	shirt.position = Vector2(-9, -68)
	_body_root.add_child(shirt)

	var neck := ColorRect.new()
	neck.color = skin_color
	neck.size = Vector2(16, 12)
	neck.position = Vector2(-8, -84)
	_body_root.add_child(neck)

	var head := ColorRect.new()
	head.color = skin_color
	head.size = Vector2(42, 42)
	head.position = Vector2(-21, -124)
	_body_root.add_child(head)

	var hair := ColorRect.new()
	hair.color = hair_color
	hair.size = Vector2(48, 24)
	hair.position = Vector2(-24, -132)
	_body_root.add_child(hair)

	var eye := ColorRect.new()
	eye.color = Color("101216")
	eye.size = Vector2(5, 5)
	eye.position = Vector2(11, -106)
	_body_root.add_child(eye)

	var phone := ColorRect.new()
	phone.color = Color("0b1117")
	phone.size = Vector2(16, 28)
	phone.position = Vector2(31, -62)
	_body_root.add_child(phone)

	var phone_screen := ColorRect.new()
	phone_screen.color = Color("8be3ff")
	phone_screen.size = Vector2(10, 18)
	phone_screen.position = Vector2(34, -59)
	_body_root.add_child(phone_screen)
