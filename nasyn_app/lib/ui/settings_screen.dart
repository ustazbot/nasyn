import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../i18n/app_locale.dart';
import '../i18n/app_strings.dart';
import '../settings/settings_providers.dart';
import '../settings/settings_repository.dart';
import '../settings/timing_profile.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _saveTiming(WidgetRef ref, TimingProfile profile) {
    final clamped = profile.clamped();
    ref.read(timingProfileProvider.notifier).state = clamped;
    try {
      ref.read(settingsRepositoryProvider).saveTimingProfile(clamped);
    } catch (_) {} // repo tiada dalam widget test — best-effort
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);
    final timing = ref.watch(timingProfileProvider);
    final alertMode = ref.watch(alertModeProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.primaryTeal,
        title: Text(AppStrings.of('setting', locale)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── Bahasa ───
          _SectionHeader(AppStrings.of('bahasa', locale)),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: AppLocale.values.map((l) {
                final isSelected = l == locale;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      ref.read(appLocaleProvider.notifier).state = l;
                      try {
                        ref.read(settingsRepositoryProvider).saveLocale(l);
                      } catch (_) {}
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accentGold
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            l == AppLocale.bm ? 'Bahasa Melayu' : 'English',
                            style: AppTextStyles.body.copyWith(
                              fontSize: 32,
                              color: isSelected
                                  ? Colors.black
                                  : AppColors.lightText,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ─── Panduan Masa ───
          _SectionHeader(AppStrings.of('panduanMasa', locale)),
          _TimingSlider(
            label: AppStrings.of('fatihah', locale),
            locale: locale,
            value: timing.fatihahSeconds,
            min: 20,
            max: 90,
            onChanged: (v) =>
                _saveTiming(ref, timing.copyWith(fatihahSeconds: v)),
          ),
          _TimingSlider(
            label: AppStrings.of('surah', locale),
            locale: locale,
            value: timing.surahSeconds,
            min: 20,
            max: 90,
            onChanged: (v) =>
                _saveTiming(ref, timing.copyWith(surahSeconds: v)),
          ),
          _TimingSlider(
            label: AppStrings.of('rukukLabel', locale),
            locale: locale,
            value: timing.rukukSeconds,
            min: TimingProfile.rukukFloor,
            max: 30,
            floorNote: true,
            onChanged: (v) =>
                _saveTiming(ref, timing.copyWith(rukukSeconds: v)),
          ),
          _TimingSlider(
            label: AppStrings.of('iktidalLabel', locale),
            locale: locale,
            value: timing.iktidalSeconds,
            min: TimingProfile.iktidalFloor,
            max: 30,
            floorNote: true,
            onChanged: (v) =>
                _saveTiming(ref, timing.copyWith(iktidalSeconds: v)),
          ),
          _TimingSlider(
            label: AppStrings.of('sujudLabel', locale),
            locale: locale,
            value: timing.sujudSeconds,
            min: TimingProfile.sujudFloor,
            max: 30,
            floorNote: true,
            onChanged: (v) =>
                _saveTiming(ref, timing.copyWith(sujudSeconds: v)),
          ),
          _TimingSlider(
            label: AppStrings.of('dudukLabel', locale),
            locale: locale,
            value: timing.dudukSeconds,
            min: TimingProfile.dudukFloor,
            max: 30,
            floorNote: true,
            onChanged: (v) =>
                _saveTiming(ref, timing.copyWith(dudukSeconds: v)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 56,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.accentGold),
              ),
              onPressed: () => _saveTiming(ref, TimingProfile.defaults),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  AppStrings.of('resetDefault', locale),
                  style: AppTextStyles.body
                      .copyWith(fontSize: 32, color: AppColors.accentGold),
                ),
              ),
            ),
          ),

          // ─── Mod Amaran ───
          _SectionHeader(AppStrings.of('modAmaran', locale)),
          RadioGroup<AlertMode>(
            groupValue: alertMode,
            onChanged: (v) {
              if (v == null) return;
              ref.read(alertModeProvider.notifier).state = v;
              try {
                ref.read(settingsRepositoryProvider).saveAlertMode(v);
              } catch (_) {}
            },
            child: Column(
              children: AlertMode.values.map((mode) {
                final label = switch (mode) {
                  AlertMode.senyap => AppStrings.of('senyap', locale),
                  AlertMode.standard => AppStrings.of('standardMode', locale),
                  AlertMode.pembelajaran =>
                    AppStrings.of('pembelajaran', locale),
                };
                return RadioListTile<AlertMode>(
                  value: mode,
                  activeColor: AppColors.accentGreen,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    label,
                    style: AppTextStyles.body.copyWith(fontSize: 32),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        text,
        style: AppTextStyles.body.copyWith(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.accentGreen,
        ),
      ),
    );
  }
}

class _TimingSlider extends StatelessWidget {
  final String label;
  final AppLocale locale;
  final int value;
  final int min;
  final int max;
  final bool floorNote;
  final ValueChanged<int> onChanged;

  const _TimingSlider({
    required this.label,
    required this.locale,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.floorNote = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    floorNote
                        ? '$label (${AppStrings.of('minLabel', locale)} ${min}s)'
                        : label,
                    style: AppTextStyles.body.copyWith(fontSize: 32),
                  ),
                ),
              ),
              Text(
                '$value ${AppStrings.of('saat', locale)}',
                style: AppTextStyles.body.copyWith(
                  fontSize: 32,
                  color: AppColors.accentGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(
            height: 48, // tap target ≥48dp
            child: Slider(
              // clamp paparan — nilai haram dari luar tak boleh crash UI
              value: value.clamp(min, max).toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: max - min,
              activeColor: AppColors.accentGreen,
              inactiveColor: AppColors.surfaceMuted,
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
        ],
      ),
    );
  }
}
