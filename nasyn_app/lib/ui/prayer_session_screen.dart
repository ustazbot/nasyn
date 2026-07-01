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

class PrayerSessionScreen extends ConsumerStatefulWidget {
  final PrayerType prayerType;
  final AssistanceLevel level;

  const PrayerSessionScreen({
    super.key,
    required this.prayerType,
    required this.level,
  });

  @override
  ConsumerState<PrayerSessionScreen> createState() => _PrayerSessionScreenState();
}

class _PrayerSessionScreenState extends ConsumerState<PrayerSessionScreen> {
  bool _hasNavigated = false;

  @override
  Widget build(BuildContext context) {
    final args = (type: widget.prayerType, level: widget.level);
    final controller = ref.watch(guidedModeControllerProvider(args));
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
