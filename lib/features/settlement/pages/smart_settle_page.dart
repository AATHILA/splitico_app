import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/models/group.dart';
import '../../../core/services/upi_payment_service.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../group/bloc/group_bloc.dart';
import '../../group/bloc/group_state.dart';

class SmartSettlementTransaction {
  final String id;
  final String fromName;
  final String fromInitial;
  final Color fromColor;
  final String toName;
  final String toInitial;
  final Color toColor;
  final double amount;
  final String upiId;

  SmartSettlementTransaction({
    required this.id,
    required this.fromName,
    required this.fromInitial,
    required this.fromColor,
    required this.toName,
    required this.toInitial,
    required this.toColor,
    required this.amount,
    required this.upiId,
  });
}

class SmartSettlePage extends StatefulWidget {
  final GroupModel? group;

  const SmartSettlePage({super.key, this.group});

  @override
  State<SmartSettlePage> createState() => _SmartSettlePageState();
}

class _SmartSettlePageState extends State<SmartSettlePage> {
  final Set<String> _settledCardIds = {};

  void _handleSettled(String id, String toName, String amount) {
    setState(() {
      _settledCardIds.add(id);
    });
  }

  void _handleUnsettle(String id, String toName) {
    setState(() {
      _settledCardIds.remove(id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Settlement with $toName unmarked.'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static String _normalizeName(String name, String currentUserName) {
    if (name.toLowerCase() == 'you' ||
        name.toLowerCase() == currentUserName.toLowerCase()) {
      return currentUserName;
    }
    return name;
  }

  static Color _getAvatarColor(int index, dynamic explicitColor) {
    if (explicitColor is Color) return explicitColor;
    if (explicitColor is int) return Color(explicitColor);
    final palette = [
      const Color(0xFF7C3AED), // purple
      const Color(0xFF4C49ED), // indigo
      const Color(0xFF10B981), // green
      const Color(0xFFEC4899), // pink
      const Color(0xFFF59E0B), // amber
      const Color(0xFF06B6D4), // cyan
      const Color(0xFF8B5CF6), // violet
    ];
    return palette[index % palette.length];
  }

  List<SmartSettlementTransaction> _computeSimplifiedDebts({
    required List<GroupModel> groups,
    required String currentUserName,
    required Map<String, Map<String, dynamic>> metadataOut,
    required ValueNotifier<int> rawCountOut,
  }) {
    final Map<String, double> netBalances = {};
    int rawCount = 0;
    int colorIdx = 0;

    // 1. Extract member metadata
    for (var g in groups) {
      for (var member in g.members) {
        final rawName = member['name'] as String;
        final normalizedName = _normalizeName(rawName, currentUserName);
        if (!metadataOut.containsKey(normalizedName)) {
          metadataOut[normalizedName] = {
            'initial':
                member['initial'] ??
                (normalizedName.isNotEmpty
                    ? normalizedName[0].toUpperCase()
                    : '?'),
            'color': _getAvatarColor(
              colorIdx++,
              member['avatarBgColor'] ?? member['color'],
            ),
            'upiId':
                member['upiId'] ??
                '${normalizedName.toLowerCase().replaceAll(' ', '')}@okaxis',
          };
        }
      }

      // 2. Process all expenses to compute net balances
      for (var expense in g.expenses) {
        final splitMembers =
            expense.splitBetween.where((m) => m['selected'] == true).toList();
        if (splitMembers.isEmpty) continue;

        final individualShare = expense.amount / splitMembers.length;
        final payer = _normalizeName(expense.paidBy, currentUserName);

        if (!metadataOut.containsKey(payer)) {
          metadataOut[payer] = {
            'initial': payer.isNotEmpty ? payer[0].toUpperCase() : '?',
            'color': _getAvatarColor(colorIdx++, null),
            'upiId': '${payer.toLowerCase().replaceAll(' ', '')}@okaxis',
          };
        }

        for (var splitMember in splitMembers) {
          final memberName = _normalizeName(
            splitMember['name'] as String,
            currentUserName,
          );
          if (!metadataOut.containsKey(memberName)) {
            metadataOut[memberName] = {
              'initial':
                  memberName.isNotEmpty ? memberName[0].toUpperCase() : '?',
              'color': _getAvatarColor(colorIdx++, splitMember['color']),
              'upiId': '${memberName.toLowerCase().replaceAll(' ', '')}@okaxis',
            };
          }

          if (memberName.toLowerCase() != payer.toLowerCase()) {
            rawCount++;
            netBalances[payer] = (netBalances[payer] ?? 0.0) + individualShare;
            netBalances[memberName] =
                (netBalances[memberName] ?? 0.0) - individualShare;
          }
        }
      }
    }

    rawCountOut.value = rawCount;

    // 3. Separate Debtors (net < 0) and Creditors (net > 0)
    final List<MapEntry<String, double>> debtors = [];
    final List<MapEntry<String, double>> creditors = [];

    netBalances.forEach((person, balance) {
      if (balance < -0.01) {
        debtors.add(MapEntry(person, -balance));
      } else if (balance > 0.01) {
        creditors.add(MapEntry(person, balance));
      }
    });

    // 4. Sort descending to minimize transaction paths
    debtors.sort((a, b) => b.value.compareTo(a.value));
    creditors.sort((a, b) => b.value.compareTo(a.value));

    final List<SmartSettlementTransaction> transactions = [];
    int dIndex = 0;
    int cIndex = 0;

    List<double> dBalances = debtors.map((e) => e.value).toList();
    List<double> cBalances = creditors.map((e) => e.value).toList();

    while (dIndex < debtors.length && cIndex < creditors.length) {
      final debtor = debtors[dIndex].key;
      final creditor = creditors[cIndex].key;
      final dAmount = dBalances[dIndex];
      final cAmount = cBalances[cIndex];

      final settledAmount = (dAmount < cAmount ? dAmount : cAmount);
      if (settledAmount > 0.01) {
        final debtorMeta =
            metadataOut[debtor] ??
            {
              'initial': debtor.isNotEmpty ? debtor[0].toUpperCase() : '?',
              'color': const Color(0xFF7C3AED),
            };
        final creditorMeta =
            metadataOut[creditor] ??
            {
              'initial':
                  creditor.isNotEmpty ? creditor[0].toUpperCase() : '?',
              'color': const Color(0xFF4C49ED),
              'upiId': '${creditor.toLowerCase().replaceAll(' ', '')}@okaxis',
            };

        transactions.add(
          SmartSettlementTransaction(
            id: '${debtor}_${creditor}_${settledAmount.toStringAsFixed(2)}',
            fromName: debtor,
            fromInitial: debtorMeta['initial'],
            fromColor: debtorMeta['color'],
            toName: creditor,
            toInitial: creditorMeta['initial'],
            toColor: creditorMeta['color'],
            amount: settledAmount,
            upiId:
                creditorMeta['upiId'] ??
                '${creditor.toLowerCase().replaceAll(' ', '')}@okaxis',
          ),
        );
      }

      dBalances[dIndex] -= settledAmount;
      cBalances[cIndex] -= settledAmount;

      if (dBalances[dIndex] <= 0.01) dIndex++;
      if (cBalances[cIndex] <= 0.01) cIndex++;
    }

    return transactions;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;

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
            if (widget.group != null) {
              if (groupState is GroupsLoaded) {
                groups = [
                  groupState.groups.firstWhere(
                    (g) => g.id == widget.group!.id,
                    orElse: () => widget.group!,
                  ),
                ];
              } else {
                groups = [widget.group!];
              }
            } else if (groupState is GroupsLoaded) {
              groups = groupState.groups;
            }

            final Map<String, Map<String, dynamic>> memberMetadata = {};
            final rawCountNotifier = ValueNotifier<int>(0);

            final transactions = _computeSimplifiedDebts(
              groups: groups,
              currentUserName: displayName,
              metadataOut: memberMetadata,
              rawCountOut: rawCountNotifier,
            );

            final rawTransactionCount = rawCountNotifier.value;

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
                      // 1. Top status & Back Button bar
                      _buildAppBar(context),
                      const SizedBox(height: AppSizes.l),

                      // 2. Dynamic Optimization Banner
                      _buildOptimizationBanner(
                        context: context,
                        transactions: transactions,
                        rawCount: rawTransactionCount,
                      ),
                      const SizedBox(height: AppSizes.xxl),

                      // 3. Section Title
                      Text(
                        'Settlement Plan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSizes.m),

                      // 4. Settlement Cards Scroll View
                      Expanded(
                        child: _buildSettlementPlanList(
                          context: context,
                          bottomPadding: bottomPadding,
                          transactions: transactions,
                          currentUserName: displayName,
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

  Widget _buildAppBar(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final title =
        widget.group != null ? 'Settle: ${widget.group!.name}' : 'Smart Settle';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Back button in soft rounded box
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        isDarkMode
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDarkMode ? 0.2 : 0.02,
                      ),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: AppSizes.m),
            // Title
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOptimizationBanner({
    required BuildContext context,
    required List<SmartSettlementTransaction> transactions,
    required int rawCount,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final totalPlans = transactions.length;
    final settledCount =
        transactions.where((t) => _settledCardIds.contains(t.id)).length;
    final allSettled = totalPlans > 0 && settledCount >= totalPlans;

    String headline;
    String subtitle;

    if (totalPlans == 0) {
      headline = '🎉 All debts settled!';
      subtitle = 'Everyone is even • No pending settlements';
    } else if (allSettled) {
      headline = '🎉 All debts simplified & settled!';
      subtitle = 'Everyone is now fully even';
    } else if (rawCount > totalPlans) {
      headline = '✨ Optimized for fewer transactions';
      subtitle =
          settledCount > 0
              ? '$settledCount of $totalPlans payments settled • ${totalPlans - settledCount} remaining'
              : '$totalPlans payment${totalPlans == 1 ? '' : 's'} instead of $rawCount • Saves everyone time';
    } else {
      headline = '✨ Smart Settle Plan';
      subtitle =
          settledCount > 0
              ? '$settledCount of $totalPlans payments settled • ${totalPlans - settledCount} remaining'
              : '$totalPlans pending settlement${totalPlans == 1 ? '' : 's'}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.l,
        vertical: AppSizes.l + 2,
      ),
      decoration: BoxDecoration(
        color:
            isDarkMode
                ? const Color(0xFF312E81).withValues(alpha: 0.35)
                : const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isDarkMode
                  ? const Color(0xFF4338CA).withValues(alpha: 0.4)
                  : const Color(0xFFD3E0FF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  headline,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color:
                  isDarkMode
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementPlanList({
    required BuildContext context,
    required double bottomPadding,
    required List<SmartSettlementTransaction> transactions,
    required String currentUserName,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final totalPlans = transactions.length;
    final settledCount =
        transactions.where((t) => _settledCardIds.contains(t.id)).length;
    final allSettled = totalPlans > 0 && settledCount >= totalPlans;

    if (transactions.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.only(top: AppSizes.xl),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color:
                  isDarkMode
                      ? const Color(0xFF334155)
                      : const Color(0xFFF1F5F9),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 14),
              Text(
                'No Pending Settlements',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'All group balances are settled and up to date!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color:
                      isDarkMode
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(bottom: 24 + bottomPadding),
      children: [
        ...transactions.map((tx) {
          final isSettled = _settledCardIds.contains(tx.id);
          final formattedAmount =
              tx.amount % 1 == 0
                  ? '₹${tx.amount.toInt()}'
                  : '₹${tx.amount.toStringAsFixed(2)}';

          return _buildPlanCard(
            context: context,
            id: tx.id,
            fromName: tx.fromName,
            fromInitial: tx.fromInitial,
            fromColor: tx.fromColor,
            toName: tx.toName,
            toInitial: tx.toInitial,
            toColor: tx.toColor,
            amount: formattedAmount,
            rawAmount: tx.amount,
            upiId: tx.upiId,
            showActions: true,
            isSettled: isSettled,
            currentUserName: currentUserName,
          );
        }),
        const SizedBox(height: AppSizes.m),

        // Bottom Status / Celebration View
        if (allSettled)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.xl,
              vertical: AppSizes.xxl,
            ),
            decoration: BoxDecoration(
              color:
                  isDarkMode
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color:
                    isDarkMode
                        ? const Color(0xFF334155)
                        : const Color(0xFFD3E0FF),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isDarkMode ? 0.25 : 0.03,
                  ),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text('🎉', style: TextStyle(fontSize: 44)),
                const SizedBox(height: 10),
                Text(
                  'All settled!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Everyone is even.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color:
                        isDarkMode
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: AppSizes.s),
            child: Center(
              child: Text(
                '$settledCount of $totalPlans payments settled',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color:
                      isDarkMode
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlanCard({
    required BuildContext context,
    required String id,
    required String fromName,
    required String fromInitial,
    required Color fromColor,
    required String toName,
    required String toInitial,
    required Color toColor,
    required String amount,
    required double rawAmount,
    required bool showActions,
    required bool isSettled,
    required String upiId,
    required String currentUserName,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isUserPayer =
        fromName.toLowerCase() == 'you' ||
        fromName.toLowerCase() == currentUserName.toLowerCase();

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row: [A] Athila  →  [R] Rahul          ₹500
          Row(
            children: [
              // Sender Avatar
              CircleAvatar(
                radius: 14,
                backgroundColor: fromColor,
                child: Text(
                  fromInitial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Sender Name
              Text(
                fromName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 6),

              // Arrow
              Icon(
                Icons.arrow_forward_rounded,
                size: 15,
                color:
                    isDarkMode
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 6),

              // Receiver Avatar
              CircleAvatar(
                radius: 14,
                backgroundColor: toColor,
                child: Text(
                  toInitial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Receiver Name
              Expanded(
                child: Text(
                  toName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Amount
              Text(
                amount,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          // Action Buttons
          if (showActions) ...[
            const SizedBox(height: AppSizes.l),
            if (isSettled)
              // When Marked Paid: Filled with blue color exact like the Pay button
              ElevatedButton.icon(
                onPressed: () => _handleUnsettle(id, toName),
                icon: const Icon(Icons.check_circle_rounded, size: 16),
                label: const Text(
                  'Paid ✓',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              )
            else if (isUserPayer)
              // If current user is the payer: show both [ Pay ] and [ Mark Paid ]
              Row(
                children: [
                  // 1. Pay Button (Elevated in AppColors.primary Blue)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        UpiPaymentService.showPaymentMethodBottomSheet(
                          context: context,
                          name: toName,
                          amount: rawAmount,
                          upiId: upiId,
                          onSettled: () => _handleSettled(id, toName, amount),
                        );
                      },
                      icon: const Icon(Icons.flash_on_rounded, size: 16),
                      label: const Text(
                        'Pay',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // 2. Mark Paid Button (Outlined in AppColors.primary Blue)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        UpiPaymentService.showMarkPaidBottomSheet(
                          context: context,
                          name: toName,
                          amount: rawAmount,
                          onSettled: () => _handleSettled(id, toName, amount),
                        );
                      },
                      icon: const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 16,
                      ),
                      label: const Text(
                        'Mark Paid',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                          color:
                              isDarkMode
                                  ? AppColors.primary.withValues(alpha: 0.6)
                                  : AppColors.primary.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        backgroundColor:
                            isDarkMode
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : AppColors.primary.withValues(alpha: 0.08),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              // If current user is NOT the payer: show only [ Mark Paid ] button (Full width)
              OutlinedButton.icon(
                onPressed: () {
                  UpiPaymentService.showMarkPaidBottomSheet(
                    context: context,
                    name: toName,
                    amount: rawAmount,
                    onSettled: () => _handleSettled(id, toName, amount),
                  );
                },
                icon: const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 16,
                ),
                label: const Text(
                  'Mark Paid',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(
                    color:
                        isDarkMode
                            ? AppColors.primary.withValues(alpha: 0.6)
                            : AppColors.primary.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  backgroundColor:
                      isDarkMode
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.primary.withValues(alpha: 0.08),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
