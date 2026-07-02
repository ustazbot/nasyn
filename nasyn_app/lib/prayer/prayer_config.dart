enum PrayerType { subuh, zuhur, asar, maghrib, isyak, sunat }

class PrayerConfig {
  final PrayerType type;
  final String displayName;
  final int rakaatCount;
  final int? tahiyatAwalAfterRakaat; // null = no tahiyat awal (Subuh/Sunat)
  final bool qunutEligible; // Subuh only; qunut adalah aliran lalai (default flow) untuk Subuh

  const PrayerConfig({
    required this.type,
    required this.displayName,
    required this.rakaatCount,
    required this.tahiyatAwalAfterRakaat,
    required this.qunutEligible,
  });
}

const Map<PrayerType, PrayerConfig> prayerConfigs = {
  PrayerType.subuh: PrayerConfig(
    type: PrayerType.subuh,
    displayName: 'Subuh',
    rakaatCount: 2,
    tahiyatAwalAfterRakaat: null,
    qunutEligible: true,
  ),
  PrayerType.maghrib: PrayerConfig(
    type: PrayerType.maghrib,
    displayName: 'Maghrib',
    rakaatCount: 3,
    tahiyatAwalAfterRakaat: 2,
    qunutEligible: false,
  ),
  PrayerType.zuhur: PrayerConfig(
    type: PrayerType.zuhur,
    displayName: 'Zuhur',
    rakaatCount: 4,
    tahiyatAwalAfterRakaat: 2,
    qunutEligible: false,
  ),
  PrayerType.asar: PrayerConfig(
    type: PrayerType.asar,
    displayName: 'Asar',
    rakaatCount: 4,
    tahiyatAwalAfterRakaat: 2,
    qunutEligible: false,
  ),
  PrayerType.isyak: PrayerConfig(
    type: PrayerType.isyak,
    displayName: 'Isyak',
    rakaatCount: 4,
    tahiyatAwalAfterRakaat: 2,
    qunutEligible: false,
  ),
  PrayerType.sunat: PrayerConfig(
    type: PrayerType.sunat,
    displayName: 'Sunat',
    rakaatCount: 2,
    tahiyatAwalAfterRakaat: null,
    qunutEligible: false,
  ),
};
