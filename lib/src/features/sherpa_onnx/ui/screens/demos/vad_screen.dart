import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:learn_language/src/features/sherpa_onnx/data/sherpa_provider.dart';
import '../../../domain/sherpa_model.dart';

class VadScreen extends ConsumerStatefulWidget {
  final SherpaModel model;
  const VadScreen({super.key, required this.model});

  @override
  ConsumerState<VadScreen> createState() => _VadScreenState();
}

class _VadScreenState extends ConsumerState<VadScreen> {
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  bool _isSpeech = false;
  String _status = 'Initializing...';
  final List<String> _history = [];
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    _initModel();
  }

  Future<void> _initModel() async {
    try {
    //  await ref.read(sherpaRunnerProvider).initVad(widget.model.id);
      if (mounted) setState(() => _status = 'Ready');
    } catch (e) {
      if (mounted) setState(() => _status = 'Error: $e');
    }
  }

  void _addHistory(String message) {
    setState(() {
      _history.add('${DateTime.now().toString().split('.').first}: $message');
      // Auto-scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
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
          _history.clear();
        });
        _addHistory('Started recording');

        // ref.read(sherpaRunnerProvider).startVadStream(stream, (isSpeech) {
        //   if (mounted && _isSpeech != isSpeech) {
        //      setState(() => _isSpeech = isSpeech);
        //      _addHistory(isSpeech ? 'Speech Detected' : 'Silence');
        //   }
        // });
      }
    } catch (e) {
      setState(() => _status = 'Error: $e');
      _addHistory('Error: $e');
    }
  }
  
  Future<void> _stopRecording() async {
    await _audioRecorder.stop();
  // ref.read(sherpaRunnerProvider).stopVadStream();
    setState(() {
      _isRecording = false;
      _isSpeech = false;
      _status = 'Stopped';
    });
    _addHistory('Stopped recording');
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _scrollController.dispose();
  //  ref.read(sherpaRunnerProvider).disposeVad();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.model.name)),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_status),
                  const SizedBox(height: 40),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isSpeech ? Colors.green : Colors.grey.shade300,
                    ),
                    child: Center(
                      child: Text(
                        _isSpeech ? 'SPEECH' : 'SILENCE',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: _isSpeech ? Colors.white : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Event History', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 1,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ListView.builder(
                controller: _scrollController,
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Text(
                      _history[index],
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                },
              ),
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
