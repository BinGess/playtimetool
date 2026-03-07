import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:playtimetool/features/splash/splash_screen.dart';
import 'package:playtimetool/l10n/app_localizations.dart';
import 'package:playtimetool/shared/widgets/neon_text.dart';

void main() {
  testWidgets('Splash shows localized zh copy and redirects after 1 second',
      (WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const SplashScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(
            body: Center(
              child: Text('hub-home'),
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        locale: const Locale('zh'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
    await tester.pump();

    expect(_findNeonText('指尖聚会'), findsOneWidget);
    expect(find.text('让聚会更加欢乐'), findsOneWidget);
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('hub-home'), findsNothing);

    await tester.pump(const Duration(milliseconds: 999));
    expect(find.text('hub-home'), findsNothing);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('hub-home'), findsOneWidget);
  });

  testWidgets('Splash title follows locale for english and japanese',
      (WidgetTester tester) async {
    Future<void> pumpForLocale(Locale locale) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, __) => const SplashScreen(),
          ),
          GoRoute(
            path: '/home',
            builder: (_, __) => const SizedBox.shrink(),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
      );
      await tester.pump();
    }

    await pumpForLocale(const Locale('en'));
    expect(_findNeonText('Finger Party'), findsOneWidget);
    expect(find.text('Make every party more fun'), findsOneWidget);

    await pumpForLocale(const Locale('ja'));
    expect(_findNeonText('フィンガーパーティー'), findsOneWidget);
    expect(find.text('パーティーをもっと楽しく'), findsOneWidget);
  });
}

Finder _findNeonText(String text) {
  return find.byWidgetPredicate(
    (widget) => widget is NeonText && widget.text == text,
  );
}
