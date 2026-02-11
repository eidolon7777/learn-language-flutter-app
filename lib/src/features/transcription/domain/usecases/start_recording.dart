import 'dart:async';
import '../../../../core/utils/logger.dart';
import '../repositories/audio_repository.dart';
import '../models/audio_frame.dart';
import '../models/rms_level.dart';
import '../exceptions/audio_exceptions.dart';

/// Use case for starting audio recording with permission handling
/// Implements FR-004: Microphone permission management
/// 
/// This use case orchestrates the permission request and audio capture start,
/// providing a clean interface for UI components to initiate recording.
class StartRecording {
  final IAudioRepository _audioRepository;
  
  StartRecording({required IAudioRepository audioRepository})
      : _audioRepository = audioRepository;
  
  /// Start audio recording with automatic permission handling
  /// 
  /// This method:
  /// 1. Checks if microphone permission is granted
  /// 2. Requests permission if not granted
  /// 3. Starts audio capture if permission is available
  /// 4. Returns a stream of AudioFrame objects
  /// 
  /// Returns:
  /// - `Stream<AudioFrame>`: Real-time audio data stream
  /// 
  /// Throws:
  /// - [MicrophonePermissionException] if permission is denied
  /// - [AudioInitializationException] if capture fails to start
  /// - [AudioCaptureException] for other capture-related errors
  Stream<AudioFrame> execute() async* {
    Logger.info("[DEBUG] [StartRecording] execute called");
    try {
      // Check if microphone permission is available
      final hasPermission = await _checkOrRequestPermission();
      
      if (!hasPermission) {
        Logger.error("[DEBUG] [StartRecording] Permission denied");
        throw const MicrophonePermissionException(
          'Microphone permission denied',
          'User denied microphone permission',
        );
      }
      
      Logger.info("[DEBUG] [StartRecording] Permission granted, starting capture");
      // Start audio capture
      yield* _startAudioCapture();
      
    } on MicrophonePermissionException {
      // Re-throw permission exceptions
      rethrow;
    } on AudioException {
      // Re-throw audio exceptions
      rethrow;
    } catch (e) {
      Logger.error("[DEBUG] [StartRecording] Error in execute", e);
      // Wrap unexpected errors
      throw AudioInitializationException(
        'Failed to start recording: ${e.toString()}',
      );
    }
  }
  
  /// Start audio recording with custom configuration
  /// 
  /// Allows specifying custom sample rate, channels, and other parameters
  /// for advanced use cases
  /// 
  /// Parameters:
  /// - [sampleRate]: Target sample rate (defaults to 16kHz per FR-001)
  /// - [channels]: Number of channels (defaults to 1 for mono)
  /// - [bitDepth]: Bit depth (defaults to 16-bit)
  /// - [requestPermission]: Whether to request permission if not granted (defaults to true)
  /// 
  /// Returns:
  /// - `Stream<AudioFrame>`: Real-time audio data stream
  /// 
  /// Throws:
  /// - [MicrophonePermissionException] if permission is denied
  /// - [AudioInitializationException] if capture fails to start
  Stream<AudioFrame> executeWithConfig({
    int? sampleRate,
    int? channels,
    int? bitDepth,
    bool requestPermission = true,
  }) async* {
    Logger.info("[DEBUG] [StartRecording] executeWithConfig called (requestPermission: $requestPermission)");
    try {
      // Check or request permission based on parameter
      final hasPermission = requestPermission 
          ? await _checkOrRequestPermission()
          : await _audioRepository.checkMicrophonePermission();
      
      if (!hasPermission) {
        Logger.info("[DEBUG] [StartRecording] Permission check failed");
        throw const MicrophonePermissionException(
          'Microphone permission not available',
          'Microphone permission is required for audio recording',
        );
      }
      
      Logger.info("[DEBUG] [StartRecording] Starting capture with config");
      // Note: For now, we use the standard capture method
      // In a more advanced implementation, we could pass these parameters
      // to the repository for custom configuration
      yield* _startAudioCapture();
      
    } on MicrophonePermissionException {
      rethrow;
    } on AudioException {
      rethrow;
    } catch (e) {
      Logger.error("[DEBUG] [StartRecording] Error in executeWithConfig", e);
      throw AudioInitializationException(
        'Failed to start recording with config: ${e.toString()}',
      );
    }
  }
  
  /// Check if recording is currently active
  bool get isRecording => _audioRepository.isCapturing;
  
  /// Get current RMS level for visualization
  /// 
  /// Returns null if not recording
  RMSLevel? get currentRMSLevel => _audioRepository.currentRMSLevel;
  
  /// Get RMS level stream for real-time visualization
  Stream<RMSLevel> get rmsLevelStream => _audioRepository.rmsLevelStream;
  
  /// Get audio capture statistics
  /// 
  /// Returns statistics about the current recording session
  Future<dynamic> getCaptureStats() async {
    return _audioRepository.captureStats;
  }
  
  /// Check or request microphone permission explicitly
  /// 
  /// Returns true if permission is granted, false otherwise
  Future<bool> checkPermission({bool request = false}) async {
    Logger.info("[DEBUG] [StartRecording] checkPermission called (request: $request)");
    try {
      // First check if permission is already granted
      final hasPermission = await _audioRepository.checkMicrophonePermission();
      
      if (hasPermission) {
        Logger.info("[DEBUG] [StartRecording] Permission already granted");
        return true;
      }
      
      if (!request) {
        return false;
      }
      
      Logger.info("[DEBUG] [StartRecording] Requesting permission");
      // Request permission if not granted
      return await _audioRepository.requestMicrophonePermission();
      
    } catch (e) {
      Logger.error("[DEBUG] [StartRecording] Error checking permission", e);
      return false;
    }
  }

  /// Check or request microphone permission
  /// 
  /// Returns true if permission is granted, false otherwise
  Future<bool> _checkOrRequestPermission() async {
    Logger.info("[DEBUG] [StartRecording] Checking/requesting permission");
    try {
      // First check if permission is already granted
      final hasPermission = await _audioRepository.checkMicrophonePermission();
      
      if (hasPermission) {
        Logger.info("[DEBUG] [StartRecording] Permission already granted");
        return true;
      }
      
      Logger.info("[DEBUG] [StartRecording] Requesting permission");
      // Request permission if not granted
      return await _audioRepository.requestMicrophonePermission();
      
    } catch (e) {
      Logger.error("[DEBUG] [StartRecording] Error checking permission", e);
      // If permission check fails, assume no permission
      return false;
    }
  }
  
  /// Start audio capture and handle errors
  Stream<AudioFrame> _startAudioCapture() async* {
    Logger.info("[DEBUG] [StartRecording] _startAudioCapture stream started");
    try {
      yield* _audioRepository.startCapture();
    } on AudioException {
      rethrow;
    } catch (e) {
      Logger.error("[DEBUG] [StartRecording] Error in _startAudioCapture", e);
      throw AudioInitializationException(
        'Audio capture failed to start: ${e.toString()}',
      );
    }
  }
}