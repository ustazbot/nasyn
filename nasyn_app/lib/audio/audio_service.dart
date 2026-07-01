abstract class AudioService {
  Future<void> play(String assetPath);
  Future<void> stop();
  Stream<void> get onComplete;
}
