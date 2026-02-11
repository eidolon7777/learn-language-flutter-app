import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/usecases/start_recording.dart';
import '../../domain/usecases/stop_recording.dart';
import '../../domain/models/audio_frame.dart';
import '../../domain/models/rms_level.dart';
import '../../domain/exceptions/audio_exceptions.dart';

/// Audio capture states
abstract class AudioState extends Equatable {
  const AudioState();
  
  @override
  List<Object?> get props => [];
}

/// Initial audio state
class AudioInitial extends AudioState {
  const AudioInitial();
}

/// Audio permission checking state
class AudioPermissionChecking extends AudioState {
  const AudioPermissionChecking();
}

/// Audio permission denied state
class AudioPermissionDenied extends AudioState {
  final String message;
  final String guidance;
  
  const AudioPermissionDenied({
    required this.message,
    required this.guidance,
  });
  
  @override
  List<Object?> get props => [message, guidance];
}

/// Audio permission granted state
class AudioPermissionGranted extends AudioState {
  const AudioPermissionGranted();
}

/// Audio recording state
class AudioRecording extends AudioState {
  final RMSLevel currentRMSLevel;
  final int totalFrames;
  final double averageRMSLevel;
  final double peakRMSLevel;
  final int sessionDurationMs;
  
  const AudioRecording({
    required this.currentRMSLevel,
    required this.totalFrames,
    required this.averageRMSLevel,
    required this.peakRMSLevel,
    required this.sessionDurationMs,
  });
  
  @override
  List<Object?> get props => [
    currentRMSLevel,
    totalFrames,
    averageRMSLevel,
    peakRMSLevel,
    sessionDurationMs,
  ];
}

/// Audio recording error state
class AudioError extends AudioState {
  final String message;
  final String? details;
  final AudioException? exception;
  
  const AudioError({
    required this.message,
    this.details,
    this.exception,
  });
  
  @override
  List<Object?> get props => [message, details, exception];
}

/// Audio recording stopped state
class AudioRecordingStopped extends AudioState {
  final int totalFrames;
  final double averageRMSLevel;
  final double peakRMSLevel;
  final int sessionDurationMs;
  
  const AudioRecordingStopped({
    required this.totalFrames,
    required this.averageRMSLevel,
    required this.peakRMSLevel,
    required this.sessionDurationMs,
  });
  
  @override
  List<Object?> get props => [
    totalFrames,
    averageRMSLevel,
    peakRMSLevel,
    sessionDurationMs,
  ];
}

/// Audio Cubit for managing audio capture state
/// 
/// This cubit handles:
/// - Microphone permission management (FR-004)
/// - Audio recording start/stop operations
/// - RMS level updates for visualization (FR-003)
/// - Error handling and state management
class AudioCubit extends Cubit<AudioState> {
  final StartRecording _startRecording;
  final StopRecording _stopRecording;
  
  StreamSubscription<AudioFrame>? _audioSubscription;
  StreamSubscription<RMSLevel>? _rmsSubscription;
  
  AudioCubit({
    required StartRecording startRecording,
    required StopRecording stopRecording,
  }) : _startRecording = startRecording,
       _stopRecording = stopRecording,
       super(const AudioInitial());
  
  /// Start audio recording with permission handling
  Future<void> startRecording() async {
    Logger.info("[DEBUG] [startRecording] Starting recording");
    if (state is AudioRecording) {
      Logger.info("[DEBUG] [startRecording] Already recording, ignoring request");
      return; // Already recording
    }
    
    emit(const AudioPermissionChecking());
    
    try {
      // Start recording
      final audioStream = _startRecording.execute();
      
      // Subscribe to audio frames
      _audioSubscription = audioStream.listen(
        (audioFrame) {
          // Audio frames are handled internally by the repository
          // We just need to update the state with current RMS levels
        },
        onError: (error) {
          _handleRecordingError(error);
        },
        onDone: () {
          _handleRecordingStopped();
        },
      );
      
      // Subscribe to RMS level stream for visualization
      _rmsSubscription = _startRecording.rmsLevelStream.listen(
        (rmsLevel) {
          _updateRecordingState(rmsLevel);
        },
        onError: (error) {
          // RMS errors are non-fatal, just log them
          // The main audio stream will handle critical errors
        },
      );
      
      emit(const AudioPermissionGranted());
      
    } on MicrophonePermissionException catch (e) {
      emit(AudioPermissionDenied(
        message: e.message,
        guidance: 'Please grant microphone permission to start recording. '
                  'Go to app settings and enable microphone permission.',
      ));
    } on AudioInitializationException catch (e) {
      emit(AudioError(
        message: 'Failed to initialize audio recording',
        details: e.details,
        exception: e,
      ));
    } catch (e) {
      emit(AudioError(
        message: 'Unexpected error starting recording',
        details: e.toString(),
      ));
    }
  }
  
  /// Stop audio recording
  Future<void> stopRecording() async {
    Logger.info("[DEBUG] [stopRecording] Stopping recording");
    if (state is! AudioRecording) {
      Logger.info("[DEBUG] [stopRecording] Not recording, ignoring request");
      return; // Not recording
    }
    
    try {
      // Stop recording and get final stats
      final stats = await _stopRecording.executeWithStats();
      
      // Cancel subscriptions
      await _audioSubscription?.cancel();
      await _rmsSubscription?.cancel();
      _audioSubscription = null;
      _rmsSubscription = null;
      
      emit(AudioRecordingStopped(
        totalFrames: stats['totalFrames'] as int,
        averageRMSLevel: stats['averageRMSLevel'] as double,
        peakRMSLevel: stats['peakRMSLevel'] as double,
        sessionDurationMs: stats['durationMs'] as int,
      ));
      
    } catch (e) {
      emit(AudioError(
        message: 'Failed to stop recording',
        details: e.toString(),
      ));
    }
  }
  
  /// Check microphone permission
  Future<void> checkPermission() async {
    Logger.info("[DEBUG] [checkPermission] Checking permission");
    emit(const AudioPermissionChecking());
    
    try {
      final hasPermission = await _startRecording.checkPermission(
        request: true, // Check and request if needed
      );
      
      if (hasPermission) {
        emit(const AudioPermissionGranted());
      } else {
        emit(AudioPermissionDenied(
          message: 'Microphone permission not granted',
          guidance: 'Please grant microphone permission in app settings',
        ));
      }
      
    } catch (e) {
      emit(AudioError(
        message: 'Failed to check permission',
        details: e.toString(),
      ));
    }
  }
  
  /// Update recording state with current RMS level
  void _updateRecordingState(RMSLevel rmsLevel) {
    if (state is! AudioRecording && state is! AudioPermissionGranted) {
      return;
    }
    
    // For now, we'll use basic stats from the repository
    // In a real implementation, we'd get this from the repository
    emit(AudioRecording(
      currentRMSLevel: rmsLevel,
      totalFrames: 0, // Will be updated by repository
      averageRMSLevel: rmsLevel.level,
      peakRMSLevel: rmsLevel.level,
      sessionDurationMs: 0, // Will be calculated
    ));
  }
  
  /// Handle recording errors
  void _handleRecordingError(dynamic error) {
    Logger.error("[DEBUG] [_handleRecordingError] Recording error", error);
    String message;
    String? details;
    AudioException? exception;
    
    if (error is AudioException) {
      message = error.message;
      details = error.details;
      exception = error;
    } else {
      message = 'Recording error';
      details = error.toString();
    }
    
    emit(AudioError(
      message: message,
      details: details,
      exception: exception,
    ));
  }
  
  /// Handle recording stopped
  void _handleRecordingStopped() {
    // This is handled by the stopRecording method
  }
  
  @override
  Future<void> close() async {
    Logger.info("[DEBUG] [close] Closing AudioCubit");
    // Clean up subscriptions
    await _audioSubscription?.cancel();
    await _rmsSubscription?.cancel();
    
    // Stop recording if active
    if (state is AudioRecording) {
      try {
        await _stopRecording.execute();
      } catch (e) {
        // Ignore errors during cleanup
      }
    }
    
    return super.close();
  }
}