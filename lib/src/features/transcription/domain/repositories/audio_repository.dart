import 'dart:async';
import '../models/audio_frame.dart';
import '../models/rms_level.dart';

/// Abstract repository interface for audio capture operations
/// Defines the contract for audio capture functionality as per FR-001 to FR-004
abstract class IAudioRepository {
  /// Start audio capture from the microphone
  /// 
  /// Returns a stream of AudioFrame objects containing PCM data, timestamps, and RMS levels
  /// Implements FR-001 (capture at 16kHz) and FR-003 (RMS calculation)
  /// 
  /// Throws:
  /// - [MicrophonePermissionException] if permission is denied
  /// - [MicrophoneBusyException] if microphone is already in use
  /// - [AudioInitializationException] if audio system fails to initialize
  Stream<AudioFrame> startCapture();
  
  /// Stop audio capture
  /// 
  /// Gracefully stops the audio capture stream and releases resources
  /// Returns stats about the captured session if successfully stopped
  /// 
  /// Throws:
  /// - [AudioStopException] if unable to stop capture cleanly
  Future<AudioCaptureStats> stopCapture();
  
  /// Check if audio capture is currently active
  bool get isCapturing;
  
  /// Get the current RMS level for visualization (FR-003)
  /// 
  /// Returns the most recently calculated RMS level (0.0 to 1.0)
  /// or null if no audio has been captured yet
  RMSLevel? get currentRMSLevel;
  
  /// Get a stream of RMS levels for real-time visualization
  /// 
  /// Emits RMSLevel objects at regular intervals for waveform visualization
  /// Implements FR-003 for visualizer widget
  Stream<RMSLevel> get rmsLevelStream;
  
  /// Request microphone permission (FR-004)
  /// 
  /// Returns true if permission is granted, false if denied
  /// Handles the permission request dialog as per FR-004
  Future<bool> requestMicrophonePermission();
  
  /// Check current microphone permission status (FR-004)
  /// 
  /// Returns the current permission status without requesting
  Future<bool> checkMicrophonePermission();
  
  /// Get audio capture statistics
  /// 
  /// Returns information about current capture session including
  /// sample rate, buffer sizes, and performance metrics
  AudioCaptureStats get captureStats;
}

/// Statistics about the current audio capture session
class AudioCaptureStats {
  /// Current sample rate in Hz
  final int sampleRate;
  
  /// Buffer size in samples
  final int bufferSize;
  
  /// Number of channels (1 for mono, 2 for stereo)
  final int channels;
  
  /// Bits per sample (8, 16, etc.)
  final int bitsPerSample;
  
  /// Total frames captured in current session
  final int totalFrames;
  
  /// Average RMS level of current session
  final double averageRMSLevel;
  
  /// Peak RMS level of current session
  final double peakRMSLevel;
  
  /// Duration of current capture session in milliseconds
  final int sessionDurationMs;
  
  /// Constructor for AudioCaptureStats
  const AudioCaptureStats({
    required this.sampleRate,
    required this.bufferSize,
    required this.channels,
    required this.bitsPerSample,
    required this.totalFrames,
    required this.averageRMSLevel,
    required this.peakRMSLevel,
    required this.sessionDurationMs,
  });
  
  /// Create a copy with updated values
  AudioCaptureStats copyWith({
    int? sampleRate,
    int? bufferSize,
    int? channels,
    int? bitsPerSample,
    int? totalFrames,
    double? averageRMSLevel,
    double? peakRMSLevel,
    int? sessionDurationMs,
  }) {
    return AudioCaptureStats(
      sampleRate: sampleRate ?? this.sampleRate,
      bufferSize: bufferSize ?? this.bufferSize,
      channels: channels ?? this.channels,
      bitsPerSample: bitsPerSample ?? this.bitsPerSample,
      totalFrames: totalFrames ?? this.totalFrames,
      averageRMSLevel: averageRMSLevel ?? this.averageRMSLevel,
      peakRMSLevel: peakRMSLevel ?? this.peakRMSLevel,
      sessionDurationMs: sessionDurationMs ?? this.sessionDurationMs,
    );
  }
}