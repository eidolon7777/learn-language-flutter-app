import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learn_language/src/features/sherpa_onnx/data/sherpa_provider.dart';
import '../../../domain/sherpa_model.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

class TtsScreen extends ConsumerStatefulWidget {
  final SherpaModel model;
  const TtsScreen({super.key, required this.model});

  @override
  ConsumerState<TtsScreen> createState() => _TtsScreenState();
}

class _TtsScreenState extends ConsumerState<TtsScreen> {
  final _textController = TextEditingController(text: 'Hello, how are you doing today?');
  final _player = AudioPlayer();
  bool _isPlaying = false;
  bool _isGenerating = false;
  String _status = 'Initializing...';
  double _speed = 1.0;
  int _speakerId = 0;
  
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initModel();
  }
  
  void _addLog(String message) {
    final time = DateTime.now().toString().split(' ')[1].substring(0, 8);
    debugPrint('[$time] $message');
    if (mounted) {
      setState(() {
        _logs.add('[$time] $message');
      });
      // Auto-scroll
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _initModel() async {
    _addLog('Initializing TTS model: ${widget.model.name}...');
    try {
      await ref.read(sherpaRunnerProvider).initTts(widget.model.id);
      if (mounted) {
        setState(() => _status = 'Ready');
        _addLog('Model initialized successfully.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _status = 'Error: $e');
        _addLog('Error initializing model: $e');
      }
    }
  }

  Future<void> _generateAndPlay() async {
    if (_textController.text.isEmpty) return;

    setState(() {
      _isGenerating = true;
      _status = 'Generating audio...';
    });
    _addLog('Generating audio for: "${_textController.text}" (Speaker: $_speakerId, Speed: $_speed)');

    try {
      final result = await ref.read(sherpaRunnerProvider).generateTts(
        _textController.text,
        speakerId: _speakerId,
        speed: _speed,
      );

      if (result != null) {
         _addLog('Audio generated. Samples: ${result.samples.length}, Rate: ${result.sampleRate}');
         setState(() => _status = 'Playing...');
         
         final tempDir = await getTemporaryDirectory();
         final file = File('${tempDir.path}/tts_output.wav');
         if (await file.exists()) {
           await file.delete();
         }
         
         // Manual WAV saving since .save() might be missing
         await _saveWav(file, result);
         _addLog('Saved WAV to ${file.path}');
         
         await _player.stop(); // Stop previous playback if any
         await _player.play(DeviceFileSource(file.path));
         
         _player.onPlayerComplete.listen((_) {
            if (mounted) {
               setState(() => _status = 'Finished');
               _addLog('Playback finished');
            }
         });
      } else {
        _addLog('Error: Generated audio is null. Check if model is loaded correctly.');
        setState(() => _status = 'Error: Generation returned null');
      }
    } catch (e) {
      _addLog('Error generating audio: $e');
      setState(() => _status = 'Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }
  
  Future<void> _saveWav(File file, sherpa.GeneratedAudio audio) async {
    final sampleRate = audio.sampleRate;
    final samples = audio.samples; // Float32List
    
    // Convert Float32 to Int16
    final int16Samples = Int16List(samples.length);
    for (int i = 0; i < samples.length; i++) {
      var s = samples[i];
      if (s > 1.0) s = 1.0;
      if (s < -1.0) s = -1.0;
      int16Samples[i] = (s * 32767).round();
    }
    
    final int channels = 1;
    final int byteRate = sampleRate * channels * 2;
    final int blockAlign = channels * 2;
    final int bitsPerSample = 16;
    final int dataSize = int16Samples.length * 2;
    final int chunkSize = 36 + dataSize;

    final bytes = BytesBuilder();
    
    // RIFF header
    bytes.add('RIFF'.codeUnits);
    _addInt32(bytes, chunkSize);
    bytes.add('WAVE'.codeUnits);
    
    // fmt chunk
    bytes.add('fmt '.codeUnits);
    _addInt32(bytes, 16); // Subchunk1Size
    _addInt16(bytes, 1); // AudioFormat (PCM)
    _addInt16(bytes, channels);
    _addInt32(bytes, sampleRate);
    _addInt32(bytes, byteRate);
    _addInt16(bytes, blockAlign);
    _addInt16(bytes, bitsPerSample);
    
    // data chunk
    bytes.add('data'.codeUnits);
    _addInt32(bytes, dataSize);
    bytes.add(int16Samples.buffer.asUint8List());
    
    await file.writeAsBytes(bytes.toBytes());
  }
  
  void _addInt32(BytesBuilder bytes, int value) {
    bytes.add([
      value & 0xff,
      (value >> 8) & 0xff,
      (value >> 16) & 0xff,
      (value >> 24) & 0xff,
    ]);
  }
  
  void _addInt16(BytesBuilder bytes, int value) {
    bytes.add([
      value & 0xff,
      (value >> 8) & 0xff,
    ]);
  }

  @override
  void dispose() {
    _player.dispose();
    _textController.dispose();
    ref.read(sherpaRunnerProvider).disposeTts();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.model.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
             TextField(
               controller: _textController,
               maxLines: 3,
               style: TextStyle(color: Colors.white),
               decoration: const InputDecoration(
                 border: OutlineInputBorder(),
                 labelStyle: TextStyle(color: Colors.white),
                 labelText: 'Text to speak',
                 
               ),
             ),
             const SizedBox(height: 16),
             Row(
               children: [
                 const Text('Speed:'),
                 Expanded(
                   child: Slider(
                     value: _speed,
                     min: 0.5,
                     max: 2.0,
                     divisions: 15,
                     label: _speed.toStringAsFixed(1),
                     onChanged: (v) => setState(() => _speed = v),
                   ),
                 ),
               ],
             ),
             const SizedBox(height: 20),
             if (_isGenerating)
               const CircularProgressIndicator()
             else
               ElevatedButton.icon(
                 onPressed: _generateAndPlay,
                 icon: const Icon(Icons.play_arrow),
                 label: const Text('Generate & Play'),
               ),
             const SizedBox(height: 20),
             Text(_status, style: const TextStyle(color: Colors.grey)),
             const SizedBox(height: 20),
             const Divider(),
             const Text('Logs:', style: TextStyle(fontWeight: FontWeight.bold)),
             Expanded(
               child: Container(
                 decoration: BoxDecoration(
                   border: Border.all(color: Colors.grey),
                   borderRadius: BorderRadius.circular(8),
                 ),
                 padding: const EdgeInsets.all(8.0),
                 child: ListView.builder(
                   controller: _scrollController,
                   itemCount: _logs.length,
                   itemBuilder: (context, index) => Text(
                     _logs[index],
                     style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                   ),
                 ),
               ),
             ),
          ],
        ),
      ),
    );
  }
}
