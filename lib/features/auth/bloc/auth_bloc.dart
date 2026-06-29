import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splitico/core/bloc/base_bloc.dart';
import 'package:splitico/features/auth/repository/auth_repository.dart' as repository;
import '../models/app_user.dart';
import '../repository/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends BaseBloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(AuthRepository authRepository)
      : _authRepository = authRepository,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<LoginRequested>(_onLoginRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<SignOutRequested>(_onSignOutRequested);
    on<PhoneLoginRequested>(_onPhoneLoginRequested);
    on<SendOtpRequested>(_onSendOtpRequested);
    on<VerifyOtpRequested>(_onVerifyOtpRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final user = await _authRepository.getCurrentUser();
    if (user != null) {
      emit(AuthAuthenticated(user));
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.login(
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(user));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        emit(const AuthError('There is no such user'));
      } else {
        emit(AuthError(e.message ?? 'Login failed'));
      }
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onSignUpRequested(
    SignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: event.email,
            password: event.password,
          );

      debugPrint("SUCCESS");
      debugPrint(credential.user?.uid);
      debugPrint(credential.user?.email);

      final user = AppUser(
        uid: credential.user!.uid,
        email: credential.user!.email ?? event.email,
        displayName: credential.user!.displayName ?? event.email.split('@').first,
      );
      emit(AuthAuthenticated(user));
    } catch (e) {
      debugPrint("ERROR: $e");
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }    
     
    
  

  Future<void> _onSignOutRequested(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.logout();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onPhoneLoginRequested(
    PhoneLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // Simulate network request for OTP verification / sign in
      await Future.delayed(const Duration(milliseconds: 1000));
      
      final user = AppUser(
        uid: 'phone-mock-uid-123',
        email: '${event.phoneNumber.replaceAll(' ', '')}@splitico.com',
        displayName: 'Phone User',
      );
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSendOtpRequested(
    SendOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final result = await repository.sendOtp(
        phoneNumber: event.phoneNumber,
      );
      if (result.userCredential != null) {
        final firebaseUser = result.userCredential!.user!;
        final appUser = AppUser(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName ?? firebaseUser.phoneNumber ?? 'Phone User',
        );
        emit(AuthAuthenticated(appUser));
      } else if (result.verificationId != null) {
        emit(OtpSent(result.verificationId!));
      } else {
        emit(const AuthError('Verification failed to initiate'));
      }
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }


Future<void> _onVerifyOtpRequested(
  VerifyOtpRequested event,
  Emitter<AuthState> emit,
) async {

  emit(AuthLoading());

  try {
    final credential =
        await repository.verifyOtp(
      verificationId: event.verificationId,
      otp: event.otp,
    );

    final firebaseUser = credential.user!;
    final appUser = AppUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? firebaseUser.phoneNumber ?? 'Phone User',
    );

    emit(AuthAuthenticated(appUser));

  } catch (e) {
    emit(AuthError(e.toString()));
  }
}
}

