import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../audio/audio_cue_resolver.dart';
import '../audio/audio_player_service.dart';
import '../guided/guided_mode_controller.dart';
import '../prayer/prayer_config.dart';
import '../prayer/prayer_state_labels.dart';
import 'session_summary_screen.dart';

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

class PrayerSessionScreen extends ConsumerWidget {
  final PrayerType prayerType;
  final AssistanceLevel level;

  const PrayerSessionScreen({
    super.key,
    required this.prayerType,
    required this.level,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (type: prayerType, level: level);
    final controller = ref.watch(guidedModeControllerProvider(args));
    final config = prayerConfigs[prayerType]!;

    if (controller.isComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => SessionSummaryScreen(
            prayerType: prayerType,
            totalRakaat: config.rakaatCount,
          ),
        ));
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text(config.displayName)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Rakaat ${controller.currentRakaat} / ${config.rakaatCount}'),
            const SizedBox(height: 16),
            Text(prayerStateLabelsBm[controller.currentState] ?? ''),
            Text(prayerStateLabelsArabic[controller.currentState] ?? ''),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.fast_rewind),
                  onPressed: controller.back,
                ),
                IconButton(
                  icon: Icon(controller.isPaused ? Icons.play_arrow : Icons.pause),
                  onPressed: controller.isPaused ? controller.resume : controller.pause,
                ),
                IconButton(
                  icon: const Icon(Icons.fast_forward),
                  onPressed: controller.next,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
