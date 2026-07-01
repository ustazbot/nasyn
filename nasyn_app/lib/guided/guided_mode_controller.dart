import 'dart:async';

import 'package:flutter/foundation.dart';

import '../audio/audio_cue_resolver.dart';
import '../audio/audio_service.dart';
import '../prayer/prayer_config.dart';
import '../prayer/prayer_state.dart';
import '../prayer/prayer_state_engine.dart';

const Map<PrayerState, Duration> tumaninahDurations = {
  PrayerState.rukuk: Duration(seconds: 3),
  PrayerState.iktidal: Duration(seconds: 2),
  PrayerState.sujud1: Duration(seconds: 3),
  PrayerState.sujud2: Duration(seconds: 3),
  PrayerState.dudukAntaraSujud: Duration(seconds: 2),
};

class GuidedModeController extends ChangeNotifier {
  final PrayerStateEngine engine;
  final AssistanceLevel level;
  final AudioService audioService;
  final AudioCueResolver cueResolver;

  static const Duration _shortTransitionDuration = Duration(seconds: 2);
  static const _shortTransitionStates = {
    PrayerState.takbiratulIhram,
    PrayerState.salam,
  };
  static const _variableReadingStates = {
    PrayerState.qiyam,
    PrayerState.dudukTahiyatAwal,
    PrayerState.dudukTahiyatAkhir,
  };

  Timer? _timer;
  StreamSubscription<void>? _audioCompleteSub;
  bool _isPaused = false;

  bool get isPaused => _isPaused;
  PrayerState get currentState => engine.currentState;
  int get currentRakaat => engine.currentRakaat;
  bool get isComplete => engine.isComplete;

  GuidedModeController({
    required PrayerConfig config,
    required this.level,
    required this.audioService,
    required this.cueResolver,
  }) : engine = PrayerStateEngine(config) {
    _enterState();
  }

  void _enterState() {
    _timer?.cancel();
    _audioCompleteSub?.cancel();

    if (engine.currentState == PrayerState.selesai) {
      return;
    }

    final cue = cueResolver.resolve(engine.currentState, level, engine.config);
    if (cue != null) {
      audioService.play(cue);
    }

    if (_shortTransitionStates.contains(engine.currentState)) {
      if (cue != null) {
        _audioCompleteSub = audioService.onComplete.listen((_) => _autoAdvance());
      } else {
        _timer = Timer(_shortTransitionDuration, _autoAdvance);
      }
      return;
    }

    if (_variableReadingStates.contains(engine.currentState)) {
      final isFullRecite = level == AssistanceLevel.fullRecite;
      if (isFullRecite && cue != null) {
        _audioCompleteSub = audioService.onComplete.listen((_) => _autoAdvance());
      }
      // else: manual Next only, no timer/subscription armed.
      return;
    }

    // Fixed-posture states.
    final tumaninah = tumaninahDurations[engine.currentState]!;
    final isFullRecite = level == AssistanceLevel.fullRecite;
    if (isFullRecite && cue != null) {
      var tumaninahElapsed = false;
      var audioCompleted = false;
      _timer = Timer(tumaninah, () {
        tumaninahElapsed = true;
        if (audioCompleted) _autoAdvance();
      });
      _audioCompleteSub = audioService.onComplete.listen((_) {
        audioCompleted = true;
        if (tumaninahElapsed) _autoAdvance();
      });
    } else {
      _timer = Timer(tumaninah, _autoAdvance);
    }
  }

  void _autoAdvance() {
    if (_isPaused) return;
    engine.advance();
    _enterState();
    notifyListeners();
  }

  void pause() {
    _isPaused = true;
    _timer?.cancel();
    _audioCompleteSub?.cancel();
    audioService.stop();
    notifyListeners();
  }

  void resume() {
    _isPaused = false;
    _enterState();
    notifyListeners();
  }

  void back() {
    _isPaused = false;
    engine.previous();
    _enterState();
    notifyListeners();
  }

  void next() {
    _isPaused = false;
    engine.advance();
    _enterState();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioCompleteSub?.cancel();
    audioService.dispose();
    super.dispose();
  }
}
