// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'sample_audio_player.dart';

/// Implementation cho Flutter Web — dùng dart:html AudioElement + Blob URL.
/// Không cần audioplayers, chạy thẳng trên browser.
class WebSampleAudioPlayer implements SampleAudioPlayer {
  html.AudioElement? _audioElement;
  String? _blobUrl;

  @override
  Future<void> play(List<int> mp3Bytes, {required void Function() onComplete}) async {
    // Dừng bất kỳ audio nào đang phát
    await stop();

    // Tạo Blob URL từ bytes MP3
    final blob = html.Blob([mp3Bytes], 'audio/mpeg');
    _blobUrl = html.Url.createObjectUrlFromBlob(blob);

    _audioElement = html.AudioElement(_blobUrl);
    _audioElement!.onEnded.listen((_) {
      _revokeBlobUrl();
      onComplete();
    });
    _audioElement!.onError.listen((_) {
      _revokeBlobUrl();
      onComplete();
    });

    await _audioElement!.play();
  }

  @override
  Future<void> stop() async {
    _audioElement?.pause();
    _audioElement = null;
    _revokeBlobUrl();
  }

  void _revokeBlobUrl() {
    if (_blobUrl != null) {
      html.Url.revokeObjectUrl(_blobUrl!);
      _blobUrl = null;
    }
  }

  @override
  void dispose() {
    stop();
  }
}

/// Factory function — shadowing_screen.dart gọi cái này
SampleAudioPlayer createSampleAudioPlayer() => WebSampleAudioPlayer();
