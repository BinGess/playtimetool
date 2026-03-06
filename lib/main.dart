import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'core/audio/audio_service.dart';
import 'features/settings/providers/settings_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Draw app content behind system bars to avoid bottom black strip.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Immersive dark UI
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarContrastEnforced: false,
  ));

  // Init Hive for wheel configs
  await Hive.initFlutter();

  // Pre-load audio (silent fail if assets missing)
  await AudioService.initialize();

  // Prevent screen sleep globally
  WakelockPlus.enable();

  // Pre-warm settings so haptic/audio flags are applied before first game
  final container = ProviderContainer();
  await container
      .read(settingsProvider.future)
      .catchError((_) => const AppSettings());

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const App(),
    ),
  );
}
