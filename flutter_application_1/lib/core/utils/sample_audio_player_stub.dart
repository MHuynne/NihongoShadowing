import 'sample_audio_player.dart';

/// Stub — không bao giờ được dùng thực tế (chỉ để Dart analyzer vui)
class StubSampleAudioPlayer implements SampleAudioPlayer {
  @override
  Future<void> play(List<int> mp3Bytes, {required void Function() onComplete}) async {}

  @override
  Future<void> stop() async {}

  @override
  void dispose() {}
}

SampleAudioPlayer createSampleAudioPlayer() => StubSampleAudioPlayer();
