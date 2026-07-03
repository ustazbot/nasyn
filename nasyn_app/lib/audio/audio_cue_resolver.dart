import '../prayer/prayer_config.dart';
import '../prayer/prayer_state.dart';
import 'nasyn_audio.dart';

enum AssistanceLevel { takbirOnly, panduanPosisi, fullRecite }

class AudioCueResolver {
  static const Set<PrayerState> _noTakbirTransition = {
    PrayerState.takbiratulIhram, // it IS the opening takbir
    PrayerState.iktidal,          // uses its own "Sami'Allahu" cue instead
    PrayerState.qunut,            // masih berdiri iktidal — tiada takbir
    PrayerState.salam,
    PrayerState.selesai,
  };

  /// Whether a takbir (Allahu Akbar) transition cue should play before this
  /// state's own cue. True for every rukun change except the opening
  /// takbir itself, Iktidal (has its own utterance), Salam, and the
  /// terminal state.
  bool needsTakbirTransition(PrayerState state) =>
      !_noTakbirTransition.contains(state);

  /// Returns the asset paths to play in sequence for this state at this
  /// level; empty if nothing should play. [config] is accepted for future
  /// per-prayer cues — the qunut state itself only occurs when the FSM's
  /// config is qunutEligible, so no config check is needed here.
  ///
  /// FIQH RULE (qiyam, Full Recite): rakaat 1 → Fatihah + surahRakaat1,
  /// rakaat 2 → Fatihah + surahRakaat2, rakaat 3+ → Fatihah SAHAJA.
  List<String> resolve(
    PrayerState state,
    AssistanceLevel level,
    PrayerConfig config, {
    int currentRakaat = 1,
    String? surahRakaat1,
    String? surahRakaat2,
  }) {
    if (state == PrayerState.iktidal) {
      return _asList(_checkPending(NasynAudio.bacaanIktidal));
    }
    if (state == PrayerState.qiyam && level == AssistanceLevel.fullRecite) {
      final fatihah = _checkPending(NasynAudio.alFatihah);
      final surah = _checkPending(switch (currentRakaat) {
        1 => surahRakaat1,
        2 => surahRakaat2,
        _ => null, // rakaat 3/4: Fatihah sahaja, tiada surah walau apa pun
      });
      return [?fatihah, ?surah];
    }
    final path = switch (level) {
      AssistanceLevel.takbirOnly => _takbirOnlyCue(state),
      AssistanceLevel.panduanPosisi => _panduanPosisiCue(state),
      AssistanceLevel.fullRecite => _fullReciteCue(state),
    };
    return _asList(_checkPending(path));
  }

  List<String> _asList(String? path) => path == null ? const [] : [path];

  String? _checkPending(String? path) {
    if (path == null) return null;
    if (NasynAudio.isPendingRecording(path)) return null;
    return path;
  }

  String? _takbirOnlyCue(PrayerState state) {
    if (state == PrayerState.takbiratulIhram) return NasynAudio.takbiratulIhram;
    return null;
  }

  String? _panduanPosisiCue(PrayerState state) {
    switch (state) {
      case PrayerState.takbiratulIhram:
        return NasynAudio.takbiratulIhram;
      case PrayerState.rukuk:
        return NasynAudio.posisiRukuk;
      case PrayerState.sujud1:
        return NasynAudio.posisiSujud;
      case PrayerState.sujud2:
        return NasynAudio.posisiSujudKedua;
      case PrayerState.dudukAntaraSujud:
        return NasynAudio.posisiDudukDuaSujud;
      case PrayerState.dudukTahiyatAwal:
        return NasynAudio.posisiTahiyatAwal;
      case PrayerState.dudukTahiyatAkhir:
        return NasynAudio.posisiTahiyatAkhir;
      default:
        return null;
    }
  }

  String? _fullReciteCue(PrayerState state) {
    switch (state) {
      case PrayerState.takbiratulIhram:
        return NasynAudio.takbiratulIhram;
      case PrayerState.qiyam:
        return NasynAudio.alFatihah;
      case PrayerState.rukuk:
        return NasynAudio.bacaanRukuk;
      case PrayerState.sujud1:
      case PrayerState.sujud2:
        return NasynAudio.bacaanSujud;
      case PrayerState.qunut:
        return NasynAudio.qunut;
      case PrayerState.dudukAntaraSujud:
        return NasynAudio.bacaanDudukAntaraSujud;
      case PrayerState.dudukTahiyatAwal:
        return NasynAudio.tahiyatAwal;
      case PrayerState.dudukTahiyatAkhir:
        return NasynAudio.tahiyatAkhir;
      case PrayerState.salam:
        return NasynAudio.salam;
      default:
        return null;
    }
  }
}
