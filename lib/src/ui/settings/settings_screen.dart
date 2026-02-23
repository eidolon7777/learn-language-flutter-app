import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learn_language/src/ui/core/widgets/staggered_item.dart';

import 'view_model/settings_view_model.dart';
import 'widgets/clear_cache_button.dart';
import 'widgets/offline_models_section.dart';
import 'widgets/recent_sessions_section.dart';
import 'widgets/settings_header.dart';
import 'widgets/storage_usage_card.dart';
import 'widgets/voice_settings_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsViewModelProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SettingsHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: [
                  StaggeredItem(
                    index: 0,
                    child: StorageUsageCard(stats: state.storage),
                  ),
                  StaggeredItem(
                    index: 1,
                    child: OfflineModelsSection(
                      autoDownload: state.autoDownload,
                      models: state.models,
                      onToggleAutoDownload: (value) {
                        ref.read(settingsViewModelProvider.notifier).toggleAutoDownload(value);
                      },
                    ),
                  ),
                  StaggeredItem(
                    index: 2,
                    child: VoiceSettingsCard(
                      settings: state.voiceSettings,
                      onSpeedChanged: (value) {
                        ref.read(settingsViewModelProvider.notifier).updateVoiceSpeed(value);
                      },
                      onPitchChanged: (value) {
                        ref.read(settingsViewModelProvider.notifier).updateVoicePitch(value);
                      },
                    ),
                  ),
                  StaggeredItem(
                    index: 3,
                    child: RecentSessionsSection(sessions: state.recentSessions),
                  ),
                  const SizedBox(height: 24),
                  StaggeredItem(
                    index: 4,
                    child: ClearCacheButton(
                      onTap: () {
                        // Implement clear cache logic
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      state.appVersion,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
