import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/group.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../group/bloc/group_bloc.dart';
import '../../group/bloc/group_state.dart';
import 'smart_settle_page.dart';
import 'settlement_detail_page.dart';

class BalancesPage extends StatelessWidget {
  const BalancesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;

    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        String displayName = 'You';
        if (authState is AuthAuthenticated && authState.user != null) {
          displayName = authState.user!.resolvedDisplayName;
          if (displayName.isNotEmpty) {
            displayName =
                displayName[0].toUpperCase() + displayName.substring(1);
          }
        }
        return BlocBuilder<GroupBloc, GroupState>(
          builder: (context, groupState) {
            List<GroupModel> groups = [];
            if (groupState is GroupsLoaded) {
              groups = groupState.groups;
            }

            final Map<String, double> memberBalances = {};
            final Map<String, Map<String, dynamic>> memberMetadata = {};

            for (var group in groups) {
              for (var member in group.members) {
                final name = member['name'] as String;
                if (name.toLowerCase() != 'you' &&
                    name.toLowerCase() != displayName.toLowerCase()) {
                  memberMetadata.putIfAbsent(
                    name,
                    () => {
                      'initial':
                          member['initial'] ??
                          (name.isNotEmpty ? name[0].toUpperCase() : '?'),
                      'color':
                          member['avatarBgColor'] ??
                          member['color'] ??
                          Colors.deepPurple,
                    },
                  );
                }
              }
              for (var expense in group.expenses) {
                final splitMembers =
                    expense.splitBetween
                        .where((m) => m['selected'] == true)
                        .toList();
                if (splitMembers.isEmpty) continue;
                final individualShare = expense.amount / splitMembers.length;
                final payer = expense.paidBy;
                final isPayerMe =
                    payer.toLowerCase() == 'you' ||
                    payer.toLowerCase() == displayName.toLowerCase();
                if (isPayerMe) {
                  // If you paid, other split members owe you
                  for (var splitMember in splitMembers) {
                    final memberName = splitMember['name'] as String;
                    if (memberName.toLowerCase() != 'you' &&
                        memberName.toLowerCase() != displayName.toLowerCase()) {
                      memberBalances[memberName] =
                          (memberBalances[memberName] ?? 0.0) + individualShare;
                    }
                  }
                } else {
                  // If someone else paid, check if you owe them
                  final isMeInSplit = splitMembers.any(
                    (m) =>
                        m['name'].toString().toLowerCase() == 'you' ||
                        m['name'].toString().toLowerCase() ==
                            displayName.toLowerCase(),
                  );

                  if (isMeInSplit) {
                    memberBalances[payer] =
                        (memberBalances[payer] ?? 0.0) - individualShare;
                  }
                  if (payer.toLowerCase() != 'you' &&
                    payer.toLowerCase() != displayName.toLowerCase()) {
                    memberMetadata.putIfAbsent(
                      payer,
                      () => {
                        'initial':
                            payer.isNotEmpty ? payer[0].toUpperCase() : '?',
                        'color': Colors.grey,
                      },
                    );
                  }
                }
              }
            }

            // Calculate totals
            double totalYouOwe = 0.0;
            double totalOwedToYou = 0.0;

            memberBalances.forEach((member, balance) {
              if (balance > 0.01) {
                totalOwedToYou += balance;
              } else if (balance < -0.01) {
                totalYouOwe += balance.abs();
              }
            });
            final netBalance = totalOwedToYou - totalYouOwe;
            final pendingSettlementsCount =
                memberBalances.values.where((b) => b.abs() > 0.01).length;

            return Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              body: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSizes.xxl,
                    topPadding > 0 ? 0 : AppSizes.m,
                    AppSizes.xxl,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Top status & Title header
                      _buildHeader(context),
                      const SizedBox(height: AppSizes.l),

                      // 2. Net Balance Gradient Card
                      _buildNetBalanceCard(
                        netBalance: netBalance,
                        groupsCount: groups.length,
                        pendingCount: pendingSettlementsCount,
                      ),
                      const SizedBox(height: AppSizes.xxl),

                      // 3. Section Title
                      Text(
                        'Who owes whom',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSizes.m),

                      // 4. Balances List
                      Expanded(
                        child: _buildBalancesList(
                          context: context,
                          memberBalances: memberBalances,
                          memberMetadata: memberMetadata,
                          groups: groups,
                          displayName: displayName,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Balances',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildNetBalanceCard({
    required double netBalance,
    required int groupsCount,
    required int pendingCount,
  }) {
    final hasBalance = netBalance.abs() > 0.01;
    final isOwed = netBalance > 0.01;
    final signText = isOwed ? '+' : (netBalance < -0.01 ? '-' : '');

    return Container(
      padding: const EdgeInsets.all(AppSizes.xxl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              !hasBalance
                  ? [const Color(0xFF64748B), const Color(0xFF475569)]
                  : isOwed
                  ? [const Color(0xFF5E5AFA), const Color(0xFF4C49ED)]
                  : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
        ),
        boxShadow: [
          BoxShadow(
            color: (!hasBalance
                    ? const Color(0xFF475569)
                    : isOwed
                    ? const Color(0xFF4C49ED)
                    : const Color(0xFFDC2626))
                .withValues(alpha: 0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left side: Net Balance Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                !hasBalance
                    ? 'Settled Up'
                    : isOwed
                    ? 'Net Balance (You are owed)'
                    : 'Net Balance (You owe)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  if (signText.isNotEmpty)
                    Text(
                      signText,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  Text(
                    '₹${netBalance.abs().toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Right side: Group & Settlement Details
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Across $groupsCount group${groupsCount == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$pendingCount pending\nsettlement${pendingCount == 1 ? '' : 's'}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalancesList({
    required BuildContext context,
    required Map<String, double> memberBalances,
    required Map<String, Map<String, dynamic>> memberMetadata,
    required List<GroupModel> groups,
    required String displayName,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final List<Map<String, dynamic>> balanceData = [];

    memberBalances.forEach((member, balance) {
      if (balance.abs() < 0.01) return; // skip zero balances

      final isOwed = balance > 0.01;
      final status = isOwed ? 'owes you' : 'you owe';

      final metadata = memberMetadata[member] ?? {};
      final initial =
          metadata['initial'] as String? ??
          (member.isNotEmpty ? member[0].toUpperCase() : '?');
      final avatarColor = metadata['color'] as Color? ?? Colors.deepPurple;

      final badgeBg = isOwed
          ? (isDarkMode ? const Color(0xFF064E3B).withValues(alpha: 0.5) : const Color(0xFFECFDF5))
          : (isDarkMode ? const Color(0xFF7F1D1D).withValues(alpha: 0.5) : const Color(0xFFFEF2F2));
      final badgeText = isOwed
          ? (isDarkMode ? const Color(0xFF34D399) : const Color(0xFF059669))
          : (isDarkMode ? const Color(0xFFF87171) : const Color(0xFFEF4444));
      final amountSign = isOwed ? '→' : '←';
      final amountText = '₹${balance.abs().toStringAsFixed(0)} $amountSign';

      balanceData.add({
        'name': member,
        'status': status,
        'initial': initial,
        'avatarColor': avatarColor,
        'badgeBg': badgeBg,
        'badgeText': badgeText,
        'amount': amountText,
      });
    });

    if (balanceData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppColors.expensePositive.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSizes.m),
            Text(
              'You are all settled up!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        ...balanceData.map((data) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => SettlementDetailPage(
                        memberName: data['name'] as String,
                        netBalance: memberBalances[data['name']] ?? 0.0,
                        initial: data['initial'] as String,
                        avatarColor: data['avatarColor'] as Color,
                        groups: groups,
                        currentUserDisplayName: displayName,
                      ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSizes.m),
              padding: const EdgeInsets.all(AppSizes.l),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Avatar  
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: data['avatarColor'] as Color,
                    child: Text(
                      data['initial'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.m),

                  // Name & Status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['name'] as String,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          data['status'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Amount Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: data['badgeBg'] as Color,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      data['amount'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: data['badgeText'] as Color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: AppSizes.m),

        // Settle All Button
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SmartSettlePage()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 54),
            elevation: 2,
            shadowColor: AppColors.primary.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '✨ Settle All with Smart Split',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
