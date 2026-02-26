enum BombPhase { setup, playing, explosion }

class BombState {
  const BombState({
    this.phase = BombPhase.setup,
    this.secretNumber = 0,
    this.minRange = 1,
    this.maxRange = 100,
    this.originalMin = 1,
    this.originalMax = 100,
    this.currentInput = '',
    this.lastGuessInvalid = false,
    this.punishmentText = '',
  });

  final BombPhase phase;
  final int secretNumber;
  final int minRange;
  final int maxRange;
  final int originalMin;
  final int originalMax;
  final String currentInput;
  final bool lastGuessInvalid;
  final String punishmentText;

  /// 0.0 = calm, 1.0 = critical
  double get pressureRatio {
    final original = originalMax - originalMin;
    if (original <= 0) return 1.0;
    final remaining = maxRange - minRange;
    return 1.0 - (remaining / original).clamp(0.0, 1.0);
  }

  bool get isCritical => (maxRange - minRange) <= 3;

  BombState copyWith({
    BombPhase? phase,
    int? secretNumber,
    int? minRange,
    int? maxRange,
    int? originalMin,
    int? originalMax,
    String? currentInput,
    bool? lastGuessInvalid,
    String? punishmentText,
  }) {
    return BombState(
      phase: phase ?? this.phase,
      secretNumber: secretNumber ?? this.secretNumber,
      minRange: minRange ?? this.minRange,
      maxRange: maxRange ?? this.maxRange,
      originalMin: originalMin ?? this.originalMin,
      originalMax: originalMax ?? this.originalMax,
      currentInput: currentInput ?? this.currentInput,
      lastGuessInvalid: lastGuessInvalid ?? this.lastGuessInvalid,
      punishmentText: punishmentText ?? this.punishmentText,
    );
  }
}

const _punishments = [
  '自罚一杯！',
  '公主抱旁边的人绕场一圈',
  '学狗叫三声',
  '给在场所有人鞠躬道歉',
  '用嘴打开一瓶饮料',
  '表演一个才艺',
  '用脚写下自己的名字',
  '用最丑表情自拍发朋友圈',
  '被在场所有人弹脑门一下',
  '给最近联系的人发一条"我爱你"',
  '唱一首歌的副歌部分',
  '单脚站立30秒',
  '学一个人走路的样子',
  '一口气说完绕口令',
];

String randomPunishment() {
  final idx = DateTime.now().millisecondsSinceEpoch % _punishments.length;
  return _punishments[idx];
}
