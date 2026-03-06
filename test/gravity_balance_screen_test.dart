import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtimetool/core/haptics/haptic_service.dart';
import 'package:playtimetool/features/gravity_balance/gravity_balance_screen.dart';
import 'package:playtimetool/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('gravity balance screen shows setup controls before game starts',
      (WidgetTester tester) async {
    HapticService.setEnabled(false);
    addTearDown(() => HapticService.setEnabled(true));
    SharedPreferences.setMockInitialValues(const {
      'game_help_seen_gravity_balance': true,
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: _GravityBalanceTestApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('平衡边缘'), findsOneWidget);
    expect(find.text('惩罚预设 Penalty Preset'), findsOneWidget);
    expect(find.text('简单'), findsOneWidget);
    expect(find.text('中等'), findsOneWidget);
    expect(find.text('困难'), findsOneWidget);
    expect(find.text('开  始'), findsOneWidget);
  });
}

class _GravityBalanceTestApp extends StatelessWidget {
  const _GravityBalanceTestApp();

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
