import 'dart:async';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'sample_audio_player.dart';

/// Implementation cho Mobile/Desktop — dùng audioplayers package.
class NativeSampleAudioPlayer implements SampleAudioPlayer {
  final _player = AudioPlayer();
  StreamSubscription<void>? _completeListener;
  Timer? _segmentTimer;

  Future<void> _cancelAll() async {
    _segmentTimer?.cancel();
    _segmentTimer = null;
    await _completeListener?.cancel();
    _completeListener = null;
    await _player.stop();
  }

  @override
  Future<void> play(List<int> mp3Bytes, {required void Function() onComplete}) async {
    await _cancelAll();
    _completeListener = _player.onPlayerComplete.listen((_) => onComplete());
    final bytes = mp3Bytes is Uint8List ? mp3Bytes : Uint8List.fromList(mp3Bytes);
    await _player.play(BytesSource(bytes));
  }

  @override
  Future<void> playUrlFromTo(
    String url,
    double startSec,
    double endSec, {
    required void Function() onComplete,
  }) async {
    await _cancelAll();
    await _player.play(UrlSource(url));

    // Seek tới startSec sau khi bắt đầu phát (chờ buffer ngắn)
    if (startSec > 0) {
      await Future.delayed(const Duration(milliseconds: 300));
      await _player.seek(Duration(milliseconds: (startSec * 1000).round()));
    }

    // Nếu có endSec hợp lệ → dùng timer để dừng
    if (endSec > startSec) {
      final durMs = ((endSec - startSec) * 1000).round();
      _segmentTimer = Timer(Duration(milliseconds: durMs), () async {
        await _player.stop();
        onComplete();
      });
    } else {
      // Phát hết file → lắng nghe onPlayerComplete
      _completeListener = _player.onPlayerComplete.listen((_) => onComplete());
    }
  }

  @override
  Future<void> stop() async => _cancelAll();

  @override
  void dispose() {
    _segmentTimer?.cancel();
    _completeListener?.cancel();
    _player.dispose();
  }
}

/// Factory function
SampleAudioPlayer createSampleAudioPlayer() => NativeSampleAudioPlayer();
