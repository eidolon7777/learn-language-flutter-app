import 'package:flutter/material.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_section_header.dart';
import '../view_model/settings_view_model.dart';

class VoiceSettingsCard extends StatelessWidget {
  final VoiceSettings settings;
  final ValueChanged<double> onSpeedChanged;
  final ValueChanged<double> onPitchChanged;

  const VoiceSettingsCard({
    super.key,
    required this.settings,
    required this.onSpeedChanged,
    required this.onPitchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(title: 'Voice Settings'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Voice Engine Dropdown
              Text(
                'Voice Engine',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      settings.engine,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.keyboard_arrow_down, color: colorScheme.onSurface),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Voice Speed Slider
              _buildSliderSection(
                context: context,
                title: 'Voice Speed',
                value: settings.speed,
                displayValue: '${settings.speed}x',
                min: 0.5,
                max: 2.0,
                onChanged: onSpeedChanged,
                labels: ['Slow', 'Normal', 'Fast'],
              ),
              const SizedBox(height: 24),

              // Voice Pitch Slider
              _buildSliderSection(
                context: context,
                title: 'Voice Pitch',
                value: settings.pitch,
                displayValue: _getPitchLabel(settings.pitch),
                min: 0.0,
                max: 1.0,
                onChanged: onPitchChanged,
                labels: ['Low', 'Medium', 'High'],
              ),
              const SizedBox(height: 24),

              // Test Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.play_circle_fill, size: 20),
                  label: const Text('Test Voice Settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary.withOpacity(0.1),
                    foregroundColor: colorScheme.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSliderSection({
    required BuildContext context,
    required String title,
    required double value,
    required String displayValue,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required List<String> labels,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              displayValue,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            activeTrackColor: colorScheme.primary,
            inactiveTrackColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
            thumbColor: colorScheme.primary,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels
                .map(
                  (label) => Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.4),
                      fontSize: 10,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  String _getPitchLabel(double value) {
    if (value < 0.33) return 'Low';
    if (value > 0.66) return 'High';
    return 'Neutral';
  }
}
