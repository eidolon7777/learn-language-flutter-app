import 'package:flutter/material.dart';
import '../view_model/journey_view_model.dart';

class TimelineItem extends StatelessWidget {
  final Milestone milestone;
  final bool isLast;
  final int index;

  const TimelineItem({
    super.key,
    required this.milestone,
    required this.isLast,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Column (Line + Icon)
          SizedBox(
            width: 60,
            child: Column(
              children: [
                // Top Line (connect to previous)
                if (index > 0)
                  Expanded(
                    flex: 1,
                    child: Container(
                      width: 2,
                      color: _getLineColor(milestone.status, colorScheme),
                    ),
                  )
                else
                  const SizedBox(height: 24), // Spacer for first item

                // Icon Circle
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _getCircleColor(milestone.status, colorScheme),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getBorderColor(milestone.status, colorScheme),
                      width: 2,
                    ),
                    boxShadow: milestone.status == MilestoneStatus.active
                        ? [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                  child: Icon(
                    _getIcon(milestone.status),
                    size: 16,
                    color: _getIconColor(milestone.status, colorScheme),
                  ),
                ),

                // Bottom Line (connect to next)
                if (!isLast)
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: 2,
                      color: _getLineColor(milestone.status, colorScheme),
                    ),
                  )
                else
                  const SizedBox(height: 24), // Spacer for last item
              ],
            ),
          ),

          // Right Column (Content)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0, right: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4), // Align with icon center
                  Text(
                    milestone.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: milestone.status == MilestoneStatus.locked
                          ? colorScheme.onSurface.withOpacity(0.4)
                          : colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    milestone.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: milestone.status == MilestoneStatus.active
                          ? colorScheme.primary
                          : colorScheme.onSurface.withOpacity(0.4),
                      fontWeight: milestone.status == MilestoneStatus.active
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                  
                  // Sub-items (if any)
                  if (milestone.subItems.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ...milestone.subItems.map((subItem) => _buildSubItem(subItem, theme)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubItem(MilestoneSubItem item, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final isLocked = item.status == MilestoneStatus.locked;
    final isActive = item.status == MilestoneStatus.active;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive 
            ? colorScheme.primary.withOpacity(0.05) 
            : colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: isActive
            ? Border.all(color: colorScheme.primary.withOpacity(0.3))
            : null,
      ),
      child: Row(
        children: [
          // Sub-item Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive 
                  ? colorScheme.primary.withOpacity(0.1) 
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isActive ? Icons.play_arrow_rounded : Icons.lock_outline_rounded,
              size: 16,
              color: isActive ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(width: 12),
          
          // Title & Progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                          color: isLocked 
                              ? colorScheme.onSurface.withOpacity(0.5) 
                              : colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                if (isActive && item.progress > 0) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: item.progress,
                      backgroundColor: colorScheme.primary.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                      minHeight: 4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Methods ---

  Color _getLineColor(MilestoneStatus status, ColorScheme colors) {
    switch (status) {
      case MilestoneStatus.completed:
        return colors.primary;
      case MilestoneStatus.active:
        return colors.primary.withOpacity(0.5);
      case MilestoneStatus.locked:
        return colors.outlineVariant.withOpacity(0.2);
    }
  }

  Color _getCircleColor(MilestoneStatus status, ColorScheme colors) {
    switch (status) {
      case MilestoneStatus.completed:
        return colors.primary;
      case MilestoneStatus.active:
        return colors.primary;
      case MilestoneStatus.locked:
        return Colors.transparent;
    }
  }

  Color _getBorderColor(MilestoneStatus status, ColorScheme colors) {
    switch (status) {
      case MilestoneStatus.completed:
        return colors.primary;
      case MilestoneStatus.active:
        return colors.primary.withOpacity(0.3);
      case MilestoneStatus.locked:
        return colors.outlineVariant.withOpacity(0.3);
    }
  }

  Color _getIconColor(MilestoneStatus status, ColorScheme colors) {
    switch (status) {
      case MilestoneStatus.completed:
      case MilestoneStatus.active:
        return colors.onPrimary;
      case MilestoneStatus.locked:
        return colors.onSurface.withOpacity(0.4);
    }
  }

  IconData _getIcon(MilestoneStatus status) {
    switch (status) {
      case MilestoneStatus.completed:
        return Icons.check_rounded;
      case MilestoneStatus.active:
        return Icons.bolt_rounded;
      case MilestoneStatus.locked:
        return Icons.lock_outline_rounded;
    }
  }
}
