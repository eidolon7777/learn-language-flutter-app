import 'dart:math' as math;
import '../models/audio_frame.dart';
import '../models/rms_level.dart';
import '../exceptions/rms_calculation_exception.dart';
import '../../../../core/constants/audio_constants.dart';

/// Use case for calculating RMS (Root Mean Square) level from audio data
/// Implements FR-003: RMS calculation for audio level visualization
/// 
/// This use case encapsulates the business logic for RMS calculation,
/// ensuring consistent and normalized RMS values across the application.
class CalculateRMS {
  /// Calculate RMS level from raw PCM audio data
  /// 
  /// Returns an RMSLevel object with normalized level (0.0 to 1.0)
  /// and timestamp information
  /// 
  /// Parameters:
  /// - [audioData]: Raw PCM audio data as bytes
  /// - [timestampMs]: Timestamp in milliseconds when the audio was captured
  /// - [bitDepth]: Bit depth of the audio data (8 or 16, defaults to 16)
  /// 
  /// Throws:
  /// - [RMSCalculationException] if audio data is invalid or empty
  RMSLevel execute({
    required List<int> audioData,
    required int timestampMs,
    int bitDepth = AudioConstants.bitsPerSample,
  }) {
    if (audioData.isEmpty) {
      throw const RMSCalculationException.invalidData('Audio data is empty');
    }
    
    if (audioData.length < 2) {
      throw const RMSCalculationException.invalidData('Audio data too short for RMS calculation');
    }
    
    // Convert raw bytes to audio samples based on bit depth
    final samples = _convertBytesToSamples(audioData, bitDepth);
    
    // Calculate RMS from samples
    final rmsValue = _calculateRMSFromSamples(samples);
    
    // Normalize the RMS value
    final normalizedLevel = _normalizeRMS(rmsValue, bitDepth);
    
    return RMSLevel(
      level: normalizedLevel,
      timestampMs: timestampMs,
      rawValue: rmsValue,
    );
  }
  
  /// Calculate RMS from an AudioFrame object
  /// 
  /// Convenience method that extracts audio data from AudioFrame
  /// and calculates RMS level
  RMSLevel executeFromAudioFrame(AudioFrame audioFrame) {
    return execute(
      audioData: audioFrame.pcmData,
      timestampMs: audioFrame.timestampMs,
      bitDepth: AudioConstants.bitsPerSample,
    );
  }
  
  /// Convert raw bytes to audio samples based on bit depth
  List<double> _convertBytesToSamples(List<int> audioData, int bitDepth) {
    switch (bitDepth) {
      case 8:
        return _convert8BitToSamples(audioData);
      case 16:
        return _convert16BitToSamples(audioData);
      default:
        throw RMSCalculationException(
          'Unsupported bit depth: $bitDepth',
          'Only 8-bit and 16-bit audio are supported',
        );
    }
  }
  
  /// Convert 8-bit audio bytes to normalized samples (-1.0 to 1.0)
  List<double> _convert8BitToSamples(List<int> audioData) {
    return audioData.map((byte) {
      // 8-bit audio is unsigned (0-255), center at 128
      final centered = byte - 128;
      // Normalize to -1.0 to 1.0 range
      return centered / 128.0;
    }).toList();
  }
  
  /// Convert 16-bit audio bytes to normalized samples (-1.0 to 1.0)
  List<double> _convert16BitToSamples(List<int> audioData) {
    final samples = <double>[];
    
    // 16-bit audio uses 2 bytes per sample, little-endian
    for (int i = 0; i < audioData.length - 1; i += 2) {
      final lowByte = audioData[i];
      final highByte = audioData[i + 1];
      
      // Combine bytes to 16-bit signed integer
      int sample = (highByte << 8) | (lowByte & 0xFF);
      
      // Handle sign extension for negative values
      if (sample > 32767) {
        sample = sample - 65536;
      }
      
      // Normalize to -1.0 to 1.0 range
      samples.add(sample / AudioConstants.rmsNormalizationFactor);
    }
    
    return samples;
  }
  
  /// Calculate RMS from normalized audio samples
  double _calculateRMSFromSamples(List<double> samples) {
    if (samples.isEmpty) {
      return 0.0;
    }
    
    // Calculate sum of squares
    double sumSquares = 0.0;
    for (final sample in samples) {
      sumSquares += sample * sample;
    }
    
    // Calculate mean of squares
    final meanSquares = sumSquares / samples.length;
    
    // Calculate root of mean squares (RMS)
    return math.sqrt(meanSquares);
  }
  
  /// Normalize RMS value to 0.0-1.0 range
  double _normalizeRMS(double rmsValue, int bitDepth) {
    // RMS value is already normalized to 0.0-1.0 range
    // since we normalized samples to -1.0 to 1.0
    
    // Clamp to valid range to handle any floating point errors
    return rmsValue.clamp(AudioConstants.rmsMinLevel, AudioConstants.rmsMaxLevel);
  }
  
  /// Calculate RMS level from a specific window of audio data
  /// 
  /// Useful for sliding window RMS calculations
  RMSLevel executeWindow({
    required List<int> audioData,
    required int timestampMs,
    required int windowStart,
    required int windowEnd,
    int bitDepth = AudioConstants.bitsPerSample,
  }) {
    if (windowStart < 0 || windowEnd > audioData.length || windowStart >= windowEnd) {
      throw RMSCalculationException(
        'Invalid window parameters',
        'Window start: $windowStart, window end: $windowEnd, data length: ${audioData.length}',
      );
    }
    
    final windowData = audioData.sublist(windowStart, windowEnd);
    
    return execute(
      audioData: windowData,
      timestampMs: timestampMs,
      bitDepth: bitDepth,
    );
  }
  
  /// Calculate average RMS level from multiple audio frames
  /// 
  /// Useful for smoothing RMS levels over time
  RMSLevel executeAverage({
    required List<RMSLevel> rmsLevels,
    required int timestampMs,
  }) {
    if (rmsLevels.isEmpty) {
      throw const RMSCalculationException.invalidData('RMS levels list is empty');
    }
    
    // Calculate average level
    double sumLevels = 0.0;
    for (final level in rmsLevels) {
      sumLevels += level.level;
    }
    
    final averageLevel = sumLevels / rmsLevels.length;
    
    return RMSLevel(
      level: averageLevel.clamp(AudioConstants.rmsMinLevel, AudioConstants.rmsMaxLevel),
      timestampMs: timestampMs,
      rawValue: averageLevel,
    );
  }
}