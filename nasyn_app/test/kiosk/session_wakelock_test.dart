import 'package:flutter_test/flutter_test.dart';
import 'package:nasyn_app/kiosk/session_wakelock.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

class _FakeWakelockPlatform extends WakelockPlusPlatformInterface {
  bool isEnabled = false;

  @override
  Future<void> toggle({required bool enable}) async {
    isEnabled = enable;
  }

  @override
  Future<bool> get enabled async => isEnabled;
}

class _ThrowingWakelockPlatform extends WakelockPlusPlatformInterface {
  @override
  Future<void> toggle({required bool enable}) async {
    throw Exception('platform meletup');
  }

  @override
  Future<bool> get enabled async => false;
}

void main() {
  test('enable/disable toggle wakelock sebenar', () async {
    final fake = _FakeWakelockPlatform();
    WakelockPlusPlatformInterface.instance = fake;

    await SessionWakelock.enable();
    expect(await WakelockPlus.enabled, isTrue);

    await SessionWakelock.disable();
    expect(await WakelockPlus.enabled, isFalse);
  });

  test('platform gagal → TIDAK throw (tak boleh block sesi solat)', () async {
    WakelockPlusPlatformInterface.instance = _ThrowingWakelockPlatform();

    await expectLater(SessionWakelock.enable(), completes);
    await expectLater(SessionWakelock.disable(), completes);
  });
}
