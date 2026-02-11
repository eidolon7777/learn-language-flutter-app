/// Audio constants for the transcription feature
/// Based on TRD section 3.1 requirements
class AudioConstants {
  /// Target sample rate for transcription (16kHz as per FR-001)
  static const int targetSampleRate = 16000;
  
  /// Alternative sample rates that may be provided by hardware (FR-002)
  static const int sampleRate44_1kHz = 44100;
  static const int sampleRate48kHz = 48000;
  
  /// PCM format specifications (FR-001)
  static const int bitsPerSample = 16;
  static const int channels = 1; // Mono
  
  /// Buffer sizes for different components
  static const int audioFrameBufferSize = 1024; // 64ms at 16kHz
  static const int ringBufferSize = 5 * targetSampleRate; // 5 seconds
  static const int vadFrameSize = 480; // 30ms at 16kHz
  static const int sttWindowSize = 3200; // 200ms at 16kHz
  
  /// RMS calculation constants (FR-003)
  static const double rmsNormalizationFactor = 32768.0; // For 16-bit audio
  static const double rmsMinLevel = 0.0;
  static const double rmsMaxLevel = 1.0;
  
  /// Audio format constants
  static const int bytesPerSample = 2; // 16-bit = 2 bytes
  static const double millisecondsPerSample = 1000.0 / targetSampleRate;
  
  /// Resampling quality settings
  static const int resampleQuality = 3; // Medium quality (1-10)
  
  /// Permission request constants
  static const String microphonePermission = 'microphone';
  static const Duration permissionRequestTimeout = Duration(seconds: 30);
}