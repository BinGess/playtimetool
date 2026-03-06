import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtimetool/core/haptics/haptic_service.dart';
import 'package:playtimetool/features/gravity_balance/gravity_balance_prep_screen.dart';
import 'package:playtimetool/features/gravity_balance/gravity_balance_screen.dart';
import 'package:playtimetool/l10n/app_localizations.dart';
import 'package:playtimetool/shared/services/penalty_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('gravity balance prep screen owns setup controls',
      (WidgetTester tester) async {
    HapticService.setEnabled(false);
    addTearDown(() => HapticService.setEnabled(true));
    SharedPreferences.setMockInitialValues(const {
      'game_help_seen_gravity_balance': true,
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: _GravityBalancePrepTestApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('平衡边缘'), findsOneWidget);
    expect(find.text('惩罚预设 Penalty Preset'), findsOneWidget);
    expect(find.text('简单'), findsOneWidget);
    expect(find.text('中等'), findsOneWidget);
    expect(find.text('困难'), findsOneWidget);
  });

  testWidgets('gravity balance play screen does not duplicate setup UI',
      (WidgetTester tester) async {
    HapticService.setEnabled(false);
    addTearDown(() => HapticService.setEnabled(true));
    SharedPreferences.setMockInitialValues(const {
      'game_help_seen_gravity_balance': true,
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: _GravityBalancePlayTestApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('平衡边缘'), findsOneWidget);
    expect(find.text('惩罚预设 Penalty Preset'), findsNothing);
    expect(find.text('简单'), findsNothing);
    expect(find.text('中等'), findsNothing);
    expect(find.text('困难'), findsNothing);
  });

  testWidgets('gravity balance play screen accepts penalty preset from route',
      (WidgetTester tester) async {
    HapticService.setEnabled(false);
    addTearDown(() => HapticService.setEnabled(true));
    SharedPreferences.setMockInitialValues(const {
      'game_help_seen_gravity_balance': true,
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
          home: GravityBalanceScreen(
            penaltyPreset: PenaltyPreset(
              scene: PenaltyScene.bar,
              intensity: PenaltyIntensity.wild,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('平衡边缘'), findsOneWidget);
  });
}

class _GravityBalancePrepTestApp extends StatelessWidget {
  const _GravityBalancePrepTestApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      locale: Locale('zh'),
      supportedLocales: [Locale('zh'), Locale('en')],
      localizationsDelegates: [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: GravityBalancePrepScreen(),
    );
  }
}

class _GravityBalancePlayTestApp extends StatelessWidget {
  const _GravityBalancePlayTestApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      locale: Locale('zh'),
      supportedLocales: [Locale('zh'), Locale('en')],
      localizationsDelegates: [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: GravityBalanceScreen(),
    );
  }
}
