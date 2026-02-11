import 'dart:async';
import 'dart:typed_data';

import 'package:record/record.dart';

import '../../../../core/constants/audio_constants.dart';
import '../../domain/exceptions/audio_exceptions.dart';
import '../../../../core/utils/logger.dart';
import 'audio_capture_datasource.dart';

/// Implementation of AudioCaptureDataSource using record package
/// 
/// This implementation provides platform-specific audio capture functionality
/// using the record package for Flutter. It handles microphone initialization,
/// permission management, and raw audio data streaming.
class AudioCaptureDataSourceImpl implements AudioCaptureDataSource {
  final AudioRecorder _audioRecorder = AudioRecorder();
  StreamSubscription<Uint8List>? _micStreamSubscription;
  StreamController<List<int>>? _audioStreamController;
  bool _isCapturing = false;
  int _actualSampleRate = AudioConstants.targetSampleRate;
  int _requestedSampleRate = AudioConstants.targetSampleRate;
  
  @override
  Stream<List<int>> startCapture({
    int sampleRate = 16000,
    int channels = 1,
    int bitDepth = 16,
  }) async* {
    Logger.info("[DEBUG] [AudioCaptureDataSourceImpl] startCapture requested");
    // Check if already capturing
    if (_isCapturing) {
      Logger.info("[DEBUG] [AudioCaptureDataSourceImpl] Already capturing");
      throw AudioInitializationException(
        'Audio capture already active',
        'Cannot start capture while another capture is in progress',
      );
    }
    
    _requestedSampleRate = sampleRate;
    _audioStreamController = StreamController<List<int>>();
    
    try {
      // Check permissions first
      if (!await _audioRecorder.hasPermission()) {
        Logger.error("[DEBUG] [AudioCaptureDataSourceImpl] Permission denied");
        throw MicrophonePermissionException(
          'Microphone permission required', 
          'Permission not granted'
        );
      }

      // Configure record with requested parameters
      // Note: record package handles PCM 16-bit by default with AudioEncoder.pcm16bits
      final config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: channels,
      );
      
      Logger.info("[DEBUG] [AudioCaptureDataSourceImpl] Starting stream with config: $config");
      final stream = await _audioRecorder.startStream(config);
      
      // We assume actual sample rate matches requested for now, as record tries to honor it
      _actualSampleRate = sampleRate;
      
      _micStreamSubscription = stream.listen(
        (Uint8List audioData) {
          // Convert Uint8List to List<int> for consistency
          final audioBytes = audioData.toList();
          
          // Apply resampling if needed (FR-002)
          final processedAudio = _resampleIfNeeded(audioBytes);
          
          _audioStreamController?.add(processedAudio);
        },
        onError: (error) {
          Logger.error("[DEBUG] [AudioCaptureDataSourceImpl] Stream error", error);
          _audioStreamController?.addError(
            AudioInitializationException('Microphone stream error', error.toString())
          );
        },
        onDone: () {
          Logger.info("[DEBUG] [AudioCaptureDataSourceImpl] Stream done");
          _isCapturing = false;
          _audioStreamController?.close();
        },
      );
      
      _isCapturing = true;
      Logger.info("[DEBUG] [AudioCaptureDataSourceImpl] Capture started");
      
      yield* _audioStreamController!.stream;
      
    } catch (e) {
      Logger.error("[DEBUG] [AudioCaptureDataSourceImpl] Exception in startCapture", e);
      _isCapturing = false;
      _audioStreamController?.close();
      
      if (e is MicrophonePermissionException) {
        rethrow;
      }
      
      throw AudioInitializationException(
        'Failed to start audio capture: ${e.toString()}',
        'Check microphone permissions and hardware availability',
      );
    }
  }
  
  @override
  Future<bool> stopCapture() async {
    Logger.info("[DEBUG] [AudioCaptureDataSourceImpl] stopCapture requested");
    if (!_isCapturing) {
      Logger.info("[DEBUG] [AudioCaptureDataSourceImpl] Not capturing");
      return false;
    }
    
    try {
      // Stop the recorder
      await _audioRecorder.stop();
      
      // Cancel the microphone stream subscription
      await _micStreamSubscription?.cancel();
      _micStreamSubscription = null;
      
      // Close the audio stream controller
      await _audioStreamController?.close();
      _audioStreamController = null;
      
      _isCapturing = false;
      Logger.info("[DEBUG] [AudioCaptureDataSourceImpl] Capture stopped");
      return true;
      
    } catch (e) {
      Logger.error("[DEBUG] [AudioCaptureDataSourceImpl] Failed to stop capture", e);
      throw AudioStopException(
        'Failed to stop audio capture: ${e.toString()}',
      );
    } finally {
      // Ensure state is reset even if stop fails
      _isCapturing = false;
      _micStreamSubscription = null;
      _audioStreamController = null;
    }
  }
  
  @override
  bool get isCapturing => _isCapturing;
  
  @override
  Future<int> get actualSampleRate async {
    if (_isCapturing) {
      return _actualSampleRate;
    }
    return AudioConstants.targetSampleRate;
  }
  
  @override
  Future<int> get actualBitDepth async {
    // PCM 16-bit
    return 16;
  }
  
  @override
  Future<int> get actualChannels async {
    // We request 1 channel
    return 1;
  }
  
  @override
  Future<int> get bufferSize async {
    // Not exposed by record package directly, return standard value or approximation
    return 2048; 
  }
  
  @override
  Future<bool> isMicrophoneAvailable() async {
    try {
      return await _audioRecorder.hasPermission();
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<Map<String, dynamic>> getPlatformAudioInfo() async {
    try {
      return {
        'sampleRate': _actualSampleRate,
        'bitDepth': 16,
        'bufferSize': 2048,
        'isCapturing': _isCapturing,
        'requestedSampleRate': _requestedSampleRate,
        'actualSampleRate': _actualSampleRate,
        'channels': 1,
        'actualBitDepth': 16,
      };
    } catch (e) {
      return {
        'error': 'Failed to get platform audio info: ${e.toString()}',
        'isCapturing': _isCapturing,
        'requestedSampleRate': _requestedSampleRate,
        'actualSampleRate': _actualSampleRate,
      };
    }
  }
  
  /// Resample audio data if needed (FR-002)
  /// 
  /// This method handles resampling from higher sample rates (44.1kHz, 48kHz)
  /// to the target 16kHz sample rate as specified in FR-002
  List<int> _resampleIfNeeded(List<int> audioData) {
    // For now, return the original data
    // TODO: Implement proper resampling algorithm
    // This would involve:
    // 1. Detecting the actual sample rate from the hardware
    // 2. Applying appropriate resampling (decimation/interpolation)
    // 3. Ensuring the output is at the target 16kHz sample rate
    return audioData;
  }
  
  /// Dispose the recorder
  void dispose() {
    _audioRecorder.dispose();
  }
}