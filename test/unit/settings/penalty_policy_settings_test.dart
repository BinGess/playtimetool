import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:playtimetool/features/penalty_plugin/domain/penalty_models.dart';
import 'package:playtimetool/features/settings/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('settings exposes penalty policy defaults', () async {
    SharedPreferences.setMockInitialValues({});

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final settings = await container.read(settingsProvider.future);
    expect(settings.defaultPenaltyCountry, PenaltyCountry.cn);
    expect(settings.defaultPenaltyDifficulty, PenaltyDifficulty.normal);
    expect(settings.defaultPenaltyScale, PenaltyScale.medium);
    expect(
      settings.defaultPenaltySelectionMode,
      PenaltySelectionMode.random,
    );
  });

  test('settings reads penalty policy values from shared preferences',
      () async {
    SharedPreferences.setMockInitialValues({
      'penaltyCountry': 'us',
      'penaltyDifficulty': 'hard',
      'penaltyScale': 'wild',
      'penaltySelectionMode': 'manual',
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final settings = await container.read(settingsProvider.future);
    expect(settings.defaultPenaltyCountry, PenaltyCountry.us);
    expect(settings.defaultPenaltyDifficulty, PenaltyDifficulty.hard);
    expect(settings.defaultPenaltyScale, PenaltyScale.wild);
    expect(
      settings.defaultPenaltySelectionMode,
      PenaltySelectionMode.manual,
    );
  });

  test('settings notifier persists penalty policy updates', () async {
    SharedPreferences.setMockInitialValues({});

    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(settingsProvider.future);

    await container
        .read(settingsProvider.notifier)
        .setPenaltyCountry(PenaltyCountry.us);
    await container
        .read(settingsProvider.notifier)
        .setPenaltyDifficulty(PenaltyDifficulty.hard);
    await container
        .read(settingsProvider.notifier)
        .setPenaltyScale(PenaltyScale.wild);
    await container
        .read(settingsProvider.notifier)
        .setPenaltySelectionMode(PenaltySelectionMode.manual);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('penaltyCountry'), 'us');
    expect(prefs.getString('penaltyDifficulty'), 'hard');
    expect(prefs.getString('penaltyScale'), 'wild');
    expect(prefs.getString('penaltySelectionMode'), 'manual');
  });
}
