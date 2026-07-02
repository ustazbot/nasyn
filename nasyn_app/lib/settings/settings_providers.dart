import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'settings_repository.dart';
import 'timing_profile.dart';

/// Di-override dalam main() selepas SettingsRepository.load().
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => throw UnimplementedError('override dalam main()'),
);

final timingProfileProvider =
    StateProvider<TimingProfile>((ref) => TimingProfile.defaults);

final alertModeProvider = StateProvider<AlertMode>((ref) => AlertMode.senyap);
