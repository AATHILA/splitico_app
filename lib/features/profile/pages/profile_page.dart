import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splitico/core/constants/app_colors.dart';
import 'package:splitico/core/constants/app_sizes.dart';
import 'package:splitico/features/auth/bloc/auth_bloc.dart';
import 'package:splitico/features/auth/bloc/auth_event.dart';
import 'package:splitico/features/auth/bloc/auth_state.dart';
import 'package:splitico/features/auth/presentation/login_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  String _selectedCurrency = 'INR ₹';

  final List<String> _currencies = [
    'INR ₹',
    'USD \$',
    'EUR €',
    'GBP £',
    'JPY ¥',
  ];

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          // Navigate to LoginScreen and clear stack
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
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
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC), // soft off-white background
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Purple Gradient Header with Stats Card overlapping
              _buildHeaderWithStats(context, topPadding),

              const SizedBox(height: 40), // Spacing for overlapping card

              // 2. Settings Card (Dark Mode, Currency, Notifications)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.xxl),
                child: _buildSettingsCard(context),
              ),

              const SizedBox(height: AppSizes.l),

              // 3. Support Card (Privacy & Security, Help & Support)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.xxl),
                child: _buildSupportCard(context),
              ),

              const SizedBox(height: AppSizes.xxl),

              // 4. Sign Out Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.xxl),
                child: _buildSignOutButton(context),
              ),

              const SizedBox(height: AppSizes.xxxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderWithStats(BuildContext context, double topPadding) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        String displayName = 'Rahul Kumar';
        String email = 'rahul.kumar@gmail.com';
        String initials = 'RK';

        if (state is AuthAuthenticated && state.user != null) {
          final user = state.user!;
          email = user.email;
          displayName = user.displayName ?? user.email.split('@').first;
          
          // Nicely capitalize display name
          if (displayName.isNotEmpty) {
            displayName = displayName[0].toUpperCase() + displayName.substring(1);
          }

          // Compute initials
          final parts = displayName.trim().split(RegExp(r'\s+'));
          if (parts.length > 1) {
            initials = (parts[0][0] + parts[1][0]).toUpperCase();
          } else if (displayName.length > 1) {
            initials = displayName.substring(0, 2).toUpperCase();
          } else if (displayName.isNotEmpty) {
            initials = displayName[0].toUpperCase();
          }
        }

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Gradient Header Background
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                AppSizes.xxl,
                topPadding + AppSizes.l,
                AppSizes.xxl,
                AppSizes.xxxl * 1.8,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF6C63FF), // Vibrant purple-indigo
                    Color(0xFF4C49ED), // Primary purple
                    Color(0xFF3B38B8), // Deep purple
                  ],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppSizes.radiusXXL),
                  bottomRight: Radius.circular(AppSizes.radiusXXL),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x334C49ED),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // App Bar Title & Subtitle Mock Status Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '9:41',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_rounded),
                        color: Colors.white,
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.s),

                  // Circular Profile Avatar with Ring
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: Colors.white,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.m),

                  // Name
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Email
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: AppSizes.xl),
                ],
              ),
            ),

            // Overlapping Stats Card
            Positioned(
              bottom: -28,
              left: AppSizes.xxl,
              right: AppSizes.xxl,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.l),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem('Groups', '5'),
                    _buildStatDivider(),
                    _buildStatItem('Expenses', '42'),
                    _buildStatDivider(),
                    _buildStatItem('Tracked Amount', '₹12,450', isAmount: true),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, {bool isAmount = false}) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isAmount ? 18 : 19,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      width: 1,
      height: 32,
      color: const Color(0xFFF1F5F9),
    );
  }

  Widget _buildSettingsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          // Row 1: Dark Mode
          _buildSettingsRow(
            icon: Icons.dark_mode_rounded,
            iconColor: const Color(0xFFFFA726), // warm yellow
            iconBgColor: const Color(0xFFFFF7ED), // light yellow/lavender
            title: 'Dark Mode',
            trailing: Switch.adaptive(
              value: _isDarkMode,
              activeTrackColor: AppColors.primary,
              onChanged: (value) {
                setState(() {
                  _isDarkMode = value;
                });
              },
            ),
          ),
          _buildItemDivider(),

          // Row 2: Currency Selection
          _buildSettingsRow(
            icon: Icons.sync_rounded,
            iconColor: AppColors.primary,
            iconBgColor: const Color(0xFFEEF2FF), // light lavender/indigo
            title: 'Currency',
            trailing: PopupMenuButton<String>(
              onSelected: (currency) {
                setState(() {
                  _selectedCurrency = currency;
                });
              },
              itemBuilder: (context) {
                return _currencies.map((currency) {
                  return PopupMenuItem<String>(
                    value: currency,
                    child: Text(
                      currency,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  );
                }).toList();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedCurrency,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_drop_down_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          _buildItemDivider(),

          // Row 3: Notifications
          _buildSettingsRow(
            icon: Icons.notifications_rounded,
            iconColor: const Color(0xFFF59E0B), // notification orange
            iconBgColor: const Color(0xFFFEF3C7), // light orange/amber
            title: 'Notifications',
            trailing: Switch.adaptive(
              value: _notificationsEnabled,
              activeTrackColor: const Color(0xFF10B981), // active green in screenshot
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          // Row 1: Privacy & Security
          _buildSettingsRow(
            icon: Icons.lock_rounded,
            iconColor: const Color(0xFFFFA726), // amber/orange lock
            iconBgColor: const Color(0xFFFEF3C7), // light yellow
            title: 'Privacy & Security',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Privacy & Security tapped'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textLight,
            ),
          ),
          _buildItemDivider(),

          // Row 2: Help & Support
          _buildSettingsRow(
            icon: Icons.help_outline_rounded,
            iconColor: const Color(0xFFEF4444), // red question
            iconBgColor: const Color(0xFFFEF2F2), // light red
            title: 'Help & Support',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Help & Support tapped'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.l,
          vertical: 14,
        ),
        child: Row(
          children: [
            // Left icon container
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSizes.l),

            // Title
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            // Trailing component (switch, chevron, selector)
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildItemDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSizes.l),
      child: Divider(
        height: 1,
        color: Color(0xFFF1F5F9),
      ),
    );
  }

  Widget _buildSignOutButton(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        context.read<AuthBloc>().add(SignOutRequested());
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFEF4444), // Red text
        backgroundColor: const Color(0xFFFEF2F2), // Soft red background
        side: const BorderSide(color: Color(0xFFFEE2E2), width: 1.5), // Red-outline
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 0,
      ),
      child: const Text(
        'Sign Out',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
