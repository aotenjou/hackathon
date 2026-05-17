class_name NpcSpriteVisual
extends Node2D

const ArtTextureLoaderScript := preload("res://scripts/art/components/art_texture_loader.gd")

const TARGET_DISPLAY_HEIGHT := 200.0
const WALK_FPS := 6.0
const ALPHA_THRESHOLD := 0.03
const MIN_ROW_SPAN := 40
const MIN_COLUMN_SPAN := 40

var sprite_path := ""
var default_animation := "idle_front"

var _built := false
var _sheet_cache: Dictionary = {}
var _display_height := TARGET_DISPLAY_HEIGHT
var _sprite: AnimatedSprite2D

func configure(path: String, initial_animation: String = "idle_front") -> void:
	_ensure_built()
	sprite_path = path
	default_animation = initial_animation
	_apply_sheet()

func set_facing(direction: float) -> void:
	_ensure_built()
	_sprite.flip_h = direction < 0.0

func set_animation(animation: String) -> void:
	_ensure_built()
	_play(animation)

func get_display_height() -> float:
	return _display_height

func _ensure_built() -> void:
	if _built:
		return

	var shadow := Polygon2D.new()
	shadow.color = Color(0, 0, 0, 0.2)
	shadow.polygon = PackedVector2Array([
		Vector2(-30, 16),
		Vector2(30, 16),
		Vector2(42, 24),
		Vector2(-42, 24),
	])
	add_child(shadow)

	_sprite = AnimatedSprite2D.new()
	_sprite.centered = true
	add_child(_sprite)

	_built = true

func _apply_sheet() -> void:
	var data: Dictionary = _sheet_data(sprite_path)
	if data.is_empty():
		return

	var frames := SpriteFrames.new()
	for animation in ["idle_front", "idle_three_quarter", "idle_side", "walk_side"]:
		frames.add_animation(animation)
		frames.set_animation_loop(animation, animation == "walk_side")
		frames.set_animation_speed(animation, WALK_FPS if animation == "walk_side" else 1.0)
		for frame_texture in data.get(animation, []):
			frames.add_frame(animation, frame_texture)

	_display_height = float(data.get("display_height", TARGET_DISPLAY_HEIGHT))
	_sprite.sprite_frames = frames
	_sprite.scale = Vector2.ONE * float(data.get("scale", 1.0))
	_sprite.offset = Vector2(0, -float(data.get("frame_height", 0.0)) / 2.0)
	_play(default_animation)

func _play(animation: String) -> void:
	if _sprite.sprite_frames == null or not _sprite.sprite_frames.has_animation(animation):
		return
	if _sprite.animation == animation and _sprite.is_playing() == (animation == "walk_side"):
		return
	_sprite.play(animation)
	if animation != "walk_side":
		_sprite.stop()
		_sprite.frame = 0

func _sheet_data(path: String) -> Dictionary:
	if path.is_empty():
		return {}
	if _sheet_cache.has(path):
		return _sheet_cache[path]

	var texture := ArtTextureLoaderScript.load_png_texture(path)
	if texture == null:
		return {}

	var image := texture.get_image()
	if image == null:
		return {}

	var pose_rects := _detect_pose_rects(image)
	if pose_rects.is_empty():
		push_error("NPC sprite sheet layout detection failed: %s" % path)
		return {}

	var unified_frames: Array[Rect2i] = [
		pose_rects.get("idle_front"),
		pose_rects.get("idle_three_quarter"),
		pose_rects.get("idle_side"),
	]
	for rect in pose_rects.get("walk_side", []):
		unified_frames.append(rect)

	var max_width := 0
	var max_height := 0.0
	for frame_rect in unified_frames:
		max_width = maxi(max_width, frame_rect.size.x)
		max_height = maxf(max_height, frame_rect.size.y)

	var canvas_size := Vector2i(max_width, int(max_height))
	var data := {
		"display_height": TARGET_DISPLAY_HEIGHT,
		"frame_height": max_height,
		"scale": TARGET_DISPLAY_HEIGHT / max_height,
		"idle_front": [_build_frame_texture(image, pose_rects.get("idle_front"), canvas_size)],
		"idle_three_quarter": [_build_frame_texture(image, pose_rects.get("idle_three_quarter"), canvas_size)],
		"idle_side": [_build_frame_texture(image, pose_rects.get("idle_side"), canvas_size)],
		"walk_side": [],
	}
	for walk_rect in pose_rects.get("walk_side", []):
		data["walk_side"].append(_build_frame_texture(image, walk_rect, canvas_size))

	_sheet_cache[path] = data
	return data

func _detect_pose_rects(image: Image) -> Dictionary:
	var row_ranges := _find_row_ranges(image)
	if row_ranges.size() < 2:
		return {}

	var top_rects := _find_rects_for_range(image, row_ranges[0])
	var bottom_rects := _find_rects_for_range(image, row_ranges[1])
	if top_rects.size() != 3 or bottom_rects.size() != 4:
		return {}

	return {
		"idle_front": top_rects[0],
		"idle_three_quarter": top_rects[1],
		"idle_side": top_rects[2],
		"walk_side": bottom_rects,
	}

func _find_row_ranges(image: Image) -> Array[Vector2i]:
	var ranges: Array[Vector2i] = []
	var start := -1
	for y in range(image.get_height()):
		var occupied := false
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a > ALPHA_THRESHOLD:
				occupied = true
				break
		if occupied and start == -1:
			start = y
		elif not occupied and start != -1:
			if y - start >= MIN_ROW_SPAN:
				ranges.append(Vector2i(start, y - 1))
			start = -1
	if start != -1 and image.get_height() - start >= MIN_ROW_SPAN:
		ranges.append(Vector2i(start, image.get_height() - 1))
	return ranges

func _find_rects_for_range(image: Image, row_range: Vector2i) -> Array[Rect2i]:
	var column_ranges: Array[Vector2i] = []
	var start := -1
	for x in range(image.get_width()):
		var occupied := false
		for y in range(row_range.x, row_range.y + 1):
			if image.get_pixel(x, y).a > ALPHA_THRESHOLD:
				occupied = true
				break
		if occupied and start == -1:
			start = x
		elif not occupied and start != -1:
			if x - start >= MIN_COLUMN_SPAN:
				column_ranges.append(Vector2i(start, x - 1))
			start = -1
	if start != -1 and image.get_width() - start >= MIN_COLUMN_SPAN:
		column_ranges.append(Vector2i(start, image.get_width() - 1))

	var rects: Array[Rect2i] = []
	for column_range in column_ranges:
		var rect := _bounding_rect(image, column_range, row_range)
		if rect.size.x > 0 and rect.size.y > 0:
			rects.append(rect)
	return rects

func _bounding_rect(image: Image, column_range: Vector2i, row_range: Vector2i) -> Rect2i:
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	for y in range(row_range.x, row_range.y + 1):
		for x in range(column_range.x, column_range.y + 1):
			if image.get_pixel(x, y).a <= ALPHA_THRESHOLD:
				continue
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)
	if max_x < min_x or max_y < min_y:
		return Rect2i()
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)

func _build_frame_texture(image: Image, source_rect: Rect2i, canvas_size: Vector2i) -> Texture2D:
	var frame := Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
	frame.fill(Color(0, 0, 0, 0))
	var dst_x := int((canvas_size.x - source_rect.size.x) / 2)
	var dst_y := canvas_size.y - source_rect.size.y
	frame.blit_rect(image, source_rect, Vector2i(dst_x, dst_y))
	return ImageTexture.create_from_image(frame)
