
  基础 UI 组件

  | 组件名 | 用途 | 状态/变体 | 优先级 |
  |---|---|---|---|
  | UIRoot | 所有 UI 总挂载容器 | 普通 / 暂停 / 剧情锁输入 | P0 |
  | PanelFrame | 通用面板底板 | 普通 / 系统风 / 手机风 / 星环风 | P0 |
  | IconButton | 图标按钮 | 默认 / 悬停 / 按下 / 禁用 | P0 |
  | TextButton | 文字按钮 | 默认 / 高亮 / 禁用 / 危险选择 | P0 |
  | ChoiceButton | 对话选择按钮 | 可选 / 已选 / 禁用 / AI 推荐 | P0 |
  | LockOverlay | 禁用条件遮罩 | 心力不足 / 准备不足 / 旗标未满足 | P0 |
  | Tooltip | 鼠标/长按提示 | 简短说明 / 条件说明 | P1 |
  | StatusTag | 标签 | 稳定 / 高收益 / 风险 / 星环认证 | P0 |
  | DeltaToast | 数值变化浮层 | +1 / -1 / 关系变化 / 道具获得 | P0 |
  | ProgressBarMini | 小型进度条 | 心力 / 压力 / 准备度 / 关系 | P0 |
  | SegmentMeter | 分段条 | 3 段 / 5 段 / 10 段 | P1 |
  | PortraitFrame | 头像框 | 普通 / 重要角色 / AI / 系统 | P0 |
  | ItemSlot | 物品格 | 空 / 有物品 / 新获得 / 锁定 | P1 |
  | KeyboardBadge | 按键提示 | E / Q / B / 回车 | P0 |
  | MobileTouchHint | 手机触控提示 | 点击 / 长按 / 拖动 | P1 |

  全局 HUD 组件

  | 组件名 | 用途 | 状态/变体 | 优先级 |
  |---|---|---|---|
  | HUDRoot | 游戏内 HUD 总容器 | 普通 / 对话中 / 压力遭遇中 | P0 |
  | ChapterBadge | 当前章节显示 | Chapter 0-8 | P0 |
  | LocationLabel | 当前地点 | 游轮 / 走廊 / 机房 / 饭桌 / 公司等 | P0 |
  | ObjectiveTracker | 当前目标 | 主目标 / 可选目标 / 已完成 | P0 |
  | HeartMeter | 心力显示 | 鲜红 / 暗红 / 灰红 / 破裂 / 灰黑 | P0 |
  | PressureMeter | 压力显示 | 低 / 中 / 高 / 失控 | P0 |
  | PreparationMeter | 准备度显示 | 不足 / 勉强 / 充分 / 优化过 | P0 |
  | StatChip | 单个数值展示 | 成绩 / 履历 / 稳定度 / 人脉等 | P1 |
  | RelationQuickBar | 主要朋友关系摘要 | 五名朋友头像 + 关系提示 | P1 |
  | ActionButtonCluster | 右下操作按钮组 | 交互 / AI / 背包 | P0 |
  | VirtualJoystick | 左下虚拟摇杆 | 静止 / 拖动 / 禁用 | P0 |
  | InteractionPrompt | 靠近可交互物提示 | NPC / 物件 / 出口 / 系统终端 | P0 |
  | NotificationStack | 提示堆叠容器 | 数值变化 / 道具 / 旗标 / 系统消息 | P0 |
  | AutoSaveIndicator | 自动保存提示 | 保存中 / 已保存 / 失败 | P2 |

  对话与选择组件

  | 组件名 | 用途 | 状态/变体 | 优先级 |
  |---|---|---|---|
  | DialoguePanel | 主对话框 | 普通 / 手机消息 / 系统提示 | P0 |
  | SpeakerNameplate | 说话人姓名条 | 主角 / 朋友 / 家长 / 老师 / AI | P0 |
  | SpeakerPortrait | 对话头像区域 | 左侧 / 右侧 / 无头像 | P0 |
  | DialogueText | 对白文本 | 普通 / 慢速打字 / 强调词 | P0 |
  | ContinueIndicator | 继续提示 | 闪烁 / 隐藏 | P0 |
  | ChoiceList | 选择列表容器 | 2 选 / 3 选 / 多选滚动 | P0 |
  | ChoiceEffectPreview | 选择结果预览 | 显示 / 隐藏 / AI 预测 | P1 |
  | DisabledChoiceReason | 禁用原因说明 | 心力不足 / 道具缺失 / 关系不足 | P0 |
  | DialogueHistoryPanel | 对话历史 | 普通历史 / 关键句标记 | P2 |
  | PhoneChatPanel | 手机聊天界面 | 父母群 / 朋友私聊 / 星环推送 | P1 |
  | PhoneMessageBubble | 单条手机消息 | 自己 / 他人 / 系统 / 未读 | P1 |
  | AIReplyBubble | AI 生成回复气泡 | 推荐 / 自动润色 / 风险提示 | P1 |

  压力遭遇组件

  | 组件名 | 用途 | 状态/变体 | 优先级 |
  |---|---|---|---|
  | PressureEncounterRoot | 压力遭遇总界面 | 饭桌 / 答辩 / 面试 / 评审 | P0 |
  | EncounterTitleBar | 遭遇标题 | 章节名 + 场景名 | P0 |
  | RoundCounter | 回合数 | 第 N 回合 / 最后一回合 | P0 |
  | EncounterHeartMeter | 遭遇中心力 | 复用 HeartMeter | P0 |
  | EncounterPressureGauge | 遭遇中压力 | 上升 / 下降 / 临界 | P0 |
  | EncounterPreparationGauge | 遭遇中准备度 | 不足 / 可行动 / 溢出 | P0 |
  | ActionCard | 单个行动卡 | 普通行动 / 朋友支援 / AI 辅助 | P0 |
  | DisabledActionCard | 禁用行动卡 | 条件不足 + 锁图标 | P0 |
  | AIInterventionCard | AI 辅助行动 | 高收益 / 高代价 / 星环推荐 | P1 |
  | SupportActionCard | 朋友支援行动 | 林舟 / 周骁 / 何启朗 / 沈柚 / 陈望 | P1 |
  | EncounterLog | 遭遇过程日志 | 简短反馈 / 关键转折 | P1 |
  | EncounterResultPanel | 成功/失败结算 | 成功 / 失败 / 勉强通过 | P0 |
  | EncounterRewardRow | 单条结算变化 | 数值 / 关系 / 旗标 / 道具 | P0 |

  系统面板组件

  | 组件名 | 用途 | 状态/变体 | 优先级 |
  |---|---|---|---|
  | SuccessPathPanel | 成功路径面板 | Chapter 0 展示 / 后续对照 | P0 |
  | SuccessMetricCard | 成功指标卡 | 财富 / 履历 / 稳定 / 人脉 / 城市身份 | P0 |
  | ChapterTransitionPanel | 章节转场 | Chapter 标题 / 阶段目标 / 系统建议 | P0 |
  | SettlementPanel | 阶段结算 | 章节结算 / 压力结算 / 结局结算 | P0 |
  | StatChangeRow | 数值变化行 | 增加 / 减少 / 无变化 | P0 |
  | InventoryPanel | 背包面板 | 普通物品 / 纪念物 / 星环物品 | P1 |
  | ItemDetailCard | 物品详情 | 描述 / 来源 / 相关人物 | P1 |
  | RelationshipPanel | 关系面板 | 五名朋友列表 | P1 |
  | CharacterRelationCard | 单人关系卡 | 亲近度 / 工具化程度 / 最近事件 | P1 |
  | ToolificationMeter | 工具化程度 | 低 / 中 / 高 / 警示 | P1 |
  | AIAdvicePanel | AI 建议面板 | 志愿 / 面试 / 工作 / 人生总结 | P0 |
  | RiskRewardRow | 收益风险行 | 收益预测 / 风险提示 / 代价 | P1 |
  | SystemOverlay | 系统覆盖层 | 星环提示 / 人格协同 / 人生总结 | P1 |
  | PauseMenu | 暂停菜单 | 继续 / 设置 / 退出 | P1 |
  | SettingsPanel | 设置界面 | 音量 / 字速 / 触控灵敏度 | P2 |

  人物头像/身份 UI 组件

  | 组件名 | 人物 | 身份变体 | 优先级 |
  |---|---|---|---|
  | PortraitXuLinSuccess | 许临 | Chapter 0 成功科技新贵 | P0 |
  | PortraitXuLinStudent | 许临 | 高中学生 | P0 |
  | PortraitXuLinUniversity | 许临 | 大学新生 / 项目期 | P1 |
  | PortraitXuLinIntern | 许临 | 实习面试者 | P0 |
  | PortraitXuLinEmployee | 许临 | 星环员工 | P1 |
  | PortraitXuLinEnding | 许临 | Chapter 8 空白 / 亲自表达 | P1 |
  | PortraitLinZhouStudent | 林舟 | 高中机房 | P0 |
  | PortraitLinZhouDropout | 林舟 | 退学夜街 | P0 |
  | PortraitLinZhouCreator | 林舟 | 独立游戏创作者 | P1 |
  | PortraitLinZhouOldMessage | 林舟 | 旧消息头像 | P1 |
  | PortraitZhouXiaoRepair | 周骁 | 校门口修手机 | P1 |
  | PortraitZhouXiaoGigWorker | 周骁 | 平台零工 | P1 |
  | PortraitZhouXiaoRiskTagged | 周骁 | 被系统标记风险 | P1 |
  | PortraitHeQilangStudent | 何启朗 | 优秀学生 | P1 |
  | PortraitHeQilangConnector | 何启朗 | 资源型学长 / 内推人 | P1 |
  | PortraitHeQilangCorporate | 何启朗 | 职场成功但僵硬 | P1 |
  | PortraitShenYouStudent | 沈柚 | 留言墙 / 高中时期 | P1 |
  | PortraitShenYouIdealist | 沈柚 | 教育理想阶段 | P1 |
  | PortraitShenYouSystemWorker | 沈柚 | 被流程吸收 | P1 |
  | PortraitChenWangStudent | 陈望 | 高中普通同学 | P1 |
  | PortraitChenWangFamilyCall | 陈望 | 家庭责任状态 | P1 |
  | PortraitChenWangStableWorker | 陈望 | 稳定工作状态 | P1 |
  | PortraitParentsDinner | 父母 | 饭桌压力 | P0 |
  | PortraitTeacher | 班主任 | 志愿推荐 / 走廊对话 | P0 |
  | PortraitHR | 星环 HR | 面试 / 招聘系统 | P1 |
  | PortraitManager | 主管 | 需求评审 / 绩效反馈 | P1 |
  | PortraitAI | 星环 AI | 无人脸系统头像 / 圆环 / 终端 | P0 |

  章节专属组件

  | 组件名 | 章节 | 用途 | 优先级 |
  |---|---|---|---|
  | LifeReplayButton | Ch0 | 人生回放入口 | P0 |
  | CruiseAchievementCard | Ch0 | 工牌、期权、晚宴、住所等成功信息 | P0 |
  | GuestListCard | Ch0 | 酒会名单 | P1 |
  | VolunteerRecommendationPanel | Ch1 | AI 志愿推荐 | P0 |
  | MajorChoiceCard | Ch1 | 专业/城市/学校推荐项 | P0 |
  | ParentDinnerTopicCard | Ch1 | 饭桌压力话题卡 | P0 |
  | GraduationMessageWall | Ch2 | 毕业留言墙 | P1 |
  | FriendTimeAllocator | Ch2 | 朋友时间分配 | P1 |
  | GraduationPhotoFrame | Ch2 | 毕业照结算 | P1 |
  | ProjectTeamBoard | Ch3 | 新生项目分组 | P1 |
  | DefenseScoreSheet | Ch3 | 项目答辩评分 | P1 |
  | LowYieldWarning | Ch4 | 低收益关系提醒 | P1 |
  | OldChatThread | Ch4/Ch8 | 旧消息回声 | P1 |
  | ResumePanel | Ch5 | 简历展示 | P0 |
  | CareerProfileRadar | Ch5 | 星环职业画像 | P1 |
  | InterviewQuestionCard | Ch5 | 面试题卡 | P0 |
  | StructuredScorePanel | Ch5 | 结构化评分 | P0 |
  | WorkTaskBoard | Ch6 | 工位任务板 | P1 |
  | RequirementReviewPanel | Ch6 | 需求评审界面 | P0 |
  | PerformanceLanguageHint | Ch6 | 绩效语言提示 | P1 |
  | CitizenCaseCard | Ch7 | 市民案例标签卡 | P1 |
  | PersonaSyncPanel | Ch7 | 人格协同系统 | P1 |
  | LifeSummaryOverlay | Ch8 | 人生总结覆盖层 | P0 |
  | MemoryEchoCard | Ch8 | 旧记忆/旧消息浮现 | P1 |
  | ManualSpeechInput | Ch8 | 亲自表达输入/选择 | P1 |
  | EndingChoicePanel | Ch8 | 三种结局选择 | P0 |

  心力组件拆分

  HeartMeter 建议拆成 5 个子组件：

  | 子组件 | 作用 |
  |---|---|
  | HeartIconBase | 心形主体 |
  | HeartFillLayer | 根据心力填充颜色 |
  | HeartCrackOverlay | 低心力时裂纹 |
  | HeartPulseAnimation | 高心力轻微跳动，低心力闪烁 |
  | HeartValueTooltip | 显示具体心力值和影响 |

  心力视觉状态：

  | 心力 | 颜色 | 表现 |
  |---|---|---|
  | 80-100 | 鲜红 | 饱满，轻微跳动 |
  | 60-79 | 红色 | 正常 |
  | 40-59 | 暗红 | 跳动变慢 |
  | 20-39 | 灰红 | 出现裂纹 |
  | 0-19 | 灰黑 | 闪烁，部分行动禁用 |