import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:learn_language/src/features/sherpa_onnx/data/sherpa_provider.dart';
import '../../../domain/sherpa_model.dart';

class AsrScreen extends ConsumerStatefulWidget {
  final SherpaModel model;
  const AsrScreen({super.key, required this.model});

  @override
  ConsumerState<AsrScreen> createState() => _AsrScreenState();
}

class _AsrScreenState extends ConsumerState<AsrScreen> {
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String _transcription = '';
  String _status = 'Initializing...';
  
  @override
  void initState() {
    super.initState();
    _initModel();
  }
  
  Future<void> _initModel() async {
    try {
      await ref.read(sherpaRunnerProvider).initAsr(widget.model.id);
      if (mounted) setState(() => _status = 'Ready to record');
    } catch (e) {
      if (mounted) setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
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
          _transcription = '';
          _status = 'Listening...';
        });

        ref.read(sherpaRunnerProvider).startAsrStream(stream, (text) {
          setState(() {
            _transcription = text;
          });
        });
      }
    } catch (e) {
      setState(() => _status = 'Error starting record: $e');
    }
  }

  Future<void> _stopRecording() async {
    await _audioRecorder.stop();
    ref.read(sherpaRunnerProvider).stopAsrStream();
    setState(() {
      _isRecording = false;
      _status = 'Stopped';
    });
  }
  
  @override
  void dispose() {
    _audioRecorder.dispose();
    ref.read(sherpaRunnerProvider).disposeAsr();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.model.name)),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(_status, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _transcription,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: _toggleRecording,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording ? Colors.red : Colors.blue,
                  boxShadow: [
                    BoxShadow(
                      color: (_isRecording ? Colors.red : Colors.blue).withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
