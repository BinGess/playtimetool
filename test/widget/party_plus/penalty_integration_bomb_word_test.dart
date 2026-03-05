import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtimetool/features/party_plus/bomb_pass_screen.dart';
import 'package:playtimetool/features/party_plus/word_chain_bomb_screen.dart';
import 'package:playtimetool/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('bomb pass result opens penalty picker after explosion', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'game_help_seen_pass_bomb': true,
    });

    await tester.pumpWidget(_buildHost(const BombPassScreen()));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Pass bomb'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 15));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('open-penalty-picker')), findsOneWidget);
    await tester.tap(find.byKey(const Key('open-penalty-picker')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('penalty-choose-button')), findsOneWidget);
  });

  testWidgets('word bomb result opens penalty picker after explosion', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'game_help_seen_word_bomb': true,
    });

    await tester.pumpWidget(_buildHost(const WordChainBombScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start timer'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 21));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('open-penalty-picker')), findsOneWidget);
    await tester.tap(find.byKey(const Key('open-penalty-picker')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('penalty-choose-button')), findsOneWidget);
  });
}

Widget _buildHost(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('zh')],
      home: child,
    ),
  );
}
