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

          // ─── Tambah Masa (slow-down only: extra atas floor) ───
          _SectionHeader(AppStrings.of('tambahMasa', locale)),
          _ExtraTimeSlider(
            label: AppStrings.of('rukukLabel', locale),
            locale: locale,
            floor: TimingProfile.rukukFloor,
            extra: timing.rukukExtra,
            onChanged: (v) => _saveTiming(ref, timing.copyWith(rukukExtra: v)),
          ),
          _ExtraTimeSlider(
            label: AppStrings.of('iktidalLabel', locale),
            locale: locale,
            floor: TimingProfile.iktidalFloor,
            extra: timing.iktidalExtra,
            onChanged: (v) =>
                _saveTiming(ref, timing.copyWith(iktidalExtra: v)),
          ),
          _ExtraTimeSlider(
            label: AppStrings.of('sujudLabel', locale),
            locale: locale,
            floor: TimingProfile.sujudFloor,
            extra: timing.sujudExtra,
            onChanged: (v) => _saveTiming(ref, timing.copyWith(sujudExtra: v)),
          ),
          _ExtraTimeSlider(
            label: AppStrings.of('dudukLabel', locale),
            locale: locale,
            floor: TimingProfile.dudukFloor,
            extra: timing.dudukExtra,
            onChanged: (v) => _saveTiming(ref, timing.copyWith(dudukExtra: v)),
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
                  style: AppTextStyles.body.copyWith(
                    fontSize: 32,
                    color: AppColors.accentGold,
                  ),
                ),
              ),
            ),
          ),

          // ─── Tempoh Bacaan Sendiri (qiyam/tahiyat, level bukan Full
          // Recite — pilot feedback 4 Julai: manual-Next = friction) ───
          _SectionHeader(AppStrings.of('tempohBacaan', locale)),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              AppStrings.of('tempohBacaanNota', locale),
              style: AppTextStyles.label.copyWith(fontSize: 24),
            ),
          ),
          _ReadingTimeSlider(
            label: AppStrings.of('qiyamBacaanLabel', locale),
            locale: locale,
            seconds: timing.qiyamReading,
            onChanged: (v) =>
                _saveTiming(ref, timing.copyWith(qiyamReading: v)),
          ),
          _ReadingTimeSlider(
            label: AppStrings.of('tahiyatBacaanLabel', locale),
            locale: locale,
            seconds: timing.tahiyatReading,
            onChanged: (v) =>
                _saveTiming(ref, timing.copyWith(tahiyatReading: v)),
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
                  AlertMode.pembelajaran => AppStrings.of(
                    'pembelajaran',
                    locale,
                  ),
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

/// Slider "Tempoh Bacaan Sendiri" — 0 = manual (tunggu ⏩), selainnya
/// app auto-maju selepas tempoh (step 5 saat, max [TimingProfile.maxReading]).
class _ReadingTimeSlider extends StatelessWidget {
  final String label;
  final AppLocale locale;
  final int seconds;
  final ValueChanged<int> onChanged;

  const _ReadingTimeSlider({
    required this.label,
    required this.locale,
    required this.seconds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final value = seconds.clamp(0, TimingProfile.maxReading);
    final display = value == 0
        ? AppStrings.of('manualLabel', locale)
        : '$value ${AppStrings.of('saat', locale)}';
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
                    label,
                    style: AppTextStyles.body.copyWith(fontSize: 32),
                  ),
                ),
              ),
              Text(
                display,
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
              value: value.toDouble(),
              min: 0,
              max: TimingProfile.maxReading.toDouble(),
              divisions: TimingProfile.maxReading ~/ 5, // step 5 saat
              activeColor: AppColors.accentGreen,
              inactiveColor: AppColors.surfaceMuted,
              onChanged: (v) => onChanged((v / 5).round() * 5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Slider "Tambah Masa" — slow-down only. Nilai = extra saat atas
/// floor (0 = ikut floor); slider secara fizikal tak boleh bawah 0.
class _ExtraTimeSlider extends StatelessWidget {
  final String label;
  final AppLocale locale;
  final int floor;
  final int extra;
  final ValueChanged<int> onChanged;

  const _ExtraTimeSlider({
    required this.label,
    required this.locale,
    required this.floor,
    required this.extra,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final saat = AppStrings.of('saat', locale);
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
                    '$label (${AppStrings.of('asasLabel', locale)} ${floor}s)',
                    style: AppTextStyles.body.copyWith(fontSize: 32),
                  ),
                ),
              ),
              Text(
                '+$extra $saat',
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
              value: extra.clamp(0, TimingProfile.maxExtra).toDouble(),
              min: 0,
              max: TimingProfile.maxExtra.toDouble(),
              divisions: TimingProfile.maxExtra,
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
