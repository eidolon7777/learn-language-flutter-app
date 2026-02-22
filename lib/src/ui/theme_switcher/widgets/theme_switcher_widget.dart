import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../view_model/theme_view_model.dart';


class ThemeSwitcherWidget extends ConsumerWidget {
  const ThemeSwitcherWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    // Dimensions
    const double width = 60.0;
    const double height = 32.0;
    const double padding = 4.0;
    const double iconSize = height - (padding * 2);

    return GestureDetector(
      onTap: () {
        ref.read(themeProvider.notifier).toggleTheme();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isDark ? const Color(0xFF2C3E50) : const Color(0xFF87CEEB),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background decorations (stars/clouds could go here if we wanted complex SVG style)
            
            // Sliding Thumb
            AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: iconSize,
                height: iconSize,
                margin: const EdgeInsets.all(padding),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFFF1C40F) : const Color(0xFFF39C12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return RotationTransition(
                        turns: animation,
                        child: ScaleTransition(
                          scale: animation,
                          child: child,
                        ),
                      );
                    },
                    child: isDark
                        ? const Icon(
                            Icons.nightlight_round,
                            key: ValueKey('moon'),
                            size: 16,
                            color: Colors.white,
                          )
                        : const Icon(
                            Icons.wb_sunny_rounded,
                            key: ValueKey('sun'),
                            size: 16,
                            color: Colors.white,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
