import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splitico/core/constants/app_colors.dart';
import 'package:splitico/core/constants/app_sizes.dart';
import 'package:splitico/features/auth/bloc/auth_bloc.dart';
import 'package:splitico/features/auth/bloc/auth_event.dart';
import 'package:splitico/features/auth/bloc/auth_state.dart';
import 'package:splitico/features/auth/presentation/login_screen.dart';
import 'package:splitico/features/group/bloc/group_bloc.dart';
import 'package:splitico/features/group/bloc/group_state.dart';
import 'package:splitico/core/theme/theme_cubit.dart';
import 'my_qr_code_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _notificationsEnabled = true;
  String _selectedCurrency = 'INR ₹';

  final List<String> _currencies = [
    'INR ₹',
    'USD \$',
    'EUR €',
    'GBP £',
    'JPY ¥',
  ];

  String get _currencySymbol {
    final parts = _selectedCurrency.split(' ');
    return parts.length > 1 ? parts.last : '₹';
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final isDarkMode = context.watch<ThemeCubit>().isDarkMode;

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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                child: _buildSettingsCard(context, isDarkMode),
              ),

              const SizedBox(height: AppSizes.l),

              // 3. Support Card (Privacy & Security, Help & Support)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.xxl),
                child: _buildSupportCard(context, isDarkMode),
              ),

              const SizedBox(height: AppSizes.xxl),

              // 4. Sign Out Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.xxl),
                child: _buildSignOutButton(context, isDarkMode),
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
      buildWhen: (previous, current) => current is AuthAuthenticated,
    
      builder: (context, authState) {
        String displayName = 'User';
        String email = 'No email provided';
        String initials = 'U';

        if (authState is AuthAuthenticated && authState.user != null) {
          final user = authState.user!;
          email = user.email.isNotEmpty ? user.email : 'No email provided';
          displayName = user.resolvedDisplayName;

          // Nicely capitalize display name
          if (displayName.isNotEmpty) {
            displayName =
                displayName[0].toUpperCase() + displayName.substring(1);
          }

          // Compute initials
          final parts =
              displayName
                  .trim()
                  .split(RegExp(r'\s+'))
                  .where((p) => p.isNotEmpty)
                  .toList();
          if (parts.length > 1) {
            initials = (parts[0][0] + parts[1][0]).toUpperCase();
          } else if (displayName.isNotEmpty) {
            initials = displayName[0].toUpperCase();
          }
        }

        return BlocBuilder<GroupBloc, GroupState>(
          builder: (context, groupState) {
            int groupCount = 0;
            int expenseCount = 0;
            double totalTrackedAmount = 0.0;
            bool isLoading = groupState is GroupsLoading;

            if (groupState is GroupsLoaded) {
              final groups = groupState.groups;
              groupCount = groups.length;

              for (final group in groups) {
                expenseCount += group.expenses.length;
                for (final expense in group.expenses) {
                  totalTrackedAmount += expense.amount;
                }
              }
            }

            final trackedAmountStr =
                isLoading
                    ? '...'
                    : '$_currencySymbol${totalTrackedAmount.toStringAsFixed(totalTrackedAmount % 1 == 0 ? 0 : 2)}';

            final groupCountStr = isLoading ? '...' : groupCount.toString();
            final expenseCountStr = isLoading ? '...' : expenseCount.toString();

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
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
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
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 4,
                          ),
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
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(context, 'Groups', groupCountStr),
                        _buildStatDivider(context),
                        _buildStatItem(context, 'Expenses', expenseCountStr),
                        _buildStatDivider(context),
                        _buildStatItem(
                          context,
                          'Tracked Amount',
                          trackedAmountStr,
                          isAmount: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value, {
    bool isAmount = false,
  }) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isAmount ? 18 : 19,
              fontWeight: FontWeight.w800,
              color: onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: Theme.of(context).dividerColor,
    );
  }

  Widget _buildSettingsCard(BuildContext context, bool isDarkMode) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          // Row 0: My UPI & QR Code
          _buildSettingsRow(
            context: context,
            icon: Icons.qr_code_2_rounded,
            iconColor: AppColors.primary,
            iconBgColor:
                isDarkMode ? const Color(0xFF312E81) : const Color(0xFFEEF2FF),
            title: 'My UPI & QR Code',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => const MyQrCodePage(),
                ),
              );
            },
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: onSurface.withValues(alpha: 0.4),
            ),
          ),
          _buildItemDivider(context),

          // Row 1: Dark Mode
          _buildSettingsRow(
            context: context,
            icon: Icons.dark_mode_rounded,
            iconColor: const Color(0xFFFFA726), // warm yellow
            iconBgColor:
                isDarkMode ? const Color(0xFF334155) : const Color(0xFFFFF7ED),
            title: 'Dark Mode',
            trailing: Switch.adaptive(
              value: isDarkMode,
              activeTrackColor: AppColors.primary,
              onChanged: (value) {
                context.read<ThemeCubit>().toggleTheme(value);
              },
            ),
          ),
          _buildItemDivider(context),

          // Row 2: Currency Selection
          _buildSettingsRow(
            context: context,
            icon: Icons.sync_rounded,
            iconColor: AppColors.primary,
            iconBgColor:
                isDarkMode ? const Color(0xFF312E81) : const Color(0xFFEEF2FF),
            title: 'Currency',
            trailing: PopupMenuButton<String>(
              color: Theme.of(context).cardColor,
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
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: onSurface,
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
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    color: onSurface.withValues(alpha: 0.7),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          _buildItemDivider(context),

          // Row 3: Notifications
          _buildSettingsRow(
            context: context,
            icon: Icons.notifications_rounded,
            iconColor: const Color(0xFFF59E0B), // notification orange
            iconBgColor:
                isDarkMode ? const Color(0xFF451A03) : const Color(0xFFFEF3C7),
            title: 'Notifications',
            trailing: Switch.adaptive(
              value: _notificationsEnabled,
              activeTrackColor: const Color(0xFF10B981), // active green
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

  Widget _buildSupportCard(BuildContext context, bool isDarkMode) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          // Row 1: Privacy & Security
          _buildSettingsRow(
            context: context,
            icon: Icons.lock_rounded,
            iconColor: const Color(0xFFFFA726), // amber/orange lock
            iconBgColor:
                isDarkMode ? const Color(0xFF334155) : const Color(0xFFFEF3C7),
            title: 'Privacy & Security',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Privacy & Security tapped'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: onSurface.withValues(alpha: 0.4),
            ),
          ),
          _buildItemDivider(context),

          // Row 2: Help & Support
          _buildSettingsRow(
            context: context,
            icon: Icons.help_outline_rounded,
            iconColor: const Color(0xFF3B82F6), // blue question
            iconBgColor:
                isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
            title: 'Help & Support',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Help & Support tapped'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: onSurface.withValues(alpha: 0.4),
            ),
          ),
          _buildItemDivider(context),

          // Row 3: Delete Account
          _buildSettingsRow(
            context: context,
            icon: Icons.delete_outline_rounded,
            iconColor:  onSurface,
            iconBgColor:
                isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                title: 'Delete Account',
                         onTap: () => _showDeleteAccountConfirmationDialog(context, isDarkMode),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsRow({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required Widget trailing,
    Color? titleColor,
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
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: AppSizes.l),

            // Title
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: titleColor ?? Theme.of(context).colorScheme.onSurface,
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

  Widget _buildItemDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.l),
      child: Divider(height: 1, color: Theme.of(context).dividerColor),
    );
  }

  Widget _buildSignOutButton(BuildContext context, bool isDarkMode) {
    final isLoading = context.watch<AuthBloc>().state is AuthLoading;
    return OutlinedButton(
      onPressed: isLoading
        ? null : () {
        context.read<AuthBloc>().add(SignOutRequested());
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFEF4444), // Red text
        backgroundColor:
            isDarkMode
                ? const Color(0xFFEF4444).withValues(alpha: 0.12)
                : const Color(0xFFFEF2F2), // Soft red background
        side: BorderSide(
          color:
              isDarkMode
                  ? const Color(0xFFEF4444).withValues(alpha: 0.25)
                  : const Color(0xFFFEE2E2),
          width: 1.5,
        ),
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),
      child: isLoading
        ? const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEF4444)),
            ),
          )
        
      : const Text(
        'Sign Out',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      ),
    );
  }


  void _showDeleteAccountConfirmationDialog(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? const Color(0xFF7F1D1D).withValues(alpha: 0.4)
                      : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFDC2626),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Delete Account',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to permanently delete your account?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? const Color(0xFF7F1D1D).withValues(alpha: 0.2)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDarkMode
                        ? const Color(0xFFEF4444).withValues(alpha: 0.25)
                        : const Color(0xFFFEE2E2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'This action cannot be undone:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildBulletItem(
                      'Your user account will be completely removed from Supabase Auth.',
                      isDarkMode,
                    ),
                    const SizedBox(height: 6),
                    _buildBulletItem(
                      'All groups, expenses, and split calculations created by you will be erased.',
                      isDarkMode,
                    ),
                    const SizedBox(height: 6),
                    _buildBulletItem(
                      'All settlement and payment reminder records will be wiped permanently.',
                      isDarkMode,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: BorderSide(
                        color: isDarkMode ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isDarkMode ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      context.read<AuthBloc>().add(DeleteAccountRequested());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Delete Forever',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildBulletItem(String text, bool isDarkMode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 5, right: 6),
          child: Icon(Icons.circle, size: 5, color: Color(0xFFDC2626)),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
