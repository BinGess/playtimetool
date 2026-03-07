import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtimetool/core/sensors/gyroscope_service.dart';
import 'package:playtimetool/features/hub/hub_screen.dart';
import 'package:playtimetool/features/hub/widgets/game_card.dart';
import 'package:playtimetool/l10n/app_localizations.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  testWidgets(
      'Hub shows top-right settings icon and locks only gravity balance',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2200));
    final testGyro = Stream<GyroscopeEvent>.value(
      GyroscopeEvent(0, 0, 0),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          gyroscopeProvider.overrideWith((ref) => testGyro),
        ],
        child: const _TestApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('hub-settings-button')), findsOneWidget);
    final visibleCards = find.byType(GameCard).evaluate().length;
    expect(visibleCards, greaterThan(0));

    final settingsRect =
        tester.getRect(find.byKey(const Key('hub-settings-button')));
    expect(settingsRect.top, lessThan(120));

    expect(find.text('Word Bomb'), findsNothing);
    expect(find.text('Challenge Auction'), findsNothing);
    expect(find.text('FINGER PICKER'), findsNothing);
    expect(find.text('Touch of fate'), findsNothing);
    expect(find.text('Gravity Balance'), findsOneWidget);
    expect(find.text('Unlock ¥1'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Decibel Bomb'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Decibel Bomb'), findsOneWidget);
    expect(find.text('Bio-Detector'), findsOneWidget);

    final numberBombOffset = tester.getTopLeft(find.text('Number Bomb'));
    final gravityBalanceOffset =
        tester.getTopLeft(find.text('Gravity Balance'));
    final passBombOffset = tester.getTopLeft(find.text('Pass Bomb'));

    expect(
      gravityBalanceOffset.dy,
      moreOrLessEquals(numberBombOffset.dy, epsilon: 1),
    );
    expect(gravityBalanceOffset.dx, greaterThan(numberBombOffset.dx));
    expect(gravityBalanceOffset.dy, lessThan(passBombOffset.dy));
    await tester.binding.setSurfaceSize(null);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      locale: Locale('en'),
      home: HubScreen(),
      supportedLocales: [Locale('zh'), Locale('en')],
      localizationsDelegates: [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
