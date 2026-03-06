import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtimetool/features/party_plus/bio_detector_screen.dart';
import 'package:playtimetool/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
      'shows hold-to-start prompt and enters initializing on long press',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(const {
      'game_help_seen_bio_detector': true,
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
        home: BioDetectorScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('惩罚预设 Penalty Preset'), findsOneWidget);
    expect(find.text('长按开始检测'), findsOneWidget);

    await tester.longPress(find.byKey(const Key('bio-detector-fingerprint')));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Initializing Bio-Link...'), findsOneWidget);
  });
}
