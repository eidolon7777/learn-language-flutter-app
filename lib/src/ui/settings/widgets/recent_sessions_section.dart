import 'package:flutter/material.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_section_header.dart';
import '../view_model/settings_view_model.dart';

class RecentSessionsSection extends StatelessWidget {
  final List<SessionItem> sessions;

  const RecentSessionsSection({
    super.key,
    required this.sessions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        AppSectionHeader(
          title: 'Recent Sessions',
          action: TextButton(
            onPressed: () {},
            child: Text(
              'View All',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: sessions.asMap().entries.map((entry) {
              final index = entry.key;
              final session = entry.value;
              final isLast = index == sessions.length - 1;

              return Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(session.icon, size: 20, color: colorScheme.onSurface),
                    ),
                    title: Text(
                      session.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        '${session.date} • ${session.duration}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurface.withOpacity(0.4),
                    ),
                    onTap: () {},
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 72,
                      color: colorScheme.outlineVariant.withOpacity(0.2),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
