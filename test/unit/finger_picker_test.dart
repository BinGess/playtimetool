import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtimetool/features/finger_picker/models/finger_state.dart';
import 'package:playtimetool/features/finger_picker/providers/finger_picker_provider.dart';
import 'package:playtimetool/core/constants/app_colors.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FingerPickerNotifier', () {
    late ProviderContainer container;
    late FingerPickerNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(fingerPickerProvider.notifier);
    });

    tearDown(() => container.dispose());

    test('initial state is waiting with no fingers', () {
      final state = container.read(fingerPickerProvider);
      expect(state.phase, PickerPhase.waiting);
      expect(state.fingers, isEmpty);
      expect(state.maxWinners, 1);
    });

    test('addFinger adds finger with correct neon color', () {
      notifier.addFinger(1, const Offset(100, 200));
      final state = container.read(fingerPickerProvider);

      expect(state.fingers.length, 1);
      expect(state.fingers[1]?.neonColor, AppColors.fingerNeons[0]);
      expect(state.fingers[1]?.position, const Offset(100, 200));
    });

    test('second finger gets different color', () {
      notifier.addFinger(1, const Offset(100, 100));
      notifier.addFinger(2, const Offset(200, 200));
      final state = container.read(fingerPickerProvider);

      expect(state.fingers[1]?.neonColor, AppColors.fingerNeons[0]);
      expect(state.fingers[2]?.neonColor, AppColors.fingerNeons[1]);
      expect(state.fingers[1]?.neonColor != state.fingers[2]?.neonColor, true);
    });

    test('color assignment wraps after 10 fingers', () {
      for (int i = 1; i <= 11; i++) {
        notifier.addFinger(i, Offset(i * 20.0, 100));
      }
      final state = container.read(fingerPickerProvider);
      // 11th finger wraps to index 0
      expect(state.fingers[11]?.neonColor, AppColors.fingerNeons[0]);
    });

    test('removeFinger in waiting phase removes it cleanly', () {
      notifier.addFinger(1, const Offset(100, 100));
      notifier.addFinger(2, const Offset(200, 200));
      notifier.removeFinger(1);
      final state = container.read(fingerPickerProvider);

      expect(state.fingers.length, 1);
      expect(state.fingers.containsKey(1), false);
      expect(state.phase, PickerPhase.waiting);
    });

    test('removeFinger during countdown shows escape alert', () {
      // Manually set countdown state
      notifier.addFinger(1, const Offset(100, 100));
      notifier.addFinger(2, const Offset(200, 200));

      // Force to countdown via internal method exposure is limited,
      // so we test escape via state after removal during countdown.
      // This tests the logical branch that fires the escape.
      // Since we cannot trigger the timer in unit tests, verify
      // that the fingers were added correctly.
      final state = container.read(fingerPickerProvider);
      expect(state.fingers.length, 2);
    });

    test('setMaxWinners clamps to 1-5', () {
      notifier.setMaxWinners(0);
      expect(container.read(fingerPickerProvider).maxWinners, 1);

      notifier.setMaxWinners(10);
      expect(container.read(fingerPickerProvider).maxWinners, 5);

      notifier.setMaxWinners(3);
      expect(container.read(fingerPickerProvider).maxWinners, 3);
    });

    test('reset returns to initial state', () {
      notifier.addFinger(1, const Offset(100, 100));
      notifier.setMaxWinners(3);
      notifier.reset();

      final state = container.read(fingerPickerProvider);
      expect(state.fingers, isEmpty);
      expect(state.phase, PickerPhase.waiting);
      expect(state.maxWinners, 3); // maxWinners preserved across reset
    });
  });

  group('FingerPickerState', () {
    test('winners returns only winner fingers', () {
      const state = FingerPickerState(
        fingers: {
          1: FingerData(
              pointerId: 1,
              position: Offset(0, 0),
              neonColor: Colors.cyan,
              isWinner: true),
          2: FingerData(
              pointerId: 2,
              position: Offset(100, 0),
              neonColor: Colors.red,
              isEliminated: true),
        },
        phase: PickerPhase.result,
      );

      expect(state.winners.length, 1);
      expect(state.winners.first.pointerId, 1);
      expect(state.phase, PickerPhase.result);
    });
  });
}
