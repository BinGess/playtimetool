import 'package:flutter/material.dart';

/// 应用多语言文案
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const _localizedValues = <String, Map<String, String>>{
    'zh': {
      // App
      'appTitle': '指尖聚会',
      'settings': '设置',
      'settingsTitle': 'SETTINGS',
      'appVersion': '指尖聚会 v1.0',
      'resultSummary': '结果说明',
      'penaltyGuideDefault': '按当前规则执行惩罚玩法',
      'penaltyGuideParty': '未命中玩家执行约定惩罚',
      'penaltyGuideWheel': '按抽中的选项执行任务或惩罚',
      'penaltyMethodRandom': '随机惩罚',
      'penaltyMethodScore': '积分结算',
      'penaltyMethodRule': '规则结算',
      'penaltyMethodGuide': '玩法引导',
      'penaltyPresetTitle': '惩罚预设',
      'penaltyPresetHint': '先约好场景和尺度，结算时自动生成 3 张命运卡。',
      'penaltySceneTitle': '场景选择',
      'penaltySceneHome': '居家模式',
      'penaltySceneBar': '酒吧模式',
      'penaltyIntensityTitle': '尺度强度',
      'penaltyIntensityMild': '热身',
      'penaltyIntensityWild': '进阶',
      'penaltyIntensityXtreme': '极限',
      'penaltyBlindBoxTitle': '命运抉择',
      'penaltyBlindBoxLosers': '{players} 接受命运抉择',
      'penaltyBlindBoxHint': '点击一张卡片，翻开本局惩罚',
      'penaltyBlindBoxRevealed': '其余两张会告诉你错过了什么',
      'penaltyCurrentPlayerLabel': '当前玩家',

      // Penalty blind box library
      'blindBoxBarLevel1DeepBomb': '深水炸弹：自选两种饮料/酒类混合，一口闷。',
      'blindBoxBarLevel1CheersMessenger': '碰杯使者：与全场每个人碰杯并说一句“合作愉快”。',
      'blindBoxBarLevel1SongPrivilege': '点歌特权：为赢家点一首最难听的歌，并听完整首。',
      'blindBoxBarLevel1SingleEar': '单边耳环：用左手摸着右耳朵保持 2 分钟。',
      'blindBoxBarLevel2DarkDrink': '特调大师：由赢家调制一杯暗黑饮品，输家喝掉。',
      'blindBoxBarLevel2TruthBody': '真心话：现场选一位异性，评价对方最吸引你的一个部位。',
      'blindBoxBarLevel2ShoutHero': '摇摆时刻：站起来大喊“我是今晚最靓的仔！”。',
      'blindBoxBarLevel2RecentCalls': '交换人生：让左手边朋友查看你的最近通话记录。',
      'blindBoxBarLevel3SinglePost': '微信冒险：朋友圈发布“我单身，有人要带走吗？”，5 分钟后可删除。',
      'blindBoxBarLevel3StrangerTissue': '陌生人任务：去隔壁桌要一张纸巾，并夸赞对方长相。',
      'blindBoxBarLevel3VoiceConfession': '酒后吐真言：给微信置顶的第一个人发语音“其实我一直想告诉你...”。',
      'blindBoxBarLevel3BlindFeed': '盲目跟随：蒙住眼睛，由赢家喂你吃下三样桌上的食物。',
      'blindBoxHomeLevel1BalanceMaster': '平衡大师：单脚站稳，闭上眼睛数 30 秒。',
      'blindBoxHomeLevel1WallSquat': '壁虎漫步：靠墙做 10 个深蹲，不能扶墙。',
      'blindBoxHomeLevel1EmojiCopy': '表情包模仿：模仿热门表情包，由大家打分，不及格重做。',
      'blindBoxHomeLevel1SilentGold': '沉默是金：接下来 3 分钟内禁止说话，违反者惩罚翻倍。',
      'blindBoxHomeLevel2SecretStory': '秘密揭晓：讲述一件从未告诉在场任何人的糗事。',
      'blindBoxHomeLevel2PhotoExplain': '手机黑洞：展示你相册里倒数第 10 张图片，并解释原因。',
      'blindBoxHomeLevel2SiriConfession': '智能助手：对着手机语音助手深情表白 30 秒。',
      'blindBoxHomeLevel2ChoresToday': '家务承包：今天的餐后洗碗/倒垃圾/整理桌面由你承包。',
      'blindBoxHomeLevel3GroupBlast': '群组轰炸：在家亲戚群里发一句“其实我不想结婚/谈恋爱，你们别催了。”',
      'blindBoxHomeLevel3AvatarSwap': '换头大师：把社交软件头像换成赢家的照片，保持 24 小时。',
      'blindBoxHomeLevel3LiveShow': '直播挑战：开启朋友圈直播或群视频，进行 1 分钟无实物表演。',
      'blindBoxHomeLevel3RolePlay': '角色互换：模仿在场某一个人，直到大家猜出来是谁。',
      'blindBoxFallbackQuickSquat': '通用惩罚：立即做 10 个深蹲。',
      'blindBoxFallbackQuickTruth': '通用惩罚：回答一个大家指定的真心话问题。',
      'blindBoxFallbackQuickSong': '通用惩罚：唱 20 秒副歌，直到全场满意。',

      // Hub
      'hubSubtitle': 'PARTY GAMES',
      'fingerPicker': '指尖轮盘',
      'fingerPickerSub': 'FINGER PICKER',
      'fingerPickerDesc': '命运的触碰',
      'fingerPrepTitle': '准备开转',
      'fingerPrepHint': '先确认规则与惩罚设置，再让大家同时按住屏幕等待命运揭晓。',
      'fingerPrepIntroTitle': '游戏基础介绍',
      'fingerPrepIntroHint': '一局流程',
      'fingerPrepIntroBody': '所有玩家同时按住屏幕，系统在倒计时后随机保留指定人数，剩余玩家出局并触发惩罚抽卡。',
      'fingerPrepWinnersTitle': '选中人数设置',
      'fingerPrepWinnersHint': '本轮最终会留下多少种颜色',
      'fingerPrepPenaltyTitle': '惩罚设置',
      'fingerPrepPenaltyHint': '先设定场景和尺度，结果页会自动生成惩罚抽卡。',
      'fingerResultTitle': '游戏结果',
      'fingerResultNoColor': '本轮暂无最终颜色',
      'fingerResultSingleColor': '最后剩下：{color}',
      'fingerResultMultiColors': '最后剩下：{colors}',
      'fingerColorCyan': '青色',
      'fingerColorMagenta': '洋红',
      'fingerColorLime': '荧光绿',
      'fingerColorYellow': '亮黄',
      'fingerColorOrange': '橙色',
      'fingerColorViolet': '紫罗兰',
      'fingerColorPink': '粉色',
      'fingerColorSpringGreen': '春绿色',
      'fingerColorAzure': '天蓝',
      'fingerColorAmber': '琥珀',
      'spinWheel': '自定义转盘',
      'spinWheelSub': 'SPIN WHEEL',
      'spinWheelDesc': '丝滑的物理感',
      'numberBomb': '数字炸弹',
      'numberBombSub': 'NUMBER BOMB',
      'numberBombDesc': '心理压迫感',
      'passBomb': '炸弹传递',
      'passBombSub': 'PASS BOMB',
      'passBombDesc': '倒计时传手机，爆炸者受罚',
      'gestureDuel': '手势对决',
      'gestureDuelSub': 'GESTURE DUEL',
      'gestureDuelDesc': '少数派/多数派受罚模式',
      'leftRight': '幸运左右',
      'leftRightSub': 'LEFT OR RIGHT',
      'leftRightDesc': '指定方向反应，错了就加罚分',
      'wordBomb': '关键词炸弹',
      'wordBombSub': 'WORD BOMB',
      'wordBombDesc': '限时接龙，卡壳即爆炸',
      'challengeAuction': '挑战拍卖',
      'challengeAuctionSub': 'CHALLENGE AUCTION',
      'challengeAuctionDesc': '最低出价者挑战任务',
      'truthRaise': '真话或加码',
      'truthRaiseSub': 'TRUTH OR RAISE',
      'truthRaiseDesc': '跳过会不断加码',
      'bioDetector': '生物检测器',
      'bioDetectorSub': 'BIO-DETECTOR',
      'bioDetectorDesc': '心理欺骗扫描',
      'decibelBomb': '分贝炸弹',
      'decibelBombSub': 'DECIBEL BOMB',
      'decibelBombDesc': '按住说话累积能量，噪声突刺瞬间爆炸',
      'decibelBombPrepTitle': '静音校准前先准备',
      'decibelBombPrepHint': '先说明规则、选好人数和惩罚预设。点击开始后会申请麦克风并进入校准。',
      'decibelBombPrepGuideHint': '按住说话会持续充能，接力瞬间的噪音突刺也会直接引爆。',
      'decibelBombPrepPlayersTitle': '人数选择',
      'decibelBombPrepPlayersHint': '建议 3 到 8 人轮流传手机，当前持有者爆炸就直接受罚。',
      'decibelBombPrepPenaltyTitle': '惩罚预设',
      'decibelBombPrepPenaltyHint': '先约好场景和尺度，爆炸后直接进入命运卡结算。',
      'gravityBalance': '平衡边缘',
      'gravityBalanceSub': 'GRAVITY BALANCE',
      'gravityBalanceDesc': '倾斜控球，顶住摆动与震荡',
      'iapPriceFallback': '¥1',
      'iapPurchaseTitle': '解锁游戏',
      'iapPurchaseBody': '{game} 需要购买后才能游玩，价格 {price}，购买后可长期使用。',
      'iapBuyNow': '立即购买',
      'iapRestore': '恢复购买',
      'iapStoreUnavailable': '商店当前不可用，请稍后重试',
      'iapProductNotFound': '商品暂不可购买，请稍后重试',
      'iapPurchasePending': '正在处理购买结果，请稍候...',
      'iapPurchaseFailed': '发起购买失败，请稍后重试',
      'iapUnlockSuccess': '已解锁：{game}',
      'iapPaywallSwitch': '游戏付费开关',
      'iapPaywallSwitchSub': 'IAP PAYWALL (DEBUG)',

      // Settings
      'sound': '音效',
      'soundSub': 'SOUND',
      'vibration': '震动',
      'vibrationSub': 'VIBRATION',
      'minimalMode': '极简模式',
      'minimalModeSub': 'MINIMAL MODE',
      'alcoholPenalty': '酒精惩罚',
      'alcoholPenaltySub': 'ALCOHOL / PURE MODE',
      'language': '语言',
      'languageSub': 'LANGUAGE',
      'about': '关于',
      'aboutSub': 'ABOUT',
      'privacyPolicy': '隐私协议',
      'contact': '联系方式',
      'langFollowSystem': '跟随系统',
      'langChinese': '中文',
      'langEnglish': 'English',

      // Finger Picker
      'placeFingers': '请放上手指',
      'placeFingersEn': 'PLACE FINGERS TO BEGIN',
      'waitingMore': '等待更多人加入...',
      'locked': '锁定！保持不动...',
      'start': '开  始',
      'someoneEscaped': '有人逃跑了！',
      'escapeHint': '请重新放上所有手指\n重新开始游戏',
      'okRetry': '好的，重来',
      'selectWinners': '选中人数',
      'selectWinnersCount': '选 {count} 人',
      'result': '结果',
      'victor': '胜利者',
      'victors': '胜利者 × {count}',
      'again': '再来一次',
      'add': '＋ 添加',
      'editWheel': '编辑转盘',
      'addOption': '添加选项',
      'editOption': '编辑选项',
      'optionName': '选项名称',
      'color': '颜色',
      'cancel': '取消',
      'confirm': '确定',
      'fateSpinning': '命运转动中...',
      'eliminated': '淘汰 {current} / {total}',
      'reveal': '揭晓胜者...',
      'touchToContinue': '轻触任意位置继续',
      'overflowTitle': '人数超限',
      'overflowHint': '最多支持 6 人参与\n请移开多余手指后重新开始',
      'ok': '好的',
      'fair': '公平',
      'prank': '作弊',
      'prankActive': '作弊中',
      'edit': '编辑',
      'slideToSpin': '滑动旋转',
      'spinWheelPrepTitle': '开转前先准备好',
      'spinWheelPrepHint': '把模板、模式和惩罚规则先设好，再开始这一轮命运转盘。',
      'spinWheelTemplateTitle': '转盘模板',
      'spinWheelModeTitle': '模式与选项',
      'spinWheelModeHelpTitle': '公平和作弊有什么区别？',
      'spinWheelModeHelpBody':
          '公平模式会按转盘当前的真实停留结果结算。作弊模式会在结果揭晓前做一次偏置，更容易把结果改到你想恶作剧的方向，适合整蛊局使用。',
      'spinWheelResultHeadline': '{template}结果',
      'spinWheelResultTypeLabel': '转盘类型',
      'spinWheelPlayerHintTitle': '默认最多 6 人',
      'spinWheelPlayerHint': '建议 2 到 6 人围成一圈快速决策，人数更多时可分组轮流开转。',
      'spinWheelSelectedOption': '最终选中',
      'spinWheelSelectedColor': '最终颜色',
      'spinWheelBlindBoxPenalty': '惩罚盲盒',
      'presetDinner': '今晚吃啥',
      'presetWhoPays': '谁买单',
      'presetTruthDare': '真心话大冒险',
      'presetGames': '玩什么游戏',
      'custom': '自定义',

      // Number Bomb
      'numberBombTitle': '数字炸弹',
      'numberBombSubtitle': 'NUMBER BOMB',
      'numberBombPrepTitle': '准备开炸',
      'numberBombPrepHint': '先设定参与人数和数字范围，再把手机交给 1 号玩家开始高压猜数。',
      'numberBombPrepPlayersTitle': '玩家人数',
      'numberBombPrepPlayersHint': '每次成功输入后自动轮到下一位玩家，踩中炸弹的人立即受罚。',
      'numberBombPrepRangeTitle': '数字范围',
      'numberBombPrepRangeHint': '范围越大，前期越安全；范围越小，心理压迫感来得越快。',
      'numberBombPrepPenaltyTitle': '惩罚联动',
      'numberBombPrepPenaltyHint': '爆炸后仅由踩中的输家执行惩罚盲盒。',
      'numberBombCurrentPlayer': '当前玩家 · {player}',
      'numberBombLoser': '本轮输家：{player}',
      'numberBombWinners': '获胜玩家：{players}',
      'selectRange': '选择范围',
      'range1_50': '1 – 50',
      'range1_100': '1 – 100',
      'range1_500': '1 – 500',
      'min': '最小值',
      'max': '最大值',
      'startGame': '开始游戏',
      'safeRange': '安全区间',
      'inputNumber': '输入数字',
      'invalidRange': '请输入 {min} 〜 {max} 范围内的数字',
      'punishment': '惩罚',
      'againRound': '再来一局',
      'reset': '重置',

      // Party Plus (shared)
      'playerLabel': '玩家{index}',
      'playersCount': '人数 {count} 人',
      'roundProgress': '第 {current} / {total} 轮',
      'doneProgress': '已完成 {current} / {total}',
      'pointsCount': '{count} 分',
      'nextRound': '再来一轮',
      'startTimer': '开始倒计时',
      'nextPlayer': '下一位',
      'playAgain': '再玩一次',
      'directionLeft': '左',
      'directionRight': '右',
      'directionUp': '上',
      'directionDown': '下',
      'penaltyLabel': '受罚',
      'penaltyResult': '{player} 受罚：{penalty}',

      // Party Plus penalties
      'penaltySipOne': '喝 1 口',
      'penaltySipTwo': '喝 2 口',
      'penaltyCheersRight': '给右手边的人敬一杯',
      'penaltyTruthOne': '真心话一题',
      'penaltyMiniShot': '小杯一口闷',
      'penaltySquatEight': '做 8 个深蹲',
      'penaltyTongueTwister': '快速说 3 次绕口令',
      'penaltyComplimentLeft': '夸左手边玩家 3 句',
      'penaltyPlankTen': '平板支撑 10 秒',
      'penaltyClapBeat': '用手打节拍 10 秒',
      'penaltyCarryLoop': '公主抱旁边的人绕场一圈',
      'penaltyBarkThree': '学狗叫三声',
      'penaltyBowAll': '给在场所有人鞠躬道歉',
      'penaltyOpenDrinkMouth': '用嘴打开一瓶饮料',
      'penaltyPerformTalent': '表演一个才艺',
      'penaltyWriteNameFoot': '用脚写下自己的名字',
      'penaltyUglySelfie': '用最丑表情自拍发朋友圈',
      'penaltyForeheadFlick': '被在场所有人弹脑门一下',
      'penaltySendLoveMsg': '给最近联系的人发一条“我爱你”',
      'penaltySingChorus': '唱一首歌的副歌部分',
      'penaltyOneLegThirty': '单脚站立 30 秒',
      'penaltyMimicWalk': '学一个人走路的样子',
      'penaltyTongueTwisterBreath': '一口气说完绕口令',

      // Pass Bomb
      'passBombReady': '准备开局',
      'passBombCurrentHolder': '当前持有',
      'passBombBoom': '💥 爆炸了！',
      'passBombSecondsLeft': '剩余 {seconds} 秒',
      'passBombPassButton': '传递炸弹',
      'passBombDanger': '随时可能爆炸...',
      'decibelBombRequestingPermission': '正在申请麦克风权限...',
      'decibelBombPermissionDenied': '麦克风权限未开启',
      'decibelBombPermissionPermanentlyDenied': '权限被系统拒绝，请前往系统设置开启麦克风',
      'decibelBombPermissionRestricted': '当前设备受系统限制，无法使用麦克风权限',
      'decibelBombCalibrating': '环境音校准中（2秒）',
      'decibelBombSpeaking': '采集中，继续说话',
      'decibelBombExploded': '炸弹已爆炸',
      'decibelBombReadyHint': '按住尖叫，松开后点击“下一位”接力',
      'decibelBombSpeakHold': '按住尖叫',
      'decibelBombCurrentPlayer': '当前持有：{player}',
      'decibelBombCurrentDb': '当前分贝',
      'decibelBombBaseline': '环境底噪',
      'decibelBombSensitivity': '敏感度 S',
      'decibelBombEnergy': '能量桶',
      'decibelBombExplosionReason': '爆炸原因',
      'decibelBombHandoffPenalty': '接力后 0.5 秒检测到突刺噪音',
      'decibelBombLoudPenalty': '持续音量过高，能量桶溢出',
      'decibelBombExplodedByHandoff': '{player} 接力瞬间触发噪音突刺爆炸',
      'decibelBombExplodedByEnergy': '{player} 说话累计能量溢出爆炸',
      'decibelBombRecalibrate': '重新校准开局',
      'decibelBombGrantPermission': '重新请求权限',
      'decibelBombOpenSettings': '去系统设置',

      // Gesture Duel
      'gestureModeMinority': '模式：少数受罚',
      'gestureModeMajority': '模式：多数受罚',
      'gestureStartDuel': '开始对决',
      'gestureRoundsSetting': '轮次：{count}',
      'gestureRoundOf': '第 {current} / {total} 轮',
      'gestureFinalResult': '最终得分',
      'gestureRoundScore': '{players} 本轮 +1 分',
      'gesturePassToPick': '请把手机交给 {player} 选择手势',
      'gestureRock': '石头',
      'gesturePaper': '布',
      'gestureScissors': '剪刀',
      'gestureRoundResult': '本轮结果',
      'gestureSameDraw': '全员同手势，平局重来',
      'gestureEveryoneHitDraw': '全员中招，平局重来',
      'gestureNoLoserDraw': '无人受罚，平局重来',
      'gesturePenaltyResult': '{players} 受罚：{penalty}',

      // Left Right
      'leftRightRule': '每轮每位玩家各 1 次，含反转回合，错误或超时记罚分',
      'leftRightDifficultyTitle': '难度模式',
      'leftRightDifficultyEasy': '简单',
      'leftRightDifficultyMedium': '中等',
      'leftRightDifficultyHard': '困难',
      'leftRightDifficultyEasyHint': '反转概率 20%，只会出现左右方向',
      'leftRightDifficultyMediumHint': '反转概率 50%，只会出现左右方向',
      'leftRightDifficultyHardHint': '反转概率 75%，会出现上下左右四方向',
      'leftRightRoundsSetting': '轮次：{count}',
      'leftRightSwipeTo': '请向 {direction} 方向滑动',
      'leftRightReverseSwipeTo': '⚡ 反转！请向 {direction} 的反方向滑动',
      'leftRightReversed': '反向操作！+2 罚分',
      'leftRightTimeout': '超时，+1 罚分',
      'leftRightWrong': '方向错误，+1 罚分',
      'leftRightSuccessMs': '成功 {ms}ms',
      'leftRightWaitingSwipe': '等待滑动...',
      'leftRightBeginReaction': '开始反应',
      'leftRightFinalPenalties': '最终罚分',
      'gravityBalancePrepTitle': '准备挑战',
      'gravityBalancePrepHint': '先选难度再开局。难度越高，路径弯曲和摆动越明显。',
      'gravityBalancePlayersSetting': '参与人数：{count}',
      'gravityBalanceStartChallenge': '开始挑战',
      'gravityBalanceCurrentPlayer': '当前玩家 {current}/{total}',
      'gravityBalanceRule': '将液态球保持在轨迹内，到达终点即获胜。\n进度过半后轨迹摆动，随机地震会强行冲击。',
      'gravityBalanceDifficultyEasyHint': '轨道更宽，摆动更轻，地震间隔更长，适合热身局。',
      'gravityBalanceDifficultyMediumHint': '默认挑战，摆动与地震频率保持均衡。',
      'gravityBalanceDifficultyHardHint': '轨道更窄，摆动更强，地震更频繁，适合高压对决。',
      'gravityBalanceQuake': '⚠ 地震冲击！立刻反向倾斜',
      'gravityBalanceCompleted': '完美通关',
      'gravityBalanceExploded': '轨迹失守，球体炸裂',
      'gravityBalanceFailed': '错过洞口，挑战失败',
      'gravityBalanceRoundResultTitle': '{player} 结果',
      'gravityBalanceResultStatus': '是否成功：{status}',
      'gravityBalanceResultTime': '完成时间：{time}',
      'gravityBalanceResultSuccessYes': '成功',
      'gravityBalanceResultSuccessNo': '失败',
      'gravityBalanceTimeUnavailable': '--',
      'gravityBalanceSeconds': '{seconds} 秒',
      'gravityBalanceViewSummary': '查看总成绩',
      'gravityBalanceSummaryTitle': '总成绩',
      'gravityBalanceNoChampion': '未决出速度冠军（需全员成功）',
      'gravityBalanceChampion': '冠军：{player}（{time}）',
      'gravityBalanceRetry': '重开一局',
      'bioDetectorHoldStart': '长按开始检测',
      'bioDetectorSamplingHint1': '读取毛细血管收缩压...',
      'bioDetectorSamplingHint2': '分析皮电反应...',
      'bioDetectorWarnBreath': '[WARN] 呼吸频率异常',
      'bioDetectorWarnCortex': '[WARN] 逻辑皮层活跃度增高',
      'bioDetectorRetry': '再测一次',
      'bioDetectorSetupTitle': '开局设置',
      'bioDetectorPrepEyebrow': 'BIO-SCAN',
      'bioDetectorPrepStandby': '待命中',
      'bioDetectorPrepHeroTitle': '准备检测',
      'bioDetectorPrepHeroBody': '校准伪生物链路后再开始。每轮通过长按指纹区触发扫描，系统会在高压阶段给出真假判定。',
      'bioDetectorPrepSignalTag': 'RED-LINE READY',
      'bioDetectorPrepRoundsLabel': '检测轮次',
      'bioDetectorPrepRoundsHint': '先设定整局节奏，再进入待机检测。',
      'bioDetectorPrepRoundsUnit': '轮流程',
      'bioDetectorPrepPenaltyTitle': '惩罚联动',
      'bioDetectorPrepPenaltyHint': '仅在判定为谎言时触发惩罚盲盒，先把场景和尺度约好。',
      'bioDetectorPrepMetricDuration': '检测时长',
      'bioDetectorPrepMetricDurationValue': '约 10 秒',
      'bioDetectorPrepMetricTrigger': '触发方式',
      'bioDetectorPrepMetricTriggerValue': '长按指纹区',
      'bioDetectorPrepMetricPenalty': '失败后果',
      'bioDetectorPrepMetricPenaltyValue': '触发惩罚',
      'bioDetectorRoundsSetting': '轮次：{count}',
      'bioDetectorSetupHint': '设置轮次后开始。每轮长按指纹区触发检测。',
      'bioDetectorRoundTruth': '本轮判定：真话',
      'bioDetectorRoundLie': '本轮判定：谎言',
      'bioDetectorFinalSummary': '检测完成：真话 {truth} / 谎言 {lie}',
      'bioDetectorResultConfidence': '结果可信度',
      'bioDetectorResultRisk': '风险指数',
      'bioDetectorResultTruthBody': '系统判定当前陈述可信，可以继续下一轮。',
      'bioDetectorResultLieBody': '系统判定当前陈述存在风险，直接进入惩罚模块。',

      // Word Bomb
      'wordBombCategory': '词库分类',
      'wordBombCategoryLine': '分类：{category}',
      'wordBombStarterPending': '起始词将在开始后生成',
      'wordBombStarterLine': '起始词：{word}',
      'wordBombExploded': '{player} 爆炸，受罚：{penalty}',
      'wordBombCategoryFood': '食物',
      'wordBombCategoryMovie': '电影',
      'wordBombCategoryTravel': '旅行地',
      'wordBombCategoryAnimal': '动物',
      'wordBombCategorySport': '运动',
      'wordBombFoodWords': '火锅|奶茶|披萨|麻辣烫|汉堡|寿司|烤肉|炸鸡|面条|蛋糕|饺子|煎饼',
      'wordBombMovieWords': '科幻片|喜剧片|爱情片|动画片|恐怖片|纪录片|悬疑片|动作片',
      'wordBombTravelWords': '海边|雪山|古镇|夜市|沙漠|温泉|草原|森林|瀑布|岛屿',
      'wordBombAnimalWords': '熊猫|金鱼|猎豹|海豚|袋鼠|鹦鹉|企鹅|考拉|老虎|北极熊',
      'wordBombSportWords': '篮球|瑜伽|跑酷|击剑|冲浪|攀岩|拳击|滑雪|乒乓球|羽毛球',
      'wordBombNext': '下一个',

      // Challenge Auction
      'challengeAuctionBidRangeLabel': '出价范围',
      'challengeAuctionBidRangeActive': '可出价范围：{min} - {max}',
      'challengeAuctionBidInputHint': '直接输入出价',
      'challengeAuctionRule': '每人报一个出价争夺挑战资格，最低价中标',
      'challengeAuctionRulePure': '每人报一个出价争夺挑战资格，最低价中标（纯净模式）',
      'challengeAuctionStart': '开始拍卖',
      'challengeAuctionBidPrompt': '{player} 出价',
      'challengeAuctionBidCount': '{count} 口',
      'challengeAuctionBidsProgress': '已报价 {current} / {total}',
      'challengeAuctionConfirmBid': '确认出价',
      'challengeAuctionWinner': '{player} 中标（{bid} 口）',
      'challengeAuctionWinnerPure': '{player} 中标（{bid} 分）',
      'challengeAuctionFailed': '挑战失败',
      'challengeAuctionSucceeded': '挑战成功',
      'challengeAuctionNext': '下一轮挑战',
      'challengeAuctionResultSuccessAlcohol': '{player} 挑战成功，其他人各喝 1 口',
      'challengeAuctionResultSuccessPure': '{player} 挑战成功，其他人各 +1 分',
      'challengeAuctionResultFailAlcohol': '{player} 挑战失败，喝 {count} 口',
      'challengeAuctionResultFailPure': '{player} 挑战失败，+{count} 分',
      'challengeAuctionItem1': '30 秒内讲一个离谱社死经历',
      'challengeAuctionItem2': '模仿在场任意一位 10 秒',
      'challengeAuctionItem3': '连续夸左手边玩家 5 句',
      'challengeAuctionItem4': '即兴广告词推销纸巾',
      'challengeAuctionItem5': '闭眼唱副歌 10 秒',
      'challengeAuctionItem6': '跟右手边的人对视 15 秒不许笑',
      'challengeAuctionItem7': '用唱歌的方式说出今天做的 3 件事',
      'challengeAuctionItem8': '表演一个无实物吃面条',
      'challengeAuctionItem9': '做 5 个不同的搞笑表情让大家猜情绪',
      'challengeAuctionItem10': '单脚站立 20 秒同时背一首诗',
      'challengeAuctionItem11': '模仿一种动物叫声 15 秒',
      'challengeAuctionItem12': '用 3 个随机词编一个完整故事',
      'challengeAuctionItem13': '给对面的人即兴编一首打油诗',
      'challengeAuctionItem14': '用方言说一段绕口令',
      'challengeAuctionItem15': '表演慢动作接电话并假装很紧张',

      // Truth or Raise
      'truthRaiseSetupTitle': '开局设置',
      'truthRaiseRoundsSetting': '轮次：{count}',
      'truthRaiseScaleTitle': '尺度等级',
      'truthRaiseScaleHint': '跳过每次 +{step} 码，最高 {max} 码',
      'truthRaiseScaleCurrent': '当前尺度：{level}',
      'truthRaiseScaleGentle': '轻松',
      'truthRaiseScaleStandard': '标准',
      'truthRaiseScaleSpicy': '刺激',
      'truthRaiseScaleExtreme': '爆表',
      'truthRaiseBackToSetup': '返回设置',
      'truthRaiseRule': '回答则重置加码；跳过按所选档位加码并计入罚分',
      'truthRaiseCurrent': '当前加码：{count}',
      'truthRaiseSkipRaise': '跳过 + 加码',
      'truthRaiseAnswer': '我回答',
      'truthRaiseSettlement': '结算',
      'truthRaiseAnsweredAction': '{player} 选择回答，重置加码',
      'truthRaiseSkippedAction': '{player} 跳过，+{count} 码',
      'truthRaiseQuestion1': '你最近一次尴尬瞬间是什么？',
      'truthRaiseQuestion2': '在场谁最会聊天？为什么？',
      'truthRaiseQuestion3': '你最离谱的一次冲动消费是什么？',
      'truthRaiseQuestion4': '你现在最想删掉手机里的哪张照片？',
      'truthRaiseQuestion5': '你做过最社恐的一件事？',
      'truthRaiseQuestion6': '你手机里最近一条搜索记录是什么？',
      'truthRaiseQuestion7': '你说过最假的一句夸人的话是什么？',
      'truthRaiseQuestion8': '如果可以删掉一段记忆你会删哪段？',
      'truthRaiseQuestion9': '你最近一次说谎是什么时候？',
      'truthRaiseQuestion10': '你觉得在座谁最好看？',
      'truthRaiseQuestion11': '你有什么别人不知道的怪癖？',
      'truthRaiseQuestion12': '你最想回到人生的哪一天？',
      'truthRaiseQuestion13': '你最不想被翻出来的聊天记录是跟谁的？',
      'truthRaiseQuestion14': '你上一次哭是什么时候？为什么？',
      'truthRaiseQuestion15': '你做过的最后悔的事是什么？',
      'truthRaiseQuestion16': '你现在手机里最多的 APP 是哪一类？',
      'truthRaiseQuestion17': '你最不擅长的一件事是什么？',
      'truthRaiseQuestion18': '你小时候最蠢的一个想法是什么？',
      'truthRaiseQuestion19': '用一个词形容你对右手边的人的印象',
      'truthRaiseQuestion20': '你这辈子收到过最奇怪的礼物是什么？',

      // Game Help
      'gameHelpTitle': '游戏说明',
      'gameHelpGotIt': '知道了',
      'helpFingerPickerBody':
          '把手指放在屏幕上。\n所有人静止后会锁定并倒计时。\n系统随机选出胜者，其余人淘汰。\n可在右上角设置胜者人数。',
      'helpSpinWheelBody':
          '左右滑动让转盘旋转。\n指针停下所指即本轮结果。\n可编辑选项、颜色与模板。\n适合抽惩罚、抽任务、抽人。',
      'helpNumberBombBody':
          '先选数字范围并开始。\n每人轮流猜一个数字。\n如果猜中隐藏数字，立即爆炸受罚。\n若没猜中，安全区间会继续收缩。',
      'helpPassBombBody':
          '开始后会随机倒计时。\n当前持有者点击“传递炸弹”把手机传下去。\n倒计时归零时，持有者受罚。\n适合快节奏热场。',
      'helpGestureDuelBody':
          '每位玩家依次选择手势。\n可切换“少数受罚/多数受罚”模式。\n系统按本轮分布判定受罚玩家。\n平局时直接重开一轮。',
      'helpLeftRightBody': '按提示方向快速滑动。\n方向错误或超时会加罚分。\n每轮每位玩家轮流进行一次。\n最后按总罚分结算。',
      'helpWordBombBody':
          '选择词库后开始倒计时。\n按顺序说同类词并传给下一位。\n卡壳、重复或超时导致爆炸受罚。\n起始词会在每轮开始时随机给出。',
      'helpChallengeAuctionBody':
          '每位玩家先为挑战出价。\n最低价中标并执行挑战。\n成功/失败按当前模式结算。\n酒精惩罚关闭后自动改为纯净积分规则。',
      'helpTruthRaiseBody':
          '轮到你时可“回答”或“跳过+加码”。\n尺度等级会决定每次跳过增加的码数与上限。\n回答会重置加码。\n跳过会提高本轮加码并累积罚分。\n回合结束后按总罚分结算。',
      'helpBioDetectorBody':
          '长按指纹区域启动伪生物检测。\n采样阶段会显示红色脉搏波与滚动分析提示。\n高压阶段震动会从 60bpm 提升至 120bpm，并随机出现告警。\n角落隐藏热区可操纵真/假结果。',
      'helpDecibelBombBody':
          '点击开始后会申请麦克风权限。\n先静默 2 秒自动校准环境底噪。\n按住 Speak 时才累计能量，越吵越危险。\n点击“下一位”后的 0.5 秒若出现突刺噪音会直接爆炸。',
      'helpGravityBalanceBody':
          '通过手机倾斜控制液态球，始终停留在贝塞尔轨迹内。\n若出界会触发 0.3 秒红色缓冲，未回正就会炸裂。\n进度达到 50% 后轨迹将以 0.5Hz 左右摆动。\n随机地震会触发重冲击，必须反向大幅倾斜抵消。',
    },
    'en': {
      'appTitle': 'Finger Party',
      'settings': 'Settings',
      'settingsTitle': 'SETTINGS',
      'appVersion': 'Finger Party v1.0',
      'resultSummary': 'Result Summary',
      'penaltyGuideDefault': 'Apply the penalty based on current rules.',
      'penaltyGuideParty': 'Non-winning players perform the agreed penalty.',
      'penaltyGuideWheel':
          'Execute the task or penalty of the selected option.',
      'penaltyMethodRandom': 'Random',
      'penaltyMethodScore': 'Score Rule',
      'penaltyMethodRule': 'Rule Result',
      'penaltyMethodGuide': 'Gameplay Guide',
      'penaltyPresetTitle': 'Penalty Preset',
      'penaltyPresetHint':
          'Choose scene and intensity first, then reveal 3 fate cards at result time.',
      'penaltySceneTitle': 'Scene',
      'penaltySceneHome': 'Home',
      'penaltySceneBar': 'Bar',
      'penaltyIntensityTitle': 'Intensity',
      'penaltyIntensityMild': 'Mild',
      'penaltyIntensityWild': 'Wild',
      'penaltyIntensityXtreme': 'Xtreme',
      'penaltyBlindBoxTitle': 'Fate Choice',
      'penaltyBlindBoxLosers': '{players} must face the fate cards',
      'penaltyBlindBoxHint': 'Tap one card to reveal the penalty',
      'penaltyBlindBoxRevealed': 'The other two show what you narrowly escaped',
      'penaltyCurrentPlayerLabel': 'Current player',

      // Penalty blind box library
      'blindBoxBarLevel1DeepBomb':
          'Depth charge: mix two drinks and finish it in one shot.',
      'blindBoxBarLevel1CheersMessenger':
          'Cheers messenger: clink glasses with everyone and say “good game”.',
      'blindBoxBarLevel1SongPrivilege':
          'Song privilege: queue the worst song for the winner and listen to all of it.',
      'blindBoxBarLevel1SingleEar':
          'Single earring: hold your right ear with your left hand for 2 minutes.',
      'blindBoxBarLevel2DarkDrink':
          'Dark mixologist: let the winner mix a cursed drink and finish it.',
      'blindBoxBarLevel2TruthBody':
          'Truth: name the most attractive feature of someone here.',
      'blindBoxBarLevel2ShoutHero':
          'Spotlight moment: stand up and shout “I am the hottest one tonight!”.',
      'blindBoxBarLevel2RecentCalls':
          'Life swap: let the player on your left inspect your recent calls.',
      'blindBoxBarLevel3SinglePost':
          'Social gamble: post “I am single, who wants me?” for 5 minutes.',
      'blindBoxBarLevel3StrangerTissue':
          'Stranger task: ask the next table for a tissue and compliment them.',
      'blindBoxBarLevel3VoiceConfession':
          'Voice confession: send “I always wanted to tell you...” to your top chat.',
      'blindBoxBarLevel3BlindFeed':
          'Blind follow: wear a blindfold and let the winner feed you three things.',
      'blindBoxHomeLevel1BalanceMaster':
          'Balance master: stand on one leg with eyes closed for 30 seconds.',
      'blindBoxHomeLevel1WallSquat':
          'Wall crawl: do 10 squats against the wall without support.',
      'blindBoxHomeLevel1EmojiCopy':
          'Meme copy: imitate a popular emoji until the room passes it.',
      'blindBoxHomeLevel1SilentGold':
          'Silence is gold: no talking for 3 minutes or the punishment doubles.',
      'blindBoxHomeLevel2SecretStory':
          'Secret drop: tell an embarrassing story no one here knows.',
      'blindBoxHomeLevel2PhotoExplain':
          'Photo void: show the 10th photo from the end of your gallery and explain it.',
      'blindBoxHomeLevel2SiriConfession':
          'Smart assistant: confess your love to Siri for 30 seconds.',
      'blindBoxHomeLevel2ChoresToday':
          'Chore duty: own tonight’s cleanup job by yourself.',
      'blindBoxHomeLevel3GroupBlast':
          'Family blast: send “stop rushing me into marriage or dating” to the family group.',
      'blindBoxHomeLevel3AvatarSwap':
          'Avatar swap: use the winner’s photo as your avatar for 24 hours.',
      'blindBoxHomeLevel3LiveShow':
          'Live challenge: do a 1-minute mime in a live story or group video.',
      'blindBoxHomeLevel3RolePlay':
          'Role switch: imitate someone here until everyone guesses who.',
      'blindBoxFallbackQuickSquat': 'Fallback: do 10 squats immediately.',
      'blindBoxFallbackQuickTruth':
          'Fallback: answer one truth question picked by the group.',
      'blindBoxFallbackQuickSong':
          'Fallback: sing 20 seconds of a chorus until everyone approves.',

      'hubSubtitle': 'PARTY GAMES',
      'fingerPicker': 'Finger Picker',
      'fingerPickerSub': 'FINGER PICKER',
      'fingerPickerDesc': 'Touch of fate',
      'fingerPrepTitle': 'Prepare round',
      'fingerPrepHint':
          'Lock your rules and penalty settings first, then let everyone hold the screen for the draw.',
      'fingerPrepIntroTitle': 'Game basics',
      'fingerPrepIntroHint': 'Round flow',
      'fingerPrepIntroBody':
          'All players hold the screen at once. After countdown, the system keeps the configured number of colors and eliminates the rest for penalty draw.',
      'fingerPrepWinnersTitle': 'Winners setting',
      'fingerPrepWinnersHint': 'How many colors survive this round',
      'fingerPrepPenaltyTitle': 'Penalty setting',
      'fingerPrepPenaltyHint':
          'Choose scene and intensity first. The result page will generate blind-box penalty cards.',
      'fingerResultTitle': 'Round result',
      'fingerResultNoColor': 'No final color yet',
      'fingerResultSingleColor': 'Final color: {color}',
      'fingerResultMultiColors': 'Final colors: {colors}',
      'fingerColorCyan': 'Cyan',
      'fingerColorMagenta': 'Magenta',
      'fingerColorLime': 'Lime',
      'fingerColorYellow': 'Yellow',
      'fingerColorOrange': 'Orange',
      'fingerColorViolet': 'Violet',
      'fingerColorPink': 'Pink',
      'fingerColorSpringGreen': 'Spring green',
      'fingerColorAzure': 'Azure',
      'fingerColorAmber': 'Amber',
      'spinWheel': 'Spin Wheel',
      'spinWheelSub': 'SPIN WHEEL',
      'spinWheelDesc': 'Smooth physics',
      'numberBomb': 'Number Bomb',
      'numberBombSub': 'NUMBER BOMB',
      'numberBombDesc': 'Psychological pressure',
      'passBomb': 'Pass Bomb',
      'passBombSub': 'PASS BOMB',
      'passBombDesc': 'Pass phone before boom',
      'gestureDuel': 'Gesture Duel',
      'gestureDuelSub': 'GESTURE DUEL',
      'gestureDuelDesc': 'Minority/majority loses mode',
      'leftRight': 'Left or Right',
      'leftRightSub': 'LEFT OR RIGHT',
      'leftRightDesc': 'React to direction fast',
      'wordBomb': 'Word Bomb',
      'wordBombSub': 'WORD BOMB',
      'wordBombDesc': 'Timed chain before explosion',
      'challengeAuction': 'Challenge Auction',
      'challengeAuctionSub': 'CHALLENGE AUCTION',
      'challengeAuctionDesc': 'Lowest bid takes challenge',
      'truthRaise': 'Truth or Raise',
      'truthRaiseSub': 'TRUTH OR RAISE',
      'truthRaiseDesc': 'Skip keeps raising stakes',
      'bioDetector': 'Bio-Detector',
      'bioDetectorSub': 'BIO-DETECTOR',
      'bioDetectorDesc': 'Psychological deception scan',
      'decibelBomb': 'Decibel Bomb',
      'decibelBombSub': 'DECIBEL BOMB',
      'decibelBombDesc': 'Hold to speak, charge energy, spike noise to explode',
      'decibelBombPrepTitle': 'Set Up Before Calibration',
      'decibelBombPrepHint':
          'Review the rules, choose the player count and penalty preset, then tap start to request microphone access and enter calibration.',
      'decibelBombPrepGuideHint':
          'Hold to speak to keep charging the bomb, and a sharp handoff noise spike can detonate it instantly.',
      'decibelBombPrepPlayersTitle': 'Player Count',
      'decibelBombPrepPlayersHint':
          'Best with 3 to 8 players passing the phone in sequence. Whoever is holding it when it explodes loses the round.',
      'decibelBombPrepPenaltyTitle': 'Penalty Preset',
      'decibelBombPrepPenaltyHint':
          'Agree on the scene and intensity now so the fate cards can resolve immediately after the blast.',
      'gravityBalance': 'Gravity Balance',
      'gravityBalanceSub': 'GRAVITY BALANCE',
      'gravityBalanceDesc': 'Tilt to steer through sway and quakes',
      'iapPriceFallback': '\$1',
      'iapPurchaseTitle': 'Unlock game',
      'iapPurchaseBody':
          '{game} requires purchase to play. Price: {price}. Once bought, it stays unlocked.',
      'iapBuyNow': 'Buy now',
      'iapRestore': 'Restore purchases',
      'iapStoreUnavailable': 'Store is unavailable. Please try again later.',
      'iapProductNotFound': 'This product is unavailable right now.',
      'iapPurchasePending': 'Processing purchase result...',
      'iapPurchaseFailed': 'Failed to start purchase. Please try again.',
      'iapUnlockSuccess': 'Unlocked: {game}',
      'iapPaywallSwitch': 'Game paywall switch',
      'iapPaywallSwitchSub': 'IAP PAYWALL (DEBUG)',

      'sound': 'Sound',
      'soundSub': 'SOUND',
      'vibration': 'Vibration',
      'vibrationSub': 'VIBRATION',
      'minimalMode': 'Minimal Mode',
      'minimalModeSub': 'MINIMAL MODE',
      'alcoholPenalty': 'Alcohol Penalty',
      'alcoholPenaltySub': 'ALCOHOL / PURE MODE',
      'language': 'Language',
      'languageSub': 'LANGUAGE',
      'about': 'About',
      'aboutSub': 'ABOUT',
      'privacyPolicy': 'Privacy Policy',
      'contact': 'Contact',
      'langFollowSystem': 'System',
      'langChinese': '中文',
      'langEnglish': 'English',

      'placeFingers': 'Place fingers',
      'placeFingersEn': 'PLACE FINGERS TO BEGIN',
      'waitingMore': 'Waiting for more...',
      'locked': 'Locked! Hold still...',
      'start': 'Start',
      'someoneEscaped': 'Someone escaped!',
      'escapeHint': 'Place all fingers again\nto restart',
      'okRetry': 'OK, Retry',
      'selectWinners': 'Winners',
      'selectWinnersCount': 'Pick {count}',
      'result': 'Result',
      'victor': 'Winner',
      'victors': 'Winners × {count}',
      'again': 'Again',
      'add': '+ Add',
      'editWheel': 'Edit Wheel',
      'addOption': 'Add Option',
      'editOption': 'Edit Option',
      'optionName': 'Option name',
      'color': 'Color',
      'cancel': 'Cancel',
      'confirm': 'OK',
      'fateSpinning': 'Spinning...',
      'eliminated': 'Out {current} / {total}',
      'reveal': 'Revealing...',
      'touchToContinue': 'Tap to continue',
      'overflowTitle': 'Too many',
      'overflowHint': 'Max 6 players\nRemove fingers to restart',
      'ok': 'OK',
      'fair': 'Fair',
      'prank': 'Cheat',
      'prankActive': 'Cheat active',
      'edit': 'Edit',
      'slideToSpin': 'Slide to spin',
      'spinWheelPrepTitle': 'Get ready before spinning',
      'spinWheelPrepHint':
          'Set the template, mode and penalties first, then kick off the wheel.',
      'spinWheelTemplateTitle': 'Wheel template',
      'spinWheelModeTitle': 'Mode and options',
      'spinWheelModeHelpTitle': 'What is the difference?',
      'spinWheelModeHelpBody':
          'Fair mode settles on the wheel\'s true stopping result. Cheat mode applies a bias right before reveal, making it easier to push the outcome toward a more mischievous pick.',
      'spinWheelResultHeadline': '{template} Result',
      'spinWheelResultTypeLabel': 'Wheel type',
      'spinWheelPlayerHintTitle': 'Best with up to 6 players',
      'spinWheelPlayerHint':
          'Works best with 2 to 6 players. Rotate in small groups if more people want in.',
      'spinWheelSelectedOption': 'Selected option',
      'spinWheelSelectedColor': 'Selected color',
      'spinWheelBlindBoxPenalty': 'Blind Box Penalty',
      'presetDinner': 'Dinner',
      'presetWhoPays': 'Who Pays',
      'presetTruthDare': 'Truth or Dare',
      'presetGames': 'Games',
      'custom': 'Custom',

      'numberBombTitle': 'Number Bomb',
      'numberBombSubtitle': 'NUMBER BOMB',
      'numberBombPrepTitle': 'Prep blast',
      'numberBombPrepHint':
          'Set player count and number range first, then hand the phone to Player 1 to start the pressure round.',
      'numberBombPrepPlayersTitle': 'Players',
      'numberBombPrepPlayersHint':
          'Each safe guess passes the turn to the next player. Whoever hits the bomb loses immediately.',
      'numberBombPrepRangeTitle': 'Number range',
      'numberBombPrepRangeHint':
          'Bigger ranges feel safer early. Smaller ranges bring pressure much faster.',
      'numberBombPrepPenaltyTitle': 'Penalty link',
      'numberBombPrepPenaltyHint':
          'After explosion, only the losing player takes the blind-box penalty.',
      'numberBombCurrentPlayer': 'Current player · {player}',
      'numberBombLoser': 'Loser: {player}',
      'numberBombWinners': 'Winners: {players}',
      'selectRange': 'Select range',
      'range1_50': '1 – 50',
      'range1_100': '1 – 100',
      'range1_500': '1 – 500',
      'min': 'Min',
      'max': 'Max',
      'startGame': 'Start',
      'safeRange': 'Safe range',
      'inputNumber': 'Enter number',
      'invalidRange': 'Enter {min} – {max}',
      'punishment': 'Punishment',
      'againRound': 'Play again',
      'reset': 'Reset',

      // Party Plus (shared)
      'playerLabel': 'Player {index}',
      'playersCount': 'Players: {count}',
      'roundProgress': 'Round {current} / {total}',
      'doneProgress': 'Done {current} / {total}',
      'pointsCount': '{count} pts',
      'nextRound': 'Next round',
      'startTimer': 'Start timer',
      'nextPlayer': 'Next player',
      'playAgain': 'Play again',
      'directionLeft': 'LEFT',
      'directionRight': 'RIGHT',
      'directionUp': 'UP',
      'directionDown': 'DOWN',
      'penaltyLabel': 'Penalty',
      'penaltyResult': '{player} penalty: {penalty}',

      // Party Plus penalties
      'penaltySipOne': 'Take 1 sip',
      'penaltySipTwo': 'Take 2 sips',
      'penaltyCheersRight': 'Cheers with the player on your right',
      'penaltyTruthOne': 'Answer one truth question',
      'penaltyMiniShot': 'Take one mini shot',
      'penaltySquatEight': 'Do 8 squats',
      'penaltyTongueTwister': 'Say a tongue twister 3 times',
      'penaltyComplimentLeft': 'Give 3 compliments to left player',
      'penaltyPlankTen': 'Hold plank for 10 seconds',
      'penaltyClapBeat': 'Clap a beat for 10 seconds',
      'penaltyCarryLoop': 'Carry the next player around the room once',
      'penaltyBarkThree': 'Bark like a dog three times',
      'penaltyBowAll': 'Bow to everyone and apologize',
      'penaltyOpenDrinkMouth': 'Open a drink bottle with your mouth',
      'penaltyPerformTalent': 'Perform a quick talent show',
      'penaltyWriteNameFoot': 'Write your name using your foot',
      'penaltyUglySelfie': 'Take your ugliest selfie and post it',
      'penaltyForeheadFlick': 'Let everyone flick your forehead once',
      'penaltySendLoveMsg': 'Text your last contact: "I love you"',
      'penaltySingChorus': 'Sing the chorus of any song',
      'penaltyOneLegThirty': 'Stand on one leg for 30 seconds',
      'penaltyMimicWalk': 'Mimic someone’s walking style',
      'penaltyTongueTwisterBreath': 'Finish a tongue twister in one breath',

      // Pass Bomb
      'passBombReady': 'Ready',
      'passBombCurrentHolder': 'Current holder',
      'passBombBoom': 'BOOM',
      'passBombSecondsLeft': '{seconds}s left',
      'passBombPassButton': 'Pass bomb',
      'passBombDanger': 'Could explode any moment...',
      'decibelBombRequestingPermission': 'Requesting microphone permission...',
      'decibelBombPermissionDenied': 'Microphone permission is required',
      'decibelBombPermissionPermanentlyDenied':
          'Permission blocked by system, open Settings to enable microphone',
      'decibelBombPermissionRestricted':
          'Microphone permission is restricted on this device',
      'decibelBombCalibrating': 'Calibrating ambient noise (2s)',
      'decibelBombSpeaking': 'Collecting voice, keep talking',
      'decibelBombExploded': 'Bomb exploded',
      'decibelBombReadyHint': 'Hold to scream, then tap "Next" after release',
      'decibelBombSpeakHold': 'Hold to Scream',
      'decibelBombCurrentPlayer': 'Current holder: {player}',
      'decibelBombCurrentDb': 'Current dB',
      'decibelBombBaseline': 'Ambient baseline',
      'decibelBombSensitivity': 'Sensitivity S',
      'decibelBombEnergy': 'Energy bucket',
      'decibelBombExplosionReason': 'Explosion reason',
      'decibelBombHandoffPenalty': 'Noise spike in 0.5s handoff window',
      'decibelBombLoudPenalty': 'Continuous loudness overflowed bucket',
      'decibelBombExplodedByHandoff':
          '{player} triggered a handoff spike explosion',
      'decibelBombExplodedByEnergy':
          '{player} overflowed the energy bucket by speaking',
      'decibelBombRecalibrate': 'Recalibrate round',
      'decibelBombGrantPermission': 'Request permission again',
      'decibelBombOpenSettings': 'Open settings',

      // Gesture Duel
      'gestureModeMinority': 'Mode: minority loses',
      'gestureModeMajority': 'Mode: majority loses',
      'gestureStartDuel': 'Start duel',
      'gestureRoundsSetting': 'Rounds: {count}',
      'gestureRoundOf': 'Round {current} / {total}',
      'gestureFinalResult': 'Final scores',
      'gestureRoundScore': '{players} +1 this round',
      'gesturePassToPick': 'Pass phone to {player} to pick a gesture',
      'gestureRock': 'Rock',
      'gesturePaper': 'Paper',
      'gestureScissors': 'Scissors',
      'gestureRoundResult': 'Round result',
      'gestureSameDraw': 'All same gesture, draw',
      'gestureEveryoneHitDraw': 'Everyone got hit, draw',
      'gestureNoLoserDraw': 'No loser, draw',
      'gesturePenaltyResult': '{players} penalty: {penalty}',

      // Left Right
      'leftRightRule':
          'One turn per player each round. Includes reverse rounds; wrong/timeout adds penalty',
      'leftRightDifficultyTitle': 'Difficulty',
      'leftRightDifficultyEasy': 'Easy',
      'leftRightDifficultyMedium': 'Medium',
      'leftRightDifficultyHard': 'Hard',
      'leftRightDifficultyEasyHint':
          '20% reverse chance, horizontal directions only',
      'leftRightDifficultyMediumHint':
          '50% reverse chance, horizontal directions only',
      'leftRightDifficultyHardHint':
          '75% reverse chance, all four directions enabled',
      'leftRightRoundsSetting': 'Rounds: {count}',
      'leftRightSwipeTo': 'Swipe {direction}',
      'leftRightReverseSwipeTo': '⚡ REVERSE! Swipe OPPOSITE of {direction}',
      'leftRightReversed': 'Reversed! +2 penalty',
      'leftRightTimeout': 'Timeout, +1 penalty',
      'leftRightWrong': 'Wrong direction, +1 penalty',
      'leftRightSuccessMs': 'Success {ms}ms',
      'leftRightWaitingSwipe': 'Waiting swipe...',
      'leftRightBeginReaction': 'Begin reaction',
      'leftRightFinalPenalties': 'Final penalties',
      'gravityBalancePrepTitle': 'Choose difficulty',
      'gravityBalancePrepHint':
          'Pick a mode before starting. Higher difficulty means a curvier and more dynamic path.',
      'gravityBalancePlayersSetting': 'Players: {count}',
      'gravityBalanceStartChallenge': 'Start challenge',
      'gravityBalanceCurrentPlayer': 'Player {current}/{total}',
      'gravityBalanceRule':
          'Keep the liquid ball inside the lane until the finish.\nAfter 50% progress, the track starts swaying and quake shocks may knock you out.',
      'gravityBalanceDifficultyEasyHint':
          'Wider lane, gentler sway, slower quakes. Good for warm-up rounds.',
      'gravityBalanceDifficultyMediumHint':
          'Default balance with steady sway and quake pressure.',
      'gravityBalanceDifficultyHardHint':
          'Narrower lane, stronger sway, more frequent quakes for high-pressure rounds.',
      'gravityBalanceQuake': '⚠ QUAKE SHOCK! Counter-tilt now',
      'gravityBalanceCompleted': 'Level cleared',
      'gravityBalanceExploded': 'Track lost, ball shattered',
      'gravityBalanceFailed': 'Missed the hole, challenge failed',
      'gravityBalanceRoundResultTitle': '{player} result',
      'gravityBalanceResultStatus': 'Success: {status}',
      'gravityBalanceResultTime': 'Completion time: {time}',
      'gravityBalanceResultSuccessYes': 'Yes',
      'gravityBalanceResultSuccessNo': 'No',
      'gravityBalanceTimeUnavailable': '--',
      'gravityBalanceSeconds': '{seconds}s',
      'gravityBalanceViewSummary': 'View summary',
      'gravityBalanceSummaryTitle': 'Final standings',
      'gravityBalanceNoChampion': 'No speed winner (everyone must clear)',
      'gravityBalanceChampion': 'Winner: {player} ({time})',
      'gravityBalanceRetry': 'Retry',
      'bioDetectorHoldStart': 'Hold to begin scan',
      'bioDetectorSamplingHint1': 'Reading capillary constriction...',
      'bioDetectorSamplingHint2': 'Analyzing galvanic response...',
      'bioDetectorWarnBreath': '[WARN] Respiration anomaly',
      'bioDetectorWarnCortex': '[WARN] Cortex activity elevated',
      'bioDetectorRetry': 'Run again',
      'bioDetectorSetupTitle': 'Game setup',
      'bioDetectorPrepEyebrow': 'BIO-SCAN',
      'bioDetectorPrepStandby': 'Stand by',
      'bioDetectorPrepHeroTitle': 'Prep scan',
      'bioDetectorPrepHeroBody':
          'Calibrate the fake bio-link before starting. Each round begins with a long press on the fingerprint zone, then the system escalates pressure before calling truth or lie.',
      'bioDetectorPrepSignalTag': 'RED-LINE READY',
      'bioDetectorPrepRoundsLabel': 'Rounds setup',
      'bioDetectorPrepRoundsHint':
          'Set the pace of the whole session before entering standby.',
      'bioDetectorPrepRoundsUnit': 'round flow',
      'bioDetectorPrepPenaltyTitle': 'Penalty link',
      'bioDetectorPrepPenaltyHint':
          'Penalty blind box only triggers on lie results, so lock the scene and intensity now.',
      'bioDetectorPrepMetricDuration': 'Scan time',
      'bioDetectorPrepMetricDurationValue': '~10 sec',
      'bioDetectorPrepMetricTrigger': 'Trigger',
      'bioDetectorPrepMetricTriggerValue': 'Hold fingerprint',
      'bioDetectorPrepMetricPenalty': 'On failure',
      'bioDetectorPrepMetricPenaltyValue': 'Penalty fires',
      'bioDetectorRoundsSetting': 'Rounds: {count}',
      'bioDetectorSetupHint':
          'Set rounds, then start. Hold the fingerprint zone each round to scan.',
      'bioDetectorRoundTruth': 'Round result: TRUTH',
      'bioDetectorRoundLie': 'Round result: LIE',
      'bioDetectorFinalSummary': 'Scan complete: Truth {truth} / Lie {lie}',
      'bioDetectorResultConfidence': 'Confidence level',
      'bioDetectorResultRisk': 'Deception index',
      'bioDetectorResultTruthBody':
          'The system marks the statement as credible. Continue to the next round.',
      'bioDetectorResultLieBody':
          'The system marks the statement as risky. Move straight to the penalty module.',

      // Word Bomb
      'wordBombCategory': 'Category',
      'wordBombCategoryLine': 'Category: {category}',
      'wordBombStarterPending': 'Starter appears on start',
      'wordBombStarterLine': 'Starter: {word}',
      'wordBombExploded': '{player} exploded. Penalty: {penalty}',
      'wordBombCategoryFood': 'Food',
      'wordBombCategoryMovie': 'Movies',
      'wordBombCategoryTravel': 'Travel',
      'wordBombCategoryAnimal': 'Animals',
      'wordBombCategorySport': 'Sports',
      'wordBombFoodWords':
          'Pizza|Burger|Noodles|Taco|Sushi|Steak|Pasta|Curry|Dumpling|Pancake|Waffle|Ramen',
      'wordBombMovieWords':
          'Sci-fi|Comedy|Romance|Animation|Horror|Documentary|Thriller|Action',
      'wordBombTravelWords':
          'Beach|Mountain|Old Town|Night Market|Desert|Hot Spring|Prairie|Forest|Waterfall|Island',
      'wordBombAnimalWords':
          'Panda|Goldfish|Cheetah|Dolphin|Kangaroo|Parrot|Penguin|Koala|Tiger|Polar Bear',
      'wordBombSportWords':
          'Basketball|Yoga|Parkour|Fencing|Surfing|Climbing|Boxing|Skiing|Ping Pong|Badminton',
      'wordBombNext': 'Next',

      // Challenge Auction
      'challengeAuctionBidRangeLabel': 'Bid range',
      'challengeAuctionBidRangeActive': 'Allowed bids: {min} - {max}',
      'challengeAuctionBidInputHint': 'Type your bid',
      'challengeAuctionRule': 'Each player bids for challenge, lowest bid wins',
      'challengeAuctionRulePure': 'Each player bids points, lowest bid wins',
      'challengeAuctionStart': 'Start auction',
      'challengeAuctionBidPrompt': '{player} bid',
      'challengeAuctionBidCount': '{count} sips',
      'challengeAuctionBidsProgress': 'Bids {current} / {total}',
      'challengeAuctionConfirmBid': 'Confirm bid',
      'challengeAuctionWinner': '{player} wins ({bid} sips)',
      'challengeAuctionWinnerPure': '{player} wins ({bid} pts)',
      'challengeAuctionFailed': 'Failed',
      'challengeAuctionSucceeded': 'Succeeded',
      'challengeAuctionNext': 'Next challenge',
      'challengeAuctionResultSuccessAlcohol':
          '{player} succeeded, others take 1 sip',
      'challengeAuctionResultSuccessPure':
          '{player} succeeded, others +1 point',
      'challengeAuctionResultFailAlcohol': '{player} failed, take {count} sips',
      'challengeAuctionResultFailPure': '{player} failed, +{count} points',
      'challengeAuctionItem1': 'Tell an awkward story in 30s',
      'challengeAuctionItem2': 'Imitate one player for 10s',
      'challengeAuctionItem3': 'Give 5 compliments to left player',
      'challengeAuctionItem4': 'Improvise an ad for tissue',
      'challengeAuctionItem5': 'Sing a chorus with eyes closed',
      'challengeAuctionItem6':
          'Stare at the right player for 15s without laughing',
      'challengeAuctionItem7': 'Sing 3 things you did today as a song',
      'challengeAuctionItem8': 'Mime eating noodles without any props',
      'challengeAuctionItem9':
          'Make 5 funny faces and let others guess emotions',
      'challengeAuctionItem10':
          'Stand on one foot for 20s while reciting a poem',
      'challengeAuctionItem11': 'Imitate an animal sound for 15s',
      'challengeAuctionItem12': 'Make up a story using 3 random words',
      'challengeAuctionItem13': 'Improvise a rhyme for the player across',
      'challengeAuctionItem14': 'Say a tongue twister in a funny accent',
      'challengeAuctionItem15':
          'Mime answering a phone call nervously in slow motion',

      // Truth or Raise
      'truthRaiseSetupTitle': 'Game setup',
      'truthRaiseRoundsSetting': 'Rounds: {count}',
      'truthRaiseScaleTitle': 'Intensity level',
      'truthRaiseScaleHint': 'Skip adds +{step}; capped at {max}',
      'truthRaiseScaleCurrent': 'Current level: {level}',
      'truthRaiseScaleGentle': 'Gentle',
      'truthRaiseScaleStandard': 'Standard',
      'truthRaiseScaleSpicy': 'Spicy',
      'truthRaiseScaleExtreme': 'Extreme',
      'truthRaiseBackToSetup': 'Back to setup',
      'truthRaiseRule':
          'Answer resets raise; skip adds raise by selected level',
      'truthRaiseCurrent': 'Current raise: {count}',
      'truthRaiseSkipRaise': 'Skip + Raise',
      'truthRaiseAnswer': 'Answer',
      'truthRaiseSettlement': 'Result',
      'truthRaiseAnsweredAction': '{player} answered, raise reset',
      'truthRaiseSkippedAction': '{player} skipped, +{count} raise',
      'truthRaiseQuestion1': 'What is your latest awkward moment?',
      'truthRaiseQuestion2': 'Who here is the best talker and why?',
      'truthRaiseQuestion3': 'What is your wildest impulse purchase?',
      'truthRaiseQuestion4': 'Which photo in your phone do you want to delete?',
      'truthRaiseQuestion5': 'What is your most socially anxious moment?',
      'truthRaiseQuestion6': 'What is your latest search history?',
      'truthRaiseQuestion7': 'What is the fakest compliment you ever gave?',
      'truthRaiseQuestion8': 'If you could erase one memory, which one?',
      'truthRaiseQuestion9': 'When was the last time you lied?',
      'truthRaiseQuestion10': 'Who here do you think is the best looking?',
      'truthRaiseQuestion11': 'What weird habit do others not know about you?',
      'truthRaiseQuestion12': 'Which day of your life would you relive?',
      'truthRaiseQuestion13':
          'Whose chat history would you least want exposed?',
      'truthRaiseQuestion14': 'When was the last time you cried and why?',
      'truthRaiseQuestion15': 'What is your biggest regret?',
      'truthRaiseQuestion16': 'What category of app do you have most of?',
      'truthRaiseQuestion17': 'What are you worst at?',
      'truthRaiseQuestion18': 'What was your dumbest childhood idea?',
      'truthRaiseQuestion19': 'Describe the player on your right in one word',
      'truthRaiseQuestion20': 'What is the weirdest gift you ever received?',

      // Game Help
      'gameHelpTitle': 'How To Play',
      'gameHelpGotIt': 'Got it',
      'helpFingerPickerBody':
          'Place fingers on screen.\nWhen everyone stays still, the round locks and starts countdown.\nWinners are chosen randomly, others are eliminated.\nYou can set winner count from top right.',
      'helpSpinWheelBody':
          'Swipe to spin the wheel.\nThe pointer decides the result when wheel stops.\nYou can edit options, colors and presets.\nGreat for random picks or punishments.',
      'helpNumberBombBody':
          'Select a range and start.\nPlayers take turns guessing a number.\nIf someone hits the hidden number, they lose instantly.\nOtherwise, the safe range keeps shrinking.',
      'helpPassBombBody':
          'A random timer starts each round.\nCurrent holder taps “Pass bomb” and passes the phone.\nWhen timer reaches zero, current holder loses.\nFast and good for warm-up.',
      'helpGestureDuelBody':
          'Each player picks a gesture in turn.\nSwitch between “minority loses” and “majority loses”.\nSystem decides losers by distribution.\nDraws restart the round.',
      'helpLeftRightBody':
          'Swipe in the prompted direction as fast as possible.\nWrong direction or timeout adds penalty points.\nEach round gives one turn to each player.\nFinal result is based on total penalties.',
      'helpWordBombBody':
          'Choose a category and start countdown.\nSpeak a valid word then pass to next player.\nStuck/repeat/timeout causes explosion and penalty.\nA starter word is generated each round.',
      'helpChallengeAuctionBody':
          'All players bid to take the challenge.\nLowest bid wins and must perform it.\nSuccess/fail follows current rule mode.\nIf alcohol mode is off, it switches to pure point rules.',
      'helpTruthRaiseBody':
          'On your turn, choose “Answer” or “Skip + Raise”.\nIntensity level controls skip step size and cap.\nAnswer resets raise level.\nSkip increases raise and accumulates penalties.\nEnd of rounds is settled by total penalties.',
      'helpBioDetectorBody':
          'Long-press the fingerprint zone to start fake bio-analysis.\nSampling stage shows a red pulse wave and rolling readouts.\nPressure stage ramps haptics from 60bpm to 120bpm with random warnings.\nHidden corner hotspots can force truth/lie outcome.',
      'helpDecibelBombBody':
          'Tap start to request microphone permission.\nStay quiet for 2 seconds to calibrate ambient baseline.\nEnergy only increases while holding Speak.\nAfter tapping Next, any >20dB spike in 0.5s explodes immediately.',
      'helpGravityBalanceBody':
          'Tilt your phone to move the liquid ball with gravity.\nStay inside the Bezier lane or a 0.3s red warning buffer starts.\nAfter 50% progress, the path sways left-right at 0.5Hz.\nRandom heavy quake shocks require strong counter-tilt to survive.',
    },
  };

  String _t(String key) =>
      _localizedValues[locale.languageCode]?[key] ??
      _localizedValues['en']?[key] ??
      key;

  String t(String key, [Map<String, String>? params]) {
    var s = _t(key);
    if (params != null) {
      for (final e in params.entries) {
        s = s.replaceAll('{${e.key}}', e.value);
      }
    }
    return s;
  }

  // Getters for type-safe access
  String get appTitle => _t('appTitle');
  String get settings => _t('settings');
  String get settingsTitle => _t('settingsTitle');
  String get appVersion => _t('appVersion');
  String get hubSubtitle => _t('hubSubtitle');
  String get fingerPicker => _t('fingerPicker');
  String get fingerPickerSub => _t('fingerPickerSub');
  String get fingerPickerDesc => _t('fingerPickerDesc');
  String get spinWheel => _t('spinWheel');
  String get spinWheelSub => _t('spinWheelSub');
  String get spinWheelDesc => _t('spinWheelDesc');
  String get numberBomb => _t('numberBomb');
  String get numberBombSub => _t('numberBombSub');
  String get numberBombDesc => _t('numberBombDesc');
  String get sound => _t('sound');
  String get soundSub => _t('soundSub');
  String get vibration => _t('vibration');
  String get vibrationSub => _t('vibrationSub');
  String get minimalMode => _t('minimalMode');
  String get minimalModeSub => _t('minimalModeSub');
  String get alcoholPenalty => _t('alcoholPenalty');
  String get alcoholPenaltySub => _t('alcoholPenaltySub');
  String get language => _t('language');
  String get languageSub => _t('languageSub');
  String get about => _t('about');
  String get aboutSub => _t('aboutSub');
  String get privacyPolicy => _t('privacyPolicy');
  String get contact => _t('contact');
  String get langFollowSystem => _t('langFollowSystem');
  String get langChinese => _t('langChinese');
  String get langEnglish => _t('langEnglish');
  String get placeFingers => _t('placeFingers');
  String get placeFingersEn => _t('placeFingersEn');
  String get waitingMore => _t('waitingMore');
  String get locked => _t('locked');
  String get start => _t('start');
  String get someoneEscaped => _t('someoneEscaped');
  String get escapeHint => _t('escapeHint');
  String get okRetry => _t('okRetry');
  String get selectWinners => _t('selectWinners');
  String get result => _t('result');
  String get victor => _t('victor');
  String get again => _t('again');
  String get add => _t('add');
  String get editWheel => _t('editWheel');
  String get addOption => _t('addOption');
  String get editOption => _t('editOption');
  String get optionName => _t('optionName');
  String get color => _t('color');
  String get cancel => _t('cancel');
  String get confirm => _t('confirm');
  String get fateSpinning => _t('fateSpinning');
  String get reveal => _t('reveal');
  String get touchToContinue => _t('touchToContinue');
  String get overflowTitle => _t('overflowTitle');
  String get overflowHint => _t('overflowHint');
  String get ok => _t('ok');
  String get fair => _t('fair');
  String get prank => _t('prank');
  String get prankActive => _t('prankActive');
  String get edit => _t('edit');
  String get slideToSpin => _t('slideToSpin');
  String get custom => _t('custom');
  String get numberBombTitle => _t('numberBombTitle');
  String get numberBombSubtitle => _t('numberBombSubtitle');
  String get selectRange => _t('selectRange');
  String get min => _t('min');
  String get max => _t('max');
  String get startGame => _t('startGame');
  String get safeRange => _t('safeRange');
  String get inputNumber => _t('inputNumber');
  String get punishment => _t('punishment');
  String get againRound => _t('againRound');
  String get reset => _t('reset');

  String selectWinnersCount(int count) =>
      t('selectWinnersCount', {'count': '$count'});
  String victorsCount(int count) => t('victors', {'count': '$count'});
  String eliminatedCount(int current, int total) =>
      t('eliminated', {'current': '$current', 'total': '$total'});
  String invalidRangeHint(int min, int max) =>
      t('invalidRange', {'min': '$min', 'max': '$max'});
  String numberBombCurrentPlayer(String player) =>
      t('numberBombCurrentPlayer', {'player': player});
  String numberBombLoser(String player) =>
      t('numberBombLoser', {'player': player});
  String numberBombWinners(String players) =>
      t('numberBombWinners', {'players': players});

  String presetDisplayName(String name) {
    switch (name) {
      case '今晚吃啥':
        return _t('presetDinner');
      case '谁买单':
        return _t('presetWhoPays');
      case '真心话大冒险':
        return _t('presetTruthDare');
      case '玩什么游戏':
        return _t('presetGames');
      case '自定义':
        return _t('custom');
      default:
        return name;
    }
  }

  String rangePresetLabel(int index) {
    switch (index) {
      case 0:
        return _t('range1_50');
      case 1:
        return _t('range1_100');
      case 2:
        return _t('range1_500');
      case 3:
        return _t('custom');
      default:
        return '';
    }
  }

  String playerLabel(int index) => t('playerLabel', {'index': '$index'});
  String playersCount(int count) => t('playersCount', {'count': '$count'});
  String roundProgress(int current, int total) =>
      t('roundProgress', {'current': '$current', 'total': '$total'});
  String doneProgress(int current, int total) =>
      t('doneProgress', {'current': '$current', 'total': '$total'});
  String pointsCount(int count) => t('pointsCount', {'count': '$count'});
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['zh', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
