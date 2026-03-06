import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtimetool/l10n/app_localizations.dart';
import 'package:playtimetool/shared/services/penalty_service.dart';
import 'package:playtimetool/shared/widgets/penalty_blind_box_overlay.dart';

void main() {
  testWidgets('blind box overlay reveals one card and dims the others',
      (WidgetTester tester) async {
    const result = PenaltyBlindBoxResult(
      losers: <String>['玩家1'],
      cards: <PenaltyBlindBoxCard>[
        PenaltyBlindBoxCard(
          entry: PenaltyEntry(
            id: 'card1',
            scene: PenaltyScene.home,
            level: PenaltyLevel.level1,
            category: PenaltyCategory.physical,
            text: '单脚站立 30 秒',
          ),
        ),
        PenaltyBlindBoxCard(
          entry: PenaltyEntry(
            id: 'card2',
            scene: PenaltyScene.home,
            level: PenaltyLevel.level2,
            category: PenaltyCategory.social,
            text: '讲一个糗事',
          ),
        ),
        PenaltyBlindBoxCard(
          entry: PenaltyEntry(
            id: 'card3',
            scene: PenaltyScene.home,
            level: PenaltyLevel.level3,
            category: PenaltyCategory.truth,
            text: '换头像 24 小时',
          ),
        ),
      ],
    );

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
        home: Scaffold(
          body: Center(
            child: PenaltyBlindBoxOverlay(result: result),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('penalty-card-back-0')), findsOneWidget);
    expect(find.byKey(const Key('penalty-card-back-1')), findsOneWidget);
    expect(find.byKey(const Key('penalty-card-back-2')), findsOneWidget);

    await tester.tap(find.byKey(const Key('penalty-card-back-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byKey(const Key('penalty-card-front-1')), findsOneWidget);
    expect(find.byKey(const Key('penalty-card-dimmed-0')), findsOneWidget);
    expect(find.byKey(const Key('penalty-card-dimmed-2')), findsOneWidget);
    expect(find.text('讲一个糗事'), findsOneWidget);
  });
}
