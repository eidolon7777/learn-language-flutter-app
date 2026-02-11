import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/audio_cubit.dart';
import '../../data/utils/permission_handler.dart';

/// Widget for requesting microphone permissions
/// 
/// This widget provides a user-friendly interface for requesting
/// microphone permissions, with proper error handling and guidance.
class PermissionRequestWidget extends StatelessWidget {
  final VoidCallback? onPermissionGranted;
  final VoidCallback? onPermissionDenied;
  final String? customMessage;
  final String? customButtonText;
  
  const PermissionRequestWidget({
    super.key,
    this.onPermissionGranted,
    this.onPermissionDenied,
    this.customMessage,
    this.customButtonText,
  });
  
  @override
  Widget build(BuildContext context) {
    return BlocListener<AudioCubit, AudioState>(
      listener: (context, state) {
        if (state is AudioPermissionGranted) {
          onPermissionGranted?.call();
        } else if (state is AudioPermissionDenied) {
          onPermissionDenied?.call();
        }
      },
      child: BlocBuilder<AudioCubit, AudioState>(
        builder: (context, state) {
          if (state is AudioPermissionChecking) {
            return _buildLoadingState();
          } else if (state is AudioPermissionDenied) {
            return _buildPermissionDeniedState(context, state);
          } else if (state is AudioPermissionGranted) {
            return _buildPermissionGrantedState();
          } else if (state is AudioError) {
            return _buildErrorState(context, state);
          } else {
            return _buildInitialState(context);
          }
        },
      ),
    );
  }
  
  /// Build initial permission request state
  Widget _buildInitialState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.mic,
            size: 64,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            customMessage ?? 'Microphone Permission Required',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'This app needs access to your microphone to record audio. '
            'Please grant microphone permission to continue.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _requestPermission(context),
            icon: const Icon(Icons.mic),
            label: Text(customButtonText ?? 'Grant Microphone Permission'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build loading state
  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: CircularProgressIndicator(),
      ),
    );
  }
  
  /// Build permission denied state
  Widget _buildPermissionDeniedState(BuildContext context, AudioPermissionDenied state) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.mic_off,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Permission Denied',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            state.message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            state.guidance,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () => _openSettings(context),
                child: const Text('Open Settings'),
              ),
              ElevatedButton.icon(
                onPressed: () => _requestPermission(context),
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  /// Build permission granted state
  Widget _buildPermissionGrantedState() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            size: 64,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          Text(
            'Permission Granted',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Microphone permission has been granted. You can now start recording.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  /// Build error state
  Widget _buildErrorState(BuildContext context, AudioError state) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            state.message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (state.details != null) ...[
            const SizedBox(height: 8),
            Text(
              state.details!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _requestPermission(context),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
  
  /// Request microphone permission
  Future<void> _requestPermission(BuildContext context) async {
    final audioCubit = context.read<AudioCubit>();
    await audioCubit.checkPermission();
  }
  
  /// Open app settings
  Future<void> _openSettings(BuildContext context) async {
    try {
      await PermissionHandler.openAppSettings();
    } catch (e) {
      // Show error if settings can't be opened
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open settings: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}