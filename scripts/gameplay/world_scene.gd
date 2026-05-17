class_name WorldScene
extends Node2D

signal interactable_focused(marker: Area2D)
signal interactable_unfocused
signal interactable_activated(data: Dictionary)
signal scene_loaded(scene_id: String, scene_data: Dictionary)

const InteractableScene = preload("res://scenes/InteractableMarker.tscn")
const PlayerControllerScript = preload("res://scripts/gameplay/player_controller.gd")
const ArtTextureLoaderScript = preload("res://scripts/art/components/art_texture_loader.gd")
const CRUISE_BACKGROUND_PATH := "res://assets/storyline/ch00_cruise_success/backgrounds/01.png"
const SCHOOL_HALLWAY_BACKGROUND_PATH := "res://assets/storyline/ch00_cruise_success/backgrounds/school_hallway.png"
const DINNER_TABLE_BACKGROUND_PATH := "res://assets/storyline/ch00_cruise_success/backgrounds/dinner_table.png"
const GRADUATION_FIELD_BACKGROUND_PATH := "res://assets/storyline/ch02_graduation/backgrounds/graduation_field.png"
const CRUISE_SUCCESS_PANEL_PATH := "res://assets/storyline/ch00_cruise_success/props/prop_success_panel.png"
const CRUISE_BADGE_TERMINAL_PATH := "res://assets/storyline/ch00_cruise_success/props/prop_starloop_badge_terminal.png"
const PLAYER_LAYER := 20
const INTERACTABLE_LAYER := 50

const PLAYER_STAGE_BY_CHAPTER := {
	"chapter_0": "adult",
	"chapter_1": "school",
	"chapter_2": "school",
	"chapter_3": "college",
	"chapter_4": "college",
	"chapter_5": "adult",
	"chapter_6": "adult",
	"chapter_7": "adult",
	"chapter_8": "adult",
}

var current_scene_id := ""
var scene_data := {}
var player: CharacterBody2D

var _background_root: Node2D
var _npc_root: Node2D
var _interactable_root: Node2D
var _label_root: Node2D
var _current_marker: Area2D

func _ready() -> void:
	_background_root = Node2D.new()
	_background_root.name = "Background"
	add_child(_background_root)

	_npc_root = Node2D.new()
	_npc_root.name = "NPCs"
	add_child(_npc_root)

	_interactable_root = Node2D.new()
	_interactable_root.name = "Interactables"
	_interactable_root.z_index = INTERACTABLE_LAYER
	add_child(_interactable_root)

	_label_root = Node2D.new()
	_label_root.name = "FloatingLabels"
	_label_root.z_index = INTERACTABLE_LAYER
	add_child(_label_root)

	player = PlayerControllerScript.new()
	player.name = "Player"
	player.z_index = PLAYER_LAYER
	add_child(player)

	load_scene("cruise_deck")

func load_scene(scene_id: String) -> void:
	current_scene_id = scene_id
	scene_data = _chapter_data().get_scene(scene_id)
	if scene_data.is_empty():
		push_error("Scene data not found: %s" % scene_id)
		return

	_clear_children(_background_root)
	_clear_children(_npc_root)
	_clear_children(_interactable_root)
	_clear_children(_label_root)
	_current_marker = null

	_draw_theme(str(scene_data.get("theme", "school")))
	_build_npcs(scene_data.get("npcs", []))
	_build_interactables(scene_data.get("interactables", []))

	player.global_position = scene_data.get("player_position", Vector2(760, 600))
	player.movement_bounds = scene_data.get("bounds", Rect2(70, 420, 1460, 280))
	player.set_age_stage(_player_stage_for_chapter(str(scene_data.get("chapter", "chapter_0"))))

	_game_state().set_context(
		str(scene_data.get("chapter", "chapter_0")),
		scene_id,
		str(scene_data.get("location", "")),
		str(scene_data.get("time", "")),
		str(scene_data.get("objective", "")),
		str(scene_data.get("ui_overlay", "")),
	)
	scene_loaded.emit(scene_id, scene_data)

func activate_current() -> void:
	if _current_marker != null:
		_current_marker.activate()

func _physics_process(_delta: float) -> void:
	var nearest := _find_nearest_marker()
	if nearest != _current_marker:
		_current_marker = nearest
		if _current_marker == null:
			interactable_unfocused.emit()
		else:
			interactable_focused.emit(_current_marker)

func _find_nearest_marker() -> Area2D:
	var best: Area2D
	var best_distance := 999999.0
	for node in _interactable_root.get_children():
		if node is Area2D and node.has_method("get_display_name"):
			var distance := player.global_position.distance_to(node.global_position)
			if distance < 145.0 and distance < best_distance:
				best = node
				best_distance = distance
	return best

func _build_interactables(items: Array) -> void:
	for item in items:
		var marker := InteractableScene.instantiate()
		_interactable_root.add_child(marker)
		marker.setup(item)
		marker.activated.connect(_on_marker_activated)

func _on_marker_activated(marker: Area2D) -> void:
	interactable_activated.emit(marker.data)

func _build_npcs(items: Array) -> void:
	for item in items:
		var npc := _make_character(str(item.get("role", "student")), str(item.get("name", "NPC")))
		npc.global_position = item.get("position", Vector2.ZERO)
		_npc_root.add_child(npc)

func _make_character(role: String, display_name: String) -> Node2D:
	var root := Node2D.new()
	root.name = display_name

	var palette := {
		"student_dark": [Color("202733"), Color("31465c"), Color("111820")],
		"student_alt": [Color("242a2c"), Color("5e6f66"), Color("202733")],
		"student_clean": [Color("22242c"), Color("d9dde1"), Color("243a5c")],
		"teacher": [Color("2a2520"), Color("6a5b45"), Color("26323b")],
		"parent": [Color("242424"), Color("6c5c4c"), Color("202020")],
		"guest": [Color("181a20"), Color("1f2d3a"), Color("0d1117")],
		"student_college": [Color("1f2530"), Color("3f6c86"), Color("1a2a35")],
		"friend_lost": [Color("171b22"), Color("544a62"), Color("11151b")],
		"mentor": [Color("202124"), Color("77624c"), Color("26323b")],
		"office_worker": [Color("1f252d"), Color("4d6071"), Color("1c2430")],
		"ai_terminal": [Color("061d29"), Color("0f4e64"), Color("08131a")],
	}
	var colors: Array = palette.get(role, palette["student_dark"])

	var shadow := Polygon2D.new()
	shadow.color = Color(0, 0, 0, 0.22)
	shadow.polygon = PackedVector2Array([Vector2(-28, 46), Vector2(28, 46), Vector2(38, 54), Vector2(-38, 54)])
	root.add_child(shadow)

	var legs := ColorRect.new()
	legs.color = colors[2]
	legs.size = Vector2(30, 48)
	legs.position = Vector2(-15, -2)
	root.add_child(legs)

	var body := ColorRect.new()
	body.color = colors[1]
	body.size = Vector2(44, 58)
	body.position = Vector2(-22, -62)
	root.add_child(body)

	var head := ColorRect.new()
	head.color = Color("d6aa85")
	head.size = Vector2(36, 36)
	head.position = Vector2(-18, -100)
	root.add_child(head)

	var hair := ColorRect.new()
	hair.color = colors[0]
	hair.size = Vector2(42, 18)
	hair.position = Vector2(-21, -108)
	root.add_child(hair)

	var label := Label.new()
	label.text = display_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("f6edd8"))
	label.add_theme_color_override("font_shadow_color", Color("0b0d10"))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.position = Vector2(-55, -148)
	label.size = Vector2(110, 26)
	root.add_child(label)

	return root

func _draw_theme(theme: String) -> void:
	match theme:
		"cruise":
			_draw_cruise()
		"computer_room":
			_draw_computer_room()
		"home":
			_draw_home()
		"graduation":
			_draw_graduation()
		"university", "campus":
			_draw_university()
		"neon_street", "neon":
			_draw_neon_street()
		"interview":
			_draw_interview()
		"office":
			_draw_office()
		"school_demo":
			_draw_school_demo()
		"city_center", "demo_center":
			_draw_city_center()
		"final_overlay", "overlay":
			_draw_final_overlay()
		_:
			_draw_school_hallway()

func _draw_cruise() -> void:
	if _draw_cruise_art():
		return
	_draw_cruise_placeholder()

func _draw_cruise_art() -> bool:
	if not _draw_fullscreen_background(CRUISE_BACKGROUND_PATH):
		return false

	_add_bottom_centered_sprite(CRUISE_SUCCESS_PANEL_PATH, Vector2(920, 690), 6)
	_add_bottom_centered_sprite(CRUISE_BADGE_TERMINAL_PATH, Vector2(1490, 735), 6)
	return true

func _draw_cruise_placeholder() -> void:
	_rect(Vector2.ZERO, Vector2(1600, 900), Color("07111d"), _background_root)
	_rect(Vector2(0, 0), Vector2(1600, 325), Color("15243a"), _background_root)
	_rect(Vector2(0, 165), Vector2(1600, 195), _color_alpha("233452", 0.74), _background_root)

	for i in range(30):
		var x := 620 + i * 34
		var y := 185 + (i % 5) * 10
		_rect(Vector2(x, y), Vector2(18, 4), _color_alpha("d88647", 0.24), _background_root)

	for i in range(21):
		var x := 500 + i * 55
		var h := 76 + (i % 6) * 28
		var color := Color("102037") if i % 3 != 0 else Color("162944")
		_rect(Vector2(x, 315 - h), Vector2(34, h), color, _background_root)
		if i % 2 == 0:
			_rect(Vector2(x + 8, 300 - h / 2), Vector2(7, 7), Color("e5953c"), _background_root)
		if i % 3 == 0:
			_rect(Vector2(x + 20, 282 - h / 3), Vector2(7, 7), Color("79e4ff"), _background_root)
		if i == 12 or i == 16:
			_label("星环", Vector2(x - 8, 245 - h / 3), Vector2(48, 18), 17, Color("4ed9ff"))

	_rect(Vector2(0, 330), Vector2(1600, 116), Color("112337"), _background_root)
	for i in range(18):
		_line(Vector2(0, 342 + i * 6), Vector2(1600, 350 + i * 4), _color_alpha("22415b", 0.42), 2)
	for i in range(18):
		_rect(Vector2(20 + i * 92, 382 + (i % 2) * 14), Vector2(64, 4), _color_alpha("e49b47", 0.48), _background_root)
		_rect(Vector2(40 + i * 92, 404 + (i % 3) * 10), Vector2(46, 3), _color_alpha("69dcff", 0.32), _background_root)

	_rect(Vector2(0, 420), Vector2(1600, 480), Color("2b1a14"), _background_root)
	for i in range(34):
		_line(Vector2(-40, 432 + i * 15), Vector2(1640, 448 + i * 15), Color("5a321f"), 3)
	for i in range(17):
		_line(Vector2(i * 110, 420), Vector2(i * 74 + 140, 900), _color_alpha("8a4a2b", 0.38), 2)
	for i in range(22):
		_rect(Vector2(36 + i * 72, 468), Vector2(18, 24), Color("f1c06b"), _background_root)
		_rect(Vector2(36 + i * 72, 492), Vector2(18, 140), _color_alpha("f1c06b", 0.12), _background_root)

	_rect(Vector2(0, 360), Vector2(1600, 18), Color("211613"), _background_root)
	for i in range(18):
		_rect(Vector2(70 + i * 86, 360), Vector2(9, 115), Color("241a17"), _background_root)
		_line(Vector2(70 + i * 86, 410), Vector2(145 + i * 86, 410), Color("6d5845"), 4)
		_line(Vector2(70 + i * 86, 452), Vector2(145 + i * 86, 452), Color("6d5845"), 4)

	_rect(Vector2(72, 100), Vector2(445, 330), Color("211a18"), _background_root)
	_rect(Vector2(90, 118), Vector2(408, 295), Color("4a352c"), _background_root)
	_rect(Vector2(116, 184), Vector2(355, 204), Color("7b2e22"), _background_root)
	_rect(Vector2(124, 198), Vector2(338, 176), _color_alpha("d68b4c", 0.16), _background_root)
	_label("行业晚宴", Vector2(184, 207), Vector2(206, 54), 42, Color("f3b24d"))
	_label("星环科技\n年度合作伙伴\n欢迎晚宴", Vector2(300, 282), Vector2(142, 90), 22, Color("e5c9a0"))
	for i in range(7):
		_rect(Vector2(112 + i * 52, 130), Vector2(18, 18), Color("f1c06b"), _background_root)
		_rect(Vector2(116 + i * 52, 150), Vector2(10, 45), _color_alpha("f1c06b", 0.16), _background_root)

	_rect(Vector2(330, 560), Vector2(225, 76), _color_alpha("f1e0c4", 0.42), _background_root)
	_rect(Vector2(355, 545), Vector2(160, 32), Color("d8d0be"), _background_root)
	_rect(Vector2(388, 500), Vector2(40, 60), Color("0d2619"), _background_root)
	_rect(Vector2(395, 486), Vector2(26, 18), Color("e4b24a"), _background_root)
	_rect(Vector2(450, 505), Vector2(16, 50), _color_alpha("f6edd8", 0.76), _background_root)
	_rect(Vector2(478, 505), Vector2(16, 50), _color_alpha("f6edd8", 0.76), _background_root)
	_label("香槟庆祝", Vector2(335, 502), Vector2(160, 28), 24, Color("f6edd8"))

	_rect(Vector2(1018, 386), Vector2(175, 195), Color("0b1118"), _background_root)
	_rect(Vector2(1035, 405), Vector2(140, 128), Color("12304a"), _background_root)
	_label("回放终端", Vector2(1042, 420), Vector2(128, 30), 23, Color("f6edd8"))
	_rect(Vector2(1055, 474), Vector2(96, 42), _color_alpha("62d8ff", 0.36), _background_root)
	_rect(Vector2(1228, 312), Vector2(270, 238), Color("0b1118"), _background_root)
	_rect(Vector2(1252, 338), Vector2(220, 162), Color("102840"), _background_root)
	_label("职业成就\n资产       S\n履历       S\n影响力     S\n生活满意度 S", Vector2(1275, 358), Vector2(178, 120), 22, Color("8fc7ee"))
	_rect(Vector2(1334, 497), Vector2(56, 36), Color("d8a13a"), _background_root)

func _draw_school_hallway() -> void:
	if current_scene_id == "school_hallway" and _draw_fullscreen_background(SCHOOL_HALLWAY_BACKGROUND_PATH):
		return
	_draw_school_hallway_placeholder()

func _draw_school_hallway_placeholder() -> void:
	_rect(Vector2.ZERO, Vector2(1600, 900), Color("d7d1bf"), _background_root)
	for i in range(26):
		_line(Vector2(i * 64, 0), Vector2(i * 64, 900), Color("bdb5a4"), 2)
	for y in range(0, 430, 48):
		_line(Vector2(0, y), Vector2(1600, y), Color("c4bbaa"), 2)
	_rect(Vector2(0, 575), Vector2(1600, 150), Color("867b6c"), _background_root)
	_rect(Vector2(0, 700), Vector2(1600, 200), Color("1a2028"), _background_root)
	_rect(Vector2(65, 120), Vector2(245, 275), Color("243746"), _background_root)
	_rect(Vector2(90, 150), Vector2(200, 210), Color("9fc6d6"), _background_root)
	_rect(Vector2(420, 150), Vector2(220, 300), Color("6c4c34"), _background_root)
	_rect(Vector2(445, 180), Vector2(170, 240), Color("c7ae8e"), _background_root)
	_label("志愿填报\n截止: 5月20日\n+ 选专业\n+ 选城市\n+ 选未来", Vector2(462, 195), Vector2(140, 190), 26, Color("4b2e24"))
	_rect(Vector2(870, 110), Vector2(265, 75), Color("244464"), _background_root)
	_label("机 房", Vector2(940, 125), Vector2(140, 46), 40, Color("e6d5c0"))
	_rect(Vector2(895, 185), Vector2(210, 300), Color("1d2a36"), _background_root)
	_rect(Vector2(1240, 180), Vector2(150, 260), Color("123b55"), _background_root)
	_label("智能通知\nAI升学建议\n稳妥路径\n冲刺路径\n保底路径", Vector2(1265, 205), Vector2(110, 180), 25, Color("8be3ff"))
	_rect(Vector2(124, 540), Vector2(1360, 12), Color("4d4a43"), _background_root)
	_rect(Vector2(124, 655), Vector2(1360, 10), Color("4d4a43"), _background_root)

func _draw_computer_room() -> void:
	_rect(Vector2.ZERO, Vector2(1600, 900), Color("c3c7bd"), _background_root)
	_rect(Vector2(0, 0), Vector2(1600, 130), Color("45494d"), _background_root)
	_rect(Vector2(0, 565), Vector2(1600, 160), Color("5e625f"), _background_root)
	_rect(Vector2(0, 710), Vector2(1600, 190), Color("1b222b"), _background_root)
	for i in range(8):
		_rect(Vector2(150 + i * 165, 390), Vector2(120, 80), Color("2a323d"), _background_root)
		_rect(Vector2(172 + i * 165, 330), Vector2(75, 55), Color("17364b"), _background_root)
		_rect(Vector2(184 + i * 165, 342), Vector2(50, 26), _color_alpha("8be3ff", 0.75), _background_root)
	_rect(Vector2(670, 145), Vector2(280, 220), Color("142333"), _background_root)
	_label("AI 志愿系统\n综合最优\n家庭沟通\nPDF 导出", Vector2(705, 175), Vector2(210, 150), 27, Color("8be3ff"))
	_rect(Vector2(80, 490), Vector2(160, 70), Color("425f42"), _background_root)
	_label("<- 走廊", Vector2(110, 505), Vector2(100, 35), 25, Color("f6edd8"))

func _draw_home() -> void:
	if current_scene_id == "dinner_table" and _draw_fullscreen_background(DINNER_TABLE_BACKGROUND_PATH):
		return
	_draw_home_placeholder()

func _draw_home_placeholder() -> void:
	_rect(Vector2.ZERO, Vector2(1600, 900), Color("5e4b3a"), _background_root)
	_rect(Vector2(0, 0), Vector2(1600, 430), Color("b59678"), _background_root)
	_rect(Vector2(0, 620), Vector2(1600, 280), Color("3a251d"), _background_root)
	_rect(Vector2(500, 430), Vector2(600, 180), Color("7a4c2e"), _background_root)
	_rect(Vector2(545, 455), Vector2(510, 125), Color("b57d4b"), _background_root)
	_label("家长饭桌\n稳定、就业、体面\n都是关心的说法", Vector2(620, 120), Vector2(360, 150), 31, Color("f6edd8"))
	_rect(Vector2(1180, 120), Vector2(170, 250), Color("12263a"), _background_root)
	_label("升学报告\n家庭安心\n路径预测", Vector2(1205, 155), Vector2(130, 120), 24, Color("8be3ff"))

func _draw_graduation() -> void:
	if _draw_fullscreen_background(GRADUATION_FIELD_BACKGROUND_PATH):
		return

	_rect(Vector2.ZERO, Vector2(1600, 900), Color("8eb0cf"), _background_root)
	_rect(Vector2(0, 0), Vector2(1600, 420), Color("b7d4ec"), _background_root)
	_rect(Vector2(0, 420), Vector2(1600, 310), Color("6b7d55"), _background_root)
	_rect(Vector2(0, 705), Vector2(1600, 195), Color("2d3338"), _background_root)
	for i in range(11):
		_line(Vector2(0, 455 + i * 22), Vector2(1600, 455 + i * 22), Color("536d42"), 2)
	_rect(Vector2(360, 130), Vector2(330, 300), Color("6d4a32"), _background_root)
	_rect(Vector2(390, 165), Vector2(270, 230), Color("d9c7a6"), _background_root)
	_label("给未来的自己\n留言墙", Vector2(430, 190), Vector2(190, 90), 34, Color("4b2e24"))
	_rect(Vector2(1270, 230), Vector2(185, 160), Color("172635"), _background_root)
	_label("毕业照\n阶段总结", Vector2(1305, 275), Vector2(120, 70), 28, Color("f6edd8"))

func _draw_university() -> void:
	_rect(Vector2.ZERO, Vector2(1600, 900), Color("4b5f68"), _background_root)
	_rect(Vector2(0, 0), Vector2(1600, 360), Color("8aa8b7"), _background_root)
	_rect(Vector2(0, 360), Vector2(1600, 285), Color("4f6f50"), _background_root)
	_rect(Vector2(0, 635), Vector2(1600, 265), Color("26333b"), _background_root)
	for i in range(12):
		_rect(Vector2(70 + i * 125, 410 + (i % 2) * 22), Vector2(75, 105), Color("294c35"), _background_root)
		_rect(Vector2(86 + i * 125, 382 + (i % 2) * 20), Vector2(42, 42), Color("3e7a45"), _background_root)
	for i in range(18):
		_line(Vector2(i * 92, 660), Vector2(55 + i * 92, 900), Color("34414a"), 3)
	_rect(Vector2(95, 108), Vector2(390, 338), Color("6f4b38"), _background_root)
	_rect(Vector2(125, 145), Vector2(330, 260), Color("9b7354"), _background_root)
	for row in range(3):
		for col in range(4):
			_rect(Vector2(155 + col * 70, 170 + row * 66), Vector2(42, 34), Color("d3d6c4"), _background_root)
	_rect(Vector2(255, 338), Vector2(70, 67), Color("34251e"), _background_root)
	_label("学生宿舍", Vector2(205, 118), Vector2(170, 42), 30, Color("f6edd8"))
	_rect(Vector2(585, 160), Vector2(420, 235), Color("323b43"), _background_root)
	_rect(Vector2(620, 195), Vector2(350, 155), Color("1d2730"), _background_root)
	_label("社团招新\n算法队 / 影像社\n创业工坊\n今晚路演", Vector2(655, 215), Vector2(275, 120), 28, Color("8be3ff"))
	_rect(Vector2(1110, 118), Vector2(330, 285), Color("5d4635"), _background_root)
	_rect(Vector2(1145, 158), Vector2(260, 200), Color("c7ae8e"), _background_root)
	_label("课程表\n8:00 高数\n10:00 程序设计\n19:00 项目会", Vector2(1170, 180), Vector2(210, 140), 25, Color("4b2e24"))

func _draw_neon_street() -> void:
	_rect(Vector2.ZERO, Vector2(1600, 900), Color("071019"), _background_root)
	_rect(Vector2(0, 0), Vector2(1600, 390), Color("111827"), _background_root)
	for i in range(17):
		var x := i * 98
		var h := 120 + (i % 5) * 42
		_rect(Vector2(x, 390 - h), Vector2(70, h), Color("172231"), _background_root)
		if i % 2 == 0:
			_rect(Vector2(x + 16, 332 - h / 2), Vector2(12, 16), Color("8be3ff"), _background_root)
			_rect(Vector2(x + 42, 350 - h / 3), Vector2(12, 16), Color("f05bd8"), _background_root)
	_rect(Vector2(0, 390), Vector2(1600, 250), Color("1a2028"), _background_root)
	_rect(Vector2(0, 640), Vector2(1600, 260), Color("11151b"), _background_root)
	for i in range(12):
		_line(Vector2(i * 145, 645), Vector2(80 + i * 145, 900), _color_alpha("8be3ff", 0.25), 2)
	_rect(Vector2(84, 235), Vector2(365, 255), Color("25172d"), _background_root)
	_rect(Vector2(118, 285), Vector2(295, 150), Color("0d1a25"), _background_root)
	_label("旧网吧\nOPEN 24H\n低延迟 / 老机器", Vector2(145, 300), Vector2(235, 105), 30, Color("f05bd8"))
	_rect(Vector2(575, 210), Vector2(245, 125), Color("201329"), _background_root)
	_label("霓虹小吃街", Vector2(605, 245), Vector2(185, 45), 31, Color("f1c06b"))
	_rect(Vector2(1075, 185), Vector2(365, 275), Color("081d29"), _background_root)
	_rect(Vector2(1115, 245), Vector2(285, 150), Color("12263a"), _background_root)
	_label("离线留言墙\n朋友最后在线\n23:48", Vector2(1145, 270), Vector2(225, 95), 28, Color("8be3ff"))

func _draw_interview() -> void:
	_rect(Vector2.ZERO, Vector2(1600, 900), Color("d3d9df"), _background_root)
	_rect(Vector2(0, 0), Vector2(1600, 420), Color("9caab5"), _background_root)
	_rect(Vector2(0, 420), Vector2(1600, 280), Color("56616b"), _background_root)
	_rect(Vector2(0, 700), Vector2(1600, 200), Color("1b222b"), _background_root)
	_rect(Vector2(145, 95), Vector2(560, 360), Color("1c2a36"), _background_root)
	_rect(Vector2(180, 135), Vector2(490, 270), Color("0d1822"), _background_root)
	_label("ONLINE INTERVIEW\n面试官 A\n面试官 B\n屏幕共享中", Vector2(215, 165), Vector2(360, 150), 28, Color("8be3ff"))
	for i in range(4):
		_rect(Vector2(215 + i * 96, 330), Vector2(62, 38), Color("263f52"), _background_root)
	_rect(Vector2(840, 108), Vector2(430, 308), Color("2d3338"), _background_root)
	_rect(Vector2(875, 145), Vector2(360, 225), Color("eef1f3"), _background_root)
	_label("招聘屏\n岗位: AI 产品实习\n状态: 初筛通过\n风险提示: 表达不稳定", Vector2(905, 170), Vector2(285, 135), 25, Color("26323b"))
	_rect(Vector2(360, 500), Vector2(880, 88), Color("343d45"), _background_root)
	_rect(Vector2(460, 530), Vector2(170, 26), Color("8be3ff"), _background_root)
	_rect(Vector2(700, 530), Vector2(170, 26), Color("f1c06b"), _background_root)
	_rect(Vector2(940, 530), Vector2(170, 26), Color("d96b6b"), _background_root)

func _draw_office() -> void:
	_rect(Vector2.ZERO, Vector2(1600, 900), Color("16202a"), _background_root)
	_rect(Vector2(0, 0), Vector2(1600, 410), Color("202b36"), _background_root)
	_rect(Vector2(0, 410), Vector2(1600, 245), Color("4a535a"), _background_root)
	_rect(Vector2(0, 655), Vector2(1600, 245), Color("151a20"), _background_root)
	for i in range(13):
		_line(Vector2(i * 130, 655), Vector2(35 + i * 130, 900), Color("29323b"), 2)
	_rect(Vector2(85, 102), Vector2(480, 290), Color("0d1720"), _background_root)
	_label("星环办公室\nSprint 18\n伦理审查: 待补充\n上线倒计时: 3天", Vector2(125, 135), Vector2(330, 140), 28, Color("f6edd8"))
	for i in range(5):
		_rect(Vector2(130 + i * 80, 310), Vector2(52, 28), Color("8be3ff"), _background_root)
	_rect(Vector2(670, 82), Vector2(690, 335), Color("071927"), _background_root)
	for row in range(4):
		for col in range(6):
			var color := Color("8be3ff") if (row + col) % 3 == 0 else Color("2e5d72")
			_rect(Vector2(705 + col * 100, 122 + row * 62), Vector2(70, 36), color, _background_root)
	_label("DATA WALL\n用户分层 / 风险预测 / 留存曲线", Vector2(760, 352), Vector2(440, 38), 25, Color("8be3ff"))
	_rect(Vector2(1010, 112), Vector2(290, 210), Color("101820"), _background_root)
	_label("XL-0417\n来源: 教育/表达/职业\n样本: 高三许临", Vector2(1038, 142), Vector2(225, 105), 23, Color("f6edd8"))
	_rect(Vector2(1038, 258), Vector2(205, 22), Color("8be3ff"), _background_root)
	_rect(Vector2(210, 515), Vector2(1180, 70), Color("303841"), _background_root)
	for i in range(6):
		_rect(Vector2(265 + i * 180, 540), Vector2(120, 20), Color("1d2730"), _background_root)

func _draw_school_demo() -> void:
	_draw_school_hallway()
	_rect(Vector2(700, 90), Vector2(590, 300), Color("071927"), _background_root)
	_label("学校合作演示\n终身协同助理\n问题改写 -> 路径建议\n低收益愿望: 折叠", Vector2(745, 130), Vector2(420, 150), 29, Color("8be3ff"))
	_rect(Vector2(765, 315), Vector2(120, 28), Color("f1c06b"), _background_root)
	_rect(Vector2(920, 315), Vector2(120, 28), Color("8be3ff"), _background_root)
	_rect(Vector2(1075, 315), Vector2(120, 28), Color("d96b6b"), _background_root)

func _draw_city_center() -> void:
	_rect(Vector2.ZERO, Vector2(1600, 900), Color("d8dde1"), _background_root)
	_rect(Vector2(0, 0), Vector2(1600, 390), Color("b9c9d7"), _background_root)
	_rect(Vector2(0, 390), Vector2(1600, 280), Color("7a8b91"), _background_root)
	_rect(Vector2(0, 670), Vector2(1600, 230), Color("202833"), _background_root)
	_rect(Vector2(120, 105), Vector2(430, 330), Color("e7e2d6"), _background_root)
	_rect(Vector2(155, 150), Vector2(360, 235), Color("aebbc1"), _background_root)
	_label("城市服务\n演示中心", Vector2(220, 178), Vector2(230, 86), 36, Color("26323b"))
	_rect(Vector2(660, 82), Vector2(650, 350), Color("16212c"), _background_root)
	_rect(Vector2(695, 122), Vector2(580, 270), Color("0f1720"), _background_root)
	_label("实时服务地图\n人口热力 / 交通流 / 求助工单\nA 区: 92%\nB 区: 64%", Vector2(740, 150), Vector2(385, 150), 27, Color("8be3ff"))
	for i in range(8):
		_rect(Vector2(760 + i * 52, 330 - (i % 4) * 22), Vector2(34, 42 + (i % 4) * 22), Color("f1c06b"), _background_root)
	_rect(Vector2(170, 505), Vector2(1260, 88), Color("58656b"), _background_root)
	_rect(Vector2(250, 535), Vector2(160, 24), Color("e7e2d6"), _background_root)
	_rect(Vector2(700, 535), Vector2(220, 24), Color("8be3ff"), _background_root)
	_rect(Vector2(1080, 535), Vector2(190, 24), Color("d96b6b"), _background_root)

func _draw_final_overlay() -> void:
	_rect(Vector2.ZERO, Vector2(1600, 900), Color("121820"), _background_root)
	_rect(Vector2(0, 0), Vector2(1600, 330), Color("1f3141"), _background_root)
	_rect(Vector2(0, 330), Vector2(1600, 310), Color("334738"), _background_root)
	_rect(Vector2(0, 640), Vector2(1600, 260), Color("151a20"), _background_root)
	for i in range(18):
		_line(Vector2(0, 350 + i * 24), Vector2(1600, 320 + i * 18), _color_alpha("8be3ff", 0.18), 2)
		_line(Vector2(i * 95, 0), Vector2(i * 52, 900), _color_alpha("f1c06b", 0.15), 2)
	_rect(Vector2(80, 115), Vector2(305, 240), _color_alpha("9b7354", 0.78), _background_root)
	_label("高中走廊", Vector2(135, 145), Vector2(165, 46), 31, Color("f6edd8"))
	_rect(Vector2(350, 250), Vector2(310, 220), _color_alpha("323b43", 0.8), _background_root)
	_label("大学社团", Vector2(420, 285), Vector2(165, 44), 30, Color("8be3ff"))
	_rect(Vector2(650, 130), Vector2(330, 245), _color_alpha("25172d", 0.82), _background_root)
	_label("霓虹街区", Vector2(725, 165), Vector2(170, 44), 30, Color("f05bd8"))
	_rect(Vector2(940, 300), Vector2(300, 225), _color_alpha("eef1f3", 0.78), _background_root)
	_label("面试屏幕", Vector2(1010, 335), Vector2(160, 44), 30, Color("26323b"))
	_rect(Vector2(1210, 125), Vector2(310, 280), _color_alpha("071927", 0.84), _background_root)
	_label("星环数据墙", Vector2(1270, 160), Vector2(190, 44), 29, Color("8be3ff"))
	_rect(Vector2(570, 510), Vector2(470, 120), _color_alpha("e7e2d6", 0.72), _background_root)
	_label("城市服务演示中心\n所有地图重叠在这里", Vector2(640, 535), Vector2(330, 58), 26, Color("26323b"))
	_rect(Vector2(1040, 510), Vector2(360, 120), _color_alpha("071927", 0.84), _background_root)
	_label("是否上传人生模型?\n上传 / 上传", Vector2(1090, 535), Vector2(240, 58), 28, Color("8be3ff"))

func _add_bottom_centered_sprite(path: String, anchor: Vector2, z_index: int = 0) -> void:
	var texture := ArtTextureLoaderScript.load_png_texture(path)
	if texture == null:
		return

	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = true
	sprite.position = anchor
	sprite.offset = Vector2(0, -float(texture.get_height()) / 2.0)
	sprite.z_index = z_index
	_background_root.add_child(sprite)

func _draw_fullscreen_background(path: String) -> bool:
	var texture := ArtTextureLoaderScript.load_png_texture(path)
	if texture == null:
		return false

	var background := Sprite2D.new()
	background.texture = texture
	background.centered = true
	background.position = Vector2(800, 450)
	var scale_factor := maxf(1600.0 / float(texture.get_width()), 900.0 / float(texture.get_height()))
	background.scale = Vector2.ONE * scale_factor
	background.z_index = -200
	_background_root.add_child(background)
	return true

func _rect(pos: Vector2, size: Vector2, color: Color, parent: Node) -> ColorRect:
	var rect := ColorRect.new()
	rect.position = pos
	rect.size = size
	rect.color = color
	parent.add_child(rect)
	return rect

func _label(text: String, pos: Vector2, size: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = size
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color("0b0d10"))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	_background_root.add_child(label)
	return label

func _line(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	var line := Line2D.new()
	line.add_point(from)
	line.add_point(to)
	line.default_color = color
	line.width = width
	_background_root.add_child(line)

func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func _color_alpha(hex: String, alpha: float) -> Color:
	var color := Color(hex)
	color.a = alpha
	return color

func _game_state() -> Node:
	return get_node("/root/GameState")

func _chapter_data() -> Node:
	return get_node("/root/ChapterData")

func _player_stage_for_chapter(chapter_id: String) -> String:
	return str(PLAYER_STAGE_BY_CHAPTER.get(chapter_id, "adult"))
