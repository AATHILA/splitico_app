import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splitico/core/constants/app_colors.dart';
import 'package:splitico/core/constants/app_sizes.dart';
import 'package:splitico/core/models/group.dart';
import 'package:splitico/core/theme/text_styles.dart';
import 'package:splitico/features/auth/bloc/auth_bloc.dart';
import 'package:splitico/features/auth/bloc/auth_state.dart';
import 'package:splitico/features/group/bloc/group_bloc.dart';
import 'package:splitico/features/group/bloc/group_state.dart';
import 'package:splitico/features/home/widgets/balance_card.dart';
import 'package:splitico/features/home/widgets/group_chip.dart';
import 'package:splitico/features/home/widgets/expense_card.dart';
import 'package:splitico/features/home/widgets/custom_bottom_nav_bar.dart';
import 'package:splitico/features/group/pages/create_group_page.dart';
import 'package:splitico/features/group/pages/groups_page.dart';
import 'package:splitico/features/group/pages/group_details_page.dart';
import 'package:splitico/features/settlement/pages/balances_page.dart';
import 'package:splitico/features/profile/pages/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentTabIndex = 0;
  final List<GroupModel> _customGroups = [];

  IconData _getGroupIcon(String type) {
    switch (type) {
      case 'Travel':
        return Icons.flight_takeoff_rounded;
      case 'Home':
        return Icons.home_rounded;
      case 'Friends':
        return Icons.people_rounded;
      case 'Family':
        return Icons.family_restroom_rounded;
      default:
        return Icons.group_rounded;
    }
  }

  Color _getGroupBgColor(String type) {
    switch (type) {
      case 'Travel':
        return AppColors.groupGoaBg;
      case 'Home':
        return AppColors.groupFlatBg;
      case 'Friends':
        return AppColors.groupFriendsBg;
      case 'Family':
        return const Color(0xFFFFF1F2);
      default:
        return AppColors.groupFriendsBg;
    }
  }

  Color _getGroupTextColor(String type) {
    switch (type) {
      case 'Travel':
        return AppColors.groupGoaText;
      case 'Home':
        return AppColors.groupFlatText;
      case 'Friends':
        return AppColors.groupFriendsText;
      case 'Family':
        return const Color(0xFFF43F5E);
      default:
        return AppColors.groupFriendsText;
    }
  }

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
      floatingActionButton:
          _currentTabIndex == 0
              ? FloatingActionButton(
                onPressed: () async {
                  final result = await Navigator.push<GroupModel>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateGroupPage(),
                    ),
                  );
                  if (result != null) {
                    setState(() {
                      _customGroups.add(result);
                    });
                  }
                },
                backgroundColor: AppColors.primary,
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
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
              displayName = state.user!.resolvedDisplayName;
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
                        BlocBuilder<GroupBloc, GroupState>(
                          builder: (context, state) {
                            List<GroupModel> groups = [];
                            if (state is GroupsLoaded) {
                              groups = state.groups;
                            }
                            if (groups.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: AppSizes.s,
                                ),
                                child: Text(
                                  'No active groups. Tap + to create one!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textLight,
                                  ),
                                ),
                              );
                            }
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              clipBehavior: Clip.none,
                              child: Row(
                                children:
                                    groups.map((group) {
                                      final isFirst =
                                          groups.indexOf(group) == 0;
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          left: isFirst ? 0 : AppSizes.m,
                                        ),
                                        child: GroupChip(
                                          label: group.name,
                                          icon: _getGroupIcon(group.type),
                                          backgroundColor: _getGroupBgColor(
                                            group.type,
                                          ),
                                          textColor: _getGroupTextColor(
                                            group.type,
                                          ),
                                          iconColor: _getGroupTextColor(
                                            group.type,
                                          ),
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) =>
                                                        GroupDetailsPage(
                                                          group: group,
                                                        ),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    }).toList(),
                              ),
                            );
                          },
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
                                builder:
                                    (context) => GroupDetailsPage(
                                      group: GroupModel(
                                        name: 'Goa Trip',
                                        type: 'Travel',
                                        members: const [
                                          {
                                            'name': 'Athila',
                                            'initial': 'A',
                                            'avatarBgColor': Color(0xFF7C3AED),
                                          },
                                          {
                                            'name': 'Riya',
                                            'initial': 'R',
                                            'avatarBgColor': Color(0xFFEC4899),
                                          },
                                          {
                                            'name': 'Kiran',
                                            'initial': 'K',
                                            'avatarBgColor': Color(0xFF10B981),
                                          },
                                        ],
                                      ),
                                    ),
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
                                builder:
                                    (context) => GroupDetailsPage(
                                      group: GroupModel(
                                        name: 'Goa Trip',
                                        type: 'Travel',
                                        members: const [
                                          {
                                            'name': 'Athila',
                                            'initial': 'A',
                                            'avatarBgColor': Color(0xFF7C3AED),
                                          },
                                          {
                                            'name': 'Riya',
                                            'initial': 'R',
                                            'avatarBgColor': Color(0xFFEC4899),
                                          },
                                          {
                                            'name': 'Kiran',
                                            'initial': 'K',
                                            'avatarBgColor': Color(0xFF10B981),
                                          },
                                        ],
                                      ),
                                    ),
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
        return const ProfilePage();
      default:
        return const Center(child: Text('Unknown Screen'));
    }
  }
}
