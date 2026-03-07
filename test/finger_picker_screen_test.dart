import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtimetool/features/finger_picker/finger_picker_screen.dart';
import 'package:playtimetool/features/finger_picker/models/finger_state.dart';
import 'package:playtimetool/features/finger_picker/providers/finger_picker_provider.dart';
import 'package:playtimetool/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('setup top bar keeps winner chip and help button aligned',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(const {
      'game_help_seen_finger_picker': true,
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('zh'),
          supportedLocales: [Locale('zh'), Locale('en')],
          localizationsDelegates: [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: FingerPickerScreen(),
        ),
      ),
    );

    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find
          .byKey(const Key('finger-picker-top-help-button'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }

    final countChip = find.text('选 1 人');
    final helpButton = find.byKey(const Key('finger-picker-top-help-button'));

    expect(countChip, findsOneWidget);
    expect(helpButton, findsOneWidget);

    final chipRect = tester.getRect(countChip);
    final helpRect = tester.getRect(helpButton);

    expect((chipRect.center.dy - helpRect.center.dy).abs(), lessThan(10));
    expect(chipRect.top, lessThan(120));
    expect(helpRect.top, lessThan(120));
  });

  testWidgets('ninth finger shows snackbar without resetting the game',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(const {
      'game_help_seen_finger_picker': true,
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final subscription = container.listen<FingerPickerState>(
      fingerPickerProvider,
      (_, __) {},
    );
    addTearDown(subscription.close);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: ThemeData(platform: TargetPlatform.iOS),
          locale: const Locale('zh'),
          supportedLocales: const [Locale('zh'), Locale('en')],
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const FingerPickerScreen(),
        ),
      ),
    );

    final notifier = container.read(fingerPickerProvider.notifier);
    notifier.startGame();
    await tester.pump();

    for (int i = 1; i <= kMaxFingerPlayers; i++) {
      notifier.addFinger(i, Offset(i * 24.0, 160));
    }
    await tester.pump();

    notifier.addFinger(99, const Offset(320, 320));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('本局游戏最多支持8人'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);

    final state = container.read(fingerPickerProvider);
    expect(state.phase, PickerPhase.waiting);
    expect(state.fingers.length, kMaxFingerPlayers);
    expect(state.fingers.containsKey(99), isFalse);

    notifier.reset();
    await tester.pump();
  });

  testWidgets('iphone shows five-player limit copy and blocks sixth finger',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(const {
      'game_help_seen_finger_picker': true,
    });
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final subscription = container.listen<FingerPickerState>(
      fingerPickerProvider,
      (_, __) {},
    );
    addTearDown(subscription.close);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('zh'),
          supportedLocales: [Locale('zh'), Locale('en')],
          localizationsDelegates: [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: FingerPickerScreen(
            forcedMaxPlayers: kIPhoneMaxFingerPlayers,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();

    expect(
      container.read(fingerPickerProvider).maxPlayers,
      kIPhoneMaxFingerPlayers,
    );

    final notifier = container.read(fingerPickerProvider.notifier);
    notifier.startGame();
    await tester.pump();

    for (int i = 1; i <= 5; i++) {
      notifier.addFinger(i, Offset(i * 24.0, 160));
    }
    await tester.pump();

    notifier.addFinger(99, const Offset(320, 320));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('本局游戏最多支持5人'), findsOneWidget);

    final state = container.read(fingerPickerProvider);
    expect(state.maxPlayers, kIPhoneMaxFingerPlayers);
    expect(state.fingers.length, kIPhoneMaxFingerPlayers);
    expect(state.fingers.containsKey(99), isFalse);

    notifier.reset();
    await tester.pump();
  });
}
