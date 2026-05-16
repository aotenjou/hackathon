class_name ArtTextureLoader
extends RefCounted

static func load_png_texture(path: String) -> Texture2D:
	var image := Image.new()
	var error := image.load(path)
	if error != OK:
		push_error("Unable to load PNG texture: %s" % path)
		return null
	return ImageTexture.create_from_image(image)
