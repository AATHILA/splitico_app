import 'package:splitico/core/bloc/base_event.dart';

abstract class AuthEvent extends BaseEvent {
  const AuthEvent();
}

class AuthCheckRequested extends AuthEvent {}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class SignUpRequested extends AuthEvent {
  final String email;
  final String password;

  const SignUpRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class SignOutRequested extends AuthEvent {}

class PhoneLoginRequested extends AuthEvent {
  final String phoneNumber;

  const PhoneLoginRequested({required this.phoneNumber});

  @override
  List<Object?> get props => [phoneNumber];
}

class SendOtpRequested extends AuthEvent {
  final String phoneNumber;

  const SendOtpRequested(this.phoneNumber);

  @override
  List<Object?> get props => [phoneNumber];
}

class VerifyOtpRequested extends AuthEvent {
  final String verificationId;
  final String otp;

  const VerifyOtpRequested({
    required this.verificationId,
    required this.otp,
  });

  @override
  List<Object?> get props => [verificationId, otp];
}
