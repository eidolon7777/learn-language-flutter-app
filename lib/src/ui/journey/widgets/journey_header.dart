import 'package:flutter/material.dart';
import 'package:learn_language/src/ui/theme_switcher/widgets/theme_switcher_widget.dart';

class JourneyHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final EdgeInsets padding;

  const JourneyHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          ThemeSwitcherWidget(),
        ],
      ),
    );
  }
}
