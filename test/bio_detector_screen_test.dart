import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtimetool/features/party_plus/bio_detector_screen.dart';
import 'package:playtimetool/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<void> pumpBioDetector(WidgetTester tester) async {
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
  }

  Future<void> advanceToResult(WidgetTester tester) async {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(seconds: 11));
    });
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets(
      'shows setup rounds slider then enters initializing after starting and long press',
      (WidgetTester tester) async {
    await pumpBioDetector(tester);

    expect(find.text('开局设置'), findsOneWidget);
    expect(find.text('BIO-SCAN'), findsOneWidget);
    expect(find.text('准备检测'), findsOneWidget);
    expect(find.text('惩罚预设'), findsOneWidget);
    expect(find.byKey(const Key('bio-detector-rounds-slider')), findsOneWidget);

    await tester.tap(find.byKey(const Key('bio-detector-start-session')));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('长按开始检测'), findsOneWidget);

    await tester.longPress(find.byKey(const Key('bio-detector-fingerprint')));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Initializing Bio-Link...'), findsOneWidget);
  });

  testWidgets('truth result keeps confidence card and removes summary block',
      (WidgetTester tester) async {
    await pumpBioDetector(tester);

    await tester.tap(find.byKey(const Key('bio-detector-start-session')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('bio-detector-force-truth')));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.longPress(find.byKey(const Key('bio-detector-fingerprint')));
    await tester.pump();
    await advanceToResult(tester);

    expect(find.text('结果可信度'), findsOneWidget);
    expect(find.text('系统判定当前陈述可信，可以继续下一轮。'), findsOneWidget);
    expect(find.textContaining('检测完成：'), findsNothing);
    expect(find.text('命运抉择'), findsNothing);
  });

  testWidgets('lie result still shows penalty blind box card',
      (WidgetTester tester) async {
    await pumpBioDetector(tester);

    await tester.tap(find.byKey(const Key('bio-detector-start-session')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('bio-detector-force-lie')));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.longPress(find.byKey(const Key('bio-detector-fingerprint')));
    await tester.pump();
    await advanceToResult(tester);

    expect(find.text('风险指数'), findsOneWidget);
    expect(find.text('命运抉择'), findsOneWidget);
    expect(find.textContaining('检测完成：'), findsNothing);
  });
}
