class_name ArtSplitCruiseDemo
extends Node2D

const MANIFEST_PATH := "res://assets/storyline/ch00_cruise_success/meta/split_manifest.json"
const ArtTextureLoaderScript := preload("res://scripts/art/components/art_texture_loader.gd")
const ArtSpriteElementScript := preload("res://scripts/art/components/art_sprite_element.gd")
const LayeredCharacterElementScript := preload("res://scripts/art/components/layered_character_element.gd")
const InteractiveHotspotScript := preload("res://scripts/art/components/interactive_hotspot.gd")
const InteractionFeedbackScript := preload("res://scripts/art/components/interaction_feedback.gd")
const StandardCruiseBackgroundScript := preload("res://scripts/art/components/standard_cruise_background.gd")
const StandardCharacterElementScript := preload("res://scripts/art/components/standard_character_element.gd")
const StandardTerminalElementScript := preload("res://scripts/art/components/standard_terminal_element.gd")
const StandardTableElementScript := preload("res://scripts/art/components/standard_table_element.gd")

var _manifest := {}
var _elements: Dictionary = {}
var _hotspots: Dictionary = {}
var _focused_hotspot_id := ""

var _background_layer: Node2D
var _prop_layer: Node2D
var _character_layer: Node2D
var _hotspot_layer: Node2D
var _effect_layer: Node2D
var _overlay_layer: CanvasLayer
var _player: Node2D
var _player_bounds := Rect2(80, 430, 1440, 285)

func _ready() -> void:
	_load_manifest()
	_build_layers()
	_build_scene()
	_update_focus("")

func _process(delta: float) -> void:
	if _player != null:
		var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		_player.move_by(input_vector, 260.0, delta)
	_update_focus(_nearest_hotspot_id())

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_activate_current_hotspot()

func _load_manifest() -> void:
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		push_error("Art split manifest missing: %s" % MANIFEST_PATH)
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_manifest = parsed
	else:
		push_error("Art split manifest is invalid JSON: %s" % MANIFEST_PATH)

func _build_layers() -> void:
	_background_layer = Node2D.new()
	_background_layer.name = "BackgroundLayer"
	add_child(_background_layer)

	_prop_layer = Node2D.new()
	_prop_layer.name = "PropLayer"
	add_child(_prop_layer)

	_character_layer = Node2D.new()
	_character_layer.name = "CharacterLayer"
	add_child(_character_layer)

	_hotspot_layer = Node2D.new()
	_hotspot_layer.name = "HotspotLayer"
	add_child(_hotspot_layer)

	_effect_layer = Node2D.new()
	_effect_layer.name = "EffectLayer"
	add_child(_effect_layer)

	_overlay_layer = InteractionFeedbackScript.new()
	_overlay_layer.name = "OverlayLayer"
	add_child(_overlay_layer)
	_overlay_layer.setup(_effect_layer)

func _build_scene() -> void:
	if not bool(_manifest.get("standard_background", false)):
		var background := Sprite2D.new()
		background.name = "Background"
		background.texture = ArtTextureLoaderScript.load_png_texture(str(_manifest.get("background", "")))
		background.centered = false
		_background_layer.add_child(background)

	var bounds: Dictionary = _manifest.get("player_bounds", {})
	_player_bounds = Rect2(
		Vector2(float(bounds.get("x", 80)), float(bounds.get("y", 430))),
		Vector2(float(bounds.get("width", 1440)), float(bounds.get("height", 285)))
	)

	for element_data in _manifest.get("elements", []):
		if element_data is Dictionary:
			_add_element(element_data)

	for hotspot_data in _manifest.get("hotspots", []):
		if hotspot_data is Dictionary:
			_add_hotspot(hotspot_data)

func _add_element(element_data: Dictionary) -> void:
	var component := str(element_data.get("component", "art_sprite"))
	var element: Node2D
	match component:
		"standard_cruise_background":
			element = StandardCruiseBackgroundScript.new()
			_background_layer.add_child(element)
		"standard_character":
			element = StandardCharacterElementScript.new()
			element.movement_bounds = _player_bounds
			_player = element
			_character_layer.add_child(element)
		"standard_terminal":
			element = StandardTerminalElementScript.new()
			_prop_layer.add_child(element)
		"standard_table":
			element = StandardTableElementScript.new()
			_prop_layer.add_child(element)
		"layered_character":
			element = LayeredCharacterElementScript.new()
			element.movement_bounds = _player_bounds
			_player = element
			_character_layer.add_child(element)
		_:
			element = ArtSpriteElementScript.new()
			_prop_layer.add_child(element)

	element.setup(element_data)
	_elements[element.element_id] = element

func _add_hotspot(hotspot_data: Dictionary) -> void:
	var hotspot: Area2D = InteractiveHotspotScript.new()
	_hotspot_layer.add_child(hotspot)
	hotspot.setup(hotspot_data)
	hotspot.focused.connect(_focus_hotspot)
	hotspot.activated.connect(_activate_hotspot_by_id)
	_hotspots[hotspot.hotspot_id] = hotspot

func _nearest_hotspot_id() -> String:
	if _player == null:
		return ""
	var best_id := ""
	var best_distance := INF
	for hotspot_id in _hotspots.keys():
		var hotspot: Area2D = _hotspots[hotspot_id]
		var distance: float = _player.base_position.distance_to(hotspot.position)
		var radius := float(hotspot.data.get("radius", 90))
		if distance <= radius and distance < best_distance:
			best_id = str(hotspot_id)
			best_distance = distance
	return best_id

func _update_focus(next_id: String) -> void:
	if next_id == _focused_hotspot_id:
		return
	_focus_hotspot(next_id)

func _focus_hotspot(hotspot_id: String) -> void:
	_focused_hotspot_id = hotspot_id
	var focused_name := ""
	for id in _hotspots.keys():
		var hotspot: Area2D = _hotspots[id]
		var focused := str(id) == hotspot_id
		hotspot.set_focused(focused)
		if focused:
			focused_name = str(hotspot.data.get("name", ""))

	for element_id in _elements.keys():
		var element: Node2D = _elements[element_id]
		element.set_focused(false)

	if not hotspot_id.is_empty():
		var hotspot: Area2D = _hotspots.get(hotspot_id)
		if hotspot != null:
			var target_id := str(hotspot.data.get("target_sprite", ""))
			var target: Node2D = _elements.get(target_id)
			if target != null:
				target.set_focused(true)

	_overlay_layer.set_focus_text(focused_name)

func _activate_current_hotspot() -> void:
	if _focused_hotspot_id.is_empty():
		return
	_activate_hotspot_by_id(_focused_hotspot_id)

func _activate_hotspot_by_id(hotspot_id: String) -> void:
	var hotspot: Area2D = _hotspots.get(hotspot_id)
	if hotspot == null:
		return
	_focus_hotspot(hotspot_id)
	_overlay_layer.show_message(str(hotspot.data.get("message", "")))

	var target_id := str(hotspot.data.get("target_sprite", ""))
	var target: Node2D = _elements.get(target_id)
	if target != null:
		target.play_activate(str(hotspot.data.get("effect", "")))

	_overlay_layer.spawn_ring(hotspot.position, _effect_color(str(hotspot.data.get("effect", ""))))

func _effect_color(effect: String) -> Color:
	match effect:
		"blue_terminal_scan":
			return Color("8be3ff")
		"glass_sparkle":
			return Color("fff0b8")
		_:
			return Color("f0c76f")
