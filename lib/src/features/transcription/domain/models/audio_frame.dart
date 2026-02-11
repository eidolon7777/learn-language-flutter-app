import 'package:equatable/equatable.dart';

/// Domain model representing an audio frame with PCM data, timestamp, and RMS level
/// Based on FR-001 and FR-003 requirements
class AudioFrame extends Equatable {
  /// Raw PCM audio data (16-bit signed integers)
  final List<int> pcmData;
  
  /// Timestamp in milliseconds when this frame was captured
  final int timestampMs;
  
  /// Calculated RMS (Root Mean Square) level for visualization (FR-003)
  final double rmsLevel;
  
  /// Sample rate of the audio data (should be 16kHz after resampling)
  final int sampleRate;
  
  /// Number of channels (1 for mono as per FR-001)
  final int channels;
  
  /// Constructor for AudioFrame
  const AudioFrame({
    required this.pcmData,
    required this.timestampMs,
    required this.rmsLevel,
    required this.sampleRate,
    this.channels = 1,
  });
  
  /// Create a copy of this AudioFrame with updated values
  AudioFrame copyWith({
    List<int>? pcmData,
    int? timestampMs,
    double? rmsLevel,
    int? sampleRate,
    int? channels,
  }) {
    return AudioFrame(
      pcmData: pcmData ?? this.pcmData,
      timestampMs: timestampMs ?? this.timestampMs,
      rmsLevel: rmsLevel ?? this.rmsLevel,
      sampleRate: sampleRate ?? this.sampleRate,
      channels: channels ?? this.channels,
    );
  }
  
  /// Convert PCM data to 16-bit signed integers
  List<int> get pcmDataAsInt16 {
    if (pcmData.isEmpty) return [];
    
    // Convert bytes to 16-bit signed integers (little-endian)
    final result = <int>[];
    for (int i = 0; i < pcmData.length - 1; i += 2) {
      final lowByte = pcmData[i];
      final highByte = pcmData[i + 1];
      final value = (highByte << 8) | (lowByte & 0xFF);
      // Convert to signed 16-bit integer
      result.add(value > 32767 ? value - 65536 : value);
    }
    return result;
  }
  
  /// Get the duration of this frame in milliseconds
  double get durationMs {
    if (pcmData.isEmpty || sampleRate == 0) return 0.0;
    return (pcmData.length / 2) * 1000.0 / sampleRate; // /2 for 16-bit samples
  }
  
  /// Get the number of samples in this frame
  int get sampleCount {
    return pcmData.length ~/ 2; // 2 bytes per 16-bit sample
  }
  
  @override
  List<Object?> get props => [
    pcmData,
    timestampMs,
    rmsLevel,
    sampleRate,
    channels,
  ];
  
  @override
  bool get stringify => true;
  
  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'pcmData': pcmData,
      'timestampMs': timestampMs,
      'rmsLevel': rmsLevel,
      'sampleRate': sampleRate,
      'channels': channels,
    };
  }
  
  /// Create from JSON
  factory AudioFrame.fromJson(Map<String, dynamic> json) {
    return AudioFrame(
      pcmData: List<int>.from(json['pcmData'] as List),
      timestampMs: json['timestampMs'] as int,
      rmsLevel: json['rmsLevel'] as double,
      sampleRate: json['sampleRate'] as int,
      channels: json['channels'] as int? ?? 1,
    );
  }
}