import 'package:flutter_test/flutter_test.dart';
import 'package:nasyn_app/prayer/prayer_state.dart';
import 'package:nasyn_app/prayer/prayer_state_labels.dart';

void main() {
  test('BM dan EN label lengkap untuk semua 12 PrayerState', () {
    for (final state in PrayerState.values) {
      expect(
        prayerStateLabelsBm[state],
        isNotNull,
        reason: 'BM label hilang untuk $state',
      );
      expect(
        prayerStateLabelsEn[state],
        isNotNull,
        reason: 'EN label hilang untuk $state',
      );
    }
  });

  test('label duduk antara sujud guna nama ringkas', () {
    expect(
      prayerStateLabelsBm[PrayerState.dudukAntaraSujud],
      'Duduk Antara Sujud',
    );
  });
}
