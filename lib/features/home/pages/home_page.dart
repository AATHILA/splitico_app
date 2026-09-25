import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splitico/core/constants/app_colors.dart';
import 'package:splitico/core/constants/app_sizes.dart';
import 'package:splitico/core/models/group.dart';
import 'package:splitico/core/models/expense.dart';
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
import 'package:splitico/features/group/bloc/group_event.dart';
import 'package:splitico/features/group/pages/group_details_page.dart';
import 'package:splitico/features/settlement/pages/balances_page.dart';
import 'package:splitico/features/analytics/pages/analytics_page.dart';
import 'package:splitico/features/profile/pages/profile_page.dart';
import 'package:splitico/features/profile/pages/my_qr_code_page.dart';
import 'package:splitico/features/settlement/pages/qr_scanner_page.dart';
import 'package:splitico/core/services/payment_reminder_service.dart';
import 'package:splitico/core/services/settlement_storage_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentTabIndex = 0;
  final List<GroupModel> _customGroups = [];

  @override
  void initState() {
    super.initState();
    // Refresh the groups list for the currently logged-in user
    context.read<GroupBloc>().add(LoadGroups());
  }

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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant_rounded;
      case 'Transport':
        return Icons.local_taxi_rounded;
      case 'Stay':
        return Icons.hotel_rounded;
      case 'Activity':
        return Icons.local_activity_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  Color _getGroupBgColor(String type) {
    switch (type) {
      case 'Travel':
        return const Color(0xFFFEF3C7); // Soft Amber/Yellow
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
        return const Color(0xFFD97706); // Amber
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                      _customGroups.insert(0, result);
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
          builder: (context, authState) {
            String displayName = 'Rahul Kumar';
            if (authState is AuthAuthenticated && authState.user != null) {
              displayName = authState.user!.resolvedDisplayName;
              // Capitalize name nicely
              if (displayName.isNotEmpty) {
                displayName =
                    displayName[0].toUpperCase() + displayName.substring(1);
              }
            }

            return BlocBuilder<GroupBloc, GroupState>(
              builder: (context, groupState) {
                if (groupState is GroupsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (groupState is GroupsError) {
                  return Center(
                    child: Text('Error loading groups: ${groupState.message}'),
                  );
                }
                List<GroupModel> groups = [];
                if (groupState is GroupsLoaded) {
                  groups = groupState.groups;
                }

                // 1. Gather all expenses across all groups
                final allRecentExpenses = <Map<String, dynamic>>[];
                for (var group in groups) {
                  for (var expense in group.expenses) {
                    allRecentExpenses.add({'group': group, 'expense': expense});
                  }
                }

                // 2. Sort them by date/time (newest first)

                allRecentExpenses.sort((a, b) {
                  final expenseA = a['expense'] as ExpenseModel;
                  final expenseB = b['expense'] as ExpenseModel;
                  return expenseB.dateTime.compareTo(expenseA.dateTime);
                });
                final recentExpenses = allRecentExpenses;

                // 3. Calculate dynamic balances

                double totalYouOwe = 0.0;
                double totalOwedToYou = 0.0;

                for (var group in groups) {
                  for (var expense in group.expenses) {
                    final splitMembers =
                        expense.splitBetween
                            .where((m) => m['selected'] == true)
                            .toList();

                    if (splitMembers.isEmpty) continue;
                    final individualShare =
                        expense.amount / splitMembers.length;
                    final isPaidByMe =
                        expense.paidBy.toLowerCase() == 'you' ||
                        expense.paidBy.toLowerCase() ==
                            displayName.toLowerCase();

                    if (isPaidByMe) {
                      final amIInSplit = splitMembers.any(
                        (m) =>
                            m['name'].toString().toLowerCase() == 'you' ||
                            m['name'].toString().toLowerCase() ==
                                displayName.toLowerCase(),
                      );

                      if (amIInSplit) {
                        totalOwedToYou += expense.amount - individualShare;
                      } else {
                        totalOwedToYou += expense.amount;
                      }
                    } else {
                      final amIInSplit = splitMembers.any(
                        (m) =>
                            m['name'].toString().toLowerCase() == 'you' ||
                            m['name'].toString().toLowerCase() ==
                                displayName.toLowerCase(),
                      );
                      if (amIInSplit) {
                        totalYouOwe += individualShare;
                      }
                    }
                  }
                }

                final netBalance = totalOwedToYou - totalYouOwe;
                final activeGroups = groups
                    .where(
                      (g) => !SettlementStorageService.isGroupSettled(
                        g,
                        displayName,
                      ),
                    )
                    .toList();

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

                            // Welcome & Username
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Text(
                                            'Hi',
                                            style: AppTextStyles.welcome,
                                          ),
                                          const SizedBox(width: AppSizes.xs),
                                          Text(
                                            '👋',
                                            style: AppTextStyles.welcome
                                                .copyWith(fontSize: 16),
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
                                // 1. My QR Code button
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (ctx) => const MyQrCodePage(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.18,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.25,
                                        ),
                                      ),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.qr_code_2_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'My QR',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // 2. Scan QR button
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (ctx) => const QrScannerPage(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.18,
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.25,
                                        ),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.qr_code_scanner_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSizes.xxl),
                            // Balance Card
                            BalanceCard(
                              youOwe: totalYouOwe,
                              owedToYou: totalOwedToYou,
                              netBalance: netBalance,
                            ),

                            // Dynamic Pending Payment Verification Card
                            ValueListenableBuilder<List<PendingPayment>>(
                              valueListenable:
                                  PaymentReminderService
                                      .pendingPaymentsNotifier,
                              builder: (context, pendingList, _) {
                                final activeList =
                                    pendingList
                                        .where((p) => !p.isPaid)
                                        .toList();
                                if (activeList.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                final firstPending = activeList.first;

                                return Container(
                                  margin: const EdgeInsets.only(top: 14),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.08,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.notifications_active_rounded,
                                          color: Color(0xFFD97706),
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Verify ₹${firstPending.amount.toStringAsFixed(0)} to ${firstPending.recipientName}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF1E293B),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              firstPending.reminderCount > 0
                                                  ? 'Reminder ${firstPending.reminderCount + 1}/2 • Completed?'
                                                  : 'Is this payment completed?',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      ElevatedButton(
                                        onPressed:
                                            () =>
                                                PaymentReminderService.markAsPaid(
                                                  firstPending.id,
                                                ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.expensePositive,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'Paid ✓',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        onPressed:
                                            () =>
                                                PaymentReminderService.remindLater(
                                                  firstPending.id,
                                                ),
                                        icon: const Icon(
                                          Icons.access_time_rounded,
                                          size: 16,
                                        ),
                                        color: const Color(0xFF64748B),
                                        tooltip: 'Remind Later',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                          minWidth: 28,
                                          minHeight: 28,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
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
                            Text(
                              'Active Groups',
                              style: AppTextStyles.sectionTitle.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: AppSizes.m),
                            if (activeGroups.isEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSizes.s,
                                ),
                                child: Text(
                                  'No active groups. All settled up! 🎉',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? const Color(0xFF94A3B8)
                                            : AppColors.textLight,
                                  ),
                                ),
                              ),
                            ] else ...[
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                clipBehavior: Clip.none,
                                child: Row(
                                  children:
                                      activeGroups.map((group) {
                                        final isFirst =
                                            activeGroups.indexOf(group) == 0;
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
                                            textColor: Colors.black,
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
                              ),
                            ],
                            const SizedBox(height: AppSizes.xxl + 8),
                            // Recent Expenses Section
                            Text(
                              'Recent Expenses',
                              style: AppTextStyles.sectionTitle.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: AppSizes.m),
                            // List of expenses
                            if (recentExpenses.isEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 24,
                                ),
                                child: Center(
                                  child: Text(
                                    'No recent expenses. 💸',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? const Color(0xFF94A3B8)
                                              : AppColors.textLight,
                                    ),
                                  ),
                                ),
                              ),
                            ] else ...[
                              ...recentExpenses.map((item) {
                                final group = item['group'] as GroupModel;
                                final expense = item['expense'] as ExpenseModel;
                                final isOwed =
                                    expense.paidBy.toLowerCase() == 'you' ||
                                    expense.paidBy.toLowerCase() ==
                                        displayName.toLowerCase();

                                return ExpenseCard(
                                  title: expense.title,
                                  groupName: group.name,
                                  payerName: expense.paidBy,
                                  amount: expense.amount,
                                  isOwed: isOwed,
                                  icon: _getCategoryIcon(expense.category),
                                  iconBgColor: _getGroupBgColor(group.type),
                                  iconColor: _getGroupTextColor(group.type),
                                  dateTime: expense.dateTime,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                GroupDetailsPage(group: group),
                                      ),
                                    );
                                  },
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      case 1:
        return const GroupsPage();
      case 2:
        return const BalancesPage();
      case 3:
        return const AnalyticsPage();
      case 4:
        return const ProfilePage();
      default:
        return const Center(child: Text('Unknown Screen'));
    }
  }
}
