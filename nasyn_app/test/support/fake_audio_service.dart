import 'dart:async';

import 'package:nasyn_app/audio/audio_service.dart';

class FakeAudioService implements AudioService {
  final _completeController = StreamController<void>.broadcast();
  String? lastPlayedPath;

  @override
  Future<void> play(String assetPath) async {
    lastPlayedPath = assetPath;
  }

  @override
  Future<void> stop() async {}

  @override
  Stream<void> get onComplete => _completeController.stream;

  /// Test helper: simulates the current audio finishing playback.
  void completeCurrent() {
    _completeController.add(null);
  }

  @override
  void dispose() {
    _completeController.close();
  }
}
