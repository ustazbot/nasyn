import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/app_locale.dart';
import '../i18n/app_strings.dart';
import '../prayer/prayer_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'home_screen.dart';

class SessionSummaryScreen extends ConsumerWidget {
  final PrayerType prayerType;
  final int totalRakaat;

  const SessionSummaryScreen({
    super.key,
    required this.prayerType,
    required this.totalRakaat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);
    final config = prayerConfigs[prayerType]!;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                config.displayName.toUpperCase(),
                style: AppTextStyles.display,
              ),
              const SizedBox(height: 24),
              Text(
                '${AppStrings.of('rakaatCheck', locale)} $totalRakaat/$totalRakaat ✔',
                style: AppTextStyles.body,
              ),
              Text(
                '${AppStrings.of('tumaninahCheck', locale)} ✔',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                },
                child: Text(
                  AppStrings.of('selesai', locale),
                  style: AppTextStyles.body.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
