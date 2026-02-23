import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- Models ---

class StorageStats {
  final double usedGB;
  final double totalGB;

  double get progress => usedGB / totalGB;
  double get availableGB => totalGB - usedGB;

  const StorageStats({
    required this.usedGB,
    required this.totalGB,
  });
}

enum ModelStatus { installed, available, downloading }

class LanguageModel {
  final String name;
  final String code;
  final ModelStatus status;
  final int sizeMB;
  final double downloadProgress; // 0.0 to 1.0

  const LanguageModel({
    required this.name,
    required this.code,
    required this.status,
    required this.sizeMB,
    this.downloadProgress = 0.0,
  });
}

class VoiceSettings {
  final String engine;
  final double speed;
  final double pitch;

  const VoiceSettings({
    required this.engine,
    required this.speed,
    required this.pitch,
  });
}

class SessionItem {
  final String title;
  final String date;
  final String duration;
  final IconData icon;

  const SessionItem({
    required this.title,
    required this.date,
    required this.duration,
    required this.icon,
  });
}

class SettingsState {
  final StorageStats storage;
  final bool autoDownload;
  final List<LanguageModel> models;
  final VoiceSettings voiceSettings;
  final List<SessionItem> recentSessions;
  final String appVersion;

  const SettingsState({
    required this.storage,
    required this.autoDownload,
    required this.models,
    required this.voiceSettings,
    required this.recentSessions,
    required this.appVersion,
  });
}

// --- ViewModel ---

class SettingsViewModel extends StateNotifier<SettingsState> {
  SettingsViewModel() : super(_initialState());

  static SettingsState _initialState() {
    return const SettingsState(
      storage: StorageStats(usedGB: 2.4, totalGB: 64.0),
      autoDownload: true,
      models: [
        LanguageModel(
          name: 'English (US)',
          code: 'en-US',
          status: ModelStatus.installed,
          sizeMB: 420,
        ),
        LanguageModel(
          name: 'Spanish (ES)',
          code: 'es-ES',
          status: ModelStatus.available,
          sizeMB: 380,
        ),
        LanguageModel(
          name: 'Japanese (JP)',
          code: 'ja-JP',
          status: ModelStatus.downloading,
          sizeMB: 450,
          downloadProgress: 0.64,
        ),
      ],
      voiceSettings: VoiceSettings(
        engine: 'Neural HD (Recommended)',
        speed: 1.0,
        pitch: 0.5, // 0.5 = Neutral (0.0 Low, 1.0 High)
      ),
      recentSessions: [
        SessionItem(
          title: 'English Practice - Unit 4',
          date: 'Oct 24, 2023',
          duration: '04:12',
          icon: Icons.graphic_eq, // Waveform placeholder
        ),
        SessionItem(
          title: 'Morning Vocabulary Quiz',
          date: 'Oct 23, 2023',
          duration: '02:45',
          icon: Icons.graphic_eq,
        ),
        SessionItem(
          title: 'Spanish Conversation Basics',
          date: 'Oct 21, 2023',
          duration: '12:05',
          icon: Icons.graphic_eq,
        ),
      ],
      appVersion: 'App Version 2.4.1 (Build 882)',
    );
  }

  void toggleAutoDownload(bool value) {
    state = SettingsState(
      storage: state.storage,
      autoDownload: value,
      models: state.models,
      voiceSettings: state.voiceSettings,
      recentSessions: state.recentSessions,
      appVersion: state.appVersion,
    );
  }

  void updateVoiceSpeed(double value) {
    state = SettingsState(
      storage: state.storage,
      autoDownload: state.autoDownload,
      models: state.models,
      voiceSettings: VoiceSettings(
        engine: state.voiceSettings.engine,
        speed: value,
        pitch: state.voiceSettings.pitch,
      ),
      recentSessions: state.recentSessions,
      appVersion: state.appVersion,
    );
  }

  void updateVoicePitch(double value) {
    state = SettingsState(
      storage: state.storage,
      autoDownload: state.autoDownload,
      models: state.models,
      voiceSettings: VoiceSettings(
        engine: state.voiceSettings.engine,
        speed: state.voiceSettings.speed,
        pitch: value,
      ),
      recentSessions: state.recentSessions,
      appVersion: state.appVersion,
    );
  }
}

final settingsViewModelProvider = StateNotifierProvider<SettingsViewModel, SettingsState>((ref) {
  return SettingsViewModel();
});
