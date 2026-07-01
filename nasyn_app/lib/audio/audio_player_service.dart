import 'package:audioplayers/audioplayers.dart';

import 'audio_service.dart';

class AudioPlayerService implements AudioService {
  final AudioPlayer _player = AudioPlayer();

  @override
  Future<void> play(String assetPath) async {
    // NasynAudio paths are declared with an 'assets/' prefix (pubspec
    // style); audioplayers' AssetSource expects that prefix stripped.
    final normalized = assetPath.startsWith('assets/')
        ? assetPath.substring('assets/'.length)
        : assetPath;
    await _player.stop();
    await _player.play(AssetSource(normalized));
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Stream<void> get onComplete => _player.onPlayerComplete;

  @override
  void dispose() => _player.dispose();
}
