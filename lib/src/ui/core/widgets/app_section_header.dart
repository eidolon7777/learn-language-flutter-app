import 'package:flutter/material.dart';

class AppSectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  final EdgeInsets padding;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.padding = const EdgeInsets.only(bottom: 12, top: 24),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
