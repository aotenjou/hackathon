class_name ArtSpriteElement
extends Node2D

const ArtTextureLoaderScript := preload("res://scripts/art/components/art_texture_loader.gd")

var element_id := ""
var focus_effect := ""
var layers: Dictionary = {}

var _layer_base_positions: Dictionary = {}
var _layer_base_modulates: Dictionary = {}
var _time := 0.0
var _focused := false

func setup(element_data: Dictionary) -> void:
	element_id = str(element_data.get("id", name))
	name = element_id
	position = _array_to_vector2(element_data.get("position", [0, 0]))
	z_index = int(element_data.get("z_index", 0))
	focus_effect = str(element_data.get("focus_effect", ""))

	for layer_data in element_data.get("layers", []):
		if layer_data is Dictionary:
			_add_layer(layer_data)

func set_focused(value: bool) -> void:
	_focused = value
	scale = Vector2(1.035, 1.035) if _focused else Vector2.ONE
	for layer_id in layers.keys():
		var sprite: Sprite2D = layers[layer_id]
		var base: Color = _layer_base_modulates.get(layer_id, Color.WHITE)
		if _focused and (focus_effect == "terminal_glow" or focus_effect == "glass_sparkle"):
			sprite.modulate = base.lightened(0.16)
		else:
			sprite.modulate = base

func play_activate(effect: String) -> void:
	var tint := Color("f0c76f")
	if effect == "blue_terminal_scan":
		tint = Color("8be3ff")
	elif effect == "glass_sparkle":
		tint = Color("fff0b8")

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.07, 1.07), 0.12)
	for sprite in layers.values():
		tween.tween_property(sprite, "modulate", tint, 0.12)
	tween.set_parallel(false)
	tween.tween_interval(0.18)
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE if not _focused else Vector2(1.035, 1.035), 0.18)
	for layer_id in layers.keys():
		var sprite: Sprite2D = layers[layer_id]
		tween.tween_property(sprite, "modulate", _layer_base_modulates.get(layer_id, Color.WHITE), 0.18)

func _process(delta: float) -> void:
	_time += delta
	for layer_id in layers.keys():
		var sprite: Sprite2D = layers[layer_id]
		var animation := str(sprite.get_meta("animation", ""))
		var base_pos: Vector2 = _layer_base_positions.get(layer_id, Vector2.ZERO)
		match animation:
			"pulse":
				sprite.modulate.a = 0.48 + sin(_time * TAU / 1.4) * 0.22
			"score_scan":
				sprite.modulate.a = 0.62 + sin(_time * TAU / 0.9) * 0.28
			"scan_down":
				sprite.position = base_pos + Vector2(0, fmod(_time * 42.0, 38.0) - 19.0)
				sprite.modulate.a = 0.54 + sin(_time * TAU / 0.8) * 0.28
			"sparkle":
				sprite.modulate = Color.WHITE.lerp(Color("fff0b8"), 0.18 + maxf(0.0, sin(_time * TAU / 1.2)) * 0.28)
			"subtle_sway":
				sprite.rotation = sin(_time * TAU / 2.4) * 0.012

func _add_layer(layer_data: Dictionary) -> void:
	var sprite := Sprite2D.new()
	var layer_id := str(layer_data.get("id", "layer"))
	sprite.name = layer_id
	sprite.texture = ArtTextureLoaderScript.load_png_texture(str(layer_data.get("texture", "")))
	sprite.centered = true
	sprite.z_index = int(layer_data.get("z_index", 0))
	if sprite.texture != null:
		sprite.offset = Vector2(0, -float(sprite.texture.get_height()) / 2.0)
	if str(layer_data.get("blend", "")) == "add":
		sprite.material = CanvasItemMaterial.new()
		sprite.material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	sprite.set_meta("animation", str(layer_data.get("animation", "")))
	add_child(sprite)
	layers[layer_id] = sprite
	_layer_base_positions[layer_id] = sprite.position
	_layer_base_modulates[layer_id] = sprite.modulate

func _array_to_vector2(value) -> Vector2:
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO
