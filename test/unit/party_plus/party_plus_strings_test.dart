import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtimetool/features/party_plus/party_plus_strings.dart';
import 'package:playtimetool/l10n/app_localizations.dart';

void main() {
  testWidgets('randomPenalty respects alcohol switch', (tester) async {
    BuildContext? capturedContext;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('en'), Locale('zh')],
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
        ],
        home: Scaffold(
          body: Builder(
            builder: (context) {
              capturedContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(capturedContext, isNotNull);
    final context = capturedContext!;

    final alcoholPenalty = PartyPlusStrings.randomPenalty(
      context,
      Random(1),
      alcoholPenaltyEnabled: true,
    );
    final purePenalty = PartyPlusStrings.randomPenalty(
      context,
      Random(1),
      alcoholPenaltyEnabled: false,
    );

    final l10n = AppLocalizations.of(context);
    final alcoholPool = <String>{
      l10n.t('penaltySipOne'),
      l10n.t('penaltySipTwo'),
      l10n.t('penaltyCheersRight'),
      l10n.t('penaltyTruthOne'),
      l10n.t('penaltyMiniShot'),
    };
    final purePool = <String>{
      l10n.t('penaltySquatEight'),
      l10n.t('penaltyTongueTwister'),
      l10n.t('penaltyComplimentLeft'),
      l10n.t('penaltyPlankTen'),
      l10n.t('penaltyClapBeat'),
    };

    expect(alcoholPool.contains(alcoholPenalty), true);
    expect(purePool.contains(purePenalty), true);
  });
}
