import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/sherpa_model.dart';
import '../view_model/models_view_model.dart';
import 'demos/asr_screen.dart';
import 'demos/tts_screen.dart';
import 'demos/vad_screen.dart';
import 'demos/lid_screen.dart';
import 'demos/diarization_screen.dart';

class DemosScreen extends ConsumerWidget {
  const DemosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final models = ref.watch(modelsViewModelProvider);
    final installedModels = models.where((m) => m.isInstalled).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Sherpa ONNX Demos')),
      body: installedModels.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No models installed.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate back or to models tab if using bottom nav
                      Navigator.pop(context); 
                    },
                    child: const Text('Go to Models Manager'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: installedModels.length,
              itemBuilder: (context, index) {
                final model = installedModels[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: _getIconForType(model.type),
                    title: Text(model.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(model.type.name.toUpperCase()),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      _navigateToDemo(context, model);
                    },
                  ),
                );
              },
            ),
    );
  }

  Icon _getIconForType(ModelType type) {
    switch (type) {
      case ModelType.asr:
        return const Icon(Icons.mic, color: Colors.blue);
      case ModelType.tts:
        return const Icon(Icons.record_voice_over, color: Colors.green);
      case ModelType.vad:
        return const Icon(Icons.graphic_eq, color: Colors.orange);
      case ModelType.speakerId:
        return const Icon(Icons.person_search, color: Colors.purple);
      case ModelType.punctuation:
        return const Icon(Icons.text_fields, color: Colors.teal);
      case ModelType.audioTagging:
        return const Icon(Icons.tag, color: Colors.red);
      case ModelType.enhancement:
        return const Icon(Icons.cleaning_services, color: Colors.amber);
      case ModelType.separation:
        return const Icon(Icons.call_split, color: Colors.indigo);
      case ModelType.kws:
        return const Icon(Icons.key, color: Colors.brown);
      case ModelType.lid:
        return const Icon(Icons.language, color: Colors.blueAccent);
      case ModelType.diarization:
        return const Icon(Icons.groups, color: Colors.deepPurple);
      default:
        return const Icon(Icons.extension, color: Colors.grey);
    }
  }

  void _navigateToDemo(BuildContext context, SherpaModel model) {
    Widget screen;
    switch (model.type) {
      case ModelType.asr:
        screen = AsrScreen(model: model);
        break;
      case ModelType.tts:
        screen = TtsScreen(model: model);
        break;
      case ModelType.vad:
        screen = VadScreen(model: model);
        break;
      case ModelType.lid:
        screen = LidScreen(model: model);
        break;
      case ModelType.diarization:
        screen = DiarizationScreen(model: model);
        break;
      default:
        screen = Scaffold(
          appBar: AppBar(title: Text(model.name)),
          body: const Center(child: Text('Demo not implemented yet')),
        );
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}
