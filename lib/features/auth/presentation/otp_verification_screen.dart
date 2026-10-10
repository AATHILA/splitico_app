import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splitico/core/constants/app_colors.dart';
import 'package:splitico/core/constants/app_sizes.dart';
import 'package:splitico/core/services/email_service.dart';
import 'package:splitico/features/auth/bloc/auth_bloc.dart';
import 'package:splitico/features/auth/bloc/auth_event.dart';
import 'package:splitico/features/auth/services/auth_service.dart';
import 'package:splitico/features/home/pages/home_page.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String name;
  final String password;
  final String initialOtp;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.name,
    required this.password,
    required this.initialOtp,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (_) => FocusNode(),
  );

  final AuthService _authService = AuthService();
  final EmailService _emailService = EmailService();

  late String _currentExpectedOtp;
  bool _isLoading = false;
  bool _isResending = false;

  Timer? _timer;
  int _secondsRemaining = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _currentExpectedOtp = widget.initialOtp;
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    setState(() {
      _secondsRemaining = 30;
      _canResend = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  String get _currentOtp => _controllers.map((c) => c.text.trim()).join();

  Future<void> _verifyOtp() async {
    final enteredOtp = _currentOtp;
    if (enteredOtp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter all 6 digits of the verification code'),
          backgroundColor: AppColors.expenseNegative,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (enteredOtp != _currentExpectedOtp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect verification code. Please check your email.'),
          backgroundColor: AppColors.expenseNegative,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Create user in Supabase
    final error = await _authService.signup(
      widget.email,
      widget.password,
      widget.name,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      // Sync auth state in BLoC
      context.read<AuthBloc>().add(AuthCheckRequested());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email verified! Account created successfully.'),
          backgroundColor: AppColors.expensePositive,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate to Home Page and clear stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _resendOtp() async {
    if (!_canResend || _isResending) return;

    setState(() => _isResending = true);

    final newOtp = (100000 + Random().nextInt(900000)).toString();
    final sent = await _emailService.sendOtpEmail(
      to: widget.email,
      otp: newOtp,
      name: widget.name,
    );

    if (!mounted) return;
    setState(() => _isResending = false);

    if (sent) {
      setState(() => _currentExpectedOtp = newOtp);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New verification code sent! Check your email.'),
          backgroundColor: AppColors.expensePositive,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _startCountdown();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not resend email. Please try again.'),
          backgroundColor: AppColors.expenseNegative,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      // Handle pasting 6 digits
      final cleanDigits = value.replaceAll(RegExp(r'\D'), '');
      if (cleanDigits.isNotEmpty) {
        for (int i = 0; i < 6 && i < cleanDigits.length; i++) {
          _controllers[i].text = cleanDigits[i];
        }
        final targetIndex = (cleanDigits.length < 6) ? cleanDigits.length : 5;
        _focusNodes[targetIndex].requestFocus();

        if (cleanDigits.length >= 6) {
          _verifyOtp();
        }
        return;
      }
    }

    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        if (_currentOtp.length == 6) {
          _verifyOtp();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSizes.xxl,
            topPadding + AppSizes.m,
            AppSizes.xxl,
            bottomPadding > 0 ? bottomPadding + AppSizes.l : AppSizes.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSizes.l),

              // Back button
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                      size: 20,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSizes.xxxl),

              // Mail Icon Graphic
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    color: AppColors.primary,
                    size: 36,
                  ),
                ),
              ),

              const SizedBox(height: AppSizes.xxl),

              // Title
              Text(
                'Verify your email',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: AppSizes.s),

              // Subtitle with user's email
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  children: [
                    const TextSpan(
                      text: 'We sent a 6-digit verification code to\n',
                    ),
                    TextSpan(
                      text: widget.email,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSizes.xxxl + 8),

              // 6 OTP Digit Input Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 46,
                    height: 56,
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (event) {
                        if (event is KeyDownEvent &&
                            event.logicalKey == LogicalKeyboardKey.backspace &&
                            _controllers[index].text.isEmpty &&
                            index > 0) {
                          _focusNodes[index - 1].requestFocus();
                          _controllers[index - 1].clear();
                        }
                      },
                      child: TextFormField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        autofocus: index == 0,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                          filled: true,
                          fillColor: isDarkMode
                              ? const Color(0xFF1E293B)
                              : const Color(0xFFF8FAFC),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDarkMode
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                        ),
                        onChanged: (val) => _onDigitChanged(index, val),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: AppSizes.xxxl),

              // Verify Button
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 54),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Verify Code',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),

              const SizedBox(height: AppSizes.xxl),

              // Resend countdown footer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive the code? ",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  _canResend
                      ? GestureDetector(
                          onTap: _isResending ? null : _resendOtp,
                          child: Text(
                            _isResending ? 'Sending...' : 'Resend Code',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : Text(
                          'Resend in ${_secondsRemaining}s',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDarkMode
                                ? Colors.white70
                                : const Color(0xFF1E293B),
                          ),
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
