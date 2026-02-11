import '../../../../core/utils/logger.dart';
import '../repositories/audio_repository.dart';
import '../exceptions/audio_exceptions.dart';

/// Use case for stopping audio recording
/// 
/// This use case provides a clean interface for stopping audio capture,
/// ensuring proper cleanup and resource management.
class StopRecording {
  final IAudioRepository _audioRepository;
  
  StopRecording({required IAudioRepository audioRepository})
      : _audioRepository = audioRepository;
  
  /// Stop audio recording
  /// 
  /// This method:
  /// 1. Stops the audio capture stream
  /// 2. Releases audio resources
  /// 3. Returns true if recording was successfully stopped
  /// 4. Returns false if no recording was active
  /// 
  /// Returns:
  /// - bool: true if recording was stopped, false if no recording was active
  /// 
  /// Throws:
  /// - [AudioStopException] if stopping fails
  Future<bool> execute() async {
    Logger.info("[DEBUG] [StopRecording] execute called");
    try {
      // Check if recording is active
      if (!_audioRepository.isCapturing) {
        Logger.info("[DEBUG] [StopRecording] Not capturing, returning false");
        return false;
      }
      
      // Stop audio capture
      await _audioRepository.stopCapture();
      Logger.info("[DEBUG] [StopRecording] Capture stopped");
      
      return true;
      
    } on AudioException {
      // Re-throw audio exceptions
      rethrow;
    } catch (e) {
      Logger.error("[DEBUG] [StopRecording] Error in execute", e);
      // Wrap unexpected errors
      throw AudioStopException(
        'Failed to stop recording: ${e.toString()}',
      );
    }
  }
  
  /// Stop recording and get capture statistics
  /// 
  /// This method stops recording and returns statistics about the recording session
  /// 
  /// Returns:
  /// - `Map<String, dynamic>`: Recording statistics including duration, frames, RMS levels
  /// 
  /// Throws:
  /// - [AudioStopException] if stopping fails
  Future<Map<String, dynamic>> executeWithStats() async {
    Logger.info("[DEBUG] [StopRecording] executeWithStats called");
    try {
      if (!_audioRepository.isCapturing) {
        // Return current stats (which should be empty/zero)
        final stats = _audioRepository.captureStats;
        return {
          'stopped': false,
          'stats': stats,
          'durationMs': stats.sessionDurationMs,
          'totalFrames': stats.totalFrames,
          'averageRMSLevel': stats.averageRMSLevel,
          'peakRMSLevel': stats.peakRMSLevel,
        };
      }

      // Stop recording and get final stats
      final stats = await _audioRepository.stopCapture();
      
      return {
        'stopped': true,
        'stats': stats,
        'durationMs': stats.sessionDurationMs,
        'totalFrames': stats.totalFrames,
        'averageRMSLevel': stats.averageRMSLevel,
        'peakRMSLevel': stats.peakRMSLevel,
      };
      
    } catch (e) {
      Logger.error("[DEBUG] [StopRecording] Error in executeWithStats", e);
      throw AudioStopException(
        'Failed to stop recording with stats: ${e.toString()}',
      );
    }
  }
  
  /// Check if recording is currently active
  bool get isRecording => _audioRepository.isCapturing;
  
  /// Get current capture statistics without stopping
  /// 
  /// Useful for getting real-time statistics during recording
  dynamic get currentStats => _audioRepository.captureStats;
}