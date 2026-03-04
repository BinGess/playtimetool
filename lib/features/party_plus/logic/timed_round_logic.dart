import 'dart:math';

class TimedHolderRound {
  const TimedHolderRound({
    required this.holderIndex,
    required this.durationSeconds,
  });

  final int holderIndex;
  final int durationSeconds;
}

TimedHolderRound createTimedHolderRound({
  required int playerCount,
  required int minDuration,
  required int maxDuration,
  required Random random,
}) {
  if (playerCount <= 0) {
    throw ArgumentError('playerCount must be positive');
  }
  if (maxDuration < minDuration) {
    throw ArgumentError('maxDuration must be >= minDuration');
  }

  final duration = minDuration + random.nextInt(maxDuration - minDuration + 1);
  final holderIndex = random.nextInt(playerCount);

  return TimedHolderRound(
    holderIndex: holderIndex,
    durationSeconds: duration,
  );
}

String pickRandomWord(List<String> words, Random random) {
  if (words.isEmpty) {
    throw ArgumentError('words must not be empty');
  }
  return words[random.nextInt(words.length)];
}
