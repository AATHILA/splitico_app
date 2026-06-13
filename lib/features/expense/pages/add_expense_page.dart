import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _titleController = TextEditingController(text: 'Dinner at Spice Garden 🍽️');
  final _amountController = TextEditingController(text: '2,400');

  String _selectedCategory = 'Food';
  String _selectedSplitType = 'Equal';

  // List of group members
  final List<Map<String, dynamic>> _members = [
    {
      'id': 'arjun',
      'name': 'Arjun',
      'initial': 'A',
      'color': const Color(0xFF7C3AED), // purple
      'selected': true,
    },
    {
      'id': 'riya',
      'name': 'Riya',
      'initial': 'R',
      'color': const Color(0xFFEC4899), // pink
      'selected': true,
    },
    {
      'id': 'kiran',
      'name': 'Kiran',
      'initial': 'K',
      'color': const Color(0xFF10B981), // green
      'selected': false,
    },
    {
      'id': 'athila',
      'name': 'Athila',
      'initial': 'A',
      'color': const Color(0xFF4C49ED), // indigo
      'selected': true,
    },
  ];

  late Map<String, dynamic> _paidByMember;

  @override
  void initState() {
    super.initState();
    // Default payer is Arjun
    _paidByMember = _members.firstWhere((m) => m['id'] == 'arjun');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // Get current parsed amount
  double get _currentAmount {
    final cleanString = _amountController.text.replaceAll(',', '').trim();
    return double.tryParse(cleanString) ?? 0.0;
  }

  // Calculate individual shares dynamically
  double get _individualShare {
    final selectedCount = _members.where((m) => m['selected'] as bool).length;
    if (selectedCount == 0) return 0.0;
    return _currentAmount / selectedCount;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Custom Top App Bar
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSizes.xxl,
                topPadding + AppSizes.s,
                AppSizes.xxl,
                AppSizes.m,
              ),
              child: _buildTopAppBar(context),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSizes.s),

                    // Expense Title Input Field
                    _buildTitleInputField(),
                    const SizedBox(height: AppSizes.xl),

                    // Large Centered Amount Display
                    _buildCenteredAmountDisplay(),
                    const SizedBox(height: AppSizes.xxl),

                    // Category Section
                    _buildSectionHeader('CATEGORY'),
                    const SizedBox(height: AppSizes.m),
                    _buildCategoryRow(),
                    const SizedBox(height: AppSizes.xxl),

                    // Paid By Dropdown
                    _buildSectionHeader('PAID BY'),
                    const SizedBox(height: AppSizes.m),
                    _buildPaidByDropdown(),
                    const SizedBox(height: AppSizes.xxl),

                    // Split Type Segmented Control
                    _buildSectionHeader('SPLIT TYPE'),
                    const SizedBox(height: AppSizes.m),
                    _buildSplitTypeSegmentedControl(),
                    const SizedBox(height: AppSizes.xxl),

                    // Split Between Checklist
                    _buildSectionHeader('SPLIT BETWEEN'),
                    const SizedBox(height: AppSizes.m),
                    _buildSplitBetweenList(),
                    const SizedBox(height: AppSizes.xxxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Status indicator dots (similar to the image)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '9:41',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E293B),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 14,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E293B),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSizes.m),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Close button in soft rounded box
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Color(0xFF64748B),
                  size: 20,
                ),
              ),
            ),

            // Title
            const Text(
              'Add Expense',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
                letterSpacing: -0.5,
              ),
            ),

            // Save button
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Expense "${_titleController.text}" of ₹${_amountController.text} saved successfully!'),
                    backgroundColor: AppColors.expensePositive,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                Navigator.of(context).pop();
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'Save',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTitleInputField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: _titleController,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
        ),
        decoration: const InputDecoration(
          hintText: 'Enter expense title',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppSizes.l,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCenteredAmountDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          '₹',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        IntrinsicWidth(
          child: TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
              letterSpacing: -0.5,
            ),
            decoration: const InputDecoration(
              hintText: '0',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            onChanged: (val) {
              setState(() {}); // refresh calculation
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: Color(0xFF64748B),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildCategoryRow() {
    final categories = [
      {'label': 'Food', 'emoji': '🍽️', 'color': const Color(0xFFEEF2FF)},
      {'label': 'Transport', 'emoji': '🚗', 'color': const Color(0xFFECFDF5)},
      {'label': 'Stay', 'emoji': '🏨', 'color': const Color(0xFFFEF3C7)},
      {'label': 'Activity', 'emoji': '🎯', 'color': const Color(0xFFFFF1F2)},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: categories.map((cat) {
        final label = cat['label'] as String;
        final emoji = cat['emoji'] as String;
        final color = cat['color'] as Color;
        final isSelected = _selectedCategory == label;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = label;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 80,
              decoration: BoxDecoration(
                color: isSelected ? color : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? AppColors.primary : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaidByDropdown() {
    return GestureDetector(
      onTap: _showPaidByPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.l, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: _paidByMember['color'] as Color,
              child: Text(
                _paidByMember['initial'] as String,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: AppSizes.s + 2),
            Text(
              _paidByMember['name'] as String,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_drop_down_rounded,
              color: Color(0xFF64748B),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  void _showPaidByPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(AppSizes.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Paid By',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: AppSizes.l),
              ..._members.map((member) {
                return ListTile(
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: member['color'] as Color,
                    child: Text(
                      member['initial'] as String,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    member['name'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    setState(() {
                      _paidByMember = member;
                    });
                    Navigator.of(context).pop();
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSplitTypeSegmentedControl() {
    final types = ['Equal', '%', 'Custom'];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: types.map((type) {
          final isSelected = _selectedSplitType == type;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSplitType = type;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  type,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSplitBetweenList() {
    return Column(
      children: _members.map((member) {
        final isSelected = member['selected'] as bool;
        final share = isSelected ? _individualShare : 0.0;
        final amountText = '₹${share.toStringAsFixed(0)}';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFFEEF2FF) : const Color(0xFFF1F5F9),
            ),
          ),
          child: Row(
            children: [
              // Custom checkbox representation
              GestureDetector(
                onTap: () {
                  setState(() {
                    member['selected'] = !isSelected;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : const Color(0xFFCBD5E1),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 14,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: AppSizes.l),

              // Avatar
              CircleAvatar(
                radius: 16,
                backgroundColor: isSelected ? member['color'] as Color : const Color(0xFF94A3B8),
                child: Text(
                  member['initial'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.m),

              // Name
              Text(
                member['name'] as String,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                ),
              ),
              const Spacer(),

              // Share amount
              Text(
                amountText,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? AppColors.primary : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
