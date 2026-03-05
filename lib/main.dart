import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:learn_language/src/ui/journey/journey_screen.dart';
import 'package:record/record.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/config/theme/app_theme.dart';
import 'src/ui/theme_switcher/view_model/theme_view_model.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:whisper_kit/whisper_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'src/features/transcription/presentation/screens/audio_capture_screen.dart';
// import 'src/features/transcription/di/audio_capture_di.dart';

import 'package:hive_flutter/hive_flutter.dart';
// import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;
// import 'src/features/sherpa_onnx/domain/sherpa_model.dart';
// import 'src/features/sherpa_onnx/ui/screens/models_screen.dart';
import 'src/features/grammar/ui/grammar_analysis_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize audio capture dependency injection
  // AudioCaptureDI.init();
  
   // sherpa_onnx.initBindings();

  // await Hive.initFlutter();
  // Hive.registerAdapter(ModelTypeAdapter());
  // Hive.registerAdapter(SherpaModelAdapter());
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    
    return MaterialApp(
      title: 'Speech App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const GrammarAnalysisPage(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const DeviceSTTScreen(),
    const WhisperScreen(),
    // const ModelsScreen(),
    const GrammarAnalysisPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.mic),
            label: 'Device STT',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.hearing),
            label: 'Whisper STT',
          ),
          /*
          BottomNavigationBarItem(
            icon: Icon(Icons.download),
            label: 'Models',
          ),
          */
          BottomNavigationBarItem(
            icon: Icon(Icons.text_fields),
            label: 'Grammar',
          ),
        ],
      ),
    );
  }
}

/// Screen 1: Device Speech to Text (using speech_to_text)
class DeviceSTTScreen extends StatefulWidget {
  const DeviceSTTScreen({super.key});

  @override
  State<DeviceSTTScreen> createState() => _DeviceSTTScreenState();
}

class _DeviceSTTScreenState extends State<DeviceSTTScreen> {
  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  String _text = 'Press the button and start speaking';
  double _confidence = 1.0;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();
    _initTts();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => debugPrint('onStatus: $val'),
        onError: (val) => debugPrint('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _text = val.recognizedWords;
            if (val.hasConfidenceRating && val.confidence > 0) {
              _confidence = val.confidence;
            }
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  Future<void> _speak() async {
    await _flutterTts.speak(_text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Device STT')),
      floatingActionButton: FloatingActionButton(
        onPressed: _listen,
        child: Icon(_isListening ? Icons.mic : Icons.mic_none),
      ),
      body: SingleChildScrollView(
        reverse: true,
        child: Container(
          padding: const EdgeInsets.fromLTRB(30.0, 30.0, 30.0, 150.0),
          child: Column(
            children: [
              Text(
                'Confidence: ${(_confidence * 100.0).toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Text(
                _text,
                style: const TextStyle(fontSize: 24.0, color: Colors.black, fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _speak,
                icon: const Icon(Icons.volume_up),
                label: const Text('Speak Text'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Screen 2: Whisper STT (using whisper_kit)
class WhisperScreen extends StatefulWidget {
  const WhisperScreen({super.key});

  @override
  State<WhisperScreen> createState() => _WhisperScreenState();
}

class _WhisperScreenState extends State<WhisperScreen> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  late FlutterTts _flutterTts;
  Whisper? _whisper;
  
  bool _isRecording = false;
  bool _isTranscribing = false;
  bool _isLiveMode = false;
  Timer? _liveTimer;
  final StringBuffer _transcribedTextBuffer = StringBuffer();
  
  String _text = 'Press record to start';
  String _modelStatus = 'Initializing...';
  // Removed unused _audioPath

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
    _initTts();
    _initWhisper();
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
  }

  Future<void> _initWhisper() async {
    if (!mounted) return;
    try {
      // Check permissions
      await Permission.microphone.request();
      await Permission.storage.request();
      
      // Initialize Whisper with Base model
      _whisper = Whisper(
        model: WhisperModel.base,
      );
      
      setState(() {
        _modelStatus = 'Whisper Base Model Ready';
      });
    } catch (e) {
      setState(() {
        _modelStatus = 'Error initializing Whisper: $e';
      });
    }
  }

  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        // Stop recording
        _liveTimer?.cancel();
        final path = await _audioRecorder.stop();
        
        setState(() {
          _isRecording = false;
        });
        
        if (path != null) {
          if (!_isLiveMode) {
             _transcribe(path);
          } else {
             // For live mode, we process the last chunk
             _processLiveChunk(path);
          }
        }
      } else {
        // Start recording
        if (await _audioRecorder.hasPermission()) {
          if (_isLiveMode) {
            _transcribedTextBuffer.clear();
            _text = '';
            _startLiveRecordingLoop();
          } else {
            await _startRecording();
          }
        }
      }
    } catch (e) {
      setState(() {
        _text = 'Error recording: $e';
      });
    }
  }

  Future<void> _startRecording() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';
    
    await _audioRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );
    setState(() {
      _isRecording = true;
      _text = _isLiveMode ? '${_transcribedTextBuffer.toString()}\n(Listening...)' : 'Recording...';
    });
  }

  void _startLiveRecordingLoop() async {
    await _startRecording();
    
    // Set up timer to process chunks every 3 seconds
    _liveTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!_isRecording) {
        timer.cancel();
        return;
      }
      
      // Stop current chunk
      final path = await _audioRecorder.stop();
      
      // Immediately start next chunk
      await _startRecording();
      
      // Process the chunk we just stopped
      if (path != null) {
        _processLiveChunk(path);
      }
    });
  }

  Future<void> _processLiveChunk(String audioPath) async {
    if (_whisper == null) return;
    
    try {
      final File audioFile = File(audioPath);
      if (!audioFile.existsSync()) return;

      final result = await _whisper!.transcribe(
        transcribeRequest: TranscribeRequest(
          audio: audioPath,
          language: 'en',
          isTranslate: false,
        ),
      );

      if (result.text.trim().isNotEmpty) {
        _transcribedTextBuffer.write("${result.text} ");
        setState(() {
          _text = _transcribedTextBuffer.toString();
        });
      }
      
      // Cleanup chunk file
      await audioFile.delete();
    } catch (e) {
      debugPrint("Error processing live chunk: $e");
    }
  }

  Future<void> _transcribe(String audioPath) async {
    if (_whisper == null) return;

    setState(() {
      _isTranscribing = true;
      _text = 'Transcribing...';
    });

    try {
      final File audioFile = File(audioPath);
      if (!audioFile.existsSync()) {
        throw Exception("Audio file not found");
      }

      final result = await _whisper!.transcribe(
        transcribeRequest: TranscribeRequest(
          audio: audioPath,
          language: 'en', // default to English
          isTranslate: false,
        ),
      );

      setState(() {
        _text = result.text;
      });
    } catch (e) {
      setState(() {
        _text = 'Transcription error: $e';
      });
    } finally {
      setState(() {
        _isTranscribing = false;
      });
    }
  }

  Future<void> _speak() async {
    await _flutterTts.speak(_text);
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Whisper STT (Base)')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text('Status: $_modelStatus', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Live Mode'),
                Switch(
                  value: _isLiveMode,
                  onChanged: _isRecording ? null : (val) {
                    setState(() {
                      _isLiveMode = val;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Center(
                child: _isTranscribing
                    ? const CircularProgressIndicator()
                    : SingleChildScrollView(
                        child: Text(
                          _text,
                          style: const TextStyle(fontSize: 24.0),
                          textAlign: TextAlign.center,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  onPressed: _isTranscribing ? null : _toggleRecording,
                  backgroundColor: _isRecording ? Colors.red : Colors.blue,
                  child: Icon(_isRecording ? Icons.stop : Icons.mic),
                ),
                FloatingActionButton(
                  onPressed: _text.isNotEmpty && !_isRecording && !_isTranscribing
                      ? _speak
                      : null,
                  child: const Icon(Icons.volume_up),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
