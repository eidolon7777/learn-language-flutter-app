import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ViewModel for managing the application theme state using Riverpod.
/// This allows toggling between Light and Dark modes globally.
class ThemeViewModel extends StateNotifier<ThemeMode> {
  ThemeViewModel() : super(ThemeMode.system);

  bool get isDarkMode => state == ThemeMode.dark;

  void toggleTheme() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }

  void setThemeMode(ThemeMode mode) {
    if (state != mode) {
      state = mode;
    }
  }
}

/// Global provider for the theme state
final themeProvider = StateNotifierProvider<ThemeViewModel, ThemeMode>((ref) {
  return ThemeViewModel();
});
