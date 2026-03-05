import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtimetool/features/spin_wheel/spin_wheel_screen.dart';
import 'package:playtimetool/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('help button does not overlap mode toggle on top bar',
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

    final modeToggle = find.byWidgetPredicate(
      (w) =>
          w is AnimatedContainer &&
          w.padding == const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    );
    final helpIcon = find.byIcon(Icons.question_mark);

    expect(modeToggle, findsOneWidget);
    expect(helpIcon, findsOneWidget);

    final modeRect = tester.getRect(modeToggle);
    final helpRect = tester.getRect(helpIcon);
    expect(modeRect.overlaps(helpRect), isFalse);
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
