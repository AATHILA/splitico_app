import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:splitico/features/auth/presentation/login_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  // Sign up function
  Future<String?> signup(String email, String password,String name) async {
    try {
      final response = await supabase.auth.signUp(
        password: password,
        email: email.trim(),
        data: {'display_name': name}, 
      );
      if (response.user != null) {
        return null; // Indicates success
      }
      return "An unknown error occurred";
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Error: $e";
    }
  }

   Future<String?> login(String email, String password) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        password: password,
        email: email,
      );
      if (response.user != null) {
        return null; // Indicates success
      }
      return "Invalid email or password";
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Error: $e";
    }
  }

  Future<void> logout(BuildContext context) async {
    try {
      await supabase.auth.signOut();
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (e) {
      print("Logout error $e");
    }
  }

  // Inside AuthService class:
  Future<String?> signInWithGoogle() async {
    try {
      const webClientId =
          '794278224451-avjottvmim5r2bu7cp08poqtddethj8b.apps.googleusercontent.com';

      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: webClientId,
      );

      // Force show the account picker every time so user can choose their Gmail account
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return 'Google sign-in was cancelled';
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        return 'No ID Token found from Google';
      }

      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      return null; // Success
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// Completely delete user account and associated data from Supabase
  Future<void> deleteAccount() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    // 1. Proactively delete user-created groups from public schema
    try {
      await supabase.from('groups').delete().eq('created_by', user.id);
    } catch (e) {
      debugPrint('[AuthService] Proactive groups cleanup: $e');
    }

    // 2. Call Supabase RPC to completely remove user from auth.users
    try {
      await supabase.rpc('delete_user');
    } catch (e) {
      debugPrint('[AuthService] RPC delete_user error: $e');
      throw Exception(
        'Could not delete user account from Supabase: $e',
      );
    }

    // 3. Clear auth session locally
    try {
      await supabase.auth.signOut();
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
    } catch (e) {
      debugPrint('[AuthService] Sign out after delete: $e');
    }
  }

  Future<String?> resendVerificationEmail(String email) async {
  try {
    await supabase.auth.resend(
      type: OtpType.signup,
      email: email.trim(),
    );
    return null; // Success
  } on AuthException catch (e) {
    return e.message;
  } catch (e) {
    return "Error: $e";
  }
}

Future<String?> verifyOtp({
  required String email,
  required String token,
}) async {
  try {
    final response = await supabase.auth.verifyOTP(
      email: email.trim(),
      token: token.trim(),
      type: OtpType.signup,
    );

    if (response.user != null && response.session != null) {
      return null; // Success: Email confirmed & session active!
    }
    return "Verification failed";
  } on AuthException catch (e) {
    return e.message;
  } catch (e) {
    return "Error: $e";
  }
}

}


