import 'sample_audio_player.dart';


class StubSampleAudioPlayer implements SampleAudioPlayer {
  @override
  Future<void> play(List<int> mp3Bytes, {required void Function() onComplete}) async {}

  @override
  Future<void> playUrlFromTo(
    String url,
    double startSec,
    double endSec, {
    required void Function() onComplete,
  }) async {}

  @override
  Future<void> stop() async {}

  @override
  void dispose() {}
}

SampleAudioPlayer createSampleAudioPlayer() => StubSampleAudioPlayer();