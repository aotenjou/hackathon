# 横屏摇杆 UI Demo 图集

生成方式：内置 `image_gen`，多 worker 并行生成  
画面规格：横屏手机游戏界面 demo，PNG，约 16:9  
统一风格：粗颗粒 2D 像素、横向卷轴可操控场景、左下摇杆、右下操作按钮、顶部目标栏、底部状态条、轻赛博朋克基础设施

## 统一提示词骨架

所有图片均基于同一套提示词规范生成：

- 16:9 horizontal mobile game UI screenshot.
- Chunky 2D pixel art, coarse visible pixels, thick outlines.
- Playable side-scrolling RPG scene, not a static visual-novel panel.
- Top HUD with location, objective, time.
- Bottom-left translucent virtual joystick.
- Bottom-right action buttons: `交互`, `AI`, `背包` or equivalent.
- Bottom status strip with short Chinese metrics.
- In-scene interaction markers: yellow `!`, blue AI/Xinghuan marker, white speech marker.
- Grounded Chinese school, university, city, and corporate environments.
- Light cyberpunk appears as AI screens, smart terminals, data walls, platform labels, not weapons or body modification.
- Xinghuan is shown as restrained, institutional, useful, and monopolistic rather than monstrous.
- Avoid portrait layout, 3D render, photorealism, smooth anime, neon overload, guns, cyborgs, hacker battles, evil red AI, watermarks, long text, and random English UI.

## 图片清单

| 文件 | 章节 | 场景用途 |
| --- | --- | --- |
| [ch00_cruise_success.png](ch00_cruise_success.png) | Chapter 0 | 游轮甲板成功未来，展示科技新贵伪目标。 |
| [ch00_life_replay.png](ch00_life_replay.png) | Chapter 0 | 人生回放交互点，进入高三时间线。 |
| [ch01_hallway_volunteer.png](ch01_hallway_volunteer.png) | Chapter 1 | 小城高三走廊，志愿填报与星环 AI 建议。 |
| [ch01_family_dinner.png](ch01_family_dinner.png) | Chapter 1 | 家中饭桌，父母期待与稳妥路线压力。 |
| [ch01_computer_room_linzhu.png](ch01_computer_room_linzhu.png) | Chapter 1 | 机房里的林舟，低收益但具体的表达。 |
| [ch02_graduation_message_wall.png](ch02_graduation_message_wall.png) | Chapter 2 | 毕业留言墙，AI 开始处理真诚表达。 |
| [ch02_last_free_time.png](ch02_last_free_time.png) | Chapter 2 | 毕业前最后自由时间，朋友关系取舍。 |
| [ch02_graduation_photo.png](ch02_graduation_photo.png) | Chapter 2 | 毕业照定格，完美表达与真实记忆分离。 |
| [ch03_club_recruitment.png](ch03_club_recruitment.png) | Chapter 3 | 大学新生周，社团、项目与城市竞争。 |
| [ch03_dorm_schedule_ai.png](ch03_dorm_schedule_ai.png) | Chapter 3 | 宿舍夜晚，AI 规划课程、竞赛和绩点。 |
| [ch03_project_presentation.png](ch03_project_presentation.png) | Chapter 3 | 团队项目答辩，AI 补齐资源差距。 |
| [ch04_bus_stop_linzhu.png](ch04_bus_stop_linzhu.png) | Chapter 4 | 夜间公交站，回应林舟退学决定。 |
| [ch04_internet_cafe_demo.png](ch04_internet_cafe_demo.png) | Chapter 4 | 旧网吧试玩包，低收益关系被自然回避。 |
| [ch04_class_reunion.png](ch04_class_reunion.png) | Chapter 4 | 同学聚会，朋友路径分叉与阶层距离。 |
| [ch05_resume_pipeline.png](ch05_resume_pipeline.png) | Chapter 5 | 简历优化流水线，把自己变成候选人。 |
| [ch05_interview_room.png](ch05_interview_room.png) | Chapter 5 | 线上面试间，AI 实时替代表达。 |
| [ch05_offer_arrival.png](ch05_offer_arrival.png) | Chapter 5 | 星环 offer 到达，前中期最大成功反馈。 |
| [ch06_xinghuan_lobby.png](ch06_xinghuan_lobby.png) | Chapter 6 | 星环总部门厅，大厂工牌与科技新贵奖励。 |
| [ch06_first_workstation.png](ch06_first_workstation.png) | Chapter 6 | 第一个工位，人格协同系统后台显形。 |
| [ch06_review_meeting.png](ch06_review_meeting.png) | Chapter 6 | 需求评审会议，低收益意愿降权功能。 |
| [ch06_friend_samples.png](ch06_friend_samples.png) | Chapter 6 | 模型运营层，朋友被转写为系统样本。 |
| [ch07_school_demo.png](ch07_school_demo.png) | Chapter 7 | 学校合作演示会，高中生问题被系统改写。 |
| [ch07_city_service_labels.png](ch07_city_service_labels.png) | Chapter 7 | 城市服务大厅，现实人物被标签覆盖。 |
| [ch07_linzhu_game_inside.png](ch07_linzhu_game_inside.png) | Chapter 7 | 林舟试玩版，游戏中的毕业前夜系统。 |
| [ch07_release_panel.png](ch07_release_panel.png) | Chapter 7 | 发布面板，上线屏蔽功能与灰度策略。 |
| [ch08_overlap_map.png](ch08_overlap_map.png) | Chapter 8 | 高中、大学、公司、游轮残影重叠地图。 |
| [ch08_life_summary.png](ch08_life_summary.png) | Chapter 8 | 人生总结生成，准确体面但空洞。 |
| [ch08_friend_echoes.png](ch08_friend_echoes.png) | Chapter 8 | 朋友回声物品，把最终选择拉回关系。 |
| [ending_real_feedback.png](ending_real_feedback.png) | Ending | 删除总结，亲自给林舟写不完整反馈。 |

## 质量备注

- 当前图片用于剧情、美术和 UI 气质 demo，不作为最终游戏资产。
- 生图模型可能无法稳定生成完全准确的中文小字；后续进入原型或视觉稿阶段时，建议用前端或图像编辑方式重新叠加精确 UI 文案。
- `ch06_review_meeting.png` 尺寸为 `1671 x 941`，其余当前检查为 `1672 x 941`；都可作为横屏示意图使用。
