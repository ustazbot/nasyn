import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../audio/nasyn_audio.dart';
import 'settings_repository.dart';
import 'timing_profile.dart';

/// Di-override dalam main() selepas SettingsRepository.load().
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => throw UnimplementedError('override dalam main()'),
);

final timingProfileProvider = StateProvider<TimingProfile>(
  (ref) => TimingProfile.defaults,
);

final alertModeProvider = StateProvider<AlertMode>((ref) => AlertMode.senyap);

// Surah selepas Fatihah (Full Recite). Default = gandingan sunnah biasa;
// di-override dalam main() dengan pilihan terakhir dari prefs.
final surahRakaat1Provider = StateProvider<String>(
  (ref) => NasynAudio.alKafirun,
);
final surahRakaat2Provider = StateProvider<String>(
  (ref) => NasynAudio.alIkhlas,
);

// Vision Mode (§8.13): pengesahan SUJUD via kamera. Default OFF;
// di-override dalam main() dengan nilai dari prefs.
final visionEnabledProvider = StateProvider<bool>((ref) => false);
