import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtimetool/core/constants/app_colors.dart';
import 'package:playtimetool/features/party_plus/gesture_duel_screen.dart';
import 'package:playtimetool/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('gesture options are large full-width bars in picking phase',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(const {
      'game_help_seen_gesture_duel': true,
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: _GestureDuelTestApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, '开始对决'));
    await tester.pumpAndSettle();

    final rockButton = find.widgetWithText(OutlinedButton, '石头');
    final paperButton = find.widgetWithText(OutlinedButton, '布');
    final scissorsButton = find.widgetWithText(OutlinedButton, '剪刀');

    expect(rockButton, findsOneWidget);
    expect(paperButton, findsOneWidget);
    expect(scissorsButton, findsOneWidget);

    final rockSize = tester.getSize(rockButton);
    final paperSize = tester.getSize(paperButton);
    final scissorsSize = tester.getSize(scissorsButton);

    expect(rockSize.width, greaterThan(500));
    expect(paperSize.width, greaterThan(500));
    expect(scissorsSize.width, greaterThan(500));
    expect(rockSize.height, greaterThanOrEqualTo(64));
    expect(paperSize.height, greaterThanOrEqualTo(64));
    expect(scissorsSize.height, greaterThanOrEqualTo(64));
  });

  testWidgets('gesture option shows tapped visual state briefly',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(const {
      'game_help_seen_gesture_duel': true,
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: _GestureDuelTestApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, '开始对决'));
    await tester.pumpAndSettle();

    final rockFinder = find.widgetWithText(OutlinedButton, '石头');
    final before = tester.widget<OutlinedButton>(rockFinder);
    final beforeColor = before.style?.backgroundColor?.resolve(<WidgetState>{});

    await tester.tap(rockFinder);
    await tester.pump(const Duration(milliseconds: 20));

    final after = tester.widget<OutlinedButton>(rockFinder);
    final afterColor = after.style?.backgroundColor?.resolve(<WidgetState>{});

    expect(afterColor, equals(AppColors.fingerCyan.withAlpha(46)));
    expect(afterColor, isNot(equals(beforeColor)));

    await tester.pump(const Duration(milliseconds: 150));
  });
}

class _GestureDuelTestApp extends StatelessWidget {
  const _GestureDuelTestApp();

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
      home: GestureDuelScreen(),
    );
  }
}
