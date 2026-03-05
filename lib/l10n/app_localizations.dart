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

      // Hub
      'hubSubtitle': 'PARTY GAMES',
      'fingerPicker': '指尖轮盘',
      'fingerPickerSub': 'FINGER PICKER',
      'fingerPickerDesc': '命运的触碰',
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
      'prank': '恶搞',
      'prankActive': '恶搞中',
      'edit': '编辑',
      'slideToSpin': '滑动旋转',
      'presetDinner': '今晚吃啥',
      'presetWhoPays': '谁买单',
      'presetTruthDare': '真心话大冒险',
      'presetGames': '玩什么游戏',
      'custom': '自定义',

      // Number Bomb
      'numberBombTitle': '数字炸弹',
      'numberBombSubtitle': 'NUMBER BOMB',
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

      // Pass Bomb
      'passBombReady': '准备开局',
      'passBombCurrentHolder': '当前持有',
      'passBombBoom': '💥 爆炸了！',
      'passBombSecondsLeft': '剩余 {seconds} 秒',
      'passBombPassButton': '传递炸弹',
      'passBombDanger': '随时可能爆炸...',

      // Gesture Duel
      'gestureModeMinority': '模式：少数受罚',
      'gestureModeMajority': '模式：多数受罚',
      'gestureStartDuel': '开始对决',
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
      'leftRightRule': '每位玩家两次机会，含反转回合，错误或超时记罚分',
      'leftRightSwipeTo': '请向 {direction} 方向滑动',
      'leftRightReverseSwipeTo': '⚡ 反转！请向 {direction} 的反方向滑动',
      'leftRightReversed': '反向操作！+2 罚分',
      'leftRightTimeout': '超时，+1 罚分',
      'leftRightWrong': '方向错误，+1 罚分',
      'leftRightSuccessMs': '成功 {ms}ms',
      'leftRightWaitingSwipe': '等待滑动...',
      'leftRightBeginReaction': '开始反应',
      'leftRightFinalPenalties': '最终罚分',

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
      'truthRaiseRule': '回答则重置加码；跳过则本轮加码+1并计入罚分',
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
    },
    'en': {
      'appTitle': 'Finger Party',
      'settings': 'Settings',
      'settingsTitle': 'SETTINGS',
      'appVersion': 'Finger Party v1.0',

      'hubSubtitle': 'PARTY GAMES',
      'fingerPicker': 'Finger Picker',
      'fingerPickerSub': 'FINGER PICKER',
      'fingerPickerDesc': 'Touch of fate',
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
      'prank': 'Prank',
      'prankActive': 'Prank active',
      'edit': 'Edit',
      'slideToSpin': 'Slide to spin',
      'presetDinner': 'Dinner',
      'presetWhoPays': 'Who Pays',
      'presetTruthDare': 'Truth or Dare',
      'presetGames': 'Games',
      'custom': 'Custom',

      'numberBombTitle': 'Number Bomb',
      'numberBombSubtitle': 'NUMBER BOMB',
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

      // Pass Bomb
      'passBombReady': 'Ready',
      'passBombCurrentHolder': 'Current holder',
      'passBombBoom': 'BOOM',
      'passBombSecondsLeft': '{seconds}s left',
      'passBombPassButton': 'Pass bomb',
      'passBombDanger': 'Could explode any moment...',

      // Gesture Duel
      'gestureModeMinority': 'Mode: minority loses',
      'gestureModeMajority': 'Mode: majority loses',
      'gestureStartDuel': 'Start duel',
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
      'leftRightRule': 'Two attempts each. Includes reverse rounds! Wrong/timeout adds penalty',
      'leftRightSwipeTo': 'Swipe {direction}',
      'leftRightReverseSwipeTo': '⚡ REVERSE! Swipe OPPOSITE of {direction}',
      'leftRightReversed': 'Reversed! +2 penalty',
      'leftRightTimeout': 'Timeout, +1 penalty',
      'leftRightWrong': 'Wrong direction, +1 penalty',
      'leftRightSuccessMs': 'Success {ms}ms',
      'leftRightWaitingSwipe': 'Waiting swipe...',
      'leftRightBeginReaction': 'Begin reaction',
      'leftRightFinalPenalties': 'Final penalties',

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
      'wordBombFoodWords': 'Pizza|Burger|Noodles|Taco|Sushi|Steak|Pasta|Curry|Dumpling|Pancake|Waffle|Ramen',
      'wordBombMovieWords': 'Sci-fi|Comedy|Romance|Animation|Horror|Documentary|Thriller|Action',
      'wordBombTravelWords': 'Beach|Mountain|Old Town|Night Market|Desert|Hot Spring|Prairie|Forest|Waterfall|Island',
      'wordBombAnimalWords': 'Panda|Goldfish|Cheetah|Dolphin|Kangaroo|Parrot|Penguin|Koala|Tiger|Polar Bear',
      'wordBombSportWords': 'Basketball|Yoga|Parkour|Fencing|Surfing|Climbing|Boxing|Skiing|Ping Pong|Badminton',
      'wordBombNext': 'Next',

      // Challenge Auction
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
      'challengeAuctionItem6': 'Stare at the right player for 15s without laughing',
      'challengeAuctionItem7': 'Sing 3 things you did today as a song',
      'challengeAuctionItem8': 'Mime eating noodles without any props',
      'challengeAuctionItem9': 'Make 5 funny faces and let others guess emotions',
      'challengeAuctionItem10': 'Stand on one foot for 20s while reciting a poem',
      'challengeAuctionItem11': 'Imitate an animal sound for 15s',
      'challengeAuctionItem12': 'Make up a story using 3 random words',
      'challengeAuctionItem13': 'Improvise a rhyme for the player across',
      'challengeAuctionItem14': 'Say a tongue twister in a funny accent',
      'challengeAuctionItem15': 'Mime answering a phone call nervously in slow motion',

      // Truth or Raise
      'truthRaiseRule': 'Answer resets raise; skip adds +1 raise and penalty',
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
      'truthRaiseQuestion13': 'Whose chat history would you least want exposed?',
      'truthRaiseQuestion14': 'When was the last time you cried and why?',
      'truthRaiseQuestion15': 'What is your biggest regret?',
      'truthRaiseQuestion16': 'What category of app do you have most of?',
      'truthRaiseQuestion17': 'What are you worst at?',
      'truthRaiseQuestion18': 'What was your dumbest childhood idea?',
      'truthRaiseQuestion19': 'Describe the player on your right in one word',
      'truthRaiseQuestion20': 'What is the weirdest gift you ever received?',
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
