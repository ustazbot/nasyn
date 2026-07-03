import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'i18n/app_locale.dart';
import 'settings/settings_providers.dart';
import 'settings/settings_repository.dart';
import 'ui/boot_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repo = await SettingsRepository.load();
  runApp(
    ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(repo),
        timingProfileProvider.overrideWith((ref) => repo.readTimingProfile()),
        alertModeProvider.overrideWith((ref) => repo.readAlertMode()),
        appLocaleProvider.overrideWith((ref) => repo.readLocale()),
        surahRakaat1Provider.overrideWith((ref) => repo.readSurahRakaat1()),
        surahRakaat2Provider.overrideWith((ref) => repo.readSurahRakaat2()),
      ],
      child: const NasynApp(),
    ),
  );
}

class NasynApp extends StatelessWidget {
  const NasynApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NASYN',
      theme: ThemeData.dark(),
      home: const BootScreen(),
    );
  }
}
