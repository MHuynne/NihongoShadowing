// Entry point — Flutter sẽ tự chọn đúng implementation theo platform
export 'sample_audio_player_stub.dart'
    if (dart.library.html) 'sample_audio_player_web.dart'
    if (dart.library.io) 'sample_audio_player_native.dart';

/// Abstract interface cho cả hai platform
abstract class SampleAudioPlayer {
  /// Phát audio từ bytes MP3. Gọi [onComplete] khi xong.
  Future<void> play(List<int> mp3Bytes, {required void Function() onComplete});

  /// Dừng phát
  Future<void> stop();

  /// Giải phóng tài nguyên
  void dispose();
}
