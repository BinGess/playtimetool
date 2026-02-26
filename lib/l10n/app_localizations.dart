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

      // Settings
      'sound': '音效',
      'soundSub': 'SOUND',
      'vibration': '震动',
      'vibrationSub': 'VIBRATION',
      'minimalMode': '极简模式',
      'minimalModeSub': 'MINIMAL MODE',
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

      'sound': 'Sound',
      'soundSub': 'SOUND',
      'vibration': 'Vibration',
      'vibrationSub': 'VIBRATION',
      'minimalMode': 'Minimal Mode',
      'minimalModeSub': 'MINIMAL MODE',
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

  String selectWinnersCount(int count) => t('selectWinnersCount', {'count': '$count'});
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
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['zh', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
