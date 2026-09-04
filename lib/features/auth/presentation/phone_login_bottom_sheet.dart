import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splitico/core/constants/app_colors.dart';
import 'package:splitico/core/constants/app_sizes.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import '../bloc/auth_event.dart';
import 'verify_otp_screen.dart';

class PhoneLoginBottomSheet extends StatefulWidget {
  const PhoneLoginBottomSheet({super.key});

  @override
  State<PhoneLoginBottomSheet> createState() => _PhoneLoginBottomSheetState();
}

class _PhoneLoginBottomSheetState extends State<PhoneLoginBottomSheet> {
  String _selectedCountryCode = '+91';
  String _selectedCountryLabel = 'IN';
  final _phoneController = TextEditingController();
  final _phoneFormKey = GlobalKey<FormState>();
  String? _pendingPhoneNumber;

  final Map<String, String> _countryCodes = {
    'IN': '+91',
    'US': '+1',
    'UK': '+44',
    'AE': '+971',
    'SG': '+65',
  };

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _sendOTP() {
    if (_phoneFormKey.currentState?.validate() ?? false) {
      final phoneNumber = '$_selectedCountryCode ${_phoneController.text.trim()}';
      setState(() {
        _pendingPhoneNumber = phoneNumber;
      });
      context.read<AuthBloc>().add(SendOtpRequested(phoneNumber));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          Navigator.of(context).pop();
        } else if (state is OtpSent) {
          final phone = _pendingPhoneNumber;
          if (phone != null) {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => VerifyOtpScreen(
                  phoneNumber: phone,
                  verificationId: state.verificationId,
                ),
              ),
            );
          }
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppSizes.xxl,
          AppSizes.s,
          AppSizes.xxl,
          bottomInset > 0 ? bottomInset + AppSizes.l : AppSizes.xxxl,
        ),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Horizontal Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(top: 8, bottom: 24),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Text(
                'Enter phone number',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                "We'll send a 6-digit OTP to verify your number",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: AppSizes.xxl),

              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state is AuthError) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSizes.l),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF7F1D1D).withValues(alpha: 0.3)
                            : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDarkMode ? const Color(0xFF991B1B) : const Color(0xFFFCA5A5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: isDarkMode ? const Color(0xFFF87171) : const Color(0xFFEF4444),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              state.message,
                              style: TextStyle(
                                color: isDarkMode ? const Color(0xFFFECACA) : const Color(0xFFB91C1C),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // Phone Input Row
              Form(
                key: _phoneFormKey,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Country Code Selector
                    PopupMenuButton<String>(
                      onSelected: (code) {
                        setState(() {
                          _selectedCountryCode = _countryCodes[code]!;
                          _selectedCountryLabel = code;
                        });
                      },
                      itemBuilder: (context) {
                        return _countryCodes.keys.map((key) {
                          return PopupMenuItem<String>(
                            value: key,
                            child: Text(
                              '$key (${_countryCodes[key]})',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          );
                        }).toList();
                      },
                      child: Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$_selectedCountryLabel $_selectedCountryCode',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_drop_down_rounded,
                              color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.m),

                    // Phone Number Field
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        autofocus: true,
                        keyboardType: TextInputType.phone,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: '98765 43210',
                          hintStyle: TextStyle(
                            color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                          filled: true,
                          fillColor: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter phone number';
                          }
                          if (value.trim().length < 8) {
                            return 'Enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.m),

              // Disclaimer Note
              Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: isDarkMode ? const Color(0xFF64748B) : Colors.grey.shade500,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Standard SMS rates may apply',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? const Color(0xFF64748B) : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.xxl),

              // Send OTP Button
              BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  final isLoading = state is AuthLoading;
                  return ElevatedButton(
                    onPressed: isLoading ? null : _sendOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Send OTP',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  );
                },
              ),
              const SizedBox(height: AppSizes.xl),

              // Policy Footer Links
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                  children: const [
                    TextSpan(text: 'By continuing, you agree to our '),
                    TextSpan(
                      text: 'Terms of Service',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(text: ' & '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
