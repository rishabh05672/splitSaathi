import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/color_generator.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import 'dart:io';

/// Repository for authentication and user management.
/// Bridges AuthService and FirestoreService to provide user lifecycle management.
class AuthRepository {
  final AuthService _authService;
  final FirestoreService _firestoreService;
  final NotificationService _notificationService;
  final StorageService _storageService;

  AuthRepository(
    this._authService,
    this._firestoreService,
    this._notificationService,
    this._storageService,
  );

  /// Stream of auth state changes.
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  /// Currently authenticated Firebase user.
  User? get currentUser => _authService.currentUser;

  /// Whether user is signed in.
  bool get isSignedIn => _authService.isSignedIn;

  /// Sign in with email/password.
  /// Returns the UserModel after refreshing FCM token.
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _authService.signInWithEmail(
      email: email,
      password: password,
    );
    return await _onSignIn(credential.user!);
  }

  /// Register with email/password.
  /// Creates user doc in Firestore with random color.
  Future<UserModel> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _authService.registerWithEmail(
      email: email,
      password: password,
    );
    await _authService.updateDisplayName(name);

    return await _createUserInFirestore(
      user: credential.user!,
      name: name,
    );
  }

  /// Sign in with Google.
  /// Creates user in Firestore if first time.
  Future<UserModel?> signInWithGoogle() async {
    final credential = await _authService.signInWithGoogle();
    if (credential == null) return null; // User cancelled

    final user = credential.user!;
    final doc = await _firestoreService.getUser(user.uid);

    if (doc.exists) {
      // Existing user — refresh FCM token
      return await _onSignIn(user);
    } else {
      // New user — create Firestore document
      return await _createUserInFirestore(
        user: user,
        name: user.displayName ?? 'User',
      );
    }
  }

  /// Fetch the current user's UserModel from Firestore.
  Future<UserModel?> getCurrentUserModel() async {
    if (currentUser == null) return null;

    final doc = await _firestoreService.getUser(currentUser!.uid);
    if (!doc.exists) return null;

    return UserModel.fromJson(
      doc.data() as Map<String, dynamic>,
      id: doc.id,
    );
  }

  /// Update user's name in both Firebase Auth and Firestore.
  /// Also syncs the name across all group memberships for real-time reflection.
  Future<void> updateName(String name) async {
    // 1. Update Auth and User Doc
    await _authService.updateDisplayName(name);
    await _firestoreService.updateUser(currentUser!.uid, {'name': name});

    // 2. Sync with all Group Memberships (Real-time update)
    try {
      final memberships = await FirebaseFirestore.instance
          .collectionGroup('members')
          .where('userId', isEqualTo: currentUser!.uid)
          .where('status', isEqualTo: 'active')
          .get();

      if (memberships.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in memberships.docs) {
          batch.update(doc.reference, {'name': name});
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error syncing name across groups: $e');
    }
  }

  /// Update user's photo URL in Firestore.
  Future<void> updatePhotoUrl(String url) async {
    await _authService.updatePhotoUrl(url);
    await _firestoreService.updateUser(currentUser!.uid, {'photoUrl': url});
  }

  /// Update the current user's FCM token in Firestore.
  Future<void> updateFcmToken(String token) async {
    if (currentUser != null) {
      await _firestoreService.setUser(currentUser!.uid, {'fcmToken': token});
    }
  }

  /// Uploads and updates profile image everywhere.
  Future<String> uploadProfileImage(File file) async {
    final url = await _storageService.uploadProfileImage(currentUser!.uid, file);
    
    // 1. Update User Document
    await updatePhotoUrl(url);

    // 2. Sync with all Group Memberships (Real-time update)
    try {
      final memberships = await FirebaseFirestore.instance
          .collectionGroup('members')
          .where('userId', isEqualTo: currentUser!.uid)
          .where('status', isEqualTo: 'active')
          .get();

      if (memberships.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in memberships.docs) {
          batch.update(doc.reference, {'photoUrl': url});
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error syncing photo across groups: $e');
    }

    return url;
  }

  /// Sign out.
  Future<void> signOut() async {
    await _authService.signOut();
  }

  /// Delete user account and cleanup data.
  Future<void> deleteAccount() async {
    if (currentUser == null) return;
    final uid = currentUser!.uid;

    // 1. Remove from all groups
    try {
      final memberships = await FirebaseFirestore.instance
          .collectionGroup('members')
          .where('userId', isEqualTo: uid)
          .get();

      if (memberships.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (var doc in memberships.docs) {
          batch.update(doc.reference, {'status': 'removed'});
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error cleaning up memberships: $e');
    }

    // 2. Delete user document
    await _firestoreService.deleteUser(uid);

    // 3. Delete Firebase Auth account
    await _authService.deleteAccount();
  }

  // ─── Private Helpers ────────────────────────────────────────

  /// Called on every sign-in to refresh FCM token.
  Future<UserModel> _onSignIn(User user) async {
    final fcmToken = await _notificationService.getToken();
    
    // First try to get the user document to see if it exists
    final doc = await _firestoreService.getUser(user.uid);
    
    if (!doc.exists) {
      // If document doesn't exist (e.g. database was reset but user still in Auth), create it
      return await _createUserInFirestore(
        user: user,
        name: user.displayName ?? 'User',
      );
    }

    if (fcmToken != null) {
      // Use merge: true via setUser instead of update to avoid NOT_FOUND errors
      // just in case, though we know it exists now.
      await _firestoreService.setUser(user.uid, {'fcmToken': fcmToken});
    }

    // Fetch the updated document
    final updatedDoc = await _firestoreService.getUser(user.uid);
    return UserModel.fromJson(
      updatedDoc.data() as Map<String, dynamic>,
      id: updatedDoc.id,
    );
  }

  /// Creates a new user document in Firestore with a randomly assigned color.
  Future<UserModel> _createUserInFirestore({
    required User user,
    required String name,
  }) async {
    final fcmToken = await _notificationService.getToken();
    final color = ColorGenerator.getRandomColorHex();

    final userModel = UserModel(
      uid: user.uid,
      name: name,
      email: user.email ?? '',
      photoUrl: user.photoURL,
      color: color,
      fcmToken: fcmToken,
      createdAt: DateTime.now(),
    );

    await _firestoreService.setUser(user.uid, userModel.toJson());
    return userModel;
  }
}
