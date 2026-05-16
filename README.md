# 毕业前夜无人回答 - Godot 纵切原型

这是一个 Godot 4.x 横屏 16:9 原型，实现 Chapter 0-8 的可走通 demo。当前版本使用程序化占位美术和数据驱动纵切：场景、对话、选择效果与压力遭遇由数据表驱动，视觉资产用于验证流程、节奏和交互闭环。

- Chapter 0：游轮成功未来、成功路径面板、人生回放入口。
- Chapter 1：高三走廊、AI 志愿系统、家长饭桌压力遭遇。
- Chapter 2：毕业典礼、毕业留言、朋友时间分配、阶段结算。
- Chapter 3：大学新生周、新生项目分组、项目答辩压力遭遇。
- Chapter 4：林舟退学夜街、低收益关系提醒、回校准备。
- Chapter 5：星环智能实习面试、实时提示、结构化面试压力遭遇。
- Chapter 6：第一个工位、需求评审、功能评审压力遭遇。
- Chapter 7：城市演示中心、标签化市民案例、上线结算。
- Chapter 8：人生总结覆盖层、旧消息回声、三种结局选择。

## 运行

1. 用 Godot 4.x 打开当前目录。
2. 运行 `res://scenes/Main.tscn`。

## 美术拆分试点

- 第一张示例图 `docs/demo/storyline-ui-demos/ch00_cruise_success.png` 已拆为独立试点资源，位于 `assets/storyline/ch00_cruise_success/`。
- 可单独运行 `res://scenes/art/ArtSplitCruiseDemo.tscn` 查看拆分效果。
- 试点覆盖三处核心热点：成功面板、星环工牌、香槟庆祝。靠近热点后点击或按 `E` 触发反馈。
- 当前版本采用标准游戏组件生成：邮轮背景、主角、成功终端、星环终端、香槟桌、热点和反馈层分别由 `scripts/art/components/` 下的脚本驱动。
- `meta/split_manifest.json` 现在主要声明 `component`、`variant`、坐标和交互语义；旧 PNG 切图保留为参考/fallback，不再驱动当前试点画面。

## 可玩验收

- 从邮轮甲板点击“人生回放”，选择“人生回放”后进入高三走廊。
- 在走廊可查看志愿填报栏、林舟、班主任和 AI 建议，其中志愿填报栏或 AI 建议可进入机房。
- 在机房完成 AI 志愿系统后，从出口回家吃饭，触发家长饭桌压力遭遇。
- 压力遭遇会按准备度禁用未满足条件的行动，并根据压力、心力和回合数结算成功或失败。
- 饭桌结算后进入毕业操场，可完成毕业留言、朋友时间和毕业照阶段结算，并继续进入 Chapter 3-8 主线节点。
- Chapter 3-8 以同一套数据驱动结构串联：关键对话写入主线旗标，新增压力遭遇覆盖成功和失败分支。
- 对话选择会写入数值、关系、道具、旗标、选择历史和反馈日志，HUD 会随状态刷新。

## 自动化测试

可在仓库根目录运行：

```bash
HOME=/tmp /tmp/godot-4.2.2/Godot_v4.2.2-stable_linux.x86_64 --headless --path . -s res://tests/smoke_test.gd
HOME=/tmp /tmp/godot-4.2.2/Godot_v4.2.2-stable_linux.x86_64 --headless --path . -s res://tests/flow_test.gd
HOME=/tmp /tmp/godot-4.2.2/Godot_v4.2.2-stable_linux.x86_64 --headless --path . -s res://tests/playable_demo_test.gd
```

`playable_demo_test.gd` 覆盖 Chapter 0-8 主线可达性、所有 scene/dialogue/pressure 引用完整性、Chapter 3-8 关键旗标写入、门控行为、压力遭遇成功/失败分支，以及对话效果落库。

当前环境下建议带 `HOME=/tmp` 运行 headless 测试，避免 Godot 写 `user://logs` 时受本机用户目录限制影响。

## 操作

- 移动：左下虚拟摇杆，或键盘 `WASD` / 方向键。
- 交互：右下 `交互` 按钮，或键盘 `E` / 回车。
- AI：右下 `AI` 按钮，或键盘 `Q`。
- 背包：右下 `背包` 按钮，或键盘 `B`。

## 架构

- `scripts/autoload/game_state.gd`：全局章节、数值、关系、背包、选择记录。
- `scripts/data/chapter_data.gd`：章节、场景、对话、选择效果和压力遭遇数据。
- `scripts/gameplay/world_scene.gd`：按数据生成横向场景、NPC、交互点和主角。
- `scripts/ui/`：HUD、虚拟摇杆、对话面板、压力遭遇界面。
