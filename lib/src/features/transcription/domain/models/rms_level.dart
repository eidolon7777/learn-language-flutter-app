import 'package:equatable/equatable.dart';

/// Domain model representing normalized RMS (Root Mean Square) audio level
/// Based on FR-003 requirements for visualizer widget
class RMSLevel extends Equatable {
  /// Normalized RMS level between 0.0 (silence) and 1.0 (maximum)
  final double level;
  
  /// Timestamp when this RMS level was calculated
  final int timestampMs;
  
  /// Raw RMS value before normalization (optional for debugging)
  final double? rawValue;
  
  /// Constructor for RMSLevel
  const RMSLevel({
    required this.level,
    required this.timestampMs,
    this.rawValue,
  });
  
  /// Create a copy of this RMSLevel with updated values
  RMSLevel copyWith({
    double? level,
    int? timestampMs,
    double? rawValue,
  }) {
    return RMSLevel(
      level: level ?? this.level,
      timestampMs: timestampMs ?? this.timestampMs,
      rawValue: rawValue ?? this.rawValue,
    );
  }
  
  /// Validate that level is within valid range [0.0, 1.0]
  bool get isValid {
    return level >= 0.0 && level <= 1.0;
  }
  
  /// Get level as percentage (0-100)
  double get levelPercentage {
    return level * 100.0;
  }
  
  /// Get level as integer percentage (0-100)
  int get levelPercentageInt {
    return (level * 100.0).round();
  }
  
  /// Check if this represents silence (level below threshold)
  bool isSilence([double threshold = 0.01]) {
    return level < threshold;
  }
  
  /// Check if this represents active audio (level above threshold)
  bool isActive([double threshold = 0.05]) {
    return level >= threshold;
  }
  
  @override
  List<Object?> get props => [level, timestampMs, rawValue];
  
  @override
  bool get stringify => true;
  
  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'timestampMs': timestampMs,
      'rawValue': rawValue,
    };
  }
  
  /// Create from JSON
  factory RMSLevel.fromJson(Map<String, dynamic> json) {
    return RMSLevel(
      level: json['level'] as double,
      timestampMs: json['timestampMs'] as int,
      rawValue: json['rawValue'] as double?,
    );
  }
}