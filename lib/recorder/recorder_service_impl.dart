import 'package:record/record.dart';

import 'recorder_service.dart';

class RecorderServiceImpl implements RecorderService {

  final AudioRecorder recorder;

  RecorderServiceImpl(this.recorder);

  @override
  Future<void> pause() async {
    await recorder.pause();
  }

  @override
  Future<void> resume() async {
    await recorder.resume();
  }

  @override
  Future<void> start() async {
    await recorder.start(RecordConfig(), path: 'audio.wav');
  }

  @override
  Future<void> stop() async {
    await recorder.stop();
  }
  
  @override
  Future<void> startStreaming() async {
    await recorder.startStream(RecordConfig());
  }
}