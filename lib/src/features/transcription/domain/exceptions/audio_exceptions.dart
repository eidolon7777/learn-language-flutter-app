/// Base exception for audio-related errors
abstract class AudioException implements Exception {
  final String message;
  final String? details;
  
  const AudioException(this.message, [this.details]);
  
  @override
  String toString() {
    if (details != null) {
      return '$message: $details';
    }
    return message;
  }
}

/// Exception thrown when microphone permission is denied or permanently denied
class MicrophonePermissionException extends AudioException {
  const MicrophonePermissionException(super.message, [super.details]);
  
  const MicrophonePermissionException.denied()
      : super('Microphone permission denied', 
              'User denied microphone permission request');
  
  const MicrophonePermissionException.permanentlyDenied()
      : super('Microphone permission permanently denied', 
              'User denied permission and selected "Don\'t ask again"');
  
  const MicrophonePermissionException.restricted()
      : super('Microphone permission restricted', 
              'Microphone access is restricted by device policy');
}

/// Exception thrown when microphone is already in use by another application
class MicrophoneBusyException extends AudioException {
  const MicrophoneBusyException([String? details])
      : super('Microphone is busy', details ?? 'Another app is using the microphone');
}

/// Exception thrown when audio system fails to initialize
class AudioInitializationException extends AudioException {
  const AudioInitializationException(super.message, [super.details]);
  
  const AudioInitializationException.platformError([String? details])
      : super('Failed to initialize audio platform', details);
  
  const AudioInitializationException.configurationError([String? details])
      : super('Invalid audio configuration', details);
}

/// Exception thrown when unable to stop audio capture
class AudioStopException extends AudioException {
  const AudioStopException([String? details])
      : super('Failed to stop audio capture', details);
}

/// Exception thrown during audio resampling operations
class AudioResamplingException extends AudioException {
  const AudioResamplingException(super.message, [super.details]);
  
  const AudioResamplingException.unsupportedRate(int fromRate, int toRate)
      : super('Unsupported resampling rate', 
              'Cannot resample from $fromRate Hz to $toRate Hz');
}

/// Exception thrown during RMS calculation
class RMSCalculationException extends AudioException {
  const RMSCalculationException(super.message, [super.details]);
  
  const RMSCalculationException.invalidData([String? details])
      : super('Invalid data for RMS calculation', details);
}