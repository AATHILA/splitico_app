import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:splitico/features/auth/models/app_user.dart';

class AuthRepository {
  AppUser? _currentUser;

  Future<AppUser?> getCurrentUser() async {
    return _currentUser;
  }

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    // Simulated network delay
    await Future.delayed(const Duration(milliseconds: 800));

    if (email.contains('error')) {
      throw Exception('Invalid credentials');
    }

    _currentUser = AppUser(
      uid: 'mock-uid-123',
      email: email,
      displayName: email.split('@').first,
    );
    return _currentUser!;
  }

  Future<AppUser> signup({
    required String email,
    required String password,
    required String name,
  }) async {
    // Simulated network delay
    await Future.delayed(const Duration(milliseconds: 800));

    _currentUser = AppUser(
      uid: 'mock-uid-123',
      email: email,
      displayName: name,
    );
    return _currentUser!;
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
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