import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../audio/audio_cue_resolver.dart';
import '../audio/audio_player_service.dart';
import '../guided/guided_mode_controller.dart';
import '../i18n/app_locale.dart';
import '../i18n/app_strings.dart';
import '../prayer/prayer_config.dart';
import '../prayer/prayer_recitation_text.dart';
import '../prayer/prayer_state.dart';
import '../prayer/prayer_state_labels.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'session_summary_screen.dart';
import 'widgets/app_bottom_nav.dart';

final guidedModeControllerProvider = ChangeNotifierProvider.autoDispose
    .family<GuidedModeController, ({PrayerType type, AssistanceLevel level})>(
  (ref, args) {
    final controller = GuidedModeController(
      config: prayerConfigs[args.type]!,
      level: args.level,
      audioService: AudioPlayerService(),
      cueResolver: AudioCueResolver(),
    );
    ref.onDispose(controller.dispose);
    return controller;
  },
);

const Map<PrayerState, String> _postureIconAssets = {
  PrayerState.takbiratulIhram: 'assets/images/poses/qiyam.png',
  PrayerState.qiyam: 'assets/images/poses/qiyam.png',
  PrayerState.salam: 'assets/images/poses/qiyam.png',
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
        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => SessionSummaryScreen(
            prayerType: widget.prayerType,
            totalRakaat: config.rakaatCount,
          ),
        ));
      });
    }

    final iconAsset = _postureIconAssets[controller.currentState];
    final recitation = prayerRecitationText[controller.currentState];

    return Scaffold(
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
                    child: Text(
                      config.displayName.toUpperCase(),
                      style: AppTextStyles.display.copyWith(fontSize: 40),
                    ),
                  ),
                  // Toggle bahasa — dipindah dari bottom nav (icon kecil corner)
                  GestureDetector(
                    onTap: () {
                      final current = ref.read(appLocaleProvider);
                      ref.read(appLocaleProvider.notifier).state =
                          current == AppLocale.bm ? AppLocale.en : AppLocale.bm;
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.language,
                            color: AppColors.lightText, size: 28),
                        Text(
                          locale == AppLocale.bm ? 'BM' : 'EN',
                          style: AppTextStyles.label.copyWith(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _RakaatPillRow(
              total: config.rakaatCount,
              current: controller.currentRakaat,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  iconSize: 48,
                  icon: const Icon(Icons.fast_rewind, color: AppColors.lightText),
                  onPressed: controller.back,
                ),
                IconButton(
                  iconSize: 48,
                  icon: Icon(
                    controller.isPaused ? Icons.play_arrow : Icons.pause,
                    color: AppColors.lightText,
                  ),
                  onPressed:
                      controller.isPaused ? controller.resume : controller.pause,
                ),
                IconButton(
                  iconSize: 48,
                  icon: const Icon(Icons.fast_forward, color: AppColors.lightText),
                  onPressed: controller.next,
                ),
              ],
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (iconAsset != null)
                    Image.asset(iconAsset, height: 140, color: AppColors.lightText),
                  const SizedBox(height: 16),
                  Text(
                    prayerStateLabelsBm[controller.currentState] ?? '',
                    style: AppTextStyles.display.copyWith(fontSize: 48),
                  ),
                  Text(
                    prayerStateLabelsArabic[controller.currentState] ?? '',
                    style: AppTextStyles.body,
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: recitation == null
                  ? null
                  : () => _showRecitationSheet(recitation),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  AppStrings.of('showRecitation', locale),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.label,
                ),
              ),
            ),
            const AppBottomNav(),
          ],
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
          final color = rakaatNumber < current
              ? AppColors.accentGold
              : rakaatNumber == current
                  ? AppColors.primaryTeal
                  : AppColors.primaryTeal.withValues(alpha: 0.25);
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
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
