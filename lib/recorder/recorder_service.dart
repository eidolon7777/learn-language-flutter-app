abstract class RecorderService {
  Future<void> start();
  Future<void> stop();
  Future<void> pause();
  Future<void> resume();
  Future<void> startStreaming();
}