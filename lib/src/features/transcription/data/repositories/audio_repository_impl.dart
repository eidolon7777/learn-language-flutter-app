import 'dart:async';
import 'dart:math' as math;
import '../../../../core/utils/logger.dart';
import '../../domain/repositories/audio_repository.dart';
import '../../domain/models/audio_frame.dart';
import '../../domain/models/rms_level.dart';
import '../../domain/exceptions/audio_exceptions.dart';
import '../datasources/audio_capture_datasource.dart';
import '../../../../core/constants/audio_constants.dart';

/// Implementation of IAudioRepository that orchestrates audio capture operations
/// Implements FR-001 to FR-004 requirements
class AudioRepositoryImpl implements IAudioRepository {
  final AudioCaptureDataSource _dataSource;
  
  bool _isCapturing = false;
  StreamController<AudioFrame>? _audioFrameController;
  StreamController<RMSLevel>? _rmsController;
  RMSLevel? _currentRMSLevel;
  int _totalFrames = 0;
  double _sumRMSLevels = 0.0;
  double _peakRMSLevel = 0.0;
  DateTime? _captureStartTime;
  
  AudioRepositoryImpl({required AudioCaptureDataSource dataSource})
      : _dataSource = dataSource;
  
  @override
  Stream<AudioFrame> startCapture() async* {
    Logger.info("[DEBUG] [AudioRepositoryImpl] startCapture called");
    if (_isCapturing) {
      Logger.info("[DEBUG] [AudioRepositoryImpl] Already capturing");
      throw const AudioInitializationException('Audio capture already active');
    }
    
    _audioFrameController = StreamController<AudioFrame>();
    _rmsController = StreamController<RMSLevel>();
    _totalFrames = 0;
    _sumRMSLevels = 0.0;
    _peakRMSLevel = 0.0;
    _captureStartTime = DateTime.now();
    
    try {
      Logger.info("[DEBUG] [AudioRepositoryImpl] Starting data source capture");
      // Start data source capture
      final rawAudioStream = _dataSource.startCapture(
        sampleRate: AudioConstants.targetSampleRate,
        channels: AudioConstants.channels,
        bitDepth: AudioConstants.bitsPerSample,
      );
      
      _isCapturing = true;
      Logger.info("[DEBUG] [AudioRepositoryImpl] Data source started, entering loop");
      
      await for (final rawAudioData in rawAudioStream) {
        if (!_isCapturing) break;
        
        // Create timestamp in milliseconds
        final timestampMs = DateTime.now().millisecondsSinceEpoch;
        
        // Calculate RMS level (FR-003)
        final rmsLevel = _calculateRMSLevel(rawAudioData);
        
        // Create AudioFrame
        final audioFrame = AudioFrame(
          pcmData: rawAudioData,
          timestampMs: timestampMs,
          rmsLevel: rmsLevel,
          sampleRate: AudioConstants.targetSampleRate,
          channels: AudioConstants.channels,
        );
        
        // Update RMS statistics
        _updateRMSStatistics(rmsLevel, timestampMs);
        
        // Create RMSLevel for visualization
        final rmsLevelObj = RMSLevel(
          level: rmsLevel,
          timestampMs: timestampMs,
          rawValue: rmsLevel * AudioConstants.rmsNormalizationFactor,
        );
        
        _currentRMSLevel = rmsLevelObj;
        _rmsController?.add(rmsLevelObj);
        
        _totalFrames++;
        
        // Add to audio frame stream
        _audioFrameController?.add(audioFrame);
        
        yield audioFrame;
      }
      
    } catch (e) {
      Logger.error("[DEBUG] [AudioRepositoryImpl] Error in startCapture loop", e);
      _isCapturing = false;
      _audioFrameController?.addError(e);
      _rmsController?.addError(e);
      rethrow;
    } finally {
      Logger.info("[DEBUG] [AudioRepositoryImpl] startCapture finally block");
      _isCapturing = false;
      _audioFrameController?.close();
      _rmsController?.close();
    }
  }
  
  @override
  Future<AudioCaptureStats> stopCapture() async {
    Logger.info("[DEBUG] [AudioRepositoryImpl] stopCapture called");
    if (!_isCapturing) {
      Logger.info("[DEBUG] [AudioRepositoryImpl] Not capturing, returning stats");
      return captureStats;
    }
    
    try {
      await _dataSource.stopCapture();
      _isCapturing = false;
      Logger.info("[DEBUG] [AudioRepositoryImpl] Capture stopped successfully");
      return captureStats;
    } catch (e) {
      Logger.error("[DEBUG] [AudioRepositoryImpl] Error stopping capture", e);
      throw AudioStopException('Failed to stop recording: ${e.toString()}');
    }
  }
  
  @override
  bool get isCapturing => _isCapturing;
  
  @override
  RMSLevel? get currentRMSLevel => _currentRMSLevel;
  
  @override
  Stream<RMSLevel> get rmsLevelStream {
    _rmsController ??= StreamController<RMSLevel>();
    return _rmsController!.stream;
  }
  
  @override
  Future<bool> requestMicrophonePermission() async {
    // This would typically use a permission handler utility
    // For now, we'll check if we can start capture
    try {
      return await _dataSource.isMicrophoneAvailable();
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<bool> checkMicrophonePermission() async {
    // Check if microphone is available without requesting permission
    try {
      return await _dataSource.isMicrophoneAvailable();
    } catch (e) {
      return false;
    }
  }
  
  @override
  AudioCaptureStats get captureStats {
    final sessionDurationMs = _captureStartTime != null 
        ? DateTime.now().difference(_captureStartTime!).inMilliseconds 
        : 0;
    
    final averageRMSLevel = _totalFrames > 0 
        ? _sumRMSLevels / _totalFrames 
        : 0.0;
    
    return AudioCaptureStats(
      sampleRate: AudioConstants.targetSampleRate,
      bufferSize: AudioConstants.audioFrameBufferSize,
      channels: AudioConstants.channels,
      bitsPerSample: AudioConstants.bitsPerSample,
      totalFrames: _totalFrames,
      averageRMSLevel: averageRMSLevel,
      peakRMSLevel: _peakRMSLevel,
      sessionDurationMs: sessionDurationMs,
    );
  }
  
  /// Calculate RMS level from audio data (FR-003)
  double _calculateRMSLevel(List<int> audioData) {
    if (audioData.isEmpty) {
      return 0.0;
    }
    
    // Convert to 16-bit samples if needed
    List<int> samples;
    if (audioData.length % 2 == 0) {
      // Assume 16-bit audio
      samples = [];
      for (int i = 0; i < audioData.length - 1; i += 2) {
        final lowByte = audioData[i];
        final highByte = audioData[i + 1];
        final value = (highByte << 8) | (lowByte & 0xFF);
        samples.add(value > 32767 ? value - 65536 : value);
      }
    } else {
      // Assume 8-bit audio
      samples = audioData;
    }
    
    // Calculate RMS
    double sumSquares = 0.0;
    for (final sample in samples) {
      final normalizedSample = sample / AudioConstants.rmsNormalizationFactor;
      sumSquares += normalizedSample * normalizedSample;
    }
    
    final rms = math.sqrt(sumSquares / samples.length);
    
    // Clamp to valid range
    return rms.clamp(AudioConstants.rmsMinLevel, AudioConstants.rmsMaxLevel);
  }
  
  /// Update RMS statistics for capture stats
  void _updateRMSStatistics(double rmsLevel, int timestampMs) {
    _sumRMSLevels += rmsLevel;
    _peakRMSLevel = math.max(_peakRMSLevel, rmsLevel);
  }
}