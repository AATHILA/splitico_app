import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splitico/core/constants/app_colors.dart';
import 'package:splitico/core/constants/app_sizes.dart';
import 'package:splitico/core/theme/text_styles.dart';
import 'package:splitico/features/auth/bloc/auth_bloc.dart';
import 'package:splitico/features/auth/bloc/auth_state.dart';
import 'package:splitico/features/home/widgets/balance_card.dart';
import 'package:splitico/features/home/widgets/group_chip.dart';
import 'package:splitico/features/home/widgets/expense_card.dart';
import 'package:splitico/features/home/widgets/custom_bottom_nav_bar.dart';
import 'package:splitico/features/group/pages/create_group_page.dart';
import 'package:splitico/features/group/pages/groups_page.dart';
import 'package:splitico/features/group/pages/group_details_page.dart';
import 'package:splitico/features/settlement/pages/balances_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildBody(context, topPadding),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _currentTabIndex,
        onTabSelected: (index) {
          setState(() {
            _currentTabIndex = index;
          });
        },
      ),
      floatingActionButton: _currentTabIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateGroupPage(),
                  ),
                );
              },
              backgroundColor: AppColors.primary,
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 28,
              ),
            )
          : null,
    );
  }

  Widget _buildBody(BuildContext context, double topPadding) {
    switch (_currentTabIndex) {
      case 0:
        return BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            // TODO: Replace with dynamic user profile data fetched from database/backend.
            String displayName = 'Rahul Kumar';
            if (state is AuthAuthenticated && state.user != null) {
              displayName =
                  state.user!.displayName ?? state.user!.email.split('@').first;
              // Capitalize name nicely
              if (displayName.isNotEmpty) {
                displayName =
                    displayName[0].toUpperCase() + displayName.substring(1);
              }
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Indigo Header Container
                  Container(
                    padding: EdgeInsets.fromLTRB(
                      AppSizes.xxl,
                      topPadding + AppSizes.m,
                      AppSizes.xxl,
                      AppSizes.xxxl,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(AppSizes.radiusXXL),
                        bottomRight: Radius.circular(AppSizes.radiusXXL),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Row representing phone top indicators (9:41, Actions)
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
                              icon: const Icon(Icons.more_horiz_rounded),
                              color: Colors.white,
                              onPressed: () {},
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.xxl),
                        // Welcome & Username
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'Good morning',
                                        style: AppTextStyles.welcome,
                                      ),
                                      const SizedBox(width: AppSizes.xs),
                                      Text(
                                        '👋',
                                        style: AppTextStyles.welcome.copyWith(
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSizes.xs),
                                  Text(
                                    displayName,
                                    style: AppTextStyles.userName,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.xxl),
                        // TODO: Fetch real user balances (youOwe, owedToYou, netBalance) from database/backend.
                        // Balance Card
                        const BalanceCard(
                          youOwe: 1240,
                          owedToYou: 3600,
                          netBalance: 2360,
                        ),
                      ],
                    ),
                  ),
                  // Main Content Body
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.xxl,
                      vertical: AppSizes.xxl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TODO: Fetch user's active groups dynamically from database/backend.
                        // Active Groups Section
                        const Text(
                          'Active Groups',
                          style: AppTextStyles.sectionTitle,
                        ),
                        const SizedBox(height: AppSizes.m),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          child: Row(
                            children: [
                              GroupChip(
                                label: 'Goa Trip',
                                icon: Icons.upload_rounded,
                                backgroundColor: AppColors.groupGoaBg,
                                textColor: AppColors.groupGoaText,
                                iconColor: AppColors.groupGoaText,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const GroupDetailsPage(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: AppSizes.m),
                              GroupChip(
                                label: 'Flat',
                                icon: Icons.home_rounded,
                                backgroundColor: AppColors.groupFlatBg,
                                textColor: AppColors.groupFlatText,
                                iconColor: AppColors.groupFlatText,
                                onTap: () {},
                              ),
                              const SizedBox(width: AppSizes.m),
                              GroupChip(
                                label: 'Friends',
                                icon: Icons.people_rounded,
                                backgroundColor: AppColors.groupFriendsBg,
                                textColor: AppColors.groupFriendsText,
                                iconColor: AppColors.groupFriendsText,
                                onTap: () {},
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSizes.xxl + 8),
                        // TODO: Fetch recent expenses dynamically from database/backend.
                        // Recent Expenses Section
                        const Text(
                          'Recent Expenses',
                          style: AppTextStyles.sectionTitle,
                        ),
                        const SizedBox(height: AppSizes.m),
                        // List of expenses
                        ExpenseCard(
                          title: 'Dinner at Spice Garden',
                          groupName: 'Goa Trip',
                          payerName: 'Arjun',
                          amount: 480,
                          isOwed: false,
                          icon: Icons.restaurant_rounded,
                          iconBgColor: AppColors.iconBgFood,
                          iconColor: AppColors.groupGoaText,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const GroupDetailsPage(),
                              ),
                            );
                          },
                        ),
                        ExpenseCard(
                          title: 'Electricity Bill',
                          groupName: 'Flat',
                          payerName: 'You',
                          amount: 600,
                          isOwed: true,
                          icon: Icons.flash_on_rounded,
                          iconBgColor: AppColors.iconBgElectricity,
                          iconColor: Colors.orange.shade700,
                          onTap: () {},
                        ),
                        ExpenseCard(
                          title: 'Cab to Airport',
                          groupName: 'Goa Trip',
                          payerName: 'Rahul',
                          amount: 320,
                          isOwed: false,
                          icon: Icons.local_taxi_rounded,
                          iconBgColor: AppColors.iconBgTransport,
                          iconColor: Colors.amber.shade800,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const GroupDetailsPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      case 1:
        return const GroupsPage();
      case 2:
        return const BalancesPage();
      case 3:
        return const Center(
          child: Text(
            'Analytics Screen',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        );
      case 4:
        return const Center(
          child: Text(
            'Profile Screen',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        );
      default:
        return const Center(
          child: Text('Unknown Screen'),
        );
    }
  }
}
