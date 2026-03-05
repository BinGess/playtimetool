import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtimetool/features/penalty_plugin/domain/penalty_models.dart';
import 'package:playtimetool/features/penalty_plugin/presentation/penalty_picker_sheet.dart';
import 'package:playtimetool/l10n/app_localizations.dart';

void main() {
  testWidgets('penalty picker supports random and manual selection', (
    tester,
  ) async {
    final items = [
      const PenaltyItem(
        id: 'p1',
        country: PenaltyCountry.cn,
        difficulty: PenaltyDifficulty.easy,
        scale: PenaltyScale.light,
        kind: PenaltyKind.clean,
        textKey: 'Penalty 1',
      ),
      const PenaltyItem(
        id: 'p2',
        country: PenaltyCountry.cn,
        difficulty: PenaltyDifficulty.normal,
        scale: PenaltyScale.medium,
        kind: PenaltyKind.clean,
        textKey: 'Penalty 2',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('zh')],
        home: Scaffold(
          body: PenaltyPickerSheet(
            candidates: items,
            selected: items.first,
            random: Random(1),
            labelBuilder: (item) => item.textKey,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Random'), findsOneWidget);
    await tester.tap(find.byKey(const Key('penalty-random-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('penalty-selected-item')), findsOneWidget);

    await tester.tap(find.byKey(const Key('penalty-choose-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('penalty-item-list')), findsOneWidget);
  });
}
