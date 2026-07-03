import 'package:flutter/services.dart';

import 'kiosk_service.dart';
import 'session_wakelock.dart';

/// SATU pintu untuk semua guard sesi solat: screen pinning + wakelock +
/// immersive (sembunyi status/nav bar sistem supaya tiada butang boleh
/// ditekan semasa solat). acquire/release SENTIASA berpasangan — elak
/// drift antara sistem-sistem ni.
///
/// Prinsip sama macam KioskService: mana-mana guard gagal TIDAK throw
/// dan TIDAK block sesi solat.
class SessionGuard {
  SessionGuard._();

  static Future<void> acquire() async {
    await KioskService.startPinning();
    await SessionWakelock.enable();
    // Immersive sticky: nav bar hilang; swipe hanya tunjuk sementara
    // dan pinning tetap block escape.
    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } catch (_) {}
  }

  static Future<void> release() async {
    await KioskService.stopPinning();
    await SessionWakelock.disable();
    try {
      // Pulih ke default Flutter (edge-to-edge).
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } catch (_) {}
  }
}
