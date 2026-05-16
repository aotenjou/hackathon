class_name HeroSpriteVisual
extends Node2D

const ArtTextureLoaderScript := preload("res://scripts/art/components/art_texture_loader.gd")

const HERO_STAGE_PATHS := {
	"school": "res://assets/storyline/ch00_cruise_success/characters/hero_1.png",
	"college": "res://assets/storyline/ch00_cruise_success/characters/hero_2.png",
	"adult": "res://assets/storyline/ch00_cruise_success/characters/hero_3.png",
}

const HERO_STAGE_ALIASES := {
	"high_school": "school",
	"school": "school",
	"student": "college",
	"college": "college",
	"university": "college",
	"casual": "college",
	"adult": "adult",
	"worker": "adult",
	"success": "adult",
}

const HERO_STAGE_RECTS := {
	"school": {
		"idle_front": Rect2i(340, 24, 136, 401),
		"idle_three_quarter": Rect2i(534, 27, 130, 402),
		"idle_side": Rect2i(732, 28, 120, 403),
		"walk_side": [
			Rect2i(292, 474, 179, 412),
			Rect2i(488, 475, 97, 411),
			Rect2i(596, 474, 100, 412),
			Rect2i(711, 474, 177, 412),
		],
	},
	"college": {
		"idle_front": Rect2i(49, 40, 191, 613),
		"idle_three_quarter": Rect2i(300, 44, 183, 612),
		"idle_side": Rect2i(534, 44, 169, 612),
		"walk_side": [
			Rect2i(11, 732, 258, 617),
			Rect2i(249, 732, 137, 617),
			Rect2i(387, 732, 142, 617),
			Rect2i(505, 732, 256, 617),
		],
	},
	"adult": {
		"idle_front": Rect2i(45, 40, 199, 611),
		"idle_three_quarter": Rect2i(299, 43, 184, 613),
		"idle_side": Rect2i(534, 43, 169, 613),
		"walk_side": [
			Rect2i(11, 731, 258, 617),
			Rect2i(249, 730, 138, 619),
			Rect2i(387, 731, 141, 618),
			Rect2i(505, 731, 256, 617),
		],
	},
}

const TARGET_DISPLAY_HEIGHT := 188.0
const WALK_FPS := 7.0

var current_stage := "adult"

var _built := false
var _stage_cache: Dictionary = {}
var _last_motion := Vector2.ZERO
var _sprite: AnimatedSprite2D

func configure(stage: String) -> void:
	_ensure_built()
	current_stage = _normalize_stage(stage)
	_apply_stage()
	update_motion(_last_motion)

func set_facing(direction: float) -> void:
	_ensure_built()
	_sprite.flip_h = direction < 0.0

func update_motion(input_vector: Vector2) -> void:
	_ensure_built()
	_last_motion = input_vector

	var animation := "idle_front"
	if input_vector.length() > 0.05:
		var horizontal := absf(input_vector.x)
		var vertical := absf(input_vector.y)
		if horizontal > 0.08:
			set_facing(signf(input_vector.x))
		if horizontal >= 0.42:
			animation = "walk_side"
		elif horizontal >= 0.12:
			animation = "idle_three_quarter" if vertical > horizontal * 0.65 else "idle_side"

	_play(animation)

func flash(tint: Color = Color("f0c76f")) -> void:
	_ensure_built()
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate", tint, 0.12)
	tween.tween_property(_sprite, "modulate", Color.WHITE, 0.22)

func _ensure_built() -> void:
	if _built:
		return

	var shadow := Polygon2D.new()
	shadow.color = Color(0, 0, 0, 0.24)
	shadow.polygon = PackedVector2Array([
		Vector2(-34, 16),
		Vector2(34, 16),
		Vector2(46, 26),
		Vector2(-46, 26),
	])
	add_child(shadow)

	_sprite = AnimatedSprite2D.new()
	_sprite.centered = true
	add_child(_sprite)

	_built = true

func _apply_stage() -> void:
	var stage_data: Dictionary = _stage_data(current_stage)
	if stage_data.is_empty():
		return

	var frames := SpriteFrames.new()
	for animation in ["idle_front", "idle_three_quarter", "idle_side", "walk_side"]:
		frames.add_animation(animation)
		frames.set_animation_loop(animation, animation == "walk_side")
		frames.set_animation_speed(animation, WALK_FPS if animation == "walk_side" else 1.0)
		for frame_texture in stage_data.get(animation, []):
			frames.add_frame(animation, frame_texture)

	_sprite.sprite_frames = frames
	_sprite.scale = Vector2.ONE * float(stage_data.get("scale", 1.0))
	_sprite.offset = Vector2(0, -float(stage_data.get("frame_height", 0.0)) / 2.0)

func _play(animation: String) -> void:
	if _sprite.sprite_frames == null:
		return
	if _sprite.animation == animation and _sprite.is_playing() == (animation == "walk_side"):
		return
	_sprite.play(animation)
	if animation != "walk_side":
		_sprite.stop()
		_sprite.frame = 0

func _stage_data(stage: String) -> Dictionary:
	if _stage_cache.has(stage):
		return _stage_cache[stage]

	var texture := ArtTextureLoaderScript.load_png_texture(str(HERO_STAGE_PATHS.get(stage, HERO_STAGE_PATHS["adult"])))
	if texture == null:
		return {}

	var image := texture.get_image()
	var stage_rects: Dictionary = HERO_STAGE_RECTS.get(stage, HERO_STAGE_RECTS["adult"])
	if image == null or stage_rects.is_empty():
		push_error("Hero sprite sheet data missing for stage: %s" % stage)
		return {}

	var walk_rects: Array = stage_rects.get("walk_side", [])
	var unified_frames: Array[Rect2i] = [
		stage_rects.get("idle_front"),
		stage_rects.get("idle_three_quarter"),
		stage_rects.get("idle_side"),
	]
	for rect in walk_rects:
		unified_frames.append(rect)

	var max_width := 0
	var max_height := 0.0
	for frame_rect in unified_frames:
		max_width = maxi(max_width, frame_rect.size.x)
		max_height = maxf(max_height, frame_rect.size.y)

	var canvas_size := Vector2i(max_width, int(max_height))
	var data := {
		"frame_height": max_height,
		"scale": TARGET_DISPLAY_HEIGHT / max_height,
		"idle_front": [_build_frame_texture(image, stage_rects.get("idle_front"), canvas_size)],
		"idle_three_quarter": [_build_frame_texture(image, stage_rects.get("idle_three_quarter"), canvas_size)],
		"idle_side": [_build_frame_texture(image, stage_rects.get("idle_side"), canvas_size)],
		"walk_side": [
			_build_frame_texture(image, walk_rects[0], canvas_size),
			_build_frame_texture(image, walk_rects[1], canvas_size),
			_build_frame_texture(image, walk_rects[2], canvas_size),
			_build_frame_texture(image, walk_rects[3], canvas_size),
		],
	}
	_stage_cache[stage] = data
	return data

func _build_frame_texture(image: Image, source_rect: Rect2i, canvas_size: Vector2i) -> Texture2D:
	var frame := Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
	frame.fill(Color(0, 0, 0, 0))
	var dst_x := int((canvas_size.x - source_rect.size.x) / 2)
	var dst_y := canvas_size.y - source_rect.size.y
	frame.blit_rect(image, source_rect, Vector2i(dst_x, dst_y))
	return ImageTexture.create_from_image(frame)

func _normalize_stage(stage: String) -> String:
	var normalized := str(stage).strip_edges().to_lower()
	if HERO_STAGE_ALIASES.has(normalized):
		return str(HERO_STAGE_ALIASES[normalized])
	return "adult"
