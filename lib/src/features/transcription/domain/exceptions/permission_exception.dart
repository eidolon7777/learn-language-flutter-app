import 'audio_exceptions.dart';

/// Exception thrown when permission operations fail
class PermissionException extends AudioException {
  const PermissionException(super.message, String super.details);
}