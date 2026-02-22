import 'package:flutter/material.dart';

class StaggeredItem extends StatelessWidget {
  final int index;
  final Widget child;
  final Duration delay;

  const StaggeredItem({
    super.key,
    required this.index,
    required this.child,
    this.delay = const Duration(milliseconds: 100),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(
        milliseconds: 300 + (index * delay.inMilliseconds),
      ),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
