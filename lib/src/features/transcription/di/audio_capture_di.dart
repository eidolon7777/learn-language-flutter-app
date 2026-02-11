import 'package:get_it/get_it.dart';
import '../../../core/utils/logger.dart';

// Data sources
import '../data/datasources/audio_capture_datasource.dart';
import '../data/datasources/audio_capture_datasource_impl.dart';

// Repositories
import '../domain/repositories/audio_repository.dart';
import '../data/repositories/audio_repository_impl.dart';

// Use cases
import '../domain/usecases/start_recording.dart';
import '../domain/usecases/stop_recording.dart';
import '../domain/usecases/calculate_rms.dart';

// Cubit
import '../presentation/cubit/audio_cubit.dart';

/// Dependency injection container setup for audio capture feature
/// 
/// This class configures all dependencies for the audio capture feature
/// following the Clean Architecture principles.
class AudioCaptureDI {
  static final GetIt _getIt = GetIt.instance;
  
  /// Initialize all dependencies
  static void init() {
    Logger.info("[DEBUG] [AudioCaptureDI] Initializing dependencies");
    _initDataSources();
    _initRepositories();
    _initUseCases();
    _initCubits();
  }
  
  /// Initialize data sources
  static void _initDataSources() {
    Logger.info("[DEBUG] [AudioCaptureDI] Registering data sources");
    _getIt.registerLazySingleton<AudioCaptureDataSource>(
      () => AudioCaptureDataSourceImpl(),
    );
  }
  
  /// Initialize repositories
  static void _initRepositories() {
    Logger.info("[DEBUG] [AudioCaptureDI] Registering repositories");
    _getIt.registerLazySingleton<IAudioRepository>(
      () => AudioRepositoryImpl(
        dataSource: _getIt<AudioCaptureDataSource>(),
      ),
    );
  }
  
  /// Initialize use cases
  static void _initUseCases() {
    Logger.info("[DEBUG] [AudioCaptureDI] Registering use cases");
    _getIt.registerLazySingleton<StartRecording>(
      () => StartRecording(
        audioRepository: _getIt<IAudioRepository>(),
      ),
    );
    
    _getIt.registerLazySingleton<StopRecording>(
      () => StopRecording(
        audioRepository: _getIt<IAudioRepository>(),
      ),
    );
    
    _getIt.registerLazySingleton<CalculateRMS>(
      () => CalculateRMS(),
    );
  }
  
  /// Initialize cubits
  static void _initCubits() {
    Logger.info("[DEBUG] [AudioCaptureDI] Registering cubits");
    _getIt.registerFactory<AudioCubit>(
      () => AudioCubit(
        startRecording: _getIt<StartRecording>(),
        stopRecording: _getIt<StopRecording>(),
      ),
    );
  }
  
  /// Get audio cubit instance
  static AudioCubit get audioCubit => _getIt<AudioCubit>();
  
  /// Get start recording use case
  static StartRecording get startRecording => _getIt<StartRecording>();
  
  /// Get stop recording use case
  static StopRecording get stopRecording => _getIt<StopRecording>();
  
  /// Get calculate RMS use case
  static CalculateRMS get calculateRMS => _getIt<CalculateRMS>();
  
  /// Get audio repository
  static IAudioRepository get audioRepository => _getIt<IAudioRepository>();
  
  /// Dispose of all dependencies
  static void dispose() {
    Logger.info("[DEBUG] [AudioCaptureDI] Disposing dependencies");
    _getIt.reset();
  }
}