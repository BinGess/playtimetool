import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtimetool/features/party_plus/left_right_react_screen.dart';
import 'package:playtimetool/l10n/app_localizations.dart';
import 'package:playtimetool/shared/widgets/difficulty_option_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('setup uses unified difficulty cards',
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

    expect(find.text('惩罚预设'), findsOneWidget);
    expect(find.text('简单'), findsOneWidget);
    expect(find.text('中等'), findsOneWidget);
    expect(find.text('困难'), findsOneWidget);
    expect(find.text('反转概率 20%，只会出现左右方向'), findsOneWidget);
    expect(find.text('反转概率 50%，只会出现左右方向'), findsOneWidget);
    expect(find.text('反转概率 75%，会出现上下左右四方向'), findsOneWidget);
    expect(find.text('轮次：8'), findsOneWidget);

    expect(find.byType(Slider), findsNWidgets(2));
    expect(find.byType(Switch), findsNothing);
    expect(find.byType(DifficultyOptionCard), findsNWidgets(3));
    expect(find.byType(ChoiceChip), findsNothing);

    final ruleY = tester
        .getTopLeft(
          find.text('每轮每位玩家各 1 次，含反转回合，错误或超时记罚分'),
        )
        .dy;
    final difficultyY = tester.getTopLeft(find.text('难度模式')).dy;
    final penaltyY = tester.getTopLeft(find.text('惩罚预设')).dy;
    final playersY = tester.getTopLeft(find.text('人数 4 人')).dy;
    final roundsY = tester.getTopLeft(find.text('轮次：8')).dy;

    expect(ruleY, lessThan(difficultyY));
    expect(difficultyY, lessThan(penaltyY));
    expect(penaltyY, lessThan(playersY));
    expect(playersY, lessThan(roundsY));
  });

  testWidgets('starts reaction window automatically after tapping start',
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

    await tester.tap(find.byType(ElevatedButton).first);
    await tester.pump();

    expect(find.text('等待滑动...'), findsOneWidget);
    expect(find.text('开始反应'), findsNothing);
  });

  testWidgets('round advances only after all players finish one turn',
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

    await tester.tap(find.byType(ElevatedButton).first);
    await tester.pump();
    expect(find.text('第 1 / 8 轮'), findsOneWidget);

    Future<void> finishCurrentTurn() async {
      await tester.fling(
        find.byType(AnimatedContainer),
        const Offset(320, 0),
        1500,
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, '下一位'));
      await tester.pump();
    }

    await finishCurrentTurn();
    expect(find.text('第 1 / 8 轮'), findsOneWidget);

    await finishCurrentTurn();
    expect(find.text('第 1 / 8 轮'), findsOneWidget);

    await finishCurrentTurn();
    expect(find.text('第 1 / 8 轮'), findsOneWidget);

    await finishCurrentTurn();
    expect(find.text('第 2 / 8 轮'), findsOneWidget);
  });
}
