import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtimetool/features/party_plus/left_right_react_screen.dart';
import 'package:playtimetool/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('setup uses simple difficulty options',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(const {
      'game_help_seen_left_right': true,
    });

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('zh'),
        supportedLocales: [Locale('zh'), Locale('en')],
        localizationsDelegates: [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: LeftRightReactScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('惩罚预设 Penalty Preset'), findsOneWidget);
    expect(find.text('简单'), findsOneWidget);
    expect(find.text('中等'), findsOneWidget);
    expect(find.text('困难'), findsOneWidget);

    expect(find.byType(Slider), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
  });
}
