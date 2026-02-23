import 'package:flutter/material.dart';
import '../../core/widgets/app_card.dart';

class ClearCacheButton extends StatelessWidget {
  final VoidCallback onTap;

  const ClearCacheButton({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Clear Cache & Offline Data',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          Icon(Icons.delete_outline, color: colorScheme.error),
        ],
      ),
    );
  }
}
