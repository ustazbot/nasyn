import 'dart:async';

import 'package:nasyn_app/vision/vision_sujud_service.dart';

class FakeVisionService implements VisionSujudService {
  final _controller = StreamController<bool>.broadcast(sync: true);
  bool started = false;
  bool stopped = false;

  @override
  Stream<bool> get onSujudChanged => _controller.stream;

  @override
  Future<void> start() async => started = true;

  @override
  Future<void> stop() async => stopped = true;

  void emitSujud(bool sujud) => _controller.add(sujud);
}
