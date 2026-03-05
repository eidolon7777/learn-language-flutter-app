import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:learn_language/src/features/sherpa_onnx/data/sherpa_provider.dart';
import '../../../domain/sherpa_model.dart';

class LidScreen extends ConsumerStatefulWidget {
  final SherpaModel model;
  const LidScreen({super.key, required this.model});

  @override
  ConsumerState<LidScreen> createState() => _LidScreenState();
}

class _LidScreenState extends ConsumerState<LidScreen> {
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String _status = 'Initializing...';
  String _detectedLanguage = '';
  
  @override
  void initState() {
    super.initState();
    _initModel();
  }

  Future<void> _initModel() async {
    try {
   //   await ref.read(sherpaRunnerProvider).initLid(widget.model.id);
      if (mounted) setState(() => _status = 'Ready (Record to detect language)');
    } catch (e) {
      if (mounted) setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final stream = await _audioRecorder.startStream(
          const RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: 16000,
            numChannels: 1,
          ),
        );

        setState(() {
          _isRecording = true;
          _status = 'Listening...';
          _detectedLanguage = '';
        });

        // Collect samples for a short duration or continuously
        // For LID, we usually need a few seconds
        List<int> buffer = [];
        final subscription = stream.listen((data) {
          buffer.addAll(data);
          // Process every 3 seconds (approx 96000 bytes for 16kHz 16bit mono)
          if (buffer.length >= 96000) {
             _processBuffer(List.from(buffer));
             buffer.clear();
          }
        });
        
        // Store subscription to cancel later?
        // Or just let it run until stop is pressed
      }
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }
  
  Future<void> _processBuffer(List<int> data) async {
    // Convert to float
    // We need to access _int16ToFloat32 from SherpaRunner, but it's private.
    // So we implement it locally or expose it.
    // For now, implement locally.
    final floatSamples = _int16ToFloat32(data);
    
    try {
      // final result = await ref.read(sherpaRunnerProvider).computeLid(floatSamples);
      // if (mounted && result != null) {
      //   setState(() {
      //      _detectedLanguage = result;
      //      _status = 'Detected: $result';
      //   });
      // }
    } catch (e) {
      debugPrint('LID Error: $e');
    }
  }
  
  List<double> _int16ToFloat32(List<int> data) {
    if (data.length % 2 != 0) {
      data = data.sublist(0, data.length - 1);
    }
    final uint8List = Uint8List.fromList(data);
    final int16List = Int16List.view(uint8List.buffer);
    final floatList = Float32List(int16List.length);
    for (var i = 0; i < int16List.length; i++) {
      floatList[i] = int16List[i] / 32768.0;
    }
    return floatList;
  }
  
  Future<void> _stopRecording() async {
    await _audioRecorder.stop();
    setState(() {
      _isRecording = false;
      if (_detectedLanguage.isEmpty) _status = 'Stopped';
    });
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
   // ref.read(sherpaRunnerProvider).disposeLid();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.model.name)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            if (_detectedLanguage.isNotEmpty)
              Text(
                _detectedLanguage,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 40),
             FloatingActionButton(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              child: Icon(_isRecording ? Icons.stop : Icons.mic),
            ),
          ],
        ),
      ),
    );
  }
}
