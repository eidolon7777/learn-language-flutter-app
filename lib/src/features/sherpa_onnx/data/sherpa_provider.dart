import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'model_manager.dart';
import 'sherpa_runner.dart';

final sherpaRunnerProvider = Provider<SherpaRunner>((ref) {
  final modelManager = ref.watch(modelManagerProvider);
  return SherpaRunner();
});
