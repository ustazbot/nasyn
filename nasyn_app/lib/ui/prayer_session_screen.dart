import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../audio/audio_cue_resolver.dart';
import '../audio/audio_player_service.dart';
import '../audio/nasyn_audio.dart';
import '../guided/guided_mode_controller.dart';
import '../i18n/app_locale.dart';
import '../i18n/app_strings.dart';
import '../kiosk/session_guard.dart';
import '../prayer/prayer_config.dart';
import '../prayer/prayer_recitation_text.dart';
import '../prayer/prayer_state.dart';
import '../prayer/prayer_state_labels.dart';
import '../settings/settings_providers.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/responsive.dart';
import 'session_summary_screen.dart';

final guidedModeControllerProvider = ChangeNotifierProvider.autoDispose
    .family<GuidedModeController, ({PrayerType type, AssistanceLevel level})>((
      ref,
      args,
    ) {
      final controller = GuidedModeController(
        config: prayerConfigs[args.type]!,
        level: args.level,
        audioService: AudioPlayerService(),
        cueResolver: AudioCueResolver(),
        timing: ref.read(timingProfileProvider),
        niatCue: NasynAudio.niatBySolat[args.type],
        surahRakaat1: ref.read(surahRakaat1Provider),
        surahRakaat2: ref.read(surahRakaat2Provider),
      );
      // JANGAN ref.onDispose(controller.dispose) — ChangeNotifierProvider
      // auto-dispose notifier; manual dispose = double-dispose assert.
      return controller;
    });

const Map<PrayerState, String> _postureIconAssets = {
  PrayerState.takbiratulIhram: 'assets/images/poses/qiyam.png',
  PrayerState.qiyam: 'assets/images/poses/qiyam.png',
  PrayerState.salam:
      'assets/images/poses/duduk.png', // salam dibuat sambil duduk
  // Iktidal & qunut dibuat berdiri — guna icon qiyam
  PrayerState.iktidal: 'assets/images/poses/qiyam.png',
  PrayerState.qunut: 'assets/images/poses/qiyam.png',
  PrayerState.rukuk: 'assets/images/poses/ruku.png',
  PrayerState.sujud1: 'assets/images/poses/sujud.png',
  PrayerState.sujud2: 'assets/images/poses/sujud.png',
  PrayerState.dudukAntaraSujud: 'assets/images/poses/duduk.png',
  PrayerState.dudukTahiyatAwal: 'assets/images/poses/duduk.png',
  PrayerState.dudukTahiyatAkhir: 'assets/images/poses/duduk.png',
};

class PrayerSessionScreen extends ConsumerStatefulWidget {
  final PrayerType prayerType;
  final AssistanceLevel level;

  const PrayerSessionScreen({
    super.key,
    required this.prayerType,
    required this.level,
  });

  @override
  ConsumerState<PrayerSessionScreen> createState() =>
      _PrayerSessionScreenState();
}

class _PrayerSessionScreenState extends ConsumerState<PrayerSessionScreen> {
  bool _hasNavigated = false;

  Future<void> _confirmExit(AppLocale locale) async {
    final controller = ref.read(
      guidedModeControllerProvider((
        type: widget.prayerType,
        level: widget.level,
      )),
    );
    final wasPaused = controller.isPaused;
    if (!wasPaused) controller.pause();

    final exit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceMuted,
        title: Text(
          AppStrings.of('exitSession', locale),
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              AppStrings.of('batal', locale),
              style: AppTextStyles.label,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              AppStrings.of('ya', locale),
              style: AppTextStyles.label.copyWith(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (exit == true) {
      // PENTING: lepas semua guard SEBELUM keluar — jangan tinggal user
      // ter-pin, skrin ter-ON, atau nav bar tersembunyi.
      await SessionGuard.release();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else if (!wasPaused) {
      controller.resume();
    }
  }

  void _showRecitationSheet(String recitation) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.primaryTeal,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
          child: Text(
            recitation,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.body,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = (type: widget.prayerType, level: widget.level);
    final controller = ref.watch(guidedModeControllerProvider(args));
    final locale = ref.watch(appLocaleProvider);
    final config = prayerConfigs[widget.prayerType]!;

    if (controller.isComplete && !_hasNavigated) {
      _hasNavigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Solat selesai natural — lepas semua guard; tak perlu tunggu
        // sebab Summary masih dalam app sendiri (fire-and-forget elak
        // async gap).
        SessionGuard.release();
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => SessionSummaryScreen(
              prayerType: widget.prayerType,
              totalRakaat: config.rakaatCount,
            ),
          ),
        );
      });
    }

    final iconAsset = _postureIconAssets[controller.currentState];
    final recitation = prayerRecitationText[controller.currentState];

    // Back sistem TIDAK boleh terus keluar dari solat — mesti lalu
    // dialog confirm yang sama dengan butang X (guard release di situ).
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit(locale);
      },
      child: Scaffold(
        backgroundColor: AppColors.darkBg,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.lightText),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          config.displayName.toUpperCase(),
                          style: AppTextStyles.display.copyWith(
                            fontSize: 40 * Responsive.scale(context),
                          ),
                        ),
                      ),
                    ),
                    // Toggle bahasa — dipindah dari bottom nav (icon kecil corner)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        final current = ref.read(appLocaleProvider);
                        final next = current == AppLocale.bm
                            ? AppLocale.en
                            : AppLocale.bm;
                        ref.read(appLocaleProvider.notifier).state = next;
                        // Best-effort persist (repo tiada dalam widget test).
                        try {
                          ref.read(settingsRepositoryProvider).saveLocale(next);
                        } catch (_) {}
                      },
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.language,
                              color: AppColors.lightText,
                              size: 28,
                            ),
                            Text(
                              locale == AppLocale.bm ? 'BM' : 'EN',
                              style: AppTextStyles.label.copyWith(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Exit sesi — visual kecil, tap target kekal 48x48dp
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _confirmExit(locale),
                      child: const SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(
                          Icons.close,
                          color: AppColors.lightText,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _RakaatPillRow(
                total: config.rakaatCount,
                current: controller.currentRakaat,
              ),
              // Kontrol walkthrough dalam satu pill gelap; Pause/Play circle hijau
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(48),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      iconSize: 40,
                      icon: const Icon(
                        Icons.fast_rewind,
                        color: AppColors.lightText,
                      ),
                      onPressed: controller.back,
                    ),
                    GestureDetector(
                      onTap: controller.isPaused
                          ? controller.resume
                          : controller.pause,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: AppColors.accentGreen,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          controller.isPaused ? Icons.play_arrow : Icons.pause,
                          color: AppColors.darkBg,
                          size: 36,
                        ),
                      ),
                    ),
                    IconButton(
                      iconSize: 40,
                      icon: const Icon(
                        Icons.fast_forward,
                        color: AppColors.lightText,
                      ),
                      onPressed: controller.next,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Semasa niat pre-session main, papar penanda niat —
                    // bukan state FSM (elak user angkat takbir sebelum
                    // niat habis, rujuk PRD §10 Niat + Bersedia)
                    if (controller.isPlayingNiat) ...[
                      const Icon(
                        Icons.volume_up,
                        color: AppColors.accentGold,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            AppStrings.of('niatPlaying', locale),
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body.copyWith(
                              fontSize: 36 * Responsive.scale(context),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      // BACKLOG: ring progress indicator — rujuk design session
                      // 2 Julai 2026, bina hanya jika pilot feedback tunjuk
                      // Takbir Only mode rasa "stuck"
                      if (iconAsset != null)
                        Container(
                          width: 132,
                          height: 132,
                          decoration: const BoxDecoration(
                            color: AppColors.surfaceMuted,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Image.asset(
                              iconAsset,
                              height: 96,
                              color: AppColors.lightText,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            (locale == AppLocale.bm
                                    ? prayerStateLabelsBm
                                    : prayerStateLabelsEn)[controller
                                    .currentState] ??
                                '',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.display.copyWith(
                              fontSize: 48 * Responsive.scale(context),
                            ),
                          ),
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          prayerStateLabelsArabic[controller.currentState] ??
                              '',
                          style: AppTextStyles.body.copyWith(
                            fontSize: 36 * Responsive.scale(context),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Trigger bacaan — pill compact dengan icon buku
              GestureDetector(
                onTap: recitation == null
                    ? null
                    : () => _showRecitationSheet(recitation),
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.menu_book,
                        color: AppColors.lightText,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.of('showRecitation', locale),
                        style: AppTextStyles.label,
                      ),
                    ],
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

class _RakaatPillRow extends StatelessWidget {
  final int total;
  final int current;

  const _RakaatPillRow({required this.total, required this.current});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(total, (index) {
          final rakaatNumber = index + 1;
          // 3-state: selesai (gold) / sedang (teal) / belum (teal pudar)
          final isCurrent = rakaatNumber == current;
          final color = rakaatNumber < current
              ? AppColors.accentGold
              : isCurrent
              ? AppColors.primaryTeal
              : AppColors.surfaceMuted;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                // Border terang extra distinction untuk rakaat sedang
                border: isCurrent
                    ? Border.all(color: AppColors.accentGreen, width: 1.5)
                    : null,
              ),
              child: Center(
                child: Text(
                  '$rakaatNumber',
                  style: AppTextStyles.display.copyWith(fontSize: 32),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
