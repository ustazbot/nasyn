import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/audio_cue_resolver.dart';
import '../i18n/app_locale.dart';
import '../i18n/app_strings.dart';
import '../prayer/prayer_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'prayer_session_screen.dart';
import 'widgets/app_bottom_nav.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  AssistanceLevel _selectedLevel = AssistanceLevel.fullRecite;

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(appLocaleProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            _ModeToggleRow(locale: locale),
            const SizedBox(height: 16),
            _AssistanceSpectrum(
              locale: locale,
              selected: _selectedLevel,
              onChanged: (level) => setState(() => _selectedLevel = level),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.all(16),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: PrayerType.values.map((type) {
                  final config = prayerConfigs[type]!;
                  return _SolatButton(
                    config: config,
                    locale: locale,
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => PrayerSessionScreen(
                          prayerType: type,
                          level: _selectedLevel,
                        ),
                      ));
                    },
                  );
                }).toList(),
              ),
            ),
            const AppBottomNav(),
          ],
        ),
      ),
    );
  }
}

class _ModeToggleRow extends StatelessWidget {
  final AppLocale locale;
  const _ModeToggleRow({required this.locale});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.accentGreen,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(
                  AppStrings.of('guidedMode', locale),
                  style: AppTextStyles.body.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Opacity(
              opacity: 0.4,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.accentBlue,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.of('visionMode', locale),
                      style: AppTextStyles.body.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      AppStrings.of('comingSoon', locale),
                      style: AppTextStyles.label.copyWith(color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistanceSpectrum extends StatelessWidget {
  final AppLocale locale;
  final AssistanceLevel selected;
  final ValueChanged<AssistanceLevel> onChanged;

  const _AssistanceSpectrum({
    required this.locale,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: AssistanceLevel.values.map((level) {
          final isSelected = level == selected;
          final label = switch (level) {
            AssistanceLevel.takbirOnly => AppStrings.of('takbirOnly', locale),
            AssistanceLevel.panduanPosisi =>
              AppStrings.of('panduanPosisi', locale),
            AssistanceLevel.fullRecite => AppStrings.of('fullRecite', locale),
          };
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(level),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accentGold : AppColors.primaryTeal,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.label.copyWith(
                      color: isSelected ? Colors.black : AppColors.lightText,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SolatButton extends StatelessWidget {
  final PrayerConfig config;
  final AppLocale locale;
  final VoidCallback onTap;

  const _SolatButton({
    required this.config,
    required this.locale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryTeal,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                config.displayName.toUpperCase(),
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '(${config.rakaatCount} ${AppStrings.of('rakaatLabel', locale)})',
                style: AppTextStyles.label,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
