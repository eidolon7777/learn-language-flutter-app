import 'dart:io';
import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

class PosModelService {
  late OrtSession _session;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      developer.log('[DEBUG] [PosModelService] : Already initialized');
      return;
    }

    try {
      developer.log('[DEBUG] [PosModelService] : Initializing...');
      // Initialize environment
      final ort = OnnxRuntime();
      
      // Ensure external data file is also available if needed.
      // However, createSessionFromAsset usually handles single file.
      // If the model has external data, we might need to copy all related files to a local directory manually.
      // The error says: filesystem error: in file_size: No such file or directory [".../pos_model.onnx.data"]
      // This means the ONNX runtime is looking for the external data file relative to the model file.
      // When using createSessionFromAsset, the plugin copies the asset to a temporary location.
      // But it might not be copying the sidecar .data file.
      
      // Let's switch to manual copy approach for both files.
      
      final modelFile = await _copyAssetToLocal('assets/models/pos_model.onnx');
       await _copyAssetToLocal('assets/models/pos_model.onnx.data'); // Copy external data
       
       // flutter_onnxruntime: createSession(String path)
       _session = await ort.createSession(modelFile.path);
       _isInitialized = true;
       developer.log('[DEBUG] [PosModelService] : Initialization successful');
    } catch (e) {
      developer.log('[DEBUG] [PosModelService] : Error initializing: $e', error: e);
      print("Error initializing [DEBUG] [PosModelService] : $e");
      rethrow;
    }
  }

  Future<List<List<double>>> run(List<int> inputIds) async {
    developer.log('[DEBUG] [PosModelService] : run called with inputIds length: ${inputIds.length}');
    if (!_isInitialized) {
      developer.log('[DEBUG] [PosModelService] : Not initialized');
      throw Exception("PosModelService not initialized");
    }

    // Prepare input tensor
    // The model seems to have a fixed input size of 10 based on the error:
    // "Got invalid dimensions for input: input for the following indices index: 1 Got: 4 Expected: 10"
    // We must pad or truncate the input to length 10.
    const fixedLength = 10;
    List<int> paddedInputIds;
    
    if (inputIds.length < fixedLength) {
      paddedInputIds = List<int>.from(inputIds)
        ..addAll(List.filled(fixedLength - inputIds.length, 0)); // Pad with 0
    } else {
      paddedInputIds = inputIds.sublist(0, fixedLength); // Truncate
    }
    developer.log('[DEBUG] [PosModelService] : paddedInputIds: $paddedInputIds');

    // Shape: [1, 10]
    final shape = [1, fixedLength];
    
    // Create tensor
    // flutter_onnxruntime: OrtValue.fromList(List<dynamic> data, List<int> shape)
    // Pass Int64List to ensure tensor is int64. 
    // If inputIds is just List<int>, it defaults to int32.
    final inputData = Int64List.fromList(paddedInputIds);
    final inputTensor = await OrtValue.fromList(inputData, shape);
    
    final inputs = {'input': inputTensor};
    
    Map<String, OrtValue?>? outputs;
    try {
      developer.log('[DEBUG] [PosModelService] : Running session...');
      outputs = await _session.run(inputs);
      developer.log('[DEBUG] [PosModelService] : Session run complete. Outputs count: ${outputs.length}');
    } catch (e) {
      developer.log('[DEBUG] [PosModelService] : Error during session run: $e', error: e);
      rethrow;
    } finally {
      // Release input tensor if possible, otherwise rely on GC
      // inputTensor.dispose(); 
    }
    
    if (outputs.isEmpty) {
       throw Exception("Model returned empty output");
    }
    
    // Get output. Assuming output name is 'output'
    // If we don't know the name, we can iterate.
    final outputVal = outputs.values.first;
    if (outputVal == null) throw Exception("Model returned null output value");

    final result = await outputVal.asList(); // Returns List<dynamic>
    
    // Result structure depends on model output shape.
    // If model outputs [1, seq_len, num_tags], asList() might flatten it or return nested lists.
    // The previous implementation assumed nested lists.
    // Let's assume flutter_onnxruntime returns nested lists for multidimensional tensors.
    
    if (result.isNotEmpty && result[0] is List) {
       // It's likely [batch, seq, tags] or [batch, tags]
       // We need to match the return type List<List<double>>
       // If it is [1, seq, tags], then result[0] is [seq, tags]
       
       final batch = result;
       final sequence = batch[0] as List;
       
       // Slice the output to match the original input length (up to fixedLength)
       final relevantLength = inputIds.length < fixedLength ? inputIds.length : fixedLength;
       final slicedSequence = sequence.sublist(0, relevantLength);
       
       return slicedSequence.map((e) => (e as List).cast<double>()).toList();
    }
    
    // Fallback if 2D
    // If output is [seq, tags] (batch dimension squeezed or not present)
    final relevantLength = inputIds.length < fixedLength ? inputIds.length : fixedLength;
    final slicedResult = result.sublist(0, relevantLength);
    
    return slicedResult.map((e) => (e as List).cast<double>()).toList();
  }
  
  void dispose() {
    if (_isInitialized) {
      // _session.release(); // Check if session needs release
      _isInitialized = false;
    }
  }

  Future<File> _copyAssetToLocal(String assetPath) async {
    final directory = await getApplicationSupportDirectory();
    final fileName = assetPath.split('/').last;
    final file = File('${directory.path}/$fileName');
    
    // Always overwrite to ensure latest version or check hash if needed.
    // For now, let's overwrite if size is 0 or it doesn't exist.
    if (!await file.exists()) {
       final byteData = await rootBundle.load(assetPath);
       await file.writeAsBytes(byteData.buffer.asUint8List());
    }
    
    return file;
  }
}
