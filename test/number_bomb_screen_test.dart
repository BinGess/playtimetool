import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtimetool/features/number_bomb/models/bomb_state.dart';
import 'package:playtimetool/features/number_bomb/number_bomb_screen.dart';
import 'package:playtimetool/features/number_bomb/providers/number_bomb_provider.dart';
import 'package:playtimetool/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('setup shows title and player count controls', (tester) async {
    SharedPreferences.setMockInitialValues(const {
      'game_help_seen_number_bomb': true,
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('zh'),
          supportedLocales: [Locale('zh'), Locale('en')],
          localizationsDelegates: [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: NumberBombScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('数字炸弹'), findsOneWidget);
    expect(find.text('玩家人数'), findsWidgets);
    expect(find.byKey(const Key('number-bomb-player-slider')), findsOneWidget);
  });

  testWidgets('explosion state only shows loser result text', (tester) async {
    SharedPreferences.setMockInitialValues(const {
      'game_help_seen_number_bomb': true,
    });

    final notifier = _TestNumberBombNotifier(
      const BombState(
        phase: BombPhase.explosion,
        secretNumber: 7,
        minRange: 5,
        maxRange: 8,
        originalMin: 1,
        originalMax: 10,
        playerCount: 4,
        currentPlayerIndex: 2,
        loserPlayerIndex: 2,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          numberBombProvider.overrideWith((ref) => notifier),
        ],
        child: const MaterialApp(
          locale: Locale('zh'),
          supportedLocales: [Locale('zh'), Locale('en')],
          localizationsDelegates: [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: NumberBombScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('本轮输家：玩家3'), findsOneWidget);
    expect(find.textContaining('当前玩家'), findsNothing);
    expect(find.textContaining('获胜玩家'), findsNothing);
  });
}

class _TestNumberBombNotifier extends NumberBombNotifier {
  _TestNumberBombNotifier(BombState initialState) : super(random: Random(0)) {
    state = initialState;
  }
}
