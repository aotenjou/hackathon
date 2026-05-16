extends SceneTree

const ArtSplitScene = preload("res://scenes/art/ArtSplitCruiseDemo.tscn")
const MANIFEST_PATH := "res://assets/storyline/ch00_cruise_success/meta/split_manifest.json"

var _failures: Array[String] = []

func _initialize() -> void:
	_check_manifest()
	await _check_scene_boots()

	if _failures.is_empty():
		print("ART SPLIT DEMO TEST PASSED")
		quit(0)
	else:
		for failure in _failures:
			push_error(failure)
		quit(1)

func _check_manifest() -> void:
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		_failures.append("missing manifest: %s" % MANIFEST_PATH)
		return

	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		_failures.append("manifest is not a dictionary")
		return

	var manifest: Dictionary = parsed
	for path in [
		str(manifest.get("source", "")),
		str(manifest.get("background", "")),
		"res://assets/storyline/ch00_cruise_success/ui/ui_hotspot_badge.png",
	]:
		if not FileAccess.file_exists(path):
			_failures.append("missing art split asset: %s" % path)

	var elements: Array = manifest.get("elements", [])
	if elements.size() < 4:
		_failures.append("expected at least 4 split elements")
	for element in elements:
		if not element is Dictionary:
			continue
		if str(element.get("component", "")).is_empty():
			_failures.append("element has no component: %s" % str(element.get("id", "")))
		var layers: Array = element.get("layers", [])
		if layers.is_empty() and str(element.get("component", "")).begins_with("art_"):
			_failures.append("element has no layers: %s" % str(element.get("id", "")))
		for layer in layers:
			if layer is Dictionary and not FileAccess.file_exists(str(layer.get("texture", ""))):
				_failures.append("missing layer texture: %s" % str(layer.get("texture", "")))

	var hotspot_ids: Dictionary = {}
	for hotspot in manifest.get("hotspots", []):
		if hotspot is Dictionary:
			hotspot_ids[str(hotspot.get("id", ""))] = true
	for required_id in ["success_panel", "starloop_badge", "champagne"]:
		if not hotspot_ids.has(required_id):
			_failures.append("missing required hotspot: %s" % required_id)

func _check_scene_boots() -> void:
	var scene := ArtSplitScene.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	for node_path in [
		"BackgroundLayer",
		"PropLayer",
		"CharacterLayer",
		"HotspotLayer",
		"EffectLayer",
		"OverlayLayer",
	]:
		if scene.get_node_or_null(node_path) == null:
			_failures.append("art split scene missing node: %s" % node_path)

	var hotspots := scene.get_node_or_null("HotspotLayer")
	if hotspots == null or hotspots.get_child_count() != 3:
		_failures.append("art split scene should create exactly 3 hotspots")

	var characters := scene.get_node_or_null("CharacterLayer")
	if characters == null or characters.get_child_count() != 1:
		_failures.append("art split scene should create one standard character")

	var props := scene.get_node_or_null("PropLayer")
	if props == null or props.get_child_count() != 3:
		_failures.append("art split scene should create three standard prop elements")

	var backgrounds := scene.get_node_or_null("BackgroundLayer")
	if backgrounds == null or backgrounds.get_child_count() != 1:
		_failures.append("art split scene should create one standard background")

	scene.queue_free()
	await process_frame
