import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:splitico/features/auth/models/app_user.dart';
import 'package:splitico/features/auth/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class AuthRepository {
    final AuthService _authService = AuthService();
  AppUser? _currentUser;

  Future<AppUser?> getCurrentUser() async {
    if (_currentUser != null) {
      return _currentUser;
    }
    final user = _authService.supabase.auth.currentUser;
    if (user != null) {
      _currentUser = AppUser(
        uid: user.id,
        email: user.email ?? '',
        displayName: user.userMetadata?['display_name'] ?? user.email?.split('@').first ?? '',
      );
      return _currentUser;
    }
    return null;
  }


Future<AppUser> login({
  required String email,
  required String password,
}) async {
  try {
    final response = await _authService.supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final user = response.user;
    if (user == null) {
      throw Exception('User not found');
    }
    _currentUser = AppUser(
      uid: user.id,
      email: user.email ?? email,
      displayName: user.userMetadata?['display_name'] ?? email.split('@').first,
    );
    return _currentUser!;
  } catch (e) {
    throw Exception(e.toString());
  }
}


  Future<AppUser> signup({
    required String email,
    required String password,
    required String name,
  }) async {

     // 1. Call the AuthService signup
    final errorMessage = await _authService.signup(email, password,name);
 // 2. If an error is returned, throw an exception
    if (errorMessage != null) {
      throw Exception(errorMessage);
    }

 // 3. Retrieve the signed-up user from Supabase session
    final sessionUser = _authService.supabase.auth.currentUser;
    if (sessionUser == null) {
      throw Exception('User session not found after signup');
    }


 // 4. Update the display name metadata in Supabase (optional, but recommended)
    await _authService.supabase.auth.updateUser(
      UserAttributes(data: {'display_name': name}),
    );
    

    // Simulated network delay
    await Future.delayed(const Duration(milliseconds: 800));

    _currentUser = AppUser(
      uid: sessionUser.id,
      email: sessionUser.email ?? email,
      displayName: name,
    );
    return _currentUser!;
  }

 Future<void> logout() async {
  await _authService.supabase.auth.signOut();
  _currentUser = null;
}

}

class PhoneAuthResult {
  final String? verificationId;
  final AppUser? appUser;

  PhoneAuthResult({this.verificationId, this.appUser});
}

Future<PhoneAuthResult> sendOtp({
  required String phoneNumber,
}) async {
  debugPrint('Starting verifyPhoneNumber for $phoneNumber');
  // Simulated network delay
  await Future.delayed(const Duration(milliseconds: 800));
  
  // Return a mock verification ID
  return PhoneAuthResult(verificationId: 'mock-verification-id-123');
}

Future<AppUser> verifyOtp({
  required String verificationId,
  required String otp,
}) async {
  // Simulated network delay
  await Future.delayed(const Duration(milliseconds: 800));
  
  if (otp != '123456') {
    throw Exception('Invalid OTP. Please use code 123456');
  }

  return AppUser(
    uid: 'phone-mock-uid-123',
    email: 'phone-user@splitico.com',
    displayName: 'Phone User',
  );
}