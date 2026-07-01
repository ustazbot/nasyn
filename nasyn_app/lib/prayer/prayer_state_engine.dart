import 'prayer_config.dart';
import 'prayer_state.dart';

class PrayerStateEngine {
  final PrayerConfig config;
  PrayerState currentState;
  int currentRakaat;

  PrayerStateEngine(this.config)
      : currentState = PrayerState.takbiratulIhram,
        currentRakaat = 1;

  static const List<PrayerState> _postureSequence = [
    PrayerState.qiyam,
    PrayerState.rukuk,
    PrayerState.iktidal,
    PrayerState.sujud1,
    PrayerState.dudukAntaraSujud,
    PrayerState.sujud2,
  ];

  bool get isComplete => currentState == PrayerState.selesai;

  /// Computes and applies the next state. No pose input — Guided Mode's
  /// sequence is fully determined by prayer type + current rakaat.
  void advance() {
    switch (currentState) {
      case PrayerState.takbiratulIhram:
        currentState = PrayerState.qiyam;
        return;
      case PrayerState.qiyam:
      case PrayerState.rukuk:
      case PrayerState.iktidal:
      case PrayerState.sujud1:
      case PrayerState.dudukAntaraSujud:
        currentState =
            _postureSequence[_postureSequence.indexOf(currentState) + 1];
        return;
      case PrayerState.sujud2:
        _advanceFromSujud2();
        return;
      case PrayerState.dudukTahiyatAwal:
        currentRakaat += 1;
        currentState = PrayerState.qiyam;
        return;
      case PrayerState.dudukTahiyatAkhir:
        currentState = PrayerState.salam;
        return;
      case PrayerState.salam:
        currentState = PrayerState.selesai;
        return;
      case PrayerState.selesai:
        return;
    }
  }

  void _advanceFromSujud2() {
    if (currentRakaat == config.tahiyatAwalAfterRakaat) {
      currentState = PrayerState.dudukTahiyatAwal;
    } else if (currentRakaat == config.rakaatCount) {
      currentState = PrayerState.dudukTahiyatAkhir;
    } else {
      currentRakaat += 1;
      currentState = PrayerState.qiyam;
    }
  }

  /// Steps back one state, for the guide walkthrough's Back control.
  void previous() {
    switch (currentState) {
      case PrayerState.takbiratulIhram:
        return;
      case PrayerState.qiyam:
        if (currentRakaat == 1) {
          currentState = PrayerState.takbiratulIhram;
        } else if (currentRakaat - 1 == config.tahiyatAwalAfterRakaat) {
          currentRakaat -= 1;
          currentState = PrayerState.dudukTahiyatAwal;
        } else {
          currentRakaat -= 1;
          currentState = PrayerState.sujud2;
        }
        return;
      case PrayerState.rukuk:
        currentState = PrayerState.qiyam;
        return;
      case PrayerState.iktidal:
        currentState = PrayerState.rukuk;
        return;
      case PrayerState.sujud1:
        currentState = PrayerState.iktidal;
        return;
      case PrayerState.dudukAntaraSujud:
        currentState = PrayerState.sujud1;
        return;
      case PrayerState.sujud2:
        currentState = PrayerState.dudukAntaraSujud;
        return;
      case PrayerState.dudukTahiyatAwal:
        currentState = PrayerState.sujud2;
        return;
      case PrayerState.dudukTahiyatAkhir:
        currentState = PrayerState.sujud2;
        return;
      case PrayerState.salam:
        currentState = PrayerState.dudukTahiyatAkhir;
        return;
      case PrayerState.selesai:
        currentState = PrayerState.salam;
        return;
    }
  }
}
