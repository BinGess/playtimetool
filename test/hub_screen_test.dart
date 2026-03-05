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
  testWidgets('Hub shows top-right settings icon and cover on each game card',
      (WidgetTester tester) async {
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
    final visibleCovers =
        find.byKey(const Key('game-card-cover')).evaluate().length;
    expect(visibleCards, greaterThan(0));
    expect(visibleCovers, visibleCards);

    final settingsRect =
        tester.getRect(find.byKey(const Key('hub-settings-button')));
    expect(settingsRect.top, lessThan(120));
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HubScreen(),
      supportedLocales: const [Locale('zh'), Locale('en')],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
