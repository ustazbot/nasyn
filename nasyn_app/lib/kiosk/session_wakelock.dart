import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Skrin kekal ON semasa Prayer Session. Enable/disable SENTIASA
/// dipanggil di titik yang sama dengan KioskService start/stopPinning —
/// jangan cipta hook point berasingan, elak drift antara dua sistem.
///
/// Prinsip sama macam KioskService: gagal tak pernah throw, log sahaja
/// — wakelock gagal tak boleh block sesi solat.
class SessionWakelock {
  SessionWakelock._();

  static Future<void> enable() => _guard(() => WakelockPlus.enable());

  static Future<void> disable() => _guard(() => WakelockPlus.disable());

  static Future<void> _guard(Future<void> Function() op) async {
    try {
      await op();
    } catch (e) {
      // PlatformException / MissingPluginException (widget test) — log je.
      debugPrint('SessionWakelock gagal (diabaikan): $e');
    }
  }
}
