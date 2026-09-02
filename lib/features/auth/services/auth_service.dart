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


}
