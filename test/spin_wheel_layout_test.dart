import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtimetool/features/spin_wheel/spin_wheel_screen.dart';
import 'package:playtimetool/l10n/app_localizations.dart';
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

    expect(find.text('Best with up to 6 players'), findsNothing);
    expect(find.text('Get ready before spinning'), findsNothing);
    expect(
        find.text(
            'Set the template, mode and penalties first, then kick off the wheel.'),
        findsNothing);
    expect(find.text('Wheel template'), findsOneWidget);
    expect(find.text('Mode and options'), findsOneWidget);
    expect(find.text('Fair'), findsOneWidget);
    expect(find.text('Cheat'), findsOneWidget);
    expect(find.text('Edit Wheel'), findsOneWidget);
    expect(find.text('Penalty Preset'), findsNothing);
    expect(find.text('Start'), findsAtLeastNWidgets(1));
  });

  testWidgets('spin wheel mode help dialog explains fair and cheat modes',
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

    await tester.tap(find.byKey(const Key('spinWheelModeHelpButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('What is the difference?'), findsOneWidget);
    expect(
      find.text(
          'Fair mode settles on the wheel\'s true stopping result. Cheat mode applies a bias right before reveal, making it easier to push the outcome toward a more mischievous pick.'),
      findsOneWidget,
    );
  });

  testWidgets('spin wheel result details show wheel type and selected option',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SpinWheelResultDetails(
            wheelTitle: 'Dinner',
            optionLabel: 'Sushi',
            accentColor: Color(0xFFFF4444),
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

    expect(find.text('Dinner Result'), findsOneWidget);
    expect(find.text('Wheel type'), findsOneWidget);
    expect(find.text('Dinner'), findsOneWidget);
    expect(find.text('Selected option'), findsOneWidget);
    expect(find.text('Sushi'), findsOneWidget);
    expect(find.text('Blind Box Penalty'), findsNothing);
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
