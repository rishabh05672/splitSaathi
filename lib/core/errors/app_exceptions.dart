/// Custom exception types for SplitSaathi.
/// Used to provide user-friendly error messages for different failure scenarios.
library;

/// Base exception class for all app-specific errors.
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AppException($code): $message';
}

/// Thrown when an authentication operation fails.
class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.originalError});
}

/// Thrown when a Firestore operation fails.
class FirestoreException extends AppException {
  const FirestoreException(super.message, {super.code, super.originalError});
}

/// Thrown when a network operation fails (no internet, timeout, etc.).
class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// Thrown when a user tries to perform an action without sufficient permissions.
class PermissionException extends AppException {
  const PermissionException(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// Thrown when an invite link is invalid, expired, or exhausted.
class InviteException extends AppException {
  const InviteException(
    super.message, {
    super.code,
    super.originalError,
  });
}

/// Thrown when a storage operation (upload/download) fails.
class StorageException extends AppException {
  const StorageException(
    super.message, {
    super.code,
    super.originalError,
  });
}
