import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:learn_language/src/features/sherpa_onnx/data/sherpa_provider.dart';
import '../../../domain/sherpa_model.dart';

class DiarizationScreen extends ConsumerStatefulWidget {
  final SherpaModel model;
  const DiarizationScreen({super.key, required this.model});

  @override
  ConsumerState<DiarizationScreen> createState() => _DiarizationScreenState();
}

class _DiarizationScreenState extends ConsumerState<DiarizationScreen> {
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String _status = 'Initializing...';
  List<dynamic> _segments = []; // Use dynamic for now
  
  @override
  void initState() {
    super.initState();
    _initModel();
  }

  Future<void> _initModel() async {
    try {
    //  await ref.read(sherpaRunnerProvider).initDiarization(widget.model.id);
      if (mounted) setState(() => _status = 'Ready (Record to analyze speakers)');
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
          _status = 'Recording (Press stop to analyze)...';
          _segments = [];
        });

        List<int> buffer = [];
        stream.listen((data) {
          buffer.addAll(data);
        }, onDone: () {
           _processBuffer(List.from(buffer));
        });
      }
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }
  
  Future<void> _processBuffer(List<int> data) async {
    if (data.isEmpty) return;
    
    setState(() => _status = 'Processing...');
    
    final floatSamples = _int16ToFloat32(data);
    
    try {
    //  final result = await ref.read(sherpaRunnerProvider).diarize(floatSamples);
      // if (mounted && result != null) {
      //   // result should have segments
      //   // We assume result has .segments property which is a List
      //   // Since we used dynamic, we need to inspect it or assume structure
      //   // Usually it's result.timestamps or result.segments
      //   // Let's assume result is printable for now
      //   setState(() {
      //      // For now just show string representation if we can't iterate
      //      _status = 'Done';
      //      // If result is iterable, we can show list
      //      // But let's just show raw result for debugging first
      //      _segments = [result.toString()]; 
      //   });
      // } else {
      //   setState(() => _status = 'No segments found');
      // }
    } catch (e) {
      if (mounted) setState(() => _status = 'Error: $e');
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
    });
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
  //  ref.read(sherpaRunnerProvider).disposeDiarization();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.model.name)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(_status, textAlign: TextAlign.center),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _segments.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_segments[index].toString()),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: FloatingActionButton(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              child: Icon(_isRecording ? Icons.stop : Icons.mic),
            ),
          ),
        ],
      ),
    );
  }
}
