import 'package:splitico/features/auth/models/app_user.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  AppUser? _currentUser;

  Future<AppUser?> getCurrentUser() async {
    // TODO: Fetch the actual authenticated user from Firebase Auth or backend API.
    return _currentUser;
  }

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;

      if (user == null) {
        throw Exception('Login failed');
      }

      return AppUser(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? '',
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('There is no such user');
      }
      throw Exception(e.message);
    }
  }

  Future<AppUser> signup({
    required String email,
    required String password,
  }) async {
    // TODO: Replace with real Firebase Auth / backend API signup implementation.
    // Simulate network delay for the UI
    await Future.delayed(const Duration(milliseconds: 800));

    _currentUser = AppUser(
      uid: 'mock-uid-123',
      email: email,
      displayName: email.split('@').first,
    );
    return _currentUser!;
  }

  Future<void> logout() async {
    // TODO: Replace with real Firebase Auth / backend API logout implementation.
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
  }
}
