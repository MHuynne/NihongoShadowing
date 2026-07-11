
export 'sample_audio_player_stub.dart'
    if (dart.library.html) 'sample_audio_player_web.dart'
    if (dart.library.io) 'sample_audio_player_native.dart';


abstract class SampleAudioPlayer {

  Future<void> play(List<int> mp3Bytes, {required void Function() onComplete});



  Future<void> playUrlFromTo(
    String url,
    double startSec,
    double endSec, {
    required void Function() onComplete,
  });


  Future<void> stop();


  void dispose();
}