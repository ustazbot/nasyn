import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../audio/audio_cue_resolver.dart';
import '../audio/nasyn_audio.dart';
import '../i18n/app_locale.dart';
import '../i18n/app_strings.dart';
import '../prayer/prayer_config.dart';
import '../settings/settings_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'prayer_session_screen.dart';

/// Pilih surah selepas Fatihah untuk rakaat 1 & 2 — Full Recite sahaja.
/// Pre-fill dari pilihan terakhir (prefs); user boleh terus tekan MULA
/// (default gandingan sunnah: Al-Kafirun / Al-Ikhlas).
class SurahSelectionScreen extends ConsumerWidget {
  final PrayerType prayerType;

  const SurahSelectionScreen({super.key, required this.prayerType});

  Future<void> _pickSurah(
    BuildContext context,
    WidgetRef ref, {
    required bool isRakaat1,
  }) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.darkBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          children: NasynAudio.surahPendek
              .map(
                (path) => SizedBox(
                  height: 64, // tap target ≥48dp
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(path),
                    child: Text(
                      NasynAudio.surahDisplayName(path),
                      style: AppTextStyles.body.copyWith(fontSize: 32),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (picked == null) return;

    final provider = isRakaat1 ? surahRakaat1Provider : surahRakaat2Provider;
    ref.read(provider.notifier).state = picked;
    // Best-effort persist (repo tiada dalam widget test).
    try {
      final repo = ref.read(settingsRepositoryProvider);
      await (isRakaat1
          ? repo.saveSurahRakaat1(picked)
          : repo.saveSurahRakaat2(picked));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(appLocaleProvider);
    final surah1 = ref.watch(surahRakaat1Provider);
    final surah2 = ref.watch(surahRakaat2Provider);
    final config = prayerConfigs[prayerType]!;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.primaryTeal,
        title: Text(
          '${config.displayName} — ${AppStrings.of('pilihSurah', locale)}',
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _SurahRow(
                label: AppStrings.of('surahRakaat1', locale),
                surahName: NasynAudio.surahDisplayName(surah1),
                onTap: () => _pickSurah(context, ref, isRakaat1: true),
              ),
              const SizedBox(height: 16),
              _SurahRow(
                label: AppStrings.of('surahRakaat2', locale),
                surahName: NasynAudio.surahDisplayName(surah2),
                onTap: () => _pickSurah(context, ref, isRakaat1: false),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 72,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accentGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => PrayerSessionScreen(
                        prayerType: prayerType,
                        level: AssistanceLevel.fullRecite,
                      ),
                    ),
                  ),
                  child: Text(
                    AppStrings.of('mula', locale),
                    style: AppTextStyles.body.copyWith(
                      fontSize: 36,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
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

class _SurahRow extends StatelessWidget {
  final String label;
  final String surahName;
  final VoidCallback onTap;

  const _SurahRow({
    required this.label,
    required this.surahName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.label.copyWith(
                fontSize: 24,
                color: AppColors.accentGreen,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      surahName,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 36,
                        color: AppColors.accentGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const Icon(
                  Icons.unfold_more,
                  color: AppColors.lightText,
                  size: 32,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
