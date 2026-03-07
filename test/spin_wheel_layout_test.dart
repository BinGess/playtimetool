import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtimetool/features/spin_wheel/providers/spin_wheel_provider.dart';
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
    expect(find.text('Add Wheel'), findsOneWidget);
    expect(find.text('Edit Wheel'), findsOneWidget);
    expect(find.text('Penalty Preset'), findsNothing);
    expect(find.text('Start'), findsAtLeastNWidgets(1));
  });

  testWidgets('spin wheel can create a new custom template from prep view',
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

    await tester.tap(find.text('Add Wheel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Create Wheel'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('wheelTemplateNameField')),
      'Road Trip',
    );
    await tester.pump();

    await tester.tap(find.text('Create Wheel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Road Trip'), findsOneWidget);
  });

  testWidgets('spin wheel delete template path removes custom template',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(
      {'game_help_seen_spin_wheel': true},
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const _SpinWheelTestApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('Add Wheel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.enterText(
      find.byKey(const Key('wheelTemplateNameField')),
      'Road Trip',
    );
    await tester.pump();

    await tester.tap(find.text('Create Wheel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final state = container.read(spinWheelProvider);
    final templateId = state.templates
        .firstWhere((template) => template.name == 'Road Trip')
        .id;
    await container.read(spinWheelProvider.notifier).deleteTemplate(templateId);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Road Trip'), findsNothing);
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
          'Fair mode settles on the wheel\'s true stopping result. Cheat mode locks a target early and visibly pulls the wheel toward that segment during slowdown.'),
      findsOneWidget,
    );
  });

  testWidgets('spin wheel play view surfaces fair mode telemetry',
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

    await tester.tap(find.text('Start').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('True landing'), findsOneWidget);
    expect(
      find.text('Where it naturally slows down is the final result.'),
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
