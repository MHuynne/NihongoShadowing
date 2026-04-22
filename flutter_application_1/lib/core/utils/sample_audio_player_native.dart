import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'sample_audio_player.dart';

/// Implementation cho Mobile/Desktop — dùng audioplayers package.
class NativeSampleAudioPlayer implements SampleAudioPlayer {
  final _player = AudioPlayer();
  bool _listenerAttached = false;

  @override
  Future<void> play(List<int> mp3Bytes, {required void Function() onComplete}) async {
    await stop();

    if (!_listenerAttached) {
      _player.onPlayerComplete.listen((_) => onComplete());
      _listenerAttached = true;
    }

    // BytesSource cần Uint8List
    final bytes = mp3Bytes is Uint8List ? mp3Bytes : Uint8List.fromList(mp3Bytes);
    await _player.play(BytesSource(bytes));
  }

  @override
  Future<void> stop() async {
    await _player.stop();
  }

  @override
  void dispose() {
    _player.dispose();
  }
}

/// Factory function
SampleAudioPlayer createSampleAudioPlayer() => NativeSampleAudioPlayer();
