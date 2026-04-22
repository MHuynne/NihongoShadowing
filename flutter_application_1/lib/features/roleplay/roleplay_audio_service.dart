// import 'package:record/record.dart';
// import 'package:path_provider/path_provider.dart';

class RoleplayAudioService {
  // final _audioRecorder = AudioRecorder();

  Future<void> startRecording() async {
    /*
    if (await _audioRecorder.hasPermission()) {
      final Directory tempDir = await getTemporaryDirectory();
      final String path = '${tempDir.path}/roleplay_temp.m4a';
      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
    }
    */
  }

  Future<String?> stopRecording() async {
    /*
    final path = await _audioRecorder.stop();
    return path;
    */
    return null;
  }
}
