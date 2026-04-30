import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A common service for managing encrypted local storage.
/// Use this for sensitive user data like tokens, passwords, or personal info.
class SecureStorageService {
  // Private constructor for singleton
  SecureStorageService._();
  static final SecureStorageService instance = SecureStorageService._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  /// Write a value to secure storage.
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  /// Read a value from secure storage.
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  /// Delete a specific key.
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  /// Clear all secure storage.
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  /// Check if a key exists.
  Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }
}
