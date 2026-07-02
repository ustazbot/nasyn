import 'package:flutter/services.dart';

/// Basic screen pinning (startLockTask/stopLockTask) — bukan Device Owner.
/// Semua method selamat dipanggil bila-bila: gagal = false, tak pernah
/// throw, sebab pinning gagal tak boleh block sesi solat.
class KioskService {
  KioskService._();

  static const _channel = MethodChannel('nasyn/kiosk');

  static Future<bool> startPinning() => _invoke('startPinning');

  static Future<bool> stopPinning() => _invoke('stopPinning');

  static Future<bool> isPinned() => _invoke('isPinned');

  static Future<bool> _invoke(String method) async {
    try {
      return await _channel.invokeMethod<bool>(method) ?? false;
    } catch (_) {
      // PlatformException / MissingPluginException (widget test) — abaikan.
      return false;
    }
  }
}
