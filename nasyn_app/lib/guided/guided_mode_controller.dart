import 'dart:async';

import 'package:flutter/foundation.dart';

import '../audio/audio_cue_resolver.dart';
import '../audio/audio_service.dart';
import '../audio/nasyn_audio.dart';
import '../prayer/prayer_config.dart';
import '../prayer/prayer_state.dart';
import '../prayer/prayer_state_engine.dart';
import '../settings/timing_profile.dart';
import '../vision/vision_sujud_service.dart';

const Map<PrayerState, Duration> tumaninahDurations = {
  PrayerState.rukuk: Duration(seconds: 4),
  PrayerState.iktidal: Duration(seconds: 3),
  // Sujud 4s->2s (maklum balas Bos 5 Julai: kadenz sujud terlalu lambat);
  // extra dari Settings masih boleh menambah atas floor ini
  PrayerState.sujud1: Duration(seconds: 2),
  PrayerState.sujud2: Duration(seconds: 2),
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

  /// Vision Mode (§8.13, spike v3): pengesahan SUJUD sahaja. null = tiada
  /// vision, behavior asal 100%. GATE FIQH: signal hanya dilayan semasa
  /// state sujud1/sujud2 — FSM hanya sampai ke situ selepas rukun qiyam
  /// dan rukuk dilaksana dalam urutan (dikuatkuasa PrayerStateEngine).
  final VisionSujudService? vision;

  /// Vision TIDAK BOLEH block solat: kalau sujud tak dikesan dalam tempoh
  /// ini, timer tuma'ninah bermula juga (fallback ke behavior timing asal).
  static const Duration visionWaitTimeout = Duration(seconds: 10);

  static const _sujudStates = {PrayerState.sujud1, PrayerState.sujud2};

  StreamSubscription<bool>? _visionSub;
  Timer? _visionWaitTimer;
  bool _sujudDetected = false;

  /// Bukan-null hanya semasa menunggu detection sujud untuk mula
  /// tuma'ninah (state sujud1/sujud2 sahaja) — inilah gate fiqh dalam kod.
  void Function()? _pendingTumaninahArm;

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
    this.vision,
  }) : engine = PrayerStateEngine(config),
       _timing = (timing ?? TimingProfile.defaults).clamped() {
    if (vision != null) {
      vision!.start();
      _visionSub = vision!.onSujudChanged.listen(_onSujudChanged);
    }
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

  void _onSujudChanged(bool sujud) {
    _sujudDetected = sujud;
    if (sujud && _pendingTumaninahArm != null && !_isPaused) {
      _visionWaitTimer?.cancel();
      final arm = _pendingTumaninahArm!;
      _pendingTumaninahArm = null;
      arm();
    }
  }

  void _enterState() {
    _isPlayingNiat = false;
    _timer?.cancel();
    _audioCompleteSub?.cancel();
    _visionWaitTimer?.cancel();
    _pendingTumaninahArm = null;

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
        // level lain: cue main tapi tak jadi gate advance.
        _playSequence(cues, isFullRecite ? _autoAdvance : () {});
      }
      if (!isFullRecite) {
        // Tempoh Bacaan Sendiri dari Settings (pilot feedback 4 Julai:
        // manual-Next pada setiap qiyam/tahiyat = friction). null/0 =
        // manual (tunggu ⏩, behavior asal); ⏩ sentiasa boleh maju awal.
        final reading = _timing.readingDurationFor(engine.currentState);
        if (reading != null) _timer = Timer(reading, _autoAdvance);
      }
      return;
    }

    // Fixed-posture states. Durasi efektif = floor + extra Settings.
    // Dual-gate untuk SEMUA level bila ada cue: tunggu tumaninah floor DAN
    // audio habis — elak cue panjang (cth. iktidal 7s > floor 3s) terpotong.
    final duration = tumaninah[engine.currentState]!;
    if (cues.isNotEmpty) {
      var tumaninahElapsed = false;
      var audioCompleted = false;
      _armTumaninah(duration, () {
        tumaninahElapsed = true;
        if (audioCompleted) _autoAdvance();
      });
      _playSequence(cues, () {
        audioCompleted = true;
        if (tumaninahElapsed) _autoAdvance();
      });
    } else {
      _armTumaninah(duration, _autoAdvance);
    }
  }

  /// Vision-confirm SUJUD (§8.13): pada sujud1/sujud2 dengan vision aktif,
  /// timer tuma'ninah bermula bila sujud DIKESAN (kepala sampai ke lantai),
  /// bukan bila state bertukar — pengguna lambat turun tak "tertinggal".
  /// Fallback [visionWaitTimeout] jamin vision tak pernah block solat.
  /// State lain / tiada vision: timer terus bermula (behavior asal).
  void _armTumaninah(Duration duration, void Function() onDone) {
    final visionGated =
        vision != null && _sujudStates.contains(engine.currentState);
    if (!visionGated || _sujudDetected) {
      _timer = Timer(duration, onDone);
      return;
    }
    _pendingTumaninahArm = () {
      _timer = Timer(duration, onDone);
    };
    _visionWaitTimer = Timer(visionWaitTimeout, () {
      final arm = _pendingTumaninahArm;
      _pendingTumaninahArm = null;
      arm?.call();
    });
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
    _visionWaitTimer?.cancel();
    _pendingTumaninahArm = null;
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
    _visionWaitTimer?.cancel();
    _visionSub?.cancel();
    vision?.stop();
    audioService.dispose();
    super.dispose();
  }
}
