import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtimetool/features/party_plus/challenge_auction_screen.dart';
import 'package:playtimetool/features/party_plus/truth_or_raise_screen.dart';
import 'package:playtimetool/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('challenge auction result supports penalty picker actions', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'game_help_seen_challenge_auction': true,
    });

    await tester.pumpWidget(_buildHost(const ChallengeAuctionScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start auction'));
    await tester.pumpAndSettle();

    for (int i = 0; i < 4; i++) {
      await tester.tap(find.text('Confirm bid'));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('Failed'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('open-penalty-picker')), findsOneWidget);
    await tester.tap(find.byKey(const Key('open-penalty-picker')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('penalty-item-list')), findsNothing);
    expect(find.byKey(const Key('penalty-choose-button')), findsOneWidget);
  });

  testWidgets('truth raise result supports penalty picker actions',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'game_help_seen_truth_or_raise': true,
    });

    await tester.pumpWidget(_buildHost(const TruthOrRaiseScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();

    for (int i = 0; i < 8; i++) {
      await tester.tap(find.text('Skip + Raise'));
      await tester.pumpAndSettle();
    }

    expect(find.byKey(const Key('open-penalty-picker')), findsOneWidget);
    await tester.tap(find.byKey(const Key('open-penalty-picker')));
    await tester.pumpAndSettle();
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
