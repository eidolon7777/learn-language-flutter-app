import 'dart:async';

/// Abstract data source interface for audio capture operations
/// Defines low-level audio capture functionality that interfaces with platform/hardware
abstract class AudioCaptureDataSource {
  /// Start capturing audio from the microphone
  /// 
  /// Returns a stream of raw PCM audio data that will be processed into AudioFrame objects
  /// Handles platform-specific microphone initialization and configuration
  /// 
  /// Parameters:
  /// - [sampleRate]: Target sample rate (default: 16000 Hz)
  /// - [channels]: Number of channels (default: 1 for mono)
  /// - [bitDepth]: Bits per sample (default: 16)
  /// 
  /// Throws:
  /// - Platform-specific exceptions for hardware initialization failures
  Stream<List<int>> startCapture({
    int sampleRate = 16000,
    int channels = 1,
    int bitDepth = 16,
  });
  
  /// Stop audio capture and release hardware resources
  /// 
  /// Returns true if successfully stopped, false if not currently capturing
  /// Ensures proper cleanup of platform resources
  Future<bool> stopCapture();
  
  /// Check if audio capture is currently active
  bool get isCapturing;
  
  /// Get the actual sample rate being used by the hardware
  /// 
  /// May differ from requested sample rate due to hardware limitations
  /// Used for resampling calculations (FR-002)
  Future<int> get actualSampleRate;
  
  /// Get the actual bit depth being used
  /// 
  /// May differ from requested bit depth due to hardware limitations
  Future<int> get actualBitDepth;
  
  /// Get the actual number of channels being used
  /// 
  /// May differ from requested channels due to hardware limitations
  Future<int> get actualChannels;
  
  /// Get the buffer size used by the platform
  /// 
  /// Platform-specific buffer size for audio data
  Future<int> get bufferSize;
  
  /// Check if the microphone is available and not in use
  /// 
  /// Returns true if microphone can be accessed, false if busy or unavailable
  Future<bool> isMicrophoneAvailable();
  
  /// Get platform-specific audio configuration information
  /// 
  /// Returns a map of platform-specific audio parameters and capabilities
  Future<Map<String, dynamic>> getPlatformAudioInfo();
}