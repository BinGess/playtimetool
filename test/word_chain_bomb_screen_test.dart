import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtimetool/features/party_plus/word_chain_bomb_screen.dart';
import 'package:playtimetool/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows one bottom action: start game then next',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(const {
      'game_help_seen_word_bomb': true,
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: _WordBombTestApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.widgetWithText(ElevatedButton, '开始游戏'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, '下一个'), findsNothing);

    await tester.tap(find.widgetWithText(ElevatedButton, '开始游戏'));
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.widgetWithText(ElevatedButton, '开始游戏'), findsNothing);
    expect(find.widgetWithText(ElevatedButton, '下一个'), findsOneWidget);
  });
}

class _WordBombTestApp extends StatelessWidget {
  const _WordBombTestApp();

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
      home: WordChainBombScreen(),
    );
  }
}
