import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/sherpa_model.dart';

final modelManagerProvider = Provider<ModelManager>((ref) {
  return ModelManager();
});

class ModelManager {
  static const String _boxName = 'sherpa_models';
  Box<SherpaModel>? _box;

  // Hardcoded English Models
  static final List<SherpaModel> _defaultModels = [
    SherpaModel(
      id: 'asr_en_zipformer',
      name: 'Streaming ASR (Zipformer)',
      type: ModelType.asr,
      url: 'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-streaming-zipformer-en-2023-02-21.tar.bz2',
      sha256: 'a3d2c7f5', // Placeholder
      compressedSize: 397939030,
      uncompressedSize: 450000000,
    ),
    SherpaModel(
      id: 'tts_en_amy',
      name: 'TTS (Amy Low)',
      type: ModelType.tts,
      url: 'https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-piper-en_US-amy-low.tar.bz2',
      sha256: 'c70f5284a09a7fd4ed203b39b2ff51cac1432b422b852eb647b481dade3cf639',
      compressedSize: 67095344,
      uncompressedSize: 100000000,
    ),
    SherpaModel(
      id: 'vad_silero',
      name: 'VAD (Silero)',
      type: ModelType.vad,
      url: 'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/silero_vad.onnx',
      sha256: '9e2449e1087496d8d4caba907f23e0bd3f78d91fa552479bb9c23ac09cbb1fd6',
      compressedSize: 643854,
      uncompressedSize: 643854,
    ),
    SherpaModel(
      id: 'speaker_id_nemo',
      name: 'Speaker Verification (Nemo)',
      type: ModelType.speakerId,
      url: 'https://github.com/k2-fsa/sherpa-onnx/releases/download/speaker-recongition-models/sherpa-onnx-nemo-speaker-verification-en-titanet_large.tar.bz2',
      sha256: 'd6g7h2j3',
      compressedSize: 25000000,
      uncompressedSize: 60000000,
    ),
    SherpaModel(
      id: 'punct_en_zh',
      name: 'Punctuation (EN/ZH)',
      type: ModelType.punctuation,
      url: 'https://github.com/k2-fsa/sherpa-onnx/releases/download/punctuation-models/sherpa-onnx-punct-ct-transformer-zh-en-vocab272727-2024-04-12.tar.bz2',
      sha256: 'e7h8i9k4',
      compressedSize: 279028058,
      uncompressedSize: 400000000,
    ),
    SherpaModel(
      id: 'audio_tagging_zipformer',
      name: 'Audio Tagging (Zipformer)',
      type: ModelType.audioTagging,
      url: 'https://github.com/k2-fsa/sherpa-onnx/releases/download/audio-tagging-models/sherpa-onnx-zipformer-audio-tagging-2024-04-09.tar.bz2',
      sha256: 'f8j9k0l5',
      compressedSize: 302315957,
      uncompressedSize: 400000000,
    ),
    SherpaModel(
      id: 'enhancement_fsmn',
      name: 'Speech Enhancement (FSMN)',
      type: ModelType.enhancement,
      url: 'https://github.com/k2-fsa/sherpa-onnx/releases/download/speech-enhancement-models/sherpa-onnx-fsmn-2024-06-24.tar.bz2',
      sha256: 'g9k1l2m6',
      compressedSize: 5000000,
      uncompressedSize: 10000000,
    ),
    SherpaModel(
      id: 'separation_tasnet',
      name: 'Source Separation (TasNet)',
      type: ModelType.separation,
      url: 'https://github.com/k2-fsa/sherpa-onnx/releases/download/source-separation-models/sherpa-onnx-conv-tasnet-2024-06-24.tar.bz2',
      sha256: 'h0l3m4n7',
      compressedSize: 8000000,
      uncompressedSize: 20000000,
    ),
    SherpaModel(
      id: 'kws_gigaspeech',
      name: 'Keyword Spotting (Gigaspeech)',
      type: ModelType.kws,
      url: 'https://github.com/k2-fsa/sherpa-onnx/releases/download/kws-models/sherpa-onnx-kws-zipformer-gigaspeech-3.3M-2024-01-01.tar.bz2',
      sha256: 'i1m5n6o8',
      compressedSize: 17626723,
      uncompressedSize: 40000000,
    ),
    SherpaModel(
      id: 'lid_whisper_tiny',
      name: 'Language ID (Whisper Tiny)',
      type: ModelType.lid, 
      url: 'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-whisper-tiny.tar.bz2',
      sha256: 'j2n7o8p9',
      compressedSize: 116204861,
      uncompressedSize: 150000000,
    ),
    SherpaModel(
      id: 'diarization_segmentation',
      name: 'Speaker Diarization (Segmentation)',
      type: ModelType.diarization, 
      url: 'https://github.com/k2-fsa/sherpa-onnx/releases/download/speaker-segmentation-models/sherpa-onnx-pyannote-segmentation-3-0.tar.bz2',
      sha256: 'k3o9p0q1',
      compressedSize: 5000000,
      uncompressedSize: 10000000,
    ),
  ];

  Future<void> init() async {
    for(var i in _defaultModels){
      debugPrint('ModelManager: Checking default model ${i.url}');
    }
    // Hive should be initialized in main, but we ensure adapter registration here just in case,
    // protecting against double registration.
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ModelTypeAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(SherpaModelAdapter());
    
    if (_box == null || !_box!.isOpen) {
      debugPrint('ModelManager: Opening Hive box $_boxName');
      _box = await Hive.openBox<SherpaModel>(_boxName);
    }

    // Sync default models with box
    for (var model in _defaultModels) {
      debugPrint('${model.url}');
      if (!_box!.containsKey(model.id)) {
        debugPrint('ModelManager: Adding default model ${model.id}');
        await _box!.put(model.id, model);
      } else {
        // Check if URL or metadata changed and update while preserving local state
        final existing = _box!.get(model.id)!;
        if (existing.url != model.url || existing.sha256 != model.sha256) {
           debugPrint('ModelManager: Updating metadata for ${model.id}');
           // Create a new model with updated metadata but keep local state
           final updated = SherpaModel(
             id: model.id,
             name: model.name,
             type: model.type,
             url: model.url,
             sha256: model.sha256,
             compressedSize: model.compressedSize,
             uncompressedSize: model.uncompressedSize,
             localPath: existing.localPath,
             isInstalled: existing.isInstalled,
           );
           await _box!.put(model.id, updated);
        }
      }
    }
  }

  List<SherpaModel> getAllModels() {
    return _box?.values.toList() ?? [];
  }

  SherpaModel? getModel(String id) {
    return _box?.get(id);
  }

  Future<void> downloadModel(String id, {Function(double)? onProgress}) async {
    debugPrint('ModelManager: Starting download for $id');
    final model = _box?.get(id);
    if (model == null) {
      debugPrint('ModelManager: Model $id not found in box');
      return;
    }

    try {
      final appDir = await getApplicationSupportDirectory();
      final modelDir = Directory('${appDir.path}/models/$id');
      if (!await modelDir.exists()) {
        await modelDir.create(recursive: true);
      }

      final fileName = model.url.split('/').last;
      final filePath = '${modelDir.path}/$fileName';
      final file = File(filePath);

      debugPrint('ModelManager: Downloading to $filePath');

      // Start download
      final request = http.Request('GET', Uri.parse(model.url));
      final response = await http.Client().send(request);
      
      if (response.statusCode != 200) {
        throw Exception('Failed to download model: HTTP ${response.statusCode}');
      }

      final contentLength = response.contentLength ?? model.compressedSize;

      int receivedBytes = 0;
      final sink = file.openWrite();

      await response.stream.listen(
        (chunk) {
          sink.add(chunk);
          receivedBytes += chunk.length;
          if (onProgress != null) {
            onProgress(receivedBytes / contentLength);
          }
        },
        onDone: () async {
          await sink.close();
          debugPrint('ModelManager: Download complete for $id');
        },
        onError: (e) {
          sink.close();
          debugPrint('ModelManager: Download error for $id: $e');
          throw e;
        },
        cancelOnError: true,
      ).asFuture();

      // Unzip if needed (using compute to avoid blocking main thread)
      debugPrint('ModelManager: Extracting $fileName...');
      if (fileName.endsWith('.tar.bz2')) {
        await compute(_extractTarBz2, {'filePath': file.path, 'outputPath': modelDir.path});
        await file.delete(); 
      } else if (fileName.endsWith('.zip')) {
        await compute(_extractZip, {'filePath': file.path, 'outputPath': modelDir.path});
        await file.delete();
      } else {
        // Just move/keep single file models like .onnx
        // Already in place
      }
      debugPrint('ModelManager: Extraction complete for $id');

      // Update model status
      final updatedModel = model.copyWith(
        isInstalled: true,
        localPath: modelDir.path,
      );
      await _box!.put(id, updatedModel);
      debugPrint('ModelManager: Model $id marked as installed at ${modelDir.path}');

    } catch (e) {
      debugPrint('ModelManager: Error downloading/installing $id: $e');
      rethrow;
    }
  }

  Future<void> deleteModel(String id) async {
    debugPrint('ModelManager: Deleting model $id');
    final model = _box?.get(id);
    if (model == null || !model.isInstalled) return;

    final dir = Directory(model.localPath);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }

    final updatedModel = model.copyWith(
      isInstalled: false,
      localPath: '',
    );
    await _box!.put(id, updatedModel);
    debugPrint('ModelManager: Model $id deleted');
  }

  Future<void> clearCache() async {
    debugPrint('ModelManager: Clearing all cache');
    final models = getAllModels();
    for (var model in models) {
      if (model.isInstalled) {
        await deleteModel(model.id);
      }
    }
  }
}

// Top-level functions for compute
Future<void> _extractTarBz2(Map<String, String> args) async {
  final filePath = args['filePath']!;
  final outputPath = args['outputPath']!;
  final file = File(filePath);
  
  final bytes = await file.readAsBytes();
  final decompressed = BZip2Decoder().decodeBytes(bytes);
  final archive = TarDecoder().decodeBytes(decompressed);
  
  for (final file in archive) {
    final filename = file.name;
    if (file.isFile) {
      final data = file.content as List<int>;
      File('$outputPath/$filename')
        ..createSync(recursive: true)
        ..writeAsBytesSync(data);
    } else {
      Directory('$outputPath/$filename').createSync(recursive: true);
    }
  }
}

Future<void> _extractZip(Map<String, String> args) async {
  final filePath = args['filePath']!;
  final outputPath = args['outputPath']!;
  final file = File(filePath);

  final bytes = await file.readAsBytes();
  final archive = ZipDecoder().decodeBytes(bytes);
  
  for (final file in archive) {
    final filename = file.name;
    if (file.isFile) {
      final data = file.content as List<int>;
      File('$outputPath/$filename')
        ..createSync(recursive: true)
        ..writeAsBytesSync(data);
    } else {
      Directory('$outputPath/$filename').createSync(recursive: true);
    }
  }
}