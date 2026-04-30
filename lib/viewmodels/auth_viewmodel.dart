import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

/// ViewModel for authentication state and operations.
/// Used by auth screens (Splash, Login, Register, Profile).
class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthViewModel(this._authRepository);

  // ─── State ──────────────────────────────────────────────────
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  // ─── Getters ────────────────────────────────────────────────
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSignedIn => _authRepository.isSignedIn;
  Stream<User?> get authStateChanges => _authRepository.authStateChanges;

  // ─── Loading & Error Helpers ────────────────────────────────
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _error = message;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ─── Auth Operations ───────────────────────────────────────

  /// Check auth state and load current user on app start.
  Future<bool> checkAuthState() async {
    try {
      if (_authRepository.isSignedIn) {
        _currentUser = await _authRepository.getCurrentUserModel();
        notifyListeners();
        return _currentUser != null;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Sign in with email and password.
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _setError(null);
      _currentUser = await _authRepository.signInWithEmail(
        email: email,
        password: password,
      );
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _setError(_mapAuthError(e.code));
      return false;
    } catch (e) {
      _setLoading(false);
      _setError('An unexpected error occurred. Please try again.');
      return false;
    }
  }

  /// Register with email and password.
  Future<bool> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _setError(null);
      _currentUser = await _authRepository.registerWithEmail(
        name: name,
        email: email,
        password: password,
      );
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _setError(_mapAuthError(e.code));
      return false;
    } catch (e) {
      _setLoading(false);
      _setError('An unexpected error occurred. Please try again.');
      return false;
    }
  }

  /// Sign in with Google.
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _setError(null);
      _currentUser = await _authRepository.signInWithGoogle();
      _setLoading(false);
      if (_currentUser == null) return false; // User cancelled
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Google sign-in failed. Please try again.');
      return false;
    }
  }

  /// Update user name.
  Future<bool> updateName(String name) async {
    try {
      _setLoading(true);
      await _authRepository.updateName(name);
      _currentUser = _currentUser?.copyWith(name: name);
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to update name.');
      return false;
    }
  }

  /// Update profile photo URL.
  Future<bool> updatePhotoUrl(String url) async {
    try {
      await _authRepository.updatePhotoUrl(url);
      _currentUser = _currentUser?.copyWith(photoUrl: url);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to update photo.');
      return false;
    }
  }

  /// Upload and update profile image.
  Future<bool> uploadProfileImage(File file) async {
    try {
      _setLoading(true);
      final url = await _authRepository.uploadProfileImage(file);
      _currentUser = _currentUser?.copyWith(photoUrl: url);
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to upload image.');
      return false;
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _setError('Failed to sign out.');
    }
  }

  /// Delete account.
  Future<bool> deleteAccount() async {
    try {
      _setLoading(true);
      await _authRepository.deleteAccount();
      _currentUser = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError('Failed to delete account.');
      return false;
    }
  }

  // ─── Error Mapping ─────────────────────────────────────────

  /// Maps Firebase Auth error codes to user-friendly messages.
  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check your email and password.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
