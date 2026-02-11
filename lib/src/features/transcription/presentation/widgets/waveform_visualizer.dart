import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/audio_cubit.dart';
import '../../domain/models/rms_level.dart';

/// Widget for visualizing audio waveform based on RMS levels
/// 
/// This widget displays a real-time waveform visualization using RMS levels
/// calculated from the audio stream. It implements FR-003 for audio level visualization.
class WaveformVisualizer extends StatelessWidget {
  final double width;
  final double height;
  final Color activeColor;
  final Color inactiveColor;
  final double barWidth;
  final double barSpacing;
  final int maxBars;
  final bool showRMSValue;
  final TextStyle? valueTextStyle;
  
  const WaveformVisualizer({
    super.key,
    this.width = double.infinity,
    this.height = 100.0,
    this.activeColor = Colors.blue,
    this.inactiveColor = Colors.grey,
    this.barWidth = 4.0,
    this.barSpacing = 2.0,
    this.maxBars = 50,
    this.showRMSValue = false,
    this.valueTextStyle,
  });
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AudioCubit, AudioState>(
      builder: (context, state) {
        if (state is AudioRecording) {
          return _buildActiveVisualizer(state);
        } else if (state is AudioRecordingStopped) {
          return _buildStoppedVisualizer(state);
        } else {
          return _buildInactiveVisualizer();
        }
      },
    );
  }
  
  /// Build active recording visualizer
  Widget _buildActiveVisualizer(AudioRecording state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildWaveformBars(state.currentRMSLevel.level),
        if (showRMSValue) ...[
          const SizedBox(height: 8),
          _buildRMSValueDisplay(state.currentRMSLevel),
        ],
      ],
    );
  }
  
  /// Build stopped recording visualizer
  Widget _buildStoppedVisualizer(AudioRecordingStopped state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildWaveformBars(state.averageRMSLevel),
        if (showRMSValue) ...[
          const SizedBox(height: 8),
          _buildRMSStatsDisplay(state),
        ],
      ],
    );
  }
  
  /// Build inactive visualizer (not recording)
  Widget _buildInactiveVisualizer() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildWaveformBars(0.0),
        if (showRMSValue) ...[
          const SizedBox(height: 8),
          Text(
            'Not recording',
            style: valueTextStyle ?? const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ],
    );
  }
  
  /// Build waveform bars
  Widget _buildWaveformBars(double rmsLevel) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: WaveformPainter(
          rmsLevel: rmsLevel,
          activeColor: activeColor,
          inactiveColor: inactiveColor,
          barWidth: barWidth,
          barSpacing: barSpacing,
          maxBars: maxBars,
        ),
      ),
    );
  }
  
  /// Build RMS value display
  Widget _buildRMSValueDisplay(RMSLevel rmsLevel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'RMS: ',
          style: valueTextStyle ?? const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        Text(
          '${(rmsLevel.level * 100).toStringAsFixed(1)}%',
          style: valueTextStyle ?? TextStyle(
            fontSize: 12,
            color: _getRMSColor(rmsLevel.level),
            fontWeight: FontWeight.bold,
          ),
        ),
        if (rmsLevel.isSilence()) ...[
          const SizedBox(width: 8),
          const Icon(
            Icons.volume_off,
            size: 16,
            color: Colors.grey,
          ),
        ] else if (rmsLevel.isActive()) ...[
          const SizedBox(width: 8),
          Icon(
            Icons.volume_up,
            size: 16,
            color: _getRMSColor(rmsLevel.level),
          ),
        ],
      ],
    );
  }
  
  /// Build RMS stats display for stopped state
  Widget _buildRMSStatsDisplay(AudioRecordingStopped state) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Avg RMS: ',
              style: valueTextStyle ?? const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            Text(
              '${(state.averageRMSLevel * 100).toStringAsFixed(1)}%',
              style: valueTextStyle ?? const TextStyle(
                fontSize: 12,
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Peak RMS: ',
              style: valueTextStyle ?? const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            Text(
              '${(state.peakRMSLevel * 100).toStringAsFixed(1)}%',
              style: valueTextStyle ?? TextStyle(
                fontSize: 12,
                color: _getRMSColor(state.peakRMSLevel),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  /// Get color based on RMS level
  Color _getRMSColor(double level) {
    if (level < 0.1) {
      return Colors.green;
    } else if (level < 0.3) {
      return Colors.yellow;
    } else if (level < 0.6) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}

/// Custom painter for waveform visualization
class WaveformPainter extends CustomPainter {
  final double rmsLevel;
  final Color activeColor;
  final Color inactiveColor;
  final double barWidth;
  final double barSpacing;
  final int maxBars;
  
  WaveformPainter({
    required this.rmsLevel,
    required this.activeColor,
    required this.inactiveColor,
    required this.barWidth,
    required this.barSpacing,
    required this.maxBars,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;
    
    final totalBarWidth = barWidth + barSpacing;
    final barsCount = (size.width / totalBarWidth).floor().clamp(1, maxBars);
    final startX = (size.width - (barsCount * totalBarWidth - barSpacing)) / 2;
    
    for (int i = 0; i < barsCount; i++) {
      final x = startX + (i * totalBarWidth);
      
      // Create animated effect with different heights
      final normalizedIndex = i / (barsCount - 1);
      final waveHeight = _calculateWaveHeight(normalizedIndex, rmsLevel);
      
      // Calculate bar height based on RMS level
      final barHeight = waveHeight * size.height;
      final y = (size.height - barHeight) / 2;
      
      // Set color based on activity
      paint.color = rmsLevel > 0.01 ? activeColor : inactiveColor;
      
      // Draw rounded rectangle for smoother appearance
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        Radius.circular(barWidth / 2),
      );
      
      canvas.drawRRect(rect, paint);
    }
  }
  
  /// Calculate wave height based on position and RMS level
  double _calculateWaveHeight(double position, double rmsLevel) {
    // Create a wave pattern that responds to RMS level
    final wave = math.sin(position * math.pi);
    final noise = math.Random().nextDouble() * 0.2 - 0.1; // Add some noise
    
    return (wave * rmsLevel + noise * rmsLevel * 0.5).clamp(0.1, 1.0);
  }
  
  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.rmsLevel != rmsLevel;
  }
}

/// Simple waveform visualizer for basic RMS display
class SimpleWaveformVisualizer extends StatelessWidget {
  final double rmsLevel;
  final double width;
  final double height;
  final Color color;
  
  const SimpleWaveformVisualizer({
    super.key,
    required this.rmsLevel,
    this.width = 200.0,
    this.height = 50.0,
    this.color = Colors.blue,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          // RMS level indicator
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: width * rmsLevel,
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // RMS value text
          Center(
            child: Text(
              '${(rmsLevel * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}