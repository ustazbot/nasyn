import 'prayer_state.dart';

const Map<PrayerState, String> prayerStateLabelsBm = {
  PrayerState.takbiratulIhram: 'Takbiratul Ihram',
  PrayerState.qiyam: 'Berdiri (Qiyam)',
  PrayerState.rukuk: 'Rukuk',
  PrayerState.iktidal: 'Iktidal',
  PrayerState.sujud1: 'Sujud',
  PrayerState.dudukAntaraSujud: 'Duduk Antara Dua Sujud',
  PrayerState.sujud2: 'Sujud Kedua',
  PrayerState.dudukTahiyatAwal: 'Tahiyat Awal',
  PrayerState.dudukTahiyatAkhir: 'Tahiyat Akhir',
  PrayerState.salam: 'Salam',
  PrayerState.selesai: 'Selesai',
};

const Map<PrayerState, String> prayerStateLabelsArabic = {
  PrayerState.takbiratulIhram: 'تكبيرة الإحرام',
  PrayerState.qiyam: 'قيام',
  PrayerState.rukuk: 'ركوع',
  PrayerState.iktidal: 'اعتدال',
  PrayerState.sujud1: 'سجود',
  PrayerState.dudukAntaraSujud: 'جلوس بين السجدتين',
  PrayerState.sujud2: 'سجود',
  PrayerState.dudukTahiyatAwal: 'تشهد أول',
  PrayerState.dudukTahiyatAkhir: 'تشهد أخير',
  PrayerState.salam: 'سلام',
  PrayerState.selesai: '',
};
