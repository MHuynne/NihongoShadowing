
import 'dart:async';
import 'dart:html' as html;
import 'sample_audio_player.dart';


class WebSampleAudioPlayer implements SampleAudioPlayer {
  html.AudioElement? _audioElement;
  String? _blobUrl;
  StreamSubscription? _endedSub;
  StreamSubscription? _errorSub;
  StreamSubscription? _timeUpdateSub;
  StreamSubscription? _canPlaySub;

  @override
  Future<void> play(List<int> mp3Bytes, {required void Function() onComplete}) async {
    await stop();
    final blob = html.Blob([mp3Bytes], 'audio/mpeg');
    _blobUrl = html.Url.createObjectUrlFromBlob(blob);
    _audioElement = html.AudioElement(_blobUrl);
    _endedSub = _audioElement!.onEnded.listen((_) { _revokeBlobUrl(); onComplete(); });
    _errorSub = _audioElement!.onError.listen((_) { _revokeBlobUrl(); onComplete(); });
    await _audioElement!.play();
  }

  @override
  Future<void> playUrlFromTo(
    String url,
    double startSec,
    double endSec, {
    required void Function() onComplete,
  }) async {
    await stop();
    _audioElement = html.AudioElement(url);
    _audioElement!.preload = 'auto';


    _canPlaySub = _audioElement!.onCanPlay.listen((_) {
      _canPlaySub?.cancel();
      _canPlaySub = null;
      _audioElement?.currentTime = startSec;
      _audioElement?.play();
    });

    if (endSec > startSec) {

      _timeUpdateSub = _audioElement!.onTimeUpdate.listen((_) {
        if ((_audioElement?.currentTime ?? 0) >= endSec) {
          _timeUpdateSub?.cancel();
          _timeUpdateSub = null;
          _audioElement?.pause();
          onComplete();
        }
      });
    } else {
      _endedSub = _audioElement!.onEnded.listen((_) => onComplete());
    }
    _errorSub = _audioElement!.onError.listen((_) => onComplete());
  }

  void _revokeBlobUrl() {
    if (_blobUrl != null) {
      html.Url.revokeObjectUrl(_blobUrl!);
      _blobUrl = null;
    }
  }

  @override
  Future<void> stop() async {
    _canPlaySub?.cancel(); _canPlaySub = null;
    _timeUpdateSub?.cancel(); _timeUpdateSub = null;
    _endedSub?.cancel(); _endedSub = null;
    _errorSub?.cancel(); _errorSub = null;
    _audioElement?.pause();
    _audioElement = null;
    _revokeBlobUrl();
  }

  @override
  void dispose() { stop(); }
}


SampleAudioPlayer createSampleAudioPlayer() => WebSampleAudioPlayer();