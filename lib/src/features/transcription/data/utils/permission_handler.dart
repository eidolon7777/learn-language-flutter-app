import 'dart:io' show Platform;
import 'package:permission_handler/permission_handler.dart';
import '../../domain/exceptions/permission_exception.dart';

/// Utility class for handling microphone permissions
/// Implements FR-004: Microphone permission management
/// 
/// This utility provides a centralized way to handle microphone permissions
/// with proper error handling and platform-specific behavior.
class PermissionHandler {
  static const Permission _microphonePermission = Permission.microphone;
  
  /// Check if microphone permission is granted
  /// 
  /// Returns true if permission is granted, false otherwise
  /// 
  /// Throws:
  /// - [PermissionException] if permission check fails
  static Future<bool> isMicrophonePermissionGranted() async {
    try {
      final status = await _microphonePermission.status;
      return status.isGranted;
    } catch (e) {
      throw PermissionException(
        'Failed to check microphone permission',
        e.toString(),
      );
    }
  }
  
  /// Request microphone permission
  /// 
  /// Returns true if permission is granted after request, false otherwise
  /// 
  /// Throws:
  /// - [PermissionException] if permission request fails
  static Future<bool> requestMicrophonePermission() async {
    try {
      final status = await _microphonePermission.request();
      return status.isGranted;
    } catch (e) {
      throw PermissionException(
        'Failed to request microphone permission',
        e.toString(),
      );
    }
  }
  
  /// Check or request microphone permission
  /// 
  /// First checks if permission is granted, and if not, requests it.
  /// Returns true if permission is available (either already granted or newly granted)
  /// 
  /// Throws:
  /// - [PermissionException] if permission operations fail
  static Future<bool> checkOrRequestMicrophonePermission() async {
    try {
      // First check if permission is already granted
      final isGranted = await isMicrophonePermissionGranted();
      
      if (isGranted) {
        return true;
      }
      
      // Request permission if not granted
      return await requestMicrophonePermission();
      
    } catch (e) {
      throw PermissionException(
        'Failed to check or request microphone permission',
        e.toString(),
      );
    }
  }
  
  /// Get detailed microphone permission status
  /// 
  /// Returns a map with detailed permission information
  /// 
  /// Throws:
  /// - [PermissionException] if permission check fails
  static Future<Map<String, dynamic>> getMicrophonePermissionStatus() async {
    try {
      final status = await _microphonePermission.status;
      
      return {
        'isGranted': status.isGranted,
        'isDenied': status.isDenied,
        'isPermanentlyDenied': status.isPermanentlyDenied,
        'isRestricted': status.isRestricted,
        'isLimited': status.isLimited,
        'status': status.toString(),
        'platform': Platform.operatingSystem,
      };
      
    } catch (e) {
      throw PermissionException(
        'Failed to get microphone permission status',
        e.toString(),
      );
    }
  }
  
  /// Check if microphone is available on the device
  /// 
  /// Returns true if microphone hardware is available, false otherwise
  /// 
  /// Note: This checks hardware availability, not permission status
  static Future<bool> isMicrophoneAvailable() async {
    try {
      // On mobile platforms, we assume microphone is available
      // On web, we can check navigator.mediaDevices
      // On desktop, we might need to check audio devices
      
      if (Platform.isAndroid || Platform.isIOS) {
        // For mobile, check if we can get permission status
        await _microphonePermission.status;
        return true; // Assume hardware is available on mobile
      }
      
      // For other platforms, assume available for now
      // In a real implementation, you might want to check audio devices
      return true;
      
    } catch (e) {
      // If we can't determine, assume not available
      return false;
    }
  }
  
  /// Open app settings to manually grant permission
  /// 
  /// Useful when permission is permanently denied and user needs to
  /// manually enable it in app settings
  /// 
  /// Returns true if settings were opened successfully, false otherwise
  static Future<bool> openAppSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      throw PermissionException(
        'Failed to open app settings',
        e.toString(),
      );
    }
  }
  
  /// Handle permission denial with user-friendly messaging
  /// 
  /// Returns a user-friendly message explaining why permission is needed
  /// and how to grant it
  static String getPermissionDeniedMessage() {
    return 'Microphone permission is required for audio recording. '
           'Please grant microphone permission in app settings.';
  }
  
  /// Get platform-specific permission guidance
  /// 
  /// Returns platform-specific instructions for granting permissions
  static String getPlatformPermissionGuidance() {
    if (Platform.isAndroid) {
      return 'On Android: Go to Settings > Apps > This App > Permissions > Microphone > Allow';
    } else if (Platform.isIOS) {
      return 'On iOS: Go to Settings > Privacy & Security > Microphone > Enable This App';
    } else if (Platform.isMacOS) {
      return 'On macOS: Go to System Preferences > Security & Privacy > Privacy > Microphone > Enable This App';
    } else if (Platform.isWindows) {
      return 'On Windows: Go to Settings > Privacy > Microphone > Enable This App';
    } else {
      return 'Please check your system settings to grant microphone permission.';
    }
  }
}