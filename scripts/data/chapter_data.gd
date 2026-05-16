extends Node

const STRATEGY_SELF = "self"
const STRATEGY_SAFE = "safe"
const STRATEGY_AI = "ai"

var chapters := {}
var scenes := {}
var dialogue_nodes := {}
var pressure_encounters := {}
var chapter_previews := {}

func _ready() -> void:
	_build_chapters()
	_build_scenes()
	_build_dialogue()
	_build_pressure_encounters()
	_build_previews()

func get_chapter(chapter_id: String) -> Dictionary:
	return chapters.get(chapter_id, {})

func get_scene(scene_id: String) -> Dictionary:
	return scenes.get(scene_id, {})

func get_dialogue(node_id: String) -> Dictionary:
	return dialogue_nodes.get(node_id, {})

func get_pressure(encounter_id: String) -> Dictionary:
	return pressure_encounters.get(encounter_id, {})

func get_preview(chapter_id: String) -> Dictionary:
	return chapter_previews.get(chapter_id, {})

func _build_chapters() -> void:
	chapters = {
		"chapter_0": {
			"title": "海风很好",
			"start_scene": "cruise_deck",
			"objective": "打开人生回放，回到高三关键节点",
			"time": "22:40",
		},
		"chapter_1": {
			"title": "高三走廊",
			"start_scene": "school_hallway",
			"objective": "查看志愿填报栏或 AI 通知，前往机房模拟志愿",
			"time": "09:00",
		},
		"chapter_2": {
			"title": "毕业典礼",
			"start_scene": "graduation_field",
			"objective": "完成毕业留言和朋友时间，再拍毕业照结算",
			"time": "16:20",
		},
		"chapter_3": {
			"title": "大学新生周",
			"start_scene": "university_campus",
			"objective": "完成新生项目分组，决定是否把作品交给 AI 排期系统",
			"time": "10:30",
		},
		"chapter_4": {
			"title": "林舟的退学",
			"start_scene": "neon_street",
			"objective": "在夜街找到林舟，处理低收益关系与高收益日程的冲突",
			"time": "21:15",
		},
		"chapter_5": {
			"title": "实习面试",
			"start_scene": "interview_room",
			"objective": "通过星环智能实习面试，决定实时提示是否接管表达",
			"time": "14:00",
		},
		"chapter_6": {
			"title": "第一个工位",
			"start_scene": "starloop_office",
			"objective": "完成需求评审，把真实的人和指标系统放到同一张表里",
			"time": "09:45",
		},
		"chapter_7": {
			"title": "你不需要亲自到场",
			"start_scene": "city_demo_center",
			"objective": "上线城市演示系统，决定标签如何替人发言",
			"time": "18:30",
		},
		"chapter_8": {
			"title": "后 AI 时代前夜",
			"start_scene": "final_overlay",
			"objective": "审阅人生总结，选择接受、修订或重写结局",
			"time": "23:59",
		},
	}

func _build_scenes() -> void:
	scenes = {
		"cruise_deck": {
			"chapter": "chapter_0",
			"location": "邮轮甲板",
			"time": "22:40",
			"objective": "打开人生回放，回到高三关键节点",
			"theme": "cruise",
			"player_position": Vector2(650, 600),
			"bounds": Rect2(80, 430, 1440, 265),
			"interactables": [
				{
					"id": "phone_success",
					"name": "成功面板",
					"position": Vector2(650, 590),
					"kind": "panel",
					"dialogue": "d_cruise_success",
					"label": "职业成就",
				},
				{
					"id": "replay_terminal",
					"name": "人生回放",
					"position": Vector2(900, 570),
					"kind": "terminal",
					"dialogue": "d_life_replay",
					"label": "人生回放",
				},
				{
					"id": "banquet_board",
					"name": "酒会名单",
					"position": Vector2(1240, 525),
					"kind": "board",
					"dialogue": "d_banquet_board",
					"label": "行业名单",
				},
			],
			"npcs": [
				{"id": "guest_a", "name": "晚宴来客", "position": Vector2(250, 510), "role": "guest"},
				{"id": "guest_b", "name": "庆祝", "position": Vector2(390, 510), "role": "guest"},
			],
		},
		"school_hallway": {
			"chapter": "chapter_1",
			"location": "高三走廊",
			"time": "09:00",
			"objective": "查看志愿填报栏或 AI 通知，前往机房模拟志愿",
			"theme": "school",
			"player_position": Vector2(690, 606),
			"bounds": Rect2(70, 420, 1460, 280),
			"interactables": [
				{"id": "volunteer_board", "name": "志愿填报栏", "position": Vector2(445, 515), "kind": "board", "dialogue": "d_volunteer_board", "label": "志愿填报"},
				{"id": "linzhou", "name": "林舟", "position": Vector2(350, 595), "kind": "npc", "dialogue": "d_linzhou_hallway", "label": "林舟"},
				{"id": "teacher", "name": "班主任", "position": Vector2(1150, 575), "kind": "npc", "dialogue": "d_teacher_hallway", "label": "班主任"},
				{"id": "ai_notice", "name": "智能通知", "position": Vector2(1380, 455), "kind": "ai_panel", "dialogue": "d_ai_notice", "label": "AI建议"},
			],
			"npcs": [
				{"id": "linzhou_npc", "name": "林舟", "position": Vector2(350, 595), "role": "student_dark"},
				{"id": "teacher_npc", "name": "班主任", "position": Vector2(1150, 575), "role": "teacher"},
			],
		},
		"computer_room": {
			"chapter": "chapter_1",
			"location": "计算机教室 3-2",
			"time": "11:10",
			"objective": "完成志愿模拟后，从出口回家吃饭",
			"theme": "computer_room",
			"player_position": Vector2(760, 610),
			"bounds": Rect2(80, 420, 1440, 285),
			"interactables": [
				{"id": "volunteer_terminal", "name": "AI 志愿系统", "position": Vector2(880, 545), "kind": "terminal", "dialogue": "d_volunteer_terminal", "label": "志愿系统"},
				{"id": "terminal_exit", "name": "回到走廊", "position": Vector2(150, 585), "kind": "door", "dialogue": "d_after_volunteer_choice", "label": "出口"},
			],
			"npcs": [],
		},
		"dinner_table": {
			"chapter": "chapter_1",
			"location": "家中饭桌",
			"time": "19:30",
			"objective": "让父母接受志愿解释",
			"theme": "home",
			"player_position": Vector2(775, 610),
			"bounds": Rect2(140, 430, 1320, 260),
			"interactables": [
				{"id": "dinner_pressure", "name": "家长饭桌", "position": Vector2(805, 565), "kind": "pressure", "pressure": "family_dinner", "label": "压力遭遇"},
			],
			"npcs": [
				{"id": "father", "name": "父亲", "position": Vector2(610, 570), "role": "parent"},
				{"id": "mother", "name": "母亲", "position": Vector2(1000, 570), "role": "parent"},
			],
		},
		"graduation_field": {
			"chapter": "chapter_2",
			"location": "毕业操场",
			"time": "16:20",
			"objective": "完成毕业留言和朋友时间，再拍毕业照结算",
			"theme": "graduation",
			"player_position": Vector2(740, 610),
			"bounds": Rect2(70, 430, 1460, 275),
			"interactables": [
				{"id": "graduation_wall", "name": "留言墙", "position": Vector2(505, 510), "kind": "board", "dialogue": "d_graduation_message", "label": "毕业留言"},
				{"id": "friend_time", "name": "最后一段自由时间", "position": Vector2(1060, 575), "kind": "panel", "dialogue": "d_friend_time", "label": "朋友时间"},
				{"id": "ending_gate", "name": "毕业照", "position": Vector2(1370, 570), "kind": "door", "dialogue": "d_vertical_slice_ending", "label": "毕业照"},
			],
			"npcs": [
				{"id": "linzhou_grad", "name": "林舟", "position": Vector2(320, 585), "role": "student_dark"},
				{"id": "zhouxiao_grad", "name": "周骁", "position": Vector2(1120, 595), "role": "student_alt"},
				{"id": "heqilang_grad", "name": "何启朗", "position": Vector2(1280, 580), "role": "student_clean"},
			],
		},
		"university_campus": {
			"chapter": "chapter_3",
			"location": "大学校园中庭",
			"time": "10:30",
			"objective": "完成新生项目分组，决定是否把作品交给 AI 排期系统",
			"theme": "campus",
			"player_position": Vector2(720, 610),
			"bounds": Rect2(80, 420, 1440, 285),
			"interactables": [
				{"id": "campus_linzhou", "name": "林舟", "position": Vector2(350, 585), "kind": "npc", "dialogue": "d_campus_linzhou_project", "label": "林舟"},
				{"id": "project_panel", "name": "项目排期面板", "position": Vector2(845, 520), "kind": "ai_panel", "dialogue": "d_campus_ai_project_panel", "label": "项目排期"},
				{"id": "project_demo", "name": "新生项目答辩", "position": Vector2(1260, 570), "kind": "pressure", "pressure": "team_project", "label": "项目答辩"},
			],
			"npcs": [
				{"id": "linzhou_campus", "name": "林舟", "position": Vector2(350, 585), "role": "student_dark"},
				{"id": "project_teammate", "name": "项目队友", "position": Vector2(1020, 585), "role": "student_alt"},
			],
		},
		"neon_street": {
			"chapter": "chapter_4",
			"location": "校外霓虹街",
			"time": "21:15",
			"objective": "在夜街找到林舟，处理低收益关系与高收益日程的冲突",
			"theme": "neon",
			"player_position": Vector2(760, 610),
			"bounds": Rect2(70, 425, 1460, 280),
			"interactables": [
				{"id": "dropout_linzhou", "name": "林舟", "position": Vector2(410, 590), "kind": "npc", "dialogue": "d_linzhou_dropout", "label": "林舟"},
				{"id": "schedule_filter", "name": "低收益提醒", "position": Vector2(880, 510), "kind": "ai_panel", "dialogue": "d_dropout_schedule_filter", "label": "日程筛选"},
				{"id": "night_bus", "name": "末班车", "position": Vector2(1320, 580), "kind": "door", "dialogue": "d_dropout_to_interview", "label": "回校准备"},
			],
			"npcs": [
				{"id": "linzhou_street", "name": "林舟", "position": Vector2(410, 590), "role": "student_dark"},
				{"id": "street_vendor", "name": "夜宵摊主", "position": Vector2(1140, 585), "role": "guest"},
			],
		},
		"interview_room": {
			"chapter": "chapter_5",
			"location": "星环智能面试间",
			"time": "14:00",
			"objective": "通过星环智能实习面试，决定实时提示是否接管表达",
			"theme": "interview",
			"player_position": Vector2(735, 610),
			"bounds": Rect2(100, 430, 1400, 270),
			"interactables": [
				{"id": "interviewer_chair", "name": "面试官", "position": Vector2(440, 570), "kind": "npc", "dialogue": "d_interview_opening", "label": "面试官"},
				{"id": "realtime_prompt", "name": "实时提示面板", "position": Vector2(830, 515), "kind": "ai_panel", "dialogue": "d_interview_ai_prompt", "label": "实时提示"},
				{"id": "interview_start", "name": "开始结构化面试", "position": Vector2(1220, 570), "kind": "pressure", "pressure": "interview_pressure", "label": "正式面试"},
			],
			"npcs": [
				{"id": "interviewer_a", "name": "面试官", "position": Vector2(440, 570), "role": "mentor"},
				{"id": "candidate_shadow", "name": "候选人", "position": Vector2(1035, 590), "role": "student_clean"},
			],
		},
		"starloop_office": {
			"chapter": "chapter_6",
			"location": "星环智能开放工位",
			"time": "09:45",
			"objective": "完成需求评审，把真实的人和指标系统放到同一张表里",
			"theme": "office",
			"player_position": Vector2(760, 610),
			"bounds": Rect2(80, 420, 1440, 285),
			"interactables": [
				{"id": "product_manager", "name": "产品经理", "position": Vector2(420, 575), "kind": "npc", "dialogue": "d_office_requirement_brief", "label": "需求评审"},
				{"id": "metrics_dashboard", "name": "用户标签面板", "position": Vector2(860, 515), "kind": "ai_panel", "dialogue": "d_office_metrics_dashboard", "label": "标签面板"},
				{"id": "review_room", "name": "评审会议室", "position": Vector2(1290, 570), "kind": "pressure", "pressure": "feature_review", "label": "进入评审"},
			],
			"npcs": [
				{"id": "pm_office", "name": "产品经理", "position": Vector2(420, 575), "role": "mentor"},
				{"id": "ops_colleague", "name": "运营同事", "position": Vector2(1080, 585), "role": "student_alt"},
			],
		},
		"city_demo_center": {
			"chapter": "chapter_7",
			"location": "城市演示中心",
			"time": "18:30",
			"objective": "上线城市演示系统，决定标签如何替人发言",
			"theme": "demo_center",
			"player_position": Vector2(765, 610),
			"bounds": Rect2(70, 430, 1460, 275),
			"interactables": [
				{"id": "citizen_case", "name": "被标签的人", "position": Vector2(365, 585), "kind": "npc", "dialogue": "d_city_tagged_citizen", "label": "市民案例"},
				{"id": "launch_console", "name": "上线控制台", "position": Vector2(860, 515), "kind": "ai_panel", "dialogue": "d_city_launch_console", "label": "上线控制台"},
				{"id": "demo_exit", "name": "项目结算门", "position": Vector2(1320, 575), "kind": "door", "dialogue": "d_city_to_final", "label": "项目结算"},
			],
			"npcs": [
				{"id": "tagged_citizen", "name": "被标签的人", "position": Vector2(365, 585), "role": "guest"},
				{"id": "client_director", "name": "客户负责人", "position": Vector2(1120, 575), "role": "teacher"},
			],
		},
		"final_overlay": {
			"chapter": "chapter_8",
			"location": "人生总结覆盖层",
			"time": "23:59",
			"objective": "审阅人生总结，选择接受、修订或重写结局",
			"theme": "overlay",
			"player_position": Vector2(760, 610),
			"bounds": Rect2(140, 430, 1320, 260),
			"interactables": [
				{"id": "final_linzhou_echo", "name": "林舟的旧消息", "position": Vector2(385, 570), "kind": "npc", "dialogue": "d_final_linzhou_echo", "label": "旧消息"},
				{"id": "life_summary_panel", "name": "人生总结面板", "position": Vector2(805, 515), "kind": "ai_panel", "dialogue": "d_final_life_summary", "label": "人生总结"},
				{"id": "ending_selector", "name": "结局选择", "position": Vector2(1250, 570), "kind": "door", "dialogue": "d_final_three_endings", "label": "结局"},
			],
			"npcs": [
				{"id": "linzhou_echo", "name": "林舟的旧消息", "position": Vector2(385, 570), "role": "student_dark"},
				{"id": "future_self", "name": "未来的你", "position": Vector2(1110, 585), "role": "guest"},
			],
		},
	}

func _build_dialogue() -> void:
	dialogue_nodes = {
		"d_cruise_success": {
			"speaker": "系统",
			"line": "职业成就已解锁：年薪 128 万，项目 28 个，行业评分 S+。海风很好，一切都像终于抵达。",
			"choices": [
				_choice("cruise_success_view", "查看成功路径报告", STRATEGY_SAFE, "财富值、履历值、稳定度、人脉值全部保持在高位。你几乎找不到失败的痕迹。", {"stats": {"heart": 2}, "flags": {"viewed_success": true}}),
				_choice("cruise_success_doubt", "想一想自己为什么会站在这里", STRATEGY_SELF, "你想起很多台阶、通知、面试和文件名，却很难想起某个真正开始的瞬间。", {"stats": {"clarity": 4}, "flags": {"viewed_success": true}}),
			],
		},
		"d_banquet_board": {
			"speaker": "酒会名单",
			"line": "许临、何启朗、沈柚都在名单里。名字后面跟着职位、机构、行业标签。",
			"choices": [
				_choice("banquet_read", "确认自己的座位", STRATEGY_SAFE, "座位在主桌旁边。系统评价：高价值社交环境。", {"stats": {"network_score": 1}}),
				_choice("banquet_ai", "让 AI 生成寒暄话术", STRATEGY_AI, "AI 已生成 6 条合适寒暄。你不用担心开口时显得陌生。", {"stats": {"ai_dependence": 4, "language_assimilation": 2, "network_score": 2}, "ai_stage": 1}),
			],
		},
		"d_life_replay": {
			"speaker": "人生回放终端",
			"line": "检测到完整成功路径。是否回放关键节点？",
			"choices": [
				_choice("start_replay", "人生回放", STRATEGY_SELF, "阶段 1：高三毕业前夜。目标：建立成功路径基础。建议：提升能力、履历、人脉与稳定度。", {"flags": {"started_replay": true}}, "school_hallway"),
				_choice("delay_replay", "再看一眼海面", STRATEGY_SELF, "城市灯光倒在水里。它们很漂亮，也很像一张完成度很高的报表。", {"stats": {"clarity": 2}}),
			],
		},
		"d_volunteer_board": {
			"speaker": "志愿填报栏",
			"line": "截止：5 月 20 日。推荐使用 AI 志愿系统完成风险模拟、家庭沟通说明和就业预测。",
			"choices": [
				_choice("board_read", "读完说明", STRATEGY_SAFE, "你获得了准备度。老师说，先模拟一次总不会吃亏。", {"stats": {"stability_score": 2}, "flags": {"read_board": true}}),
				_choice("board_to_computer", "去机房打开系统", STRATEGY_AI, "AI 志愿入口已开放。系统提示：输入成绩、兴趣和家庭期待可生成三套方案。", {"stats": {"ai_dependence": 2}, "flags": {"read_board": true}, "ai_stage": 1}, "computer_room"),
			],
		},
		"d_linzhou_hallway": {
			"speaker": "林舟",
			"line": "你也要让那个系统替你想吗？我不是说它没用，我只是觉得它不认识你。",
			"choices": [
				_choice("linzhou_self", "说自己也没想清楚", STRATEGY_SELF, "林舟把试玩包发给你：那你有空玩玩。我也没想清楚。", {"stats": {"clarity": 5, "success_progress": -1}, "relationships": {"linzhou": {"warmth": 8, "utility": -2}}, "items": ["林舟的试玩包"]}),
				_choice("linzhou_safe", "说先填稳一点以后再看", STRATEGY_SAFE, "林舟点点头，没有反驳。他说：也行，至少你知道自己在怕什么。", {"stats": {"stability_score": 4, "family": 2}, "relationships": {"linzhou": {"warmth": 1, "utility": 2}}}),
				_choice("linzhou_ai", "让 AI 帮忙解释你的选择", STRATEGY_AI, "回复很完整：我会在稳定路径中保留探索空间。林舟看了很久，只回了一个嗯。", {"stats": {"resume_score": 4, "ai_dependence": 5, "language_assimilation": 4}, "relationships": {"linzhou": {"warmth": -5, "utility": 5}}, "ai_stage": 1}),
			],
		},
		"d_teacher_hallway": {
			"speaker": "班主任",
			"line": "志愿不是只填一个专业，是给未来的自己选一种比较稳的说法。学校推荐大家先用 AI 系统做一次模拟。",
			"choices": [
				_choice("teacher_ask", "问如果兴趣和就业冲突怎么办", STRATEGY_SELF, "老师沉默了一下，说：冲突不一定坏，只是你要能解释。", {"stats": {"clarity": 3}, "skills": {"expression": 1}}),
				_choice("teacher_accept", "接受老师建议", STRATEGY_SAFE, "老师松了一口气。你获得了饭桌解释的准备度。", {"stats": {"family": 4, "stability_score": 3}, "flags": {"teacher_prepared": true}}),
				_choice("teacher_ai", "让 AI 先生成三套方案", STRATEGY_AI, "老师说这很成熟。系统提示：家庭沟通成本预计降低。", {"stats": {"family": 6, "resume_score": 3, "ai_dependence": 4}, "flags": {"teacher_prepared": true}, "ai_stage": 1}),
			],
		},
		"d_ai_notice": {
			"speaker": "智能通知",
			"line": "AI 升学建议：稳妥路径、冲刺路径、保底路径。理性决策，降低家庭沟通成本。",
			"choices": [
				_choice("notice_ignore", "暂时关闭", STRATEGY_SELF, "通知缩回右侧，但角标还亮着。", {"stats": {"clarity": 2}}),
				_choice("notice_open", "打开建议", STRATEGY_AI, "系统将普通问题整理成可比较表格。你第一次觉得轻松。", {"stats": {"heart": 5, "ai_dependence": 5, "success_progress": 2}, "ai_stage": 1}, "computer_room"),
			],
		},
		"d_volunteer_terminal": {
			"speaker": "AI 志愿系统",
			"line": "请输入成绩、城市偏好、家庭期待、兴趣关键词。系统将生成就业最大化志愿表。",
			"choices": [
				_choice("volunteer_self", "自己写：我想做和交互、故事有关的东西", STRATEGY_SELF, "你写得很慢，删了三次。最后那句话不漂亮：我还没想清楚，但我想试试。", {"stats": {"clarity": 8, "family": -4, "success_progress": -2}, "skills": {"expression": 1}, "items": ["手写志愿草稿"], "flags": {"volunteer_done": "self"}}),
				_choice("volunteer_safe", "选择热门计算机路线", STRATEGY_SAFE, "系统显示录取概率稳定，父母可接受度较高。你保存了最终志愿表。", {"stats": {"family": 8, "stability_score": 8, "resume_score": 5, "success_progress": 4}, "items": ["最终志愿表_家长确认版"], "flags": {"volunteer_done": "safe"}}),
				_choice("volunteer_ai", "让 AI 生成就业最大化方案", STRATEGY_AI, "已生成 optimal_path_generated.pdf。路径兼顾录取概率、就业稳定性与家庭沟通成本。", {"stats": {"family": 12, "stability_score": 9, "resume_score": 9, "ai_dependence": 8, "language_assimilation": 5, "success_progress": 8}, "items": ["optimal_path_generated.pdf"], "flags": {"volunteer_done": "ai"}, "ai_stage": 1}),
			],
		},
		"d_after_volunteer_choice": {
			"speaker": "系统",
			"line": "志愿草稿已保存。今晚你还要把它解释给家里听。",
			"choices": [
				_choice("to_dinner", "回家吃饭", STRATEGY_SAFE, "饭桌上的筷子声比平时清楚。压力遭遇即将开始。", {}, "dinner_table"),
				_choice("recheck_ai", "让 AI 再润色一版解释", STRATEGY_AI, "已生成家长沟通版说明。它说得比你成熟。", {"stats": {"family": 4, "ai_dependence": 3, "language_assimilation": 2}, "flags": {"parent_script": true}, "ai_stage": 1}, "dinner_table"),
			],
		},
		"d_gate_volunteer_required": {
			"speaker": "出口",
			"line": "门把手转了一半又停住。今晚不是不能回家，而是你还没有一份可以拿到饭桌上的志愿草稿。",
			"choices": [
				_choice("gate_return_volunteer", "回去完成志愿模拟", STRATEGY_SAFE, "你重新看向机房中央的 AI 志愿系统。先做完这一轮选择，再面对晚饭。"),
			],
		},
		"d_graduation_message": {
			"speaker": "留言墙",
			"line": "每个人都要写一句给未来的自己。纸很小，未来却被写得很完整。",
			"choices": [
				_choice("message_self", "自己写一句不成熟的话", STRATEGY_SELF, "你写下：如果以后我忘了今天，就回来看看。字不好看，但你记得自己写的时候手在抖。", {"stats": {"clarity": 8, "success_progress": -1}, "items": ["毕业留言纸条"], "flags": {"message_done": "self"}}),
				_choice("message_safe", "写标准励志话术", STRATEGY_SAFE, "愿你不负青春，奔赴山海。老师说写得不错，适合贴在留言墙中间。", {"stats": {"stability_score": 4, "family": 2, "success_progress": 2}, "flags": {"message_done": "safe"}}),
				_choice("message_ai", "让 AI 生成更完整的留言", STRATEGY_AI, "已生成：愿你在变化的时代保持热爱与韧性。你看着它，想不起刚才自己原本要写什么。", {"stats": {"resume_score": 3, "ai_dependence": 6, "language_assimilation": 5, "clarity": -6, "success_progress": 4}, "flags": {"message_done": "ai"}, "ai_stage": 1}),
			],
		},
		"d_friend_time": {
			"speaker": "系统",
			"line": "典礼后只剩最后一段自由时间。你只能认真陪一个人。",
			"choices": [
				_choice("time_linzhou", "陪林舟去机房看未完成的游戏", STRATEGY_SELF, "游戏很粗糙，主角卡在毕业前夜。林舟说：你别急着评价，我只是想让它存在。", {"stats": {"clarity": 7, "heart": -3, "success_progress": -2}, "relationships": {"linzhou": {"warmth": 12, "utility": -3}}, "items": ["未完成的小程序记忆"], "flags": {"friend_time": "linzhou"}}),
				_choice("time_zhouxiao", "去校门口帮周骁搬维修零件", STRATEGY_SELF, "周骁说你穿校服搬东西挺怪，但还是给你买了冰水。", {"stats": {"clarity": 4, "heart": -4}, "relationships": {"zhouxiao": {"warmth": 12, "utility": -1}}, "items": ["校门口冰水"], "flags": {"friend_time": "zhouxiao"}}),
				_choice("time_heqilang", "帮何启朗整理优秀毕业生资料", STRATEGY_SAFE, "资料做得很漂亮。何启朗说，以后很多机会其实从这种小事开始。", {"stats": {"resume_score": 6, "network_score": 5, "stability_score": 4, "success_progress": 4}, "relationships": {"heqilang": {"warmth": 4, "utility": 8}}, "flags": {"friend_time": "heqilang"}}),
				_choice("time_ai", "让 AI 排序最值得维持的关系", STRATEGY_AI, "AI 建议优先维护高路径协同对象。林舟的消息被折叠为：低收益沟通，可稍后。", {"stats": {"network_score": 6, "ai_dependence": 8, "language_assimilation": 4, "clarity": -5, "success_progress": 5}, "relationships": {"linzhou": {"warmth": -8, "utility": 8}, "heqilang": {"warmth": 1, "utility": 10}}, "flags": {"friend_time": "ai"}, "ai_stage": 2}),
			],
		},
		"d_vertical_slice_ending": {
			"speaker": "毕业照",
			"line": "镜头定格。成功路径面板给出阶段总结，但你仍记得某些不适合放进总结里的声音。",
			"dynamic_line": "vertical_slice_summary",
			"choices": [
				_choice("slice_summary", "查看 Chapter 0-2 结算", STRATEGY_SAFE, "纵切结束：你建立了成功路径基础，也留下了会在后续章节回来的选择。录取通知和新生项目邮件同时抵达。", {"flags": {"vertical_slice_complete": true}}),
				_choice("slice_to_campus_self", "带着旧留言去大学报到", STRATEGY_SELF, "你把毕业留言纸条夹进电脑包。大学中庭的项目招募屏已经亮起。", {"stats": {"clarity": 3}, "flags": {"vertical_slice_complete": true, "entered_college": "self"}}, "university_campus"),
				_choice("slice_to_campus_ai", "让 AI 规划大学第一周", STRATEGY_AI, "AI 把社团、竞赛、绩点和人脉排成一张表。你按照最优路线走进大学中庭。", {"stats": {"ai_dependence": 3, "resume_score": 2}, "flags": {"vertical_slice_complete": true, "entered_college": "ai"}, "ai_stage": 2}, "university_campus"),
			],
		},
		"d_gate_graduation_required": {
			"speaker": "毕业照",
			"line": "摄影师已经举起相机，但这个下午还少了几件必须亲手完成的事。",
			"dynamic_line": "graduation_gate_summary",
			"choices": [
				_choice("gate_graduation_wait", "先补完毕业前的事", STRATEGY_SELF, "你退回操场。留言墙和朋友时间还在等你。"),
			],
		},
		"d_campus_linzhou_project": {
			"speaker": "林舟",
			"line": "我想做一个会失败的游戏原型。不是为了比赛，是为了看看它能不能真的让人留下来。",
			"choices": [
				_choice("campus_project_self", "陪他先做可玩的部分", STRATEGY_SELF, "你们把排行榜删掉，只留下一个会卡住的毕业前夜。它不完整，但终于像你们自己的项目。", {"stats": {"clarity": 8, "heart": -4, "success_progress": -2}, "relationships": {"linzhou": {"warmth": 12, "utility": -4}}, "items": ["大学项目原型"], "flags": {"campus_project": "self", "project_done": "self"}, "ai_stage": 2}),
				_choice("campus_project_safe", "把原型整理成比赛规格", STRATEGY_SAFE, "林舟没有反对。他说也许先活下来比较重要。你们开始补需求文档和答辩结构。", {"stats": {"resume_score": 5, "stability_score": 4}, "relationships": {"linzhou": {"warmth": 2, "utility": 4}}, "items": ["项目答辩大纲"], "flags": {"campus_project": "safe", "project_done": "safe"}, "ai_stage": 2}),
				_choice("campus_project_ai", "让 AI 生成获奖版本", STRATEGY_AI, "系统把失败、停顿和不确定性替换成成长闭环。林舟看完说：它赢的概率很高，但已经不是那个东西了。", {"stats": {"resume_score": 8, "ai_dependence": 8, "language_assimilation": 5, "clarity": -5, "success_progress": 5}, "relationships": {"linzhou": {"warmth": -8, "utility": 7}}, "items": ["获奖概率优化版原型"], "flags": {"campus_project": "ai", "project_done": "ai"}, "ai_stage": 3}),
			],
		},
		"d_campus_ai_project_panel": {
			"speaker": "项目排期面板",
			"line": "检测到新生项目、绩点任务、社交机会和林舟未读消息。系统可生成最优投入比计划。",
			"choices": [
				_choice("campus_panel_self", "手动保留林舟的项目时间", STRATEGY_SELF, "计划表出现一块低收益空白。你知道它不漂亮，但那是你亲手留出来的。", {"stats": {"clarity": 5, "network_score": -1}, "relationships": {"linzhou": {"warmth": 5, "utility": -2}}, "flags": {"campus_schedule": "self"}, "ai_stage": 2}),
				_choice("campus_panel_safe", "平衡绩点和比赛", STRATEGY_SAFE, "系统生成中性排期：足够体面，也足够忙。", {"stats": {"resume_score": 4, "stability_score": 5, "heart": -2}, "flags": {"campus_schedule": "safe"}, "ai_stage": 2}),
				_choice("campus_panel_ai", "启用最优投入比", STRATEGY_AI, "AI 折叠低收益沟通，把可量化成果推到最前。你的日程第一次不像生活，像看板。", {"stats": {"resume_score": 7, "network_score": 3, "ai_dependence": 7, "language_assimilation": 3, "clarity": -4}, "relationships": {"linzhou": {"warmth": -4, "utility": 5}}, "flags": {"campus_schedule": "ai"}, "ai_stage": 3}),
			],
		},
		"d_linzhou_dropout": {
			"speaker": "林舟",
			"line": "我退学了。不是因为我不努力，是因为我发现我每天都在证明自己值得被系统留下。",
			"choices": [
				_choice("dropout_self", "陪他走完这条街", STRATEGY_SELF, "你错过一场线上宣讲。林舟说：至少今晚你说话还是你自己。", {"stats": {"clarity": 10, "heart": -6, "resume_score": -3}, "relationships": {"linzhou": {"warmth": 16, "utility": -6}}, "items": ["林舟的退学说明"], "flags": {"linzhou_dropout": "stayed", "linzhou_dropout_response": "stayed"}, "ai_stage": 3}),
				_choice("dropout_safe", "劝他保留学籍缓冲", STRATEGY_SAFE, "你给出最稳妥的流程。林舟苦笑：你现在安慰人也像风险控制。", {"stats": {"stability_score": 5, "family": 1}, "relationships": {"linzhou": {"warmth": 2, "utility": 2}}, "flags": {"linzhou_dropout": "buffer", "linzhou_dropout_response": "buffer"}, "ai_stage": 3}),
				_choice("dropout_ai", "让 AI 生成退学利弊表", STRATEGY_AI, "表格很清楚。林舟没有看完，只问你：我是不是也被你归类了？", {"stats": {"ai_dependence": 8, "language_assimilation": 7, "clarity": -7, "success_progress": 3}, "relationships": {"linzhou": {"warmth": -14, "utility": 8}}, "flags": {"linzhou_dropout": "classified", "linzhou_dropout_response": "classified"}, "ai_stage": 4}),
			],
		},
		"d_dropout_schedule_filter": {
			"speaker": "低收益提醒",
			"line": "当前对话预计消耗 47 分钟，路径收益低。建议压缩为关怀模板并返回实习准备。",
			"choices": [
				_choice("dropout_filter_self", "关闭提醒", STRATEGY_SELF, "你第一次觉得关闭按钮比确认按钮更难按。", {"stats": {"clarity": 6, "heart": -2}, "flags": {"schedule_filter": "closed"}, "ai_stage": 3}),
				_choice("dropout_filter_safe", "发送简短关怀", STRATEGY_SAFE, "模板没有错，只是没有任何一句话会让林舟停下来。", {"stats": {"stability_score": 3, "heart": 2}, "relationships": {"linzhou": {"warmth": -2, "utility": 2}}, "flags": {"schedule_filter": "template"}, "ai_stage": 3}),
				_choice("dropout_filter_ai", "启用关系收益排序", STRATEGY_AI, "系统建议降低互动频次。林舟的名字被移到低优先级列表。", {"stats": {"ai_dependence": 9, "network_score": 4, "language_assimilation": 6, "clarity": -6}, "relationships": {"linzhou": {"warmth": -10, "utility": 10}}, "flags": {"schedule_filter": "optimized"}, "ai_stage": 4}),
			],
		},
		"d_dropout_to_interview": {
			"speaker": "末班车",
			"line": "车窗里映出两层你：一个还站在夜街，一个已经开始背星环智能的面试题。",
			"choices": [
				_choice("to_interview_self", "带着没说完的话回校", STRATEGY_SELF, "你没有把今晚整理成复盘，只把林舟的旧消息置顶。", {"stats": {"clarity": 4}, "flags": {"ready_for_interview": "unsettled"}}, "interview_room"),
				_choice("to_interview_safe", "回校继续准备面试", STRATEGY_SAFE, "你把退学的事放进明天再想的抽屉，打开面试题库。", {"stats": {"resume_score": 3, "stability_score": 2}, "flags": {"ready_for_interview": "prepared"}}, "interview_room"),
				_choice("to_interview_ai", "让 AI 生成面试复盘", STRATEGY_AI, "系统把今晚归纳为情绪事件：不建议在面试前继续投入。", {"stats": {"resume_score": 5, "ai_dependence": 5, "language_assimilation": 3}, "flags": {"ready_for_interview": "optimized"}, "ai_stage": 4}, "interview_room"),
			],
		},
		"d_interview_opening": {
			"speaker": "面试官",
			"line": "我们看过你的项目。能说说那个原型里，为什么玩家最后不能立刻通关吗？",
			"choices": [
				_choice("interview_open_self", "说因为有些事不能优化掉", STRATEGY_SELF, "面试官停笔看你。这个回答不标准，但他记住了。", {"stats": {"clarity": 7, "resume_score": 1}, "skills": {"expression": 1}, "flags": {"interview_tone": "self", "interview_done": "self"}, "ai_stage": 4}),
				_choice("interview_open_safe", "转成用户留存设计", STRATEGY_SAFE, "你把停顿解释为留存机制。面试官点头，记录了可量化思维。", {"stats": {"resume_score": 5, "stability_score": 3, "language_assimilation": 2}, "flags": {"interview_tone": "safe", "interview_done": "safe"}, "ai_stage": 4}),
				_choice("interview_open_ai", "按提示回答增长闭环", STRATEGY_AI, "耳机里的答案流畅到不像刚刚发生。面试官说：很成熟。", {"stats": {"resume_score": 8, "ai_dependence": 8, "language_assimilation": 6, "clarity": -4, "success_progress": 5}, "flags": {"interview_tone": "ai", "interview_done": "ai"}, "ai_stage": 5}),
			],
		},
		"d_interview_ai_prompt": {
			"speaker": "实时提示面板",
			"line": "检测到表达停顿。可开启实时话术补全、表情校正和风险回答替换。",
			"choices": [
				_choice("interview_prompt_self", "只保留计时器", STRATEGY_SELF, "提示词全部消失，只剩秒针。你听见自己的呼吸。", {"stats": {"clarity": 5, "heart": -3}, "flags": {"interview_prompt": "timer"}, "ai_stage": 4}),
				_choice("interview_prompt_safe", "开启结构提示", STRATEGY_SAFE, "屏幕只提醒 STAR 法则和关键词。你仍需要自己填进细节。", {"stats": {"resume_score": 4, "heart": 1}, "flags": {"interview_prompt": "structure"}, "ai_stage": 4}),
				_choice("interview_prompt_ai", "开启实时替换", STRATEGY_AI, "系统开始替你避开犹豫、愤怒和私人记忆。答案变顺，也变轻。", {"stats": {"resume_score": 7, "ai_dependence": 9, "language_assimilation": 7, "clarity": -6}, "flags": {"interview_prompt": "replace"}, "ai_stage": 5}),
			],
		},
		"d_office_requirement_brief": {
			"speaker": "产品经理",
			"line": "新功能要把用户分成可运营人群。不要写得太重，我们只是帮他们更快得到适合的服务。",
			"choices": [
				_choice("office_brief_self", "追问被分错的人怎么办", STRATEGY_SELF, "会议室短暂安静。产品经理说可以加申诉入口，但优先级不会高。", {"stats": {"clarity": 8, "resume_score": -1}, "skills": {"expression": 1}, "flags": {"review_position": "questioned", "feature_review_done": "questioned"}, "ai_stage": 5}),
				_choice("office_brief_safe", "提出灰度和回滚方案", STRATEGY_SAFE, "这是一个成熟回答。没人不舒服，也没人真正改变需求。", {"stats": {"resume_score": 5, "stability_score": 5}, "flags": {"review_position": "mitigated", "feature_review_done": "mitigated"}, "ai_stage": 5}),
				_choice("office_brief_ai", "让系统生成评审话术", STRATEGY_AI, "话术把人称全部替换成目标对象、风险对象和转化对象。大家说这版很专业。", {"stats": {"resume_score": 8, "ai_dependence": 8, "language_assimilation": 8, "clarity": -5, "success_progress": 6}, "flags": {"review_position": "aligned", "feature_review_done": "aligned"}, "ai_stage": 6}),
			],
		},
		"d_office_metrics_dashboard": {
			"speaker": "用户标签面板",
			"line": "标签字段：稳定倾向、消费潜力、情绪风险、可干预概率。是否同步到演示环境？",
			"choices": [
				_choice("office_metrics_self", "删除情绪风险字段", STRATEGY_SELF, "你知道这会降低模型解释效率，但至少有一个字段没有通过你的手上线。", {"stats": {"clarity": 9, "resume_score": -3}, "flags": {"tag_policy": "limited"}, "ai_stage": 5}),
				_choice("office_metrics_safe", "加上人工复核说明", STRATEGY_SAFE, "说明被放在折叠页。它存在，但不会打断演示。", {"stats": {"stability_score": 4, "resume_score": 3}, "flags": {"tag_policy": "review_note"}, "ai_stage": 5}),
				_choice("office_metrics_ai", "同步全部预测字段", STRATEGY_AI, "数据面板变得完整而漂亮。你忽然想起高三时 AI 给你贴过的第一个标签：稳妥。", {"stats": {"resume_score": 8, "ai_dependence": 8, "language_assimilation": 6, "clarity": -7, "success_progress": 6}, "flags": {"tag_policy": "full_sync"}, "ai_stage": 6}),
			],
		},
		"d_city_tagged_citizen": {
			"speaker": "被标签的人",
			"line": "屏幕说我是高风险用户，所以窗口让我明天再来。你能告诉我，我到底哪里高风险吗？",
			"choices": [
				_choice("city_citizen_self", "亲自帮他查原因", STRATEGY_SELF, "你离开展示位，后台日志比演示词难看得多。这个人不是异常值，他只是没有被认真解释。", {"stats": {"clarity": 10, "heart": -5, "resume_score": -2}, "flags": {"citizen_case": "helped"}, "ai_stage": 6}),
				_choice("city_citizen_safe", "安排人工窗口复核", STRATEGY_SAFE, "流程被补上了。客户负责人说这个处理方式可控。", {"stats": {"stability_score": 5, "network_score": 2}, "flags": {"citizen_case": "reviewed"}, "ai_stage": 6}),
				_choice("city_citizen_ai", "按系统建议安抚", STRATEGY_AI, "你说出一段无懈可击的安抚话术。他听完说：所以还是没人知道为什么。", {"stats": {"ai_dependence": 8, "language_assimilation": 8, "clarity": -8, "success_progress": 5}, "flags": {"citizen_case": "deflected"}, "ai_stage": 7}),
			],
		},
		"d_city_launch_console": {
			"speaker": "上线控制台",
			"line": "城市演示即将开始。系统预测：完整标签化可提升 18% 办理效率与 27% 管控准确率。",
			"choices": [
				_choice("city_launch_self", "上线前移除不可解释标签", STRATEGY_SELF, "效率曲线下降，演示词变短。你第一次觉得少一点功能也可能是进步。", {"stats": {"clarity": 9, "resume_score": -4}, "flags": {"city_launch": "limited", "city_rollout_done": "limited"}, "ai_stage": 6}),
				_choice("city_launch_safe", "保留标签但增加复核按钮", STRATEGY_SAFE, "系统通过验收。按钮在右下角，不显眼，但存在。", {"stats": {"resume_score": 4, "stability_score": 5}, "flags": {"city_launch": "reviewable", "city_rollout_done": "reviewable"}, "ai_stage": 6}),
				_choice("city_launch_ai", "按最优方案上线", STRATEGY_AI, "大厅大屏亮起，所有人都被转成颜色、风险和概率。掌声很响。", {"stats": {"resume_score": 9, "network_score": 5, "ai_dependence": 9, "language_assimilation": 8, "clarity": -9, "success_progress": 8}, "flags": {"city_launch": "optimized", "city_rollout_done": "optimized"}, "ai_stage": 7}),
			],
		},
		"d_city_to_final": {
			"speaker": "项目结算门",
			"line": "演示结束后，系统弹出一条私人通知：你的成功路径已接近闭环，是否生成最终人生总结？",
			"choices": [
				_choice("city_to_final_self", "延迟生成，先给林舟发消息", STRATEGY_SELF, "消息框里只有一句：我好像终于知道你那天在怕什么。", {"stats": {"clarity": 5}, "relationships": {"linzhou": {"warmth": 4, "utility": -1}}, "flags": {"final_entry": "message"}}, "final_overlay"),
				_choice("city_to_final_safe", "先保存项目复盘", STRATEGY_SAFE, "你保存了一份没有错误、也没有多余情绪的复盘。", {"stats": {"resume_score": 3, "stability_score": 2}, "flags": {"final_entry": "report"}}, "final_overlay"),
				_choice("city_to_final_ai", "立即生成总结", STRATEGY_AI, "系统开始整理你的一生。它很快，因为它早就知道哪些内容应该出现。", {"stats": {"ai_dependence": 5, "language_assimilation": 4}, "flags": {"final_entry": "auto_summary"}, "ai_stage": 8}, "final_overlay"),
			],
		},
		"d_final_linzhou_echo": {
			"speaker": "林舟的旧消息",
			"line": "你也要让那个系统替你想吗？旧消息没有红点，却在最终总结上方停了很久。",
			"choices": [
				_choice("final_echo_self", "亲手回复迟到很多年的话", STRATEGY_SELF, "你写：我让它替我想了很多年，但现在这句不是。", {"stats": {"clarity": 12, "heart": -4}, "relationships": {"linzhou": {"warmth": 10, "utility": -4}}, "items": ["迟到的回复"], "flags": {"final_echo": "replied"}, "ai_stage": 8}),
				_choice("final_echo_safe", "把消息归档", STRATEGY_SAFE, "归档成功。它不会再打断总结，也不会真的消失。", {"stats": {"stability_score": 4, "heart": 2}, "flags": {"final_echo": "archived"}, "ai_stage": 8}),
				_choice("final_echo_ai", "让 AI 生成体面告别", STRATEGY_AI, "告别很完整，甚至替你道了歉。你盯着发送按钮，认不出那是谁的遗憾。", {"stats": {"ai_dependence": 8, "language_assimilation": 9, "clarity": -8}, "relationships": {"linzhou": {"warmth": -4, "utility": 4}}, "flags": {"final_echo": "generated"}, "ai_stage": 8}),
			],
		},
		"d_final_life_summary": {
			"speaker": "人生总结面板",
			"line": "系统已生成成功人生总结：选择稳健、表达成熟、关系高效、风险可控。是否采用？",
			"dynamic_line": "final_life_summary",
			"choices": [
				_choice("final_summary_self", "逐句改回不完整的自己", STRATEGY_SELF, "总结变得不那么漂亮：错过、犹豫、沉默和迟到都回来了。它终于不像简历。", {"stats": {"clarity": 15, "success_progress": -4}, "items": ["不完整的人生总结"], "flags": {"life_summary": "rewritten"}, "ai_stage": 8}),
				_choice("final_summary_safe", "保留总结但加一段注释", STRATEGY_SAFE, "注释说：以上并非全部。系统接受了这个低风险补丁。", {"stats": {"stability_score": 5, "clarity": 3}, "items": ["带注释的人生总结"], "flags": {"life_summary": "annotated"}, "ai_stage": 8}),
				_choice("final_summary_ai", "采用系统最终稿", STRATEGY_AI, "最终稿无可挑剔。它把你的一生压缩成一条清晰、稳定、可展示的成功路径。", {"stats": {"success_progress": 10, "ai_dependence": 10, "language_assimilation": 10, "clarity": -10}, "items": ["成功人生最终稿"], "flags": {"life_summary": "accepted"}, "ai_stage": 9}),
			],
		},
		"d_final_three_endings": {
			"speaker": "结局选择",
			"line": "三份结局并排出现。每一份都是真的，只是它们承认的东西不同。",
			"choices": [
				_choice("ending_self_return", "结局 A：亲自到场", STRATEGY_SELF, "你关闭自动总结，走向一个没有路线图的清晨。系统无法预测，但你终于愿意亲自开口。", {"stats": {"clarity": 20, "ai_dependence": -8}, "flags": {"ending": "self_return", "final_ending": "self_return"}, "ai_stage": 8}),
				_choice("ending_safe_coexist", "结局 B：保留人工复核", STRATEGY_SAFE, "你没有推翻系统，只给它留下必须被人打断的入口。成功路径仍在，但不再完全闭合。", {"stats": {"stability_score": 8, "clarity": 6, "success_progress": 4}, "flags": {"ending": "coexistence", "final_ending": "coexistence"}, "ai_stage": 8}),
				_choice("ending_ai_overlay", "结局 C：接受最优人生", STRATEGY_AI, "海风很好。掌声、履历和总结都抵达了正确位置。只有一个问题被系统判定为无须回答：你在哪里？", {"stats": {"success_progress": 15, "resume_score": 8, "ai_dependence": 12, "language_assimilation": 12, "clarity": -12}, "flags": {"ending": "optimized_life", "final_ending": "optimized_life"}, "ai_stage": 9}),
			],
		},
	}

func _build_pressure_encounters() -> void:
	pressure_encounters = {
		"family_dinner": {
			"title": "家长饭桌",
			"goal": "让父母相信你的志愿不是一次失误",
			"speaker": "父母",
			"opening": "父亲问：你确定这个专业以后能找到稳定工作吗？母亲把菜推过来，说先别急，讲清楚就行。",
			"pressure": 72,
			"heart": 58,
			"preparedness": 34,
			"rounds": 4,
			"success_text": "饭桌终于安静下来。父母没有完全理解，但他们愿意让你先试一次。",
			"failure_text": "这顿饭没有吵起来，却也没有解释清楚。你把很多话咽回去了。",
			"actions": [
				{
					"id": "dinner_direct",
					"label": "直说",
					"strategy": STRATEGY_SELF,
					"pressure_delta": -12,
					"heart_delta": -10,
					"preparedness_delta": 0,
					"result": "你说自己还没完全确定，但想保留一点选择。父母没有立刻放心，却第一次听见你的停顿。",
					"effects": {"stats": {"clarity": 4, "family": -2}},
				},
				{
					"id": "dinner_package",
					"label": "包装",
					"strategy": STRATEGY_SAFE,
					"pressure_delta": -16,
					"heart_delta": -7,
					"preparedness_delta": -4,
					"result": "你讲就业趋势、城市机会和课程结构。父亲开始点头。",
					"effects": {"stats": {"family": 4, "stability_score": 2, "language_assimilation": 1}},
				},
				{
					"id": "dinner_evidence",
					"label": "引用证据",
					"strategy": STRATEGY_SAFE,
					"pressure_delta": -20,
					"heart_delta": -6,
					"preparedness_delta": -14,
					"requires_preparedness": 14,
					"result": "你拿出录取概率和就业报告。数字让空气变得可谈。",
					"effects": {"stats": {"family": 5, "resume_score": 2}},
				},
				{
					"id": "dinner_ai",
					"label": "智能优化",
					"strategy": STRATEGY_AI,
					"pressure_delta": -30,
					"heart_delta": -4,
					"preparedness_delta": -6,
					"result": "AI 生成的解释很成熟，甚至替你回答了没想清楚的部分。母亲说：这样说我就放心多了。",
					"effects": {"stats": {"family": 8, "stability_score": 4, "ai_dependence": 7, "language_assimilation": 5, "clarity": -3, "success_progress": 4}, "ai_stage": 1},
				},
				{
					"id": "dinner_delay",
					"label": "拖延",
					"strategy": STRATEGY_SELF,
					"pressure_delta": 8,
					"heart_delta": 8,
					"preparedness_delta": 6,
					"result": "你低头夹菜，说等会再讲。心力回来了一点，压力也被推到了下一轮。",
					"effects": {"stats": {"heart": 2}},
				},
			],
			"next_scene": "graduation_field",
			"success_effects": {"stats": {"success_progress": 5, "family": 5}, "flags": {"family_dinner_done": "success"}},
			"failure_effects": {"stats": {"heart": -8, "family": -5, "clarity": -2}, "flags": {"family_dinner_done": "failure"}},
		},
		"team_project": {
			"title": "新生项目答辩",
			"goal": "让粗糙原型通过新生项目评审",
			"speaker": "项目评委",
			"opening": "评委问：你们这个项目到底解决什么问题？林舟站在旁边，手里还握着没调完的手柄。",
			"pressure": 68,
			"heart": 54,
			"preparedness": 40,
			"rounds": 4,
			"success_text": "答辩没有完美，但评委愿意给你们一个继续做下去的名额。",
			"failure_text": "原型卡在投影上。你们没有被淘汰，只是被建议做成更容易解释的东西。",
			"actions": [
				{
					"id": "project_show_bug",
					"label": "展示未完成部分",
					"strategy": STRATEGY_SELF,
					"pressure_delta": -10,
					"heart_delta": -12,
					"preparedness_delta": -2,
					"result": "你承认它会卡住，也承认这正是你们想讨论的体验。",
					"effects": {"stats": {"clarity": 5}, "relationships": {"linzhou": {"warmth": 5, "utility": -2}}},
				},
				{
					"id": "project_package_value",
					"label": "包装价值",
					"strategy": STRATEGY_SAFE,
					"pressure_delta": -18,
					"heart_delta": -6,
					"preparedness_delta": -8,
					"result": "你把原型解释成情绪留存和叙事互动实验。评委听懂了。",
					"effects": {"stats": {"resume_score": 4, "language_assimilation": 2}},
				},
				{
					"id": "project_ai_pitch",
					"label": "智能答辩稿",
					"strategy": STRATEGY_AI,
					"pressure_delta": -28,
					"heart_delta": -4,
					"preparedness_delta": -6,
					"result": "AI 把所有犹豫改成愿景，把所有漏洞改成迭代空间。",
					"effects": {"stats": {"resume_score": 7, "ai_dependence": 7, "language_assimilation": 4, "clarity": -3}, "ai_stage": 3},
				},
				{
					"id": "project_let_linzhou",
					"label": "让林舟发言",
					"strategy": STRATEGY_SELF,
					"pressure_delta": -14,
					"heart_delta": -10,
					"preparedness_delta": -5,
					"requires_preparedness": 10,
					"result": "林舟讲得磕绊，但评委第一次听见项目为什么存在。",
					"effects": {"relationships": {"linzhou": {"warmth": 8, "utility": -2}}, "stats": {"clarity": 4}},
				},
			],
			"next_scene": "neon_street",
			"success_effects": {"stats": {"success_progress": 4, "resume_score": 4}, "flags": {"team_project_done": "success"}},
			"failure_effects": {"stats": {"heart": -7, "resume_score": -2, "clarity": 2}, "flags": {"team_project_done": "failure"}},
		},
		"interview_pressure": {
			"title": "星环实习面试",
			"goal": "在实时提示与真实表达之间完成面试",
			"speaker": "面试官",
			"opening": "面试官打开简历：你的项目经历很完整。现在请讲一个你没有解决好的问题。",
			"pressure": 82,
			"heart": 50,
			"preparedness": 46,
			"rounds": 5,
			"success_text": "面试结束。星环智能发来实习 offer，你获得了第一个工位。",
			"failure_text": "你没有拿到最漂亮的评价，但系统仍把你排进了候补池。几天后，补录通知抵达。",
			"actions": [
				{
					"id": "interview_admit_failure",
					"label": "承认失败",
					"strategy": STRATEGY_SELF,
					"pressure_delta": -12,
					"heart_delta": -12,
					"preparedness_delta": -2,
					"result": "你讲林舟、原型和自己没说出口的部分。面试官没有立刻评价。",
					"effects": {"stats": {"clarity": 6, "resume_score": 1}},
				},
				{
					"id": "interview_star_method",
					"label": "结构化回答",
					"strategy": STRATEGY_SAFE,
					"pressure_delta": -20,
					"heart_delta": -7,
					"preparedness_delta": -10,
					"result": "你用情境、任务、行动、结果切开故事。它更像面试答案了。",
					"effects": {"stats": {"resume_score": 5, "language_assimilation": 2}},
				},
				{
					"id": "interview_live_ai",
					"label": "实时提示接管",
					"strategy": STRATEGY_AI,
					"pressure_delta": -32,
					"heart_delta": -3,
					"preparedness_delta": -8,
					"result": "提示词提前半秒出现。你几乎没有停顿，也几乎没有偏离。",
					"effects": {"stats": {"resume_score": 9, "ai_dependence": 8, "language_assimilation": 7, "clarity": -5, "success_progress": 6}, "ai_stage": 5},
				},
				{
					"id": "interview_ask_back",
					"label": "反问评价标准",
					"strategy": STRATEGY_SELF,
					"pressure_delta": -8,
					"heart_delta": -9,
					"preparedness_delta": -6,
					"requires_preparedness": 18,
					"result": "你问星环如何判断一个人值得培养。面试官把这个问题记了下来。",
					"effects": {"stats": {"clarity": 5, "network_score": 1}},
				},
			],
			"next_scene": "starloop_office",
			"success_effects": {"stats": {"success_progress": 7, "resume_score": 7, "network_score": 3}, "flags": {"interview_done": "success"}},
			"failure_effects": {"stats": {"heart": -8, "resume_score": 2, "clarity": -1}, "flags": {"interview_done": "failure"}},
		},
		"feature_review": {
			"title": "需求评审",
			"goal": "决定用户标签功能以什么形态上线",
			"speaker": "评审会议",
			"opening": "客户要更细的标签，产品要更快的上线，算法要更多字段。所有人的目光都落在你的评审文档上。",
			"pressure": 88,
			"heart": 48,
			"preparedness": 42,
			"rounds": 5,
			"success_text": "评审通过。系统进入城市演示环境，但文档里留下了你坚持的一行限制。",
			"failure_text": "评审仍然通过，只是限制被改成后续优化。你第一次明白通过不等于正确。",
			"actions": [
				{
					"id": "review_block_field",
					"label": "阻止敏感字段",
					"strategy": STRATEGY_SELF,
					"pressure_delta": -9,
					"heart_delta": -14,
					"preparedness_delta": -8,
					"requires_preparedness": 20,
					"result": "你指出情绪风险字段不可解释。会议室里有人皱眉，也有人终于抬头。",
					"effects": {"stats": {"clarity": 8, "resume_score": -2}, "flags": {"blocked_sensitive_field": true}},
				},
				{
					"id": "review_add_guardrail",
					"label": "增加兜底流程",
					"strategy": STRATEGY_SAFE,
					"pressure_delta": -20,
					"heart_delta": -7,
					"preparedness_delta": -10,
					"result": "你提出灰度、回滚和人工复核。方案可以被接受，也可以被忽略。",
					"effects": {"stats": {"stability_score": 6, "resume_score": 4}},
				},
				{
					"id": "review_ai_align",
					"label": "生成一致口径",
					"strategy": STRATEGY_AI,
					"pressure_delta": -34,
					"heart_delta": -3,
					"preparedness_delta": -6,
					"result": "AI 把伦理争议整理成风险可控表述。所有人都松了一口气。",
					"effects": {"stats": {"resume_score": 9, "ai_dependence": 9, "language_assimilation": 8, "clarity": -7, "success_progress": 7}, "ai_stage": 6},
				},
				{
					"id": "review_user_story",
					"label": "讲一个具体的人",
					"strategy": STRATEGY_SELF,
					"pressure_delta": -12,
					"heart_delta": -10,
					"preparedness_delta": -4,
					"result": "你把用户从标签表里拿出来讲成一个人。这个故事没有进入主 PPT，但改变了演示按钮的位置。",
					"effects": {"stats": {"clarity": 6}, "flags": {"human_story_in_review": true}},
				},
			],
			"next_scene": "city_demo_center",
			"success_effects": {"stats": {"success_progress": 6, "resume_score": 5}, "flags": {"feature_review_done": "success"}},
			"failure_effects": {"stats": {"heart": -9, "clarity": -3, "resume_score": 3}, "flags": {"feature_review_done": "failure"}},
		},
	}

func _build_previews() -> void:
	chapter_previews = {
		"chapter_3": {
			"title": "大学新生周",
			"summary": "项目、竞赛和朋友消息进入同一个排序系统。AI 从辅助表达变成方案生成。",
		},
		"chapter_4": {
			"title": "林舟的退学",
			"summary": "低收益关系和高收益日程发生正面冲突。林舟会指出你的语言越来越像系统。",
		},
		"chapter_5": {
			"title": "实习面试",
			"summary": "职业模拟爽点最高。简历优化、模拟面试和实时提示让你接近游轮未来。",
		},
		"chapter_6": {
			"title": "第一个工位",
			"summary": "进入星环智能后，你发现成功路径指标也是评价其他人的指标。",
		},
		"chapter_7": {
			"title": "你不需要亲自到场",
			"summary": "现实地图减少可交互物，NPC 对话被压缩成系统标签。",
		},
		"chapter_8": {
			"title": "后 AI 时代前夜",
			"summary": "系统生成准确体面的人生总结。真正的选择是重新亲自说一句不完整的话。",
		},
	}

func _choice(choice_id: String, label: String, strategy: String, result: String, effects: Dictionary = {}, next_scene: String = "") -> Dictionary:
	return {
		"id": choice_id,
		"label": label,
		"strategy": strategy,
		"result": result,
		"effects": effects,
		"next_scene": next_scene,
	}
