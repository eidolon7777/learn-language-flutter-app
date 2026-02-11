import 'audio_exceptions.dart';

/// Exception thrown when RMS calculation fails
class RMSCalculationException extends AudioException {
  const RMSCalculationException(super.message, String super.details);

  /// Factory constructor for invalid data exceptions
  const RMSCalculationException.invalidData(String message)
      : super('Invalid audio data', message);

  /// Factory constructor for unsupported bit depth exceptions
  const RMSCalculationException.unsupportedBitDepth(int bitDepth)
      : super(
          'Unsupported bit depth: $bitDepth',
          'Only 8-bit and 16-bit audio are supported',
        );

  /// Factory constructor for window calculation exceptions
  const RMSCalculationException.invalidWindow(String message)
      : super('Invalid window parameters', message);
}