import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtimetool/features/decibel_bomb/decibel_bomb_screen.dart';
import 'package:playtimetool/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const permissionChannel = MethodChannel(
    'flutter.baseflow.com/permissions/methods',
  );
  const audioChannel = EventChannel('audio_streamer.eventChannel');

  setUp(() {
    SharedPreferences.setMockInitialValues(const {
      'game_help_seen_decibel_bomb': true,
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissionChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(audioChannel, null);
  });

  testWidgets('setup shows simplified prep content and start', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('静音校准前先准备'), findsNothing);
    expect(
      find.text('按住说话会持续充能，接力瞬间的噪音突刺也会直接引爆。'),
      findsOneWidget,
    );
    expect(
      find.text('先说明规则、选好人数和惩罚预设。点击开始后会申请麦克风并进入校准。'),
      findsNothing,
    );
    expect(find.text('人数选择'), findsOneWidget);
    expect(find.byKey(const Key('penalty-preset-card')), findsOneWidget);
    expect(find.byKey(const Key('decibel-bomb-start-button')), findsOneWidget);
  });

  testWidgets('tap start leaves setup and enters permission flow',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissionChannel, (call) async {
      switch (call.method) {
        case 'checkPermissionStatus':
          return 0;
        case 'requestPermissions':
          return <int, int>{7: 0};
      }
      return null;
    });

    await tester.pumpWidget(_buildTestApp());
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.byKey(const Key('decibel-bomb-start-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(const Key('decibel-bomb-start-button')), findsNothing);
    expect(find.text('麦克风权限未开启'), findsOneWidget);
  });

  testWidgets('single action button switches between scream and next player',
      (tester) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissionChannel, (call) async {
      switch (call.method) {
        case 'checkPermissionStatus':
          return 1;
        case 'requestPermissions':
          return <int, int>{7: 1};
      }
      return null;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockStreamHandler(
      audioChannel,
      MockStreamHandler.inline(
        onListen: (_, __) {},
      ),
    );

    await tester.pumpWidget(_buildTestApp());
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.byKey(const Key('decibel-bomb-start-button')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));

    expect(find.byKey(const Key('decibel-bomb-scream-button')), findsOneWidget);
    expect(find.byKey(const Key('decibel-bomb-next-button')), findsNothing);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('decibel-bomb-scream-button'))),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pump();

    expect(find.byKey(const Key('decibel-bomb-scream-button')), findsNothing);
    expect(find.byKey(const Key('decibel-bomb-next-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('decibel-bomb-next-button')));
    await tester.pump();

    expect(find.byKey(const Key('decibel-bomb-scream-button')), findsOneWidget);
    expect(find.byKey(const Key('decibel-bomb-next-button')), findsNothing);
  });
}

Widget _buildTestApp() {
  return const MaterialApp(
    locale: Locale('zh'),
    supportedLocales: [Locale('zh'), Locale('en')],
    localizationsDelegates: [
      AppLocalizationsDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: DecibelBombScreen(),
  );
}
