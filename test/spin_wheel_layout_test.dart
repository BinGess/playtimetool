import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtimetool/features/spin_wheel/spin_wheel_screen.dart';
import 'package:playtimetool/l10n/app_localizations.dart';
import 'package:playtimetool/shared/services/penalty_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('spin wheel shows a preparation view with visible settings',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(
      {'game_help_seen_spin_wheel': true},
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: _SpinWheelTestApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Get ready before spinning'), findsOneWidget);
    expect(find.text('Best with up to 6 players'), findsOneWidget);
    expect(find.text('Penalty Preset'), findsOneWidget);
    expect(find.text('Start'), findsAtLeastNWidgets(1));
  });

  testWidgets('spin wheel result details show selected color and penalty box',
      (WidgetTester tester) async {
    const blindBox = PenaltyBlindBoxResult(
      losers: <String>['Pizza'],
      cards: <PenaltyBlindBoxCard>[
        PenaltyBlindBoxCard(
          entry: PenaltyEntry(
            id: 'card1',
            scene: PenaltyScene.home,
            level: PenaltyLevel.level1,
            category: PenaltyCategory.physical,
            text: 'Do 10 squats',
          ),
        ),
        PenaltyBlindBoxCard(
          entry: PenaltyEntry(
            id: 'card2',
            scene: PenaltyScene.home,
            level: PenaltyLevel.level2,
            category: PenaltyCategory.social,
            text: 'Sing a chorus',
          ),
        ),
        PenaltyBlindBoxCard(
          entry: PenaltyEntry(
            id: 'card3',
            scene: PenaltyScene.home,
            level: PenaltyLevel.level3,
            category: PenaltyCategory.truth,
            text: 'Change your avatar',
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SpinWheelResultDetails(
            optionLabel: 'Pizza',
            selectedColor: Color(0xFFFF4444),
            blindBoxResult: blindBox,
          ),
        ),
        locale: Locale('en'),
        supportedLocales: [Locale('zh'), Locale('en')],
        localizationsDelegates: [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
    await tester.pump();

    expect(find.text('Selected color'), findsOneWidget);
    expect(find.text('#FF4444'), findsOneWidget);
    expect(find.text('Blind Box Penalty'), findsOneWidget);
  });
}

class _SpinWheelTestApp extends StatelessWidget {
  const _SpinWheelTestApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SpinWheelScreen(),
      locale: Locale('en'),
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
