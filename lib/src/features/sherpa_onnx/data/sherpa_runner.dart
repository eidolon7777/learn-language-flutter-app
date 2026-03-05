// import 'dart:io';
// import 'dart:async';
// import 'dart:typed_data';
// import 'package:flutter/foundation.dart';
// //import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;
// import 'package:path/path.dart' as p;
// import 'model_manager.dart';

// import '../domain/sherpa_model.dart';

// class SherpaRunner {
//   final ModelManager _modelManager;

//   sherpa.OnlineRecognizer? _onlineRecognizer;
//   sherpa.OfflineTts? _offlineTts;
//   sherpa.VoiceActivityDetector? _vad;
//   sherpa.SpeakerEmbeddingExtractor? _speakerExtractor;
//   sherpa.SpokenLanguageIdentification? _lid;
//   sherpa.OfflineSpeakerDiarization? _diarization;
  
//   StreamSubscription? _asrSubscription;
//   StreamSubscription? _vadSubscription;

//   SherpaRunner(this._modelManager) {
//     sherpa.initBindings();
//   }

//   /// Initialize Streaming ASR
//   Future<void> initAsr(String modelId) async {
//     final model = _modelManager.getModel(modelId);
//     if (model == null || !model.isInstalled) {
//       throw Exception('Model $modelId not installed');
//     }

//     debugPrint('SherpaRunner: Initializing ASR with model $modelId at ${model.localPath}');

//     final dir = Directory(model.localPath);
//     if (!dir.existsSync()) {
//        throw Exception('Model directory not found: ${model.localPath}');
//     }
    
//     final files = dir.listSync(recursive: true).whereType<File>().toList();
    
//     String? tokens = _findFile(files, ['tokens.txt']);
//     String? encoder = _findFile(files, ['encoder', 'encoder-epoch-99-avg-1'], extension: '.onnx');
//     String? decoder = _findFile(files, ['decoder', 'decoder-epoch-99-avg-1'], extension: '.onnx');
//     String? joiner = _findFile(files, ['joiner', 'joiner-epoch-99-avg-1'], extension: '.onnx');

//     if (tokens == null || encoder == null || decoder == null || joiner == null) {
//       throw Exception('Missing ASR model files in ${model.localPath}');
//     }

//     final config = sherpa.OnlineRecognizerConfig(
//       model: sherpa.OnlineModelConfig(
//         transducer: sherpa.OnlineTransducerModelConfig(
//           encoder: encoder,
//           decoder: decoder,
//           joiner: joiner,
//         ),
//         tokens: tokens,
//         numThreads: 1,
//         debug: false,
//       ),
//     );

//     _onlineRecognizer = sherpa.OnlineRecognizer(config);
//     debugPrint('SherpaRunner: ASR Initialized');
//   }

//   void startAsrStream(Stream<List<int>> audioStream, Function(String) onText) {
//     if (_onlineRecognizer == null) {
//       debugPrint('SherpaRunner: ASR not initialized');
//       return;
//     }
    
//     final stream = _onlineRecognizer!.createStream();
    
//     _asrSubscription = audioStream.listen((data) {
//         final samples = _int16ToFloat32(data);
//         final floatSamples = Float32List.fromList(samples);
        
//         stream.acceptWaveform(samples: floatSamples, sampleRate: 16000);
        
//         while (_onlineRecognizer!.isReady(stream)) {
//           _onlineRecognizer!.decode(stream);
//         }
        
//         final result = _onlineRecognizer!.getResult(stream);
//         if (result.text.isNotEmpty) {
//            onText(result.text);
//         }
//     });
//   }

//   void stopAsrStream() {
//     _asrSubscription?.cancel();
//     _asrSubscription = null;
//   }

//   /// Initialize TTS
//   Future<void> initTts(String modelId) async {
//     final model = _modelManager.getModel(modelId);
//     if (model == null || !model.isInstalled) {
//       throw Exception('Model $modelId not installed');
//     }

//     final dir = Directory(model.localPath);
//     // We need both files and directories (for espeak-ng-data)
//     final fileEntities = dir.listSync(recursive: true).toList();

//     String? vitsModel = _findFile(fileEntities, ['.onnx'], extension: '.onnx');
//     String? tokens = _findFile(fileEntities, ['tokens.txt']);
//     String? dataDir = _findFile(fileEntities, ['espeak-ng-data'], isDirectory: true);
    
//     if (vitsModel == null || tokens == null) {
//        throw Exception('Missing TTS model files');
//     }
    
//     // Ensure dataDir is valid for Piper models
//     if (dataDir == null && model.url.contains('piper')) {
//        debugPrint('SherpaRunner: Warning - espeak-ng-data directory not found for Piper model. TTS might fail.');
//        // We don't throw here as some might not need it, but it's likely an issue.
//     }

//     final config = sherpa.OfflineTtsConfig(
//       model: sherpa.OfflineTtsModelConfig(
//         vits: sherpa.OfflineTtsVitsModelConfig(
//           model: vitsModel,
//           tokens: tokens,
//           dataDir: dataDir ?? '',
//         ),
//         numThreads: 1,
//         debug: false,
//       ),
//     );

//     _offlineTts = sherpa.OfflineTts(config);
//     debugPrint('SherpaRunner: TTS Initialized');
//   }

//   Future<sherpa.GeneratedAudio?> generateTts(String text, {int speakerId = 0, double speed = 1.0}) async {
//     if (_offlineTts == null) return null;
//     return _offlineTts!.generate(text: text, sid: speakerId, speed: speed);
//   }

//   /// Initialize VAD
//   Future<void> initVad(String modelId) async {
//      final model = _modelManager.getModel(modelId);
//     if (model == null || !model.isInstalled) {
//       throw Exception('Model $modelId not installed');
//     }

//     final dir = Directory(model.localPath);
//     final files = dir.listSync(recursive: true).whereType<File>().toList();
    
//     // For VAD, look for silero_vad.onnx specifically or just .onnx
//     String? vadModel = _findFile(files, ['silero_vad', 'model'], extension: '.onnx');
    
//     if (vadModel == null) {
//       throw Exception('Missing VAD model file');
//     }

//     final config = sherpa.VadModelConfig(
//       sileroVad: sherpa.SileroVadModelConfig(
//         model: vadModel,
//         threshold: 0.5,
//         minSpeechDuration: 0.25,
//         minSilenceDuration: 0.5,
//       ),
//       sampleRate: 16000,
//       numThreads: 1,
//       debug: false,
//     );
    
//     _vad = sherpa.VoiceActivityDetector(config: config, bufferSizeInSeconds: 60);
//     debugPrint('SherpaRunner: VAD Initialized');
//   }
  
//   void startVadStream(Stream<List<int>> audioStream, Function(bool) onSpeech) {
//     if (_vad == null) return;
    
//     _vad!.reset();
//     _vadSubscription = audioStream.listen((data) {
//         final samples = _int16ToFloat32(data);
//         final floatSamples = Float32List.fromList(samples);
//         _vad!.acceptWaveform(floatSamples);
        
//         // Use detected based on !isEmpty
//         // isEmpty means silence
//         bool detected = !_vad!.isEmpty(); 
        
//         // We should also check isDetected if possible, but isEmpty is the main check for VAD in some examples
//         // However, for Silero VAD, we might need to check if we have speech segments
        
//         onSpeech(detected);
        
//         if (detected) {
//           _vad!.pop();
//         }
//     });
//   }

//   void stopVadStream() {
//     _vadSubscription?.cancel();
//     _vadSubscription = null;
//   }
  
//   /// Initialize Speaker ID (Embedding Extractor)
//   Future<void> initSpeakerId(String modelId) async {
//     final model = _modelManager.getModel(modelId);
//     if (model == null || !model.isInstalled) {
//       throw Exception('Model $modelId not installed');
//     }
    
//     final dir = Directory(model.localPath);
//     final files = dir.listSync(recursive: true).whereType<File>().toList();
    
//     String? embeddingModel = _findFile(files, ['titanet', 'resnet', 'model'], extension: '.onnx');
    
//     if (embeddingModel == null) {
//       throw Exception('Missing Speaker ID model file');
//     }
    
//     final config = sherpa.SpeakerEmbeddingExtractorConfig(
//       model: embeddingModel,
//       numThreads: 1,
//       debug: false,
//     );
    
//     _speakerExtractor = sherpa.SpeakerEmbeddingExtractor(config: config);
//     debugPrint('SherpaRunner: Speaker ID Initialized');
//   }
  
//   /// Initialize Language ID
//   Future<void> initLid(String modelId) async {
//     final model = _modelManager.getModel(modelId);
//     if (model == null || !model.isInstalled) {
//       throw Exception('Model $modelId not installed');
//     }
    
//     final dir = Directory(model.localPath);
//     final files = dir.listSync(recursive: true).whereType<File>().toList();
    
//     String? encoder = _findFile(files, ['encoder', 'tiny-encoder'], extension: '.onnx');
//     String? decoder = _findFile(files, ['decoder', 'tiny-decoder'], extension: '.onnx');
    
//     if (encoder == null || decoder == null) {
//       // Try single model (some LID models are single file)
//       String? modelFile = _findFile(files, ['model'], extension: '.onnx');
//       if (modelFile == null) {
//         throw Exception('Missing LID model files');
//       }
//       // If single file, might be different config, but Whisper usually needs encoder/decoder
//       // Assuming Whisper based LID for now as per model list
//       throw Exception('Missing Whisper LID model files (encoder/decoder). If you downloaded a Zipformer model, it might not be supported yet.');
//     }
    
//     final config = sherpa.SpokenLanguageIdentificationConfig(
//       whisper: sherpa.SpokenLanguageIdentificationWhisperConfig(
//         encoder: encoder,
//         decoder: decoder,
//         tailPaddings: -1, // default
//       ),
//       numThreads: 1,
//       debug: false,
//     );
    
//     _lid = sherpa.SpokenLanguageIdentification(config);
//     debugPrint('SherpaRunner: LID Initialized');
//   }

//   /// Initialize Speaker Diarization
//   Future<void> initDiarization(String modelId) async {
//     final model = _modelManager.getModel(modelId);
//     if (model == null || !model.isInstalled) {
//       throw Exception('Model $modelId not installed');
//     }
    
//     final dir = Directory(model.localPath);
//     final files = dir.listSync(recursive: true).whereType<File>().toList();
    
//     // For diarization, we need segmentation model and embedding model
//     // The current download link in model_manager is just for segmentation (pyannote)
//     // We also need an embedding model (like titanet)
    
//     String? segmentationModel = _findFile(files, ['segmentation', 'model'], extension: '.onnx');
//     String? embeddingModel = _findFile(files, ['titanet', 'resnet'], extension: '.onnx'); // This might be missing if downloaded separately
    
//     // Check if user has downloaded speaker id model separately and we can use it?
//     // Or maybe the diarization package includes both? 
//     // The current URL is `sherpa-onnx-pyannote-segmentation-3.0.tar.bz2`.
//     // It only contains segmentation model.
    
//     if (segmentationModel == null) {
//       throw Exception('Missing Diarization Segmentation model file');
//     }
    
//     if (embeddingModel == null) {
//         // Fallback: Check if we have a speaker_id model installed and use that
//         final embeddingModels = _modelManager.getAllModels().where((m) => m.type == ModelType.speakerId && m.isInstalled).toList();
//         if (embeddingModels.isNotEmpty) {
//            final embeddingDir = Directory(embeddingModels.first.localPath);
//            final embeddingFiles = embeddingDir.listSync(recursive: true).whereType<File>().toList();
//            embeddingModel = _findFile(embeddingFiles, ['titanet', 'resnet', 'model'], extension: '.onnx');
//         }
//     }
    
//     if (embeddingModel == null) {
//        throw Exception('Missing Embedding model for Diarization. Please download a Speaker Verification model.');
//     }

//     final config = sherpa.OfflineSpeakerDiarizationConfig(
//       segmentation: sherpa.OfflineSpeakerSegmentationModelConfig(
//         pyannote: sherpa.OfflineSpeakerSegmentationPyannoteModelConfig(
//           model: segmentationModel,
//         ),
//       ),
//       embedding: sherpa.SpeakerEmbeddingExtractorConfig(
//         model: embeddingModel,
//       ),
//       clustering: const sherpa.FastClusteringConfig(
//         numClusters: -1, // Auto
//         threshold: 0.5,
//       ),
//     );
    
//     _diarization = sherpa.OfflineSpeakerDiarization(config);
//     debugPrint('SherpaRunner: Diarization Initialized');
//   }

//   Future<dynamic> diarize(List<double> samples) async {
//     if (_diarization == null) return null;
//     // process usually takes Float32List or List<double>
//     return _diarization!.process(samples: Float32List.fromList(samples));
//   }

//   Future<String?> computeLid(List<double> samples) async {
//     if (_lid == null) return null;
//     final stream = _lid!.createStream();
//     stream.acceptWaveform(samples: Float32List.fromList(samples), sampleRate: 16000);
//     final result = _lid!.compute(stream);
//     return result.lang;
//   }

//   // Helper to find files
//   String? _findFile(List<FileSystemEntity> files, List<String> patterns, {String? extension, bool isDirectory = false}) {
//     try {
//       final found = files.firstWhere((f) {
//         if (isDirectory && f is! Directory) return false;
//         if (!isDirectory && f is! File) return false;
        
//         final name = p.basename(f.path);
//         bool match = false;
//         for (var pattern in patterns) {
//            if (name.contains(pattern)) {
//              match = true;
//              break;
//            }
//         }
        
//         if (match && extension != null) {
//           match = match && name.endsWith(extension);
//         }
//         return match;
//       });
      
//       if (!isDirectory && found is File) {
//         // Check for extremely small files (likely corrupted downloads or empty files)
//         // But be careful not to exclude valid small configuration files like tokens.txt
//         // 100 bytes is a safer lower bound, or we can check extension.
//         if (found.lengthSync() < 50) { 
//           debugPrint('SherpaRunner: Warning - Found file ${found.path} but it is very small (${found.lengthSync()} bytes). Ignoring.');
//           return null;
//         }
//       }
      
//       return found.path;
//     } catch (e) {
//       return null;
//     }
//   }

//   // PCM16 to Float32 conversion
//   List<double> _int16ToFloat32(List<int> data) {
//     // Ensure we have an even number of bytes for Int16
//     if (data.length % 2 != 0) {
//       debugPrint('SherpaRunner: Warning - odd number of bytes (${data.length}), trimming last byte.');
//       data = data.sublist(0, data.length - 1);
//     }
    
//     // Create Uint8List from input data to ensure it's a typed array
//     final uint8List = Uint8List.fromList(data);
    
//     // Create Int16 view
//     final int16List = Int16List.view(uint8List.buffer);
    
//     final floatList = Float32List(int16List.length);
//     for (var i = 0; i < int16List.length; i++) {
//       floatList[i] = int16List[i] / 32768.0;
//     }
//     return floatList;
//   }
  
//   void disposeAsr() {
//     _onlineRecognizer?.free();
//     _onlineRecognizer = null;
//     stopAsrStream();
//   }
  
//   void disposeTts() {
//     _offlineTts?.free();
//     _offlineTts = null;
//   }
  
//   void disposeVad() {
//     _vad?.free();
//     _vad = null;
//     stopVadStream();
//   }
  
//   void disposeSpeakerId() {
//     _speakerExtractor?.free();
//     _speakerExtractor = null;
//   }
  
//   void disposeLid() {
//     _lid?.free();
//     _lid = null;
//   }
  
//   void disposeDiarization() {
//     _diarization?.free();
//     _diarization = null;
//   }

//   void dispose() {
//     disposeAsr();
//     disposeTts();
//     disposeVad();
//     disposeSpeakerId();
//     disposeLid();
//     disposeDiarization();
//   }
// }

class SherpaRunner{}
