import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:splitico/features/auth/presentation/login_screen.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  // Sign up function
  Future<String?> signup(String email, String password,String name) async {
    try {
      final response = await supabase.auth.signUp(
        password: password,
        email: email,
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
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  } catch (e) {
    print("Logout error $e");
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
    } catch (e) {
      debugPrint('[AuthService] Sign out after delete: $e');
    }
  }
}

