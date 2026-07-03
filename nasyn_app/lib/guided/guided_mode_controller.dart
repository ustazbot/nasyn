import 'dart:async';

import 'package:flutter/foundation.dart';

import '../audio/audio_cue_resolver.dart';
import '../audio/audio_service.dart';
import '../audio/nasyn_audio.dart';
import '../prayer/prayer_config.dart';
import '../prayer/prayer_state.dart';
import '../prayer/prayer_state_engine.dart';
import '../settings/timing_profile.dart';

const Map<PrayerState, Duration> tumaninahDurations = {
  PrayerState.rukuk: Duration(seconds: 4),
  PrayerState.iktidal: Duration(seconds: 3),
  PrayerState.sujud1: Duration(seconds: 4),
  PrayerState.sujud2: Duration(seconds: 4),
  PrayerState.dudukAntaraSujud: Duration(seconds: 3),
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
    PrayerState.qunut, // bacaan panjang, ikut tempoh audio (bukan tuma'ninah)
    PrayerState.dudukTahiyatAwal,
    PrayerState.dudukTahiyatAkhir,
  };

  Timer? _timer;
  StreamSubscription<void>? _audioCompleteSub;
  bool _isPaused = false;
  bool _isPlayingNiat = false;

  bool get isPaused => _isPaused;

  /// True semasa audio niat pre-session main — UI papar "Niat sedang
  /// dimainkan", bukan state FSM (elak user angkat takbir awal).
  bool get isPlayingNiat => _isPlayingNiat;
  PrayerState get currentState => engine.currentState;
  int get currentRakaat => engine.currentRakaat;
  bool get isComplete => engine.isComplete;

  /// Timing dari Settings; clamped() jamin extra dalam [0, maxExtra] —
  /// slow-down only, floor tumaninahDurations tak boleh dikurangkan.
  final TimingProfile _timing;

  /// Durasi tuma'ninah efektif per posture: floor + extra dari Settings.
  /// Default (tiada custom) = floor sedia ada.
  late final Map<PrayerState, Duration> tumaninah = {
    for (final state in tumaninahDurations.keys)
      state: _timing.tumaninahFor(state)!,
  };

  /// Audio niat — pre-session cue, BUKAN PrayerState. Dimain sekali di
  /// permulaan sesi; FSM mula hanya selepas audio habis (gate onComplete,
  /// bukan fixed timer — elak niat terputus atau jeda janggal).
  final String? niatCue;

  /// Surah selepas Fatihah (Full Recite, qiyam). FIQH: rakaat 1 →
  /// surahRakaat1, rakaat 2 → surahRakaat2, rakaat 3+ → Fatihah sahaja.
  final String? surahRakaat1;
  final String? surahRakaat2;

  GuidedModeController({
    required PrayerConfig config,
    required this.level,
    required this.audioService,
    required this.cueResolver,
    TimingProfile? timing,
    this.niatCue,
    this.surahRakaat1,
    this.surahRakaat2,
  }) : engine = PrayerStateEngine(config),
       _timing = (timing ?? TimingProfile.defaults).clamped() {
    if (niatCue != null && !NasynAudio.isPendingRecording(niatCue!)) {
      _isPlayingNiat = true;
      audioService.play(niatCue!);
      _audioCompleteSub = audioService.onComplete.listen((_) {
        _audioCompleteSub?.cancel();
        _enterState();
        notifyListeners();
      });
    } else {
      _enterState();
    }
  }

  void _enterState() {
    _isPlayingNiat = false;
    _timer?.cancel();
    _audioCompleteSub?.cancel();

    if (engine.currentState == PrayerState.selesai) {
      return;
    }

    final isFirstQiyamOfSession =
        engine.currentState == PrayerState.qiyam && engine.currentRakaat == 1;

    if (cueResolver.needsTakbirTransition(engine.currentState) &&
        !isFirstQiyamOfSession) {
      audioService.play(NasynAudio.takbiratulIhram);
      _audioCompleteSub = audioService.onComplete.listen((_) {
        _audioCompleteSub?.cancel();
        _playCueAndArmAdvance();
      });
    } else {
      _playCueAndArmAdvance();
    }
  }

  /// Main [cues] satu demi satu — setiap fail tunggu onComplete sendiri
  /// (Fatihah habis PENUH dulu baru surah mula, tiada overlap/cut-off).
  /// [onAllComplete] dipanggil selepas fail TERAKHIR habis.
  void _playSequence(List<String> cues, void Function() onAllComplete) {
    var index = 0;
    audioService.play(cues[index]);
    _audioCompleteSub = audioService.onComplete.listen((_) {
      index++;
      if (index < cues.length) {
        audioService.play(cues[index]);
      } else {
        _audioCompleteSub?.cancel();
        onAllComplete();
      }
    });
  }

  void _playCueAndArmAdvance() {
    final cues = cueResolver.resolve(
      engine.currentState,
      level,
      engine.config,
      currentRakaat: engine.currentRakaat,
      surahRakaat1: surahRakaat1,
      surahRakaat2: surahRakaat2,
    );

    if (_shortTransitionStates.contains(engine.currentState)) {
      if (cues.isNotEmpty) {
        _playSequence(cues, _autoAdvance);
      } else {
        _timer = Timer(_shortTransitionDuration, _autoAdvance);
      }
      return;
    }

    if (_variableReadingStates.contains(engine.currentState)) {
      final isFullRecite = level == AssistanceLevel.fullRecite;
      if (cues.isNotEmpty) {
        // Full Recite: advance selepas SEMUA dalam senarai habis;
        // level lain: cue main tapi tunggu manual Next.
        _playSequence(cues, isFullRecite ? _autoAdvance : () {});
      }
      // else: manual Next only, no timer/subscription armed.
      return;
    }

    // Fixed-posture states. Durasi efektif = floor + extra Settings.
    // Dual-gate untuk SEMUA level bila ada cue: tunggu tumaninah floor DAN
    // audio habis — elak cue panjang (cth. iktidal 7s > floor 3s) terpotong.
    final duration = tumaninah[engine.currentState]!;
    if (cues.isNotEmpty) {
      var tumaninahElapsed = false;
      var audioCompleted = false;
      _timer = Timer(duration, () {
        tumaninahElapsed = true;
        if (audioCompleted) _autoAdvance();
      });
      _playSequence(cues, () {
        audioCompleted = true;
        if (tumaninahElapsed) _autoAdvance();
      });
    } else {
      _timer = Timer(duration, _autoAdvance);
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
