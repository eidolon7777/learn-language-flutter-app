import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../cubit/audio_cubit.dart';
import '../widgets/waveform_visualizer.dart';
import '../widgets/permission_request_widget.dart';
import '../../di/audio_capture_di.dart';
import '../../../../core/utils/logger.dart';

/// Comprehensive audio capture screen that can be integrated into main.dart
/// 
/// This screen provides a complete audio capture interface with:
/// - Permission management
/// - Recording controls
/// - Audio visualization
/// - Recording statistics
/// - Error handling
class AudioCaptureScreen extends StatefulWidget {
  const AudioCaptureScreen({super.key});

  @override
  State<AudioCaptureScreen> createState() => _AudioCaptureScreenState();
}

class _AudioCaptureScreenState extends State<AudioCaptureScreen> {
  late AudioCubit _audioCubit;

  @override
  void initState() {
    Logger.info("[DEBUG] [initState] Initializing AudioCaptureScreen");
    super.initState();
    _audioCubit = AudioCaptureDI.audioCubit;
    // Check permission on initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Logger.info("[DEBUG] [initState] Checking permission on post frame callback");
      _audioCubit.checkPermission();
    });
  }

  @override
  void dispose() {
    Logger.info("[DEBUG] [dispose] Disposing AudioCaptureScreen");
    // Don't dispose the cubit as it's managed by DI
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Logger.info("[DEBUG] [build] Building AudioCaptureScreen");
    return BlocProvider.value(
      value: _audioCubit,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Audio Capture'),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showInfoDialog(context),
            ),
          ],
        ),
        body: BlocBuilder<AudioCubit, AudioState>(
          builder: (context, state) {
            return Column(
              children: [
                // Permission status section
                _buildPermissionStatus(state),
                
                // Main content area
                Expanded(
                  child: _buildMainContent(state),
                ),
                
                // Recording statistics
                _buildRecordingStats(state),
                
                // Control buttons
                _buildControlButtons(state),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Build permission status indicator
  Widget _buildPermissionStatus(AudioState state) {
    Logger.info("[DEBUG] [_buildPermissionStatus] Building permission status for state: ${state.runtimeType}");
    final permissionStatus = _getPermissionStatus(state);
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: _getPermissionStatusColor(permissionStatus),
      child: Row(
        children: [
          Icon(
            _getPermissionStatusIcon(permissionStatus),
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _getPermissionStatusText(permissionStatus, state),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          if (permissionStatus == PermissionStatus.denied || 
              permissionStatus == PermissionStatus.permanentlyDenied)
            TextButton(
              onPressed: () => _audioCubit.checkPermission(),
              child: const Text('Grant', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  /// Build main content area based on state
  Widget _buildMainContent(AudioState state) {
    Logger.info("[DEBUG] [_buildMainContent] Building main content for state: ${state.runtimeType}");
    if (state is AudioPermissionChecking) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (state is AudioPermissionDenied) {
      return Center(
        child: PermissionRequestWidget(
          onPermissionGranted: () {},
          onPermissionDenied: () {},
          customMessage: 'Audio Capture Permission',
          customButtonText: 'Enable Microphone',
        ),
      );
    }
    
    if (state is AudioError) {
      Logger.error("[DEBUG] [_buildMainContent] AudioError: ${state.message} - ${state.details}");
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error: ${state.message}',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (state.details != null) ...[
              const SizedBox(height: 8),
              Text(
                state.details!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _audioCubit.checkPermission(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    // Default content for granted, recording, or stopped states
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Audio visualization
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Audio Visualization',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  WaveformVisualizer(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: 120,
                    activeColor: _getVisualizerColor(state),
                    inactiveColor: Colors.grey,
                    showRMSValue: true,
                    barWidth: 6,
                    barSpacing: 3,
                    maxBars: 40,
                  ),
                ],
              ),
            ),
          ),
          
          // Recording status
          if (_isRecording(state)) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Recording...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ] else if (state is AudioRecordingStopped) ...[
            const SizedBox(height: 16),
            Text(
              'Recording Stopped',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build recording statistics
  Widget _buildRecordingStats(AudioState state) {
    Logger.info("[DEBUG] [_buildRecordingStats] Building recording stats for state: ${state.runtimeType}");
    if (state is AudioRecording) {
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              'Recording Statistics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Duration', _formatDuration(state.sessionDurationMs)),
                _buildStatItem('Frames', state.totalFrames.toString()),
                _buildStatItem('Current RMS', '${(state.currentRMSLevel.level * 100).toStringAsFixed(1)}%'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Avg RMS', '${(state.averageRMSLevel * 100).toStringAsFixed(1)}%'),
                _buildStatItem('Peak RMS', '${(state.peakRMSLevel * 100).toStringAsFixed(1)}%'),
              ],
            ),
          ],
        ),
      );
    } else if (state is AudioRecordingStopped) {
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              'Recording Complete',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.green[700]),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total Duration', _formatDuration(state.sessionDurationMs)),
                _buildStatItem('Total Frames', state.totalFrames.toString()),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Average RMS', '${(state.averageRMSLevel * 100).toStringAsFixed(1)}%'),
                _buildStatItem('Peak RMS', '${(state.peakRMSLevel * 100).toStringAsFixed(1)}%'),
              ],
            ),
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  /// Build control buttons
  Widget _buildControlButtons(AudioState state) {
    Logger.info("[DEBUG] [_buildControlButtons] Building control buttons for state: ${state.runtimeType}");
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Start/Stop Recording Button
          ElevatedButton.icon(
            onPressed: _getRecordButtonAction(state),
            icon: Icon(_isRecording(state) ? Icons.stop : Icons.mic),
            label: Text(_isRecording(state) ? 'Stop Recording' : 'Start Recording'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isRecording(state) ? Colors.red : Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
          
          // Reset Button (only when stopped)
          if (state is AudioRecordingStopped) ...[
            ElevatedButton.icon(
              onPressed: () {
                Logger.info("[DEBUG] [ResetButton] Reset pressed");
                // Reset functionality would need to be added to AudioCubit
                // For now, we'll just stop recording if active
                if (_isRecording(state)) {
                  _audioCubit.stopRecording();
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reset'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Helper method to get permission status from state
  PermissionStatus _getPermissionStatus(AudioState state) {
    if (state is AudioInitial || state is AudioPermissionChecking) {
      return PermissionStatus.denied;
    } else if (state is AudioPermissionDenied) {
      return PermissionStatus.permanentlyDenied;
    } else if (state is AudioPermissionGranted || 
               state is AudioRecording || 
               state is AudioRecordingStopped) {
      return PermissionStatus.granted;
    } else if (state is AudioError) {
      return PermissionStatus.denied;
    }
    return PermissionStatus.denied;
  }

  /// Helper method to check if currently recording
  bool _isRecording(AudioState state) {
    return state is AudioRecording;
  }

  /// Helper method to get record button action
  VoidCallback? _getRecordButtonAction(AudioState state) {
    if (state is AudioPermissionDenied || state is AudioError) {
      return null; // Disabled
    }
    
    if (state is AudioRecording) {
      return () {
        Logger.info("[DEBUG] [RecordButton] Stop recording pressed");
        _audioCubit.stopRecording();
      };
    } else {
      return () {
        Logger.info("[DEBUG] [RecordButton] Start recording pressed");
        _audioCubit.startRecording();
      };
    }
  }

  /// Helper method to get permission status color
  Color _getPermissionStatusColor(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return Colors.green;
      case PermissionStatus.denied:
        return Colors.orange;
      case PermissionStatus.permanentlyDenied:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Helper method to get permission status icon
  IconData _getPermissionStatusIcon(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return Icons.check_circle;
      case PermissionStatus.denied:
        return Icons.warning;
      case PermissionStatus.permanentlyDenied:
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  /// Helper method to get permission status text
  String _getPermissionStatusText(PermissionStatus status, AudioState state) {
    if (state is AudioPermissionChecking) {
      return 'Checking microphone permission...';
    }
    
    switch (status) {
      case PermissionStatus.granted:
        return 'Microphone permission granted';
      case PermissionStatus.denied:
        return 'Microphone permission required';
      case PermissionStatus.permanentlyDenied:
        return 'Microphone permission denied - Please enable in settings';
      default:
        return 'Permission status unknown';
    }
  }

  /// Helper method to get visualizer color
  Color _getVisualizerColor(AudioState state) {
    if (state is AudioRecording) {
      return Colors.blue;
    } else if (state is AudioRecordingStopped) {
      return Colors.green;
    } else {
      return Colors.grey;
    }
  }

  /// Helper method to build stat item
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  /// Helper method to format duration
  String _formatDuration(int milliseconds) {
    final seconds = (milliseconds / 1000).floor();
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Show info dialog
  void _showInfoDialog(BuildContext context) {
    Logger.info("[DEBUG] [_showInfoDialog] Showing info dialog");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Audio Capture Info'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('This screen provides comprehensive audio capture functionality:'),
              SizedBox(height: 16),
              Text('• Real-time audio visualization'),
              Text('• RMS level monitoring'),
              Text('• Recording statistics'),
              Text('• Permission management'),
              Text('• Error handling'),
              SizedBox(height: 16),
              Text('Features:'),
              Text('• 16kHz PCM audio capture'),
              Text('• Real-time waveform visualization'),
              Text('• Recording duration tracking'),
              Text('• RMS level statistics'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}