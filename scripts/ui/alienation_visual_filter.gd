class_name AlienationVisualFilter
extends CanvasLayer

const MODE_NORMAL := "normal"
const MODE_FLICKER := "flicker"
const MODE_PERSISTENT := "persistent"
const FILTER_LAYER := 90
const PERSISTENT_FADE_DURATION := 0.6
const NORMAL_FADE_DURATION := 0.18
const FLICKER_MIN_DELAY := 5.0
const FLICKER_MAX_DELAY := 9.0
const FLICKER_HOLD_DURATION := 0.08
const FLICKER_FADE_DURATION := 0.16
const FLICKER_DOUBLE_CHANCE := 0.55
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
var _flash_timer := 0.0
var _rng := RandomNumberGenerator.new()
var _fade_tween: Tween
var _flash_tween: Tween
var _last_heart := -1
var _last_ai_dependence := -1

func _ready() -> void:
	layer = FILTER_LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_build_filter_rect()
	_connect_game_state()
	_capture_stat_snapshot()
	refresh_from_state(true)

func _process(delta: float) -> void:
	if _mode != MODE_FLICKER:
		return
	if _flash_tween != null and _flash_tween.is_running():
		return
	_flash_timer -= delta
	if _flash_timer <= 0.0:
		var pulse_count := 2 if _rng.randf() <= FLICKER_DOUBLE_CHANCE else 1
		_start_flicker_flash(pulse_count)
		_schedule_next_flash()

func refresh_from_state(instant: bool = false) -> void:
	var game_state := _game_state()
	if game_state == null or not game_state.has_method("get_alienation_visual_state"):
		_mode = MODE_NORMAL
		_fade_to(0.0, 0.0)
		return

	var visual_state: Dictionary = game_state.get_alienation_visual_state()
	var next_mode := str(visual_state.get("mode", MODE_NORMAL))
	if not [MODE_NORMAL, MODE_FLICKER, MODE_PERSISTENT].has(next_mode):
		next_mode = MODE_NORMAL

	var previous_mode := _mode
	_mode = next_mode
	match _mode:
		MODE_PERSISTENT:
			_cancel_flash()
			_fade_to(1.0, 0.0 if instant else PERSISTENT_FADE_DURATION)
		MODE_FLICKER:
			_cancel_fade()
			if previous_mode != MODE_FLICKER:
				_set_amount(0.0)
				_schedule_next_flash()
		_:
			_cancel_flash()
			_fade_to(0.0, 0.0 if instant else NORMAL_FADE_DURATION)

func trigger_checkpoint_flash() -> void:
	refresh_from_state()
	if _mode != MODE_FLICKER:
		return
	_start_flicker_flash(2)
	_schedule_next_flash()

func get_visual_mode() -> String:
	return _mode

func get_filter_amount() -> float:
	return _current_amount

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
	game_state.chapter_changed.connect(func(_chapter_id: String) -> void:
		_on_context_changed()
	)
	game_state.ui_phase_changed.connect(func(_phase: String) -> void:
		_on_context_changed()
	)

func _on_state_changed() -> void:
	var previous_heart := _last_heart
	var previous_ai_dependence := _last_ai_dependence
	_capture_stat_snapshot()
	refresh_from_state()
	if _mode != MODE_FLICKER:
		return
	if previous_heart < 0 or previous_ai_dependence < 0:
		return
	if _last_heart < previous_heart or _last_ai_dependence > previous_ai_dependence:
		_start_flicker_flash(2)
		_schedule_next_flash()

func _on_context_changed() -> void:
	refresh_from_state()
	trigger_checkpoint_flash()

func _start_flicker_flash(pulse_count: int = 1) -> void:
	if _mode != MODE_FLICKER:
		return
	_cancel_flash()
	_cancel_fade()
	var pulses := clampi(pulse_count, 1, 3)
	_set_amount(1.0)
	_flash_tween = create_tween()
	_flash_tween.set_trans(Tween.TRANS_SINE)
	_flash_tween.set_ease(Tween.EASE_OUT)
	for index in range(pulses):
		if index > 0:
			_flash_tween.tween_interval(0.08)
			_flash_tween.tween_callback(Callable(self, "_set_amount").bind(1.0))
		_flash_tween.tween_interval(FLICKER_HOLD_DURATION)
		_flash_tween.tween_method(Callable(self, "_set_amount"), 1.0, 0.0, FLICKER_FADE_DURATION)

func _schedule_next_flash() -> void:
	_flash_timer = _rng.randf_range(FLICKER_MIN_DELAY, FLICKER_MAX_DELAY)

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

func _cancel_flash() -> void:
	if _flash_tween != null and _flash_tween.is_running():
		_flash_tween.kill()

func _capture_stat_snapshot() -> void:
	var game_state := _game_state()
	if game_state == null:
		return
	var stats: Dictionary = game_state.get("stats")
	_last_heart = int(stats.get("heart", 0))
	_last_ai_dependence = int(stats.get("ai_dependence", 0))

func _game_state() -> Node:
	var tree := get_tree()
	if tree == null or not tree.root.has_node("GameState"):
		return null
	return tree.root.get_node("GameState")
