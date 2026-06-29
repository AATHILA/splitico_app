import 'package:splitico/features/auth/models/app_user.dart';
import 'package:splitico/core/bloc/base_state.dart';

abstract class AuthState extends BaseState {
  const AuthState();
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final AppUser? user;

  const AuthAuthenticated([this.user]);

  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class OtpSent extends AuthState {
  final String verificationId;

  const OtpSent(this.verificationId);

  @override
  List<Object?> get props => [verificationId];
}

class OtpVerified extends AuthState {}






