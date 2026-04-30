import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Service layer for Firebase Authentication.
/// Handles email/password auth, Google Sign-In, and auth state.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Stream of auth state changes (login/logout events).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Currently authenticated user, or null.
  User? get currentUser => _auth.currentUser;

  /// Whether a user is currently signed in.
  bool get isSignedIn => currentUser != null;

  /// Sign in with email and password.
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Register a new user with email and password.
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign in with Google account.
  Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // User cancelled

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await _auth.signInWithCredential(credential);
  }

  /// Update the user's display name.
  Future<void> updateDisplayName(String name) async {
    await currentUser?.updateDisplayName(name);
  }

  /// Update the user's photo URL.
  Future<void> updatePhotoUrl(String url) async {
    await currentUser?.updatePhotoURL(url);
  }

  /// Sign out from both Firebase and Google.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Delete the current user's account.
  Future<void> deleteAccount() async {
    await currentUser?.delete();
  }
}
