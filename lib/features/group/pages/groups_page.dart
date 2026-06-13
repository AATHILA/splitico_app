import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import 'create_group_page.dart';
import 'group_details_page.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  final List<Map<String, dynamic>> _allGroups = [
    {
      'name': 'Goa Trip 2024',
      'category': 'Travel',
      'emoji': '🌴',
      'emojiBg': Color(0xFFEEF2FF), // light purple
      'membersCount': 4,
      'expensesCount': 12,
      'balance': -1240.0,
      'balanceLabel': 'you owe',
    },
    {
      'name': 'Flat Mates',
      'category': 'Home',
      'emoji': '🏠',
      'emojiBg': Color(0xFFECFDF5), // light green
      'membersCount': 3,
      'expensesCount': 8,
      'balance': 2400.0,
      'balanceLabel': 'owed to you',
    },
    {
      'name': 'Family',
      'category': 'Family',
      'emoji': '👪',
      'emojiBg': Color(0xFFFFF1F2), // light pink
      'membersCount': 6,
      'expensesCount': 5,
      'balance': 0.0,
      'balanceLabel': 'settled up',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredGroups {
    return _allGroups.where((group) {
      final matchesCategory = _selectedCategory == 'All' || group['category'] == _selectedCategory;
      final matchesSearch = group['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // soft off-white background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSizes.l),
              // Header Row: My Groups + New Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Groups',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CreateGroupPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: const Text(
                      '+ New',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.l),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search groups...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        '🔍',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.l),

              // Category Filter Chips
              _buildCategoryChips(),
              const SizedBox(height: AppSizes.l),

              // Group Cards List
              Expanded(
                child: _filteredGroups.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: _filteredGroups.length,
                        itemBuilder: (context, index) {
                          return _buildGroupCard(_filteredGroups[index]);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = ['All', 'Travel', 'Friends', 'Family'];

    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category;

          return Padding(
            padding: const EdgeInsets.only(right: AppSizes.s),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = category;
                });
              },
              selectedColor: AppColors.primary,
              backgroundColor: const Color(0xFFF1F5F9),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              side: BorderSide.none,
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    final name = group['name'] as String;
    final emoji = group['emoji'] as String;
    final emojiBg = group['emojiBg'] as Color;
    final membersCount = group['membersCount'] as int;
    final expensesCount = group['expensesCount'] as int;
    final balance = group['balance'] as double;
    final balanceLabel = group['balanceLabel'] as String;

    Color balanceColor = const Color(0xFF64748B); // default grey
    String balanceText = '₹0';

    if (balance < 0) {
      balanceColor = AppColors.expenseNegative; // red
      balanceText = '-₹${balance.abs().toStringAsFixed(0)}';
    } else if (balance > 0) {
      balanceColor = AppColors.expensePositive; // green
      balanceText = '+₹${balance.toStringAsFixed(0)}';
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const GroupDetailsPage()),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.m),
        padding: const EdgeInsets.all(AppSizes.l),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusXL + 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            // Emoji/Icon Container
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: emojiBg,
                borderRadius: BorderRadius.circular(AppSizes.radiusXL),
              ),
              alignment: Alignment.center,
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 28),
              ),
            ),
            const SizedBox(width: AppSizes.l),

            // Group Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$membersCount members • $expensesCount expenses',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            // Balance details
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  balanceText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: balanceColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  balanceLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '🔍',
            style: TextStyle(fontSize: 48),
          ),
          const SizedBox(height: AppSizes.m),
          const Text(
            'No groups found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          const Text(
            'Try adjusting your search query or filters',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
