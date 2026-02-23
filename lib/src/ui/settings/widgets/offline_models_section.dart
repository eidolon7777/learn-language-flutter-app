import 'package:flutter/material.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_section_header.dart';
import '../view_model/settings_view_model.dart';

class OfflineModelsSection extends StatelessWidget {
  final bool autoDownload;
  final List<LanguageModel> models;
  final ValueChanged<bool> onToggleAutoDownload;

  const OfflineModelsSection({
    super.key,
    required this.autoDownload,
    required this.models,
    required this.onToggleAutoDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppSectionHeader(
          title: 'Offline Models',
          action: Row(
            children: [
              Text(
                'Auto-download',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 8),
              Switch(
                value: autoDownload,
                onChanged: onToggleAutoDownload,
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            ],
          ),
        ),
        ...models.map((model) => _ModelItem(model: model)).toList(),
      ],
    );
  }
}

class _ModelItem extends StatelessWidget {
  final LanguageModel model;

  const _ModelItem({required this.model});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.translate, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getStatusText(model),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (model.status == ModelStatus.installed)
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.delete_outline, color: colorScheme.error),
                )
              else if (model.status == ModelStatus.available)
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Download'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    textStyle: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              else if (model.status == ModelStatus.downloading)
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.close, color: colorScheme.onSurface),
                ),
            ],
          ),
          if (model.status == ModelStatus.downloading) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: model.downloadProgress,
                backgroundColor: colorScheme.surfaceContainerHighest,
                color: colorScheme.primary,
                minHeight: 4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getStatusText(LanguageModel model) {
    switch (model.status) {
      case ModelStatus.installed:
        return 'Installed • ${model.sizeMB} MB';
      case ModelStatus.available:
        return 'Available • ${model.sizeMB} MB';
      case ModelStatus.downloading:
        return 'Downloading... ${(model.downloadProgress * 100).toInt()}%';
    }
  }
}
