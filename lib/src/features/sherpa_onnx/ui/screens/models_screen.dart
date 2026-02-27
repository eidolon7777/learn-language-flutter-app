import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learn_language/src/ui/theme_switcher/widgets/theme_switcher_widget.dart';
import '../../domain/sherpa_model.dart';
import '../view_model/models_view_model.dart';
import 'demos_screen.dart';

class ModelsScreen extends ConsumerWidget {
  const ModelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final models = ref.watch(modelsViewModelProvider);
    final downloadProgress = ref.watch(downloadProgressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sherpa ONNX Models'),
        actions: [
          ThemeSwitcherWidget(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(modelsViewModelProvider.notifier).refresh();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () async {
               final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear All Models?'),
                  content: const Text('This will delete all downloaded models. Are you sure?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              
              if (confirmed == true) {
                 ref.read(modelsViewModelProvider.notifier).clearAll();
              }
            },
          ),
        ],
      ),
      floatingActionButton: models.any((m) => m.isInstalled)
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const DemosScreen()));
              },
              label: const Text('Try Demos'),
              icon: const Icon(Icons.play_arrow),
            )
          : null,
      body: models.isEmpty
          ? const Center(child: Text('No models found'))
          : Padding(
            padding: const EdgeInsets.only(bottom: 64.0),
            child: ListView.builder(
                itemCount: models.length,
                itemBuilder: (context, index) {
                  final model = models[index];
                  final progress = downloadProgress[model.id];
                  final isDownloading = progress != null;
            
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(model.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text('${model.type.name.toUpperCase()} • ${(model.compressedSize / 1024 / 1024).toStringAsFixed(1)} MB'),
                                if (model.isInstalled)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      'Installed at: ${model.localPath}',
                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                                    ),
                                  ),
                                if (isDownloading)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        LinearProgressIndicator(value: progress),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Downloading: ${(progress * 100).toStringAsFixed(1)}%',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            trailing: _buildActionButtons(context, ref, model, isDownloading),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, SherpaModel model, bool isDownloading) {
    if (isDownloading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (model.isInstalled) {
      return IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () {
          ref.read(modelsViewModelProvider.notifier).deleteModel(model.id);
        },
      );
    }

    return IconButton(
      icon: const Icon(Icons.download),
      onPressed: () {
        ref.read(modelsViewModelProvider.notifier).downloadModel(model.id, ref);
      },
    );
  }
}
