import 'dart:async';

import 'package:flutter/services.dart';

/// Vision Mode (PRD §8.13, spike v3 PARTIAL-GO): SATU signal sahaja —
/// pengesahan SUJUD via proximity bbox pada kamera depan. Bukan classifier
/// 4-pose; qiyam/rukuk/duduk kekal dipandu Guided Mode (timing/audio).
///
/// PRINSIP: vision TIDAK BOLEH block sesi solat. Semua kegagalan
/// (tiada kamera, permission ditolak, channel error) = senyap, stream
/// kosong, Guided Mode berjalan macam biasa.
abstract class VisionSujudService {
  /// Stream perubahan state sujud: true = kepala dekat lens (sujud),
  /// false = keluar sujud.
  Stream<bool> get onSujudChanged;

  Future<void> start();
  Future<void> stop();
}

class ChannelVisionSujudService implements VisionSujudService {
  static const _method = MethodChannel('nasyn/vision');
  static const _events = EventChannel('nasyn/vision/events');

  @override
  Stream<bool> get onSujudChanged => _events
      .receiveBroadcastStream()
      .map((e) => e == true)
      .handleError((_) {}); // ralat channel = tiada event, bukan crash

  @override
  Future<void> start() async {
    try {
      await _method.invokeMethod('start');
    } catch (_) {
      // Kamera/permission gagal — vision dilumpuhkan senyap
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _method.invokeMethod('stop');
    } catch (_) {}
  }
}
