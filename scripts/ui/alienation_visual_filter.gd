class_name AlienationVisualFilter
extends CanvasLayer

const MODE_NORMAL := "normal"
const MODE_GRADIENT := "gradient"
const LEGACY_MODE_FLICKER := "flicker"
const MODE_PERSISTENT := "persistent"
const FILTER_LAYER := 90
const AI_FADE_DURATION := 1.4
const STATE_FADE_DURATION := 0.9
const RECOVERY_FADE_DURATION := 0.45
const PERSISTENT_FADE_DURATION := 2.0
const NORMAL_FADE_DURATION := 0.45
const FILTER_SHADER := """
shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 screen_color = texture(screen_texture, SCREEN_UV);
	float gray = dot(screen_color.rgb, vec3(0.299, 0.587, 0.114));
	COLOR = vec4(vec3(gray), amount);
}
"""

var _filter_rect: ColorRect
var _filter_material: ShaderMaterial
var _mode := MODE_NORMAL
var _current_amount := 0.0
var _target_amount := 0.0
var _fade_tween: Tween
var _scene_suppressed := false

func _ready() -> void:
	layer = FILTER_LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_filter_rect()
	_connect_game_state()
	refresh_from_state(true)

func refresh_from_state(instant: bool = false) -> void:
	if _scene_suppressed:
		_mode = MODE_NORMAL
		_target_amount = 0.0
		_fade_to(0.0, 0.0)
		return

	var game_state := _game_state()
	if game_state == null or not game_state.has_method("get_alienation_visual_state"):
		_mode = MODE_NORMAL
		_target_amount = 0.0
		_fade_to(0.0, 0.0)
		return

	var visual_state: Dictionary = game_state.get_alienation_visual_state()
	var next_mode := str(visual_state.get("mode", MODE_NORMAL))
	if not [MODE_NORMAL, MODE_GRADIENT, LEGACY_MODE_FLICKER, MODE_PERSISTENT].has(next_mode):
		next_mode = MODE_NORMAL
	if next_mode == LEGACY_MODE_FLICKER:
		next_mode = MODE_GRADIENT

	_mode = next_mode
	var next_amount := clampf(float(visual_state.get("intensity", 0.0)), 0.0, 1.0)
	if _mode == MODE_PERSISTENT:
		next_amount = 1.0
	elif _mode == MODE_NORMAL:
		next_amount = 0.0
	_target_amount = next_amount
	_fade_to(next_amount, 0.0 if instant else _fade_duration_for_target(next_amount))

func refresh_checkpoint_state() -> void:
	refresh_from_state()

func set_scene_suppressed(value: bool) -> void:
	_scene_suppressed = value
	refresh_from_state(value)

func trigger_checkpoint_flash() -> void:
	refresh_checkpoint_state()

func get_visual_mode() -> String:
	return _mode

func get_filter_amount() -> float:
	return _current_amount

func get_target_filter_amount() -> float:
	return _target_amount

func _build_filter_rect() -> void:
	_filter_rect = ColorRect.new()
	_filter_rect.name = "AlienationFilterRect"
	_filter_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_filter_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_filter_rect.offset_left = 0.0
	_filter_rect.offset_top = 0.0
	_filter_rect.offset_right = 0.0
	_filter_rect.offset_bottom = 0.0
	_filter_rect.color = Color.WHITE

	var shader := Shader.new()
	shader.code = FILTER_SHADER
	_filter_material = ShaderMaterial.new()
	_filter_material.shader = shader
	_filter_material.set_shader_parameter("amount", 0.0)
	_filter_rect.material = _filter_material

	add_child(_filter_rect)
	_set_amount(0.0)

func _connect_game_state() -> void:
	var game_state := _game_state()
	if game_state == null:
		return
	game_state.stats_changed.connect(_on_state_changed)
	game_state.route_profile_changed.connect(_on_state_changed)
	game_state.chapter_changed.connect(func(_chapter_id: String) -> void:
		_on_context_changed()
	)
	game_state.ui_phase_changed.connect(func(_phase: String) -> void:
		_on_context_changed()
	)

func _on_state_changed() -> void:
	refresh_from_state()

func _on_context_changed() -> void:
	refresh_from_state()

func _fade_to(target_amount: float, duration: float) -> void:
	_cancel_fade()
	if duration <= 0.0:
		_set_amount(target_amount)
		return
	_fade_tween = create_tween()
	_fade_tween.set_trans(Tween.TRANS_SINE)
	_fade_tween.set_ease(Tween.EASE_IN_OUT)
	_fade_tween.tween_method(Callable(self, "_set_amount"), _current_amount, target_amount, duration)

func _set_amount(amount: float) -> void:
	_current_amount = clampf(amount, 0.0, 1.0)
	if _filter_material != null:
		_filter_material.set_shader_parameter("amount", _current_amount)
	if _filter_rect != null:
		_filter_rect.visible = _current_amount > 0.001

func _cancel_fade() -> void:
	if _fade_tween != null and _fade_tween.is_running():
		_fade_tween.kill()

func _fade_duration_for_target(target_amount: float) -> float:
	if _mode == MODE_PERSISTENT:
		return PERSISTENT_FADE_DURATION
	if target_amount < _current_amount:
		return RECOVERY_FADE_DURATION
	if target_amount > _current_amount + 0.04:
		return AI_FADE_DURATION
	if _mode == MODE_NORMAL:
		return NORMAL_FADE_DURATION
	return STATE_FADE_DURATION

func _game_state() -> Node:
	var tree := get_tree()
	if tree == null or not tree.root.has_node("GameState"):
		return null
	return tree.root.get_node("GameState")
