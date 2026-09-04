import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../group/bloc/group_bloc.dart';
import '../../group/bloc/group_event.dart';
import '../../../core/models/expense.dart';
import '../../../core/models/group.dart';

class AddExpensePage extends StatefulWidget {
  final bool isEditing;
  final GroupModel group;
  final ExpenseModel? expenseToEdit;
  const AddExpensePage({
    super.key,
    this.isEditing = false,
    required this.group,
    this.expenseToEdit,
  });

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;

  String _selectedCategory = 'Food';
  String _selectedSplitType = 'Equal';

  // List of group members
  List<Map<String, dynamic>> _members = [];

  late Map<String, dynamic> _paidByMember;

  @override
  void initState() {
    super.initState();

    final isEdit = widget.isEditing && widget.expenseToEdit != null;
    _titleController = TextEditingController(
      text: isEdit ? widget.expenseToEdit!.title : '',
    );
    _amountController = TextEditingController(
      text: isEdit ? widget.expenseToEdit!.amount.toString() : '',
    );

    _selectedCategory = isEdit ? widget.expenseToEdit!.category : 'Food';
    _selectedSplitType = isEdit ? widget.expenseToEdit!.splitType : 'Equal';

    _members =
        widget.group.members.map((member) {
          final isMemberSelected =
              isEdit
                  ? widget.expenseToEdit!.splitBetween.any(
                    (m) =>
                        m['name'].toString().toLowerCase() ==
                            member['name'].toString().toLowerCase() &&
                        (m['selected'] ?? true) == true,
                  )
                  : true;

          return {
            'id': member['name'].toString().toLowerCase(),
            'name': member['name'],
            'initial':
                member['initial'] ??
                (member['name'].isNotEmpty
                    ? member['name'][0].toUpperCase()
                    : '?'),
            'color': member['avatarBgColor'] ?? const Color(0xFF7C3AED),
            'selected': isMemberSelected,
          };
        }).toList();

    if (_members.isNotEmpty) {
      if (isEdit) {
        _paidByMember = _members.firstWhere(
          (m) =>
              m['name'].toString().toLowerCase() ==
              widget.expenseToEdit!.paidBy.toLowerCase(),
          orElse: () => _members.first,
        );
      } else {
        _paidByMember = _members.first;
      }
    } else {
      _paidByMember = {
        'id': 'unknown',
        'name': 'No members',
        'initial': '?',
        'color': Colors.grey,
      };
    }
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

  void _saveExpense() {
    final title = _titleController.text.trim();
    final amount = _currentAmount;

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an expense title! ⚠️'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount! ⚠️'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final newExpense = ExpenseModel(
      id:
          widget.isEditing && widget.expenseToEdit != null
              ? widget.expenseToEdit!.id
              : null,
      title: title,
      amount: amount,
      paidBy: _paidByMember['name'],
      splitType: _selectedSplitType,
      splitBetween: _members,
      category: _selectedCategory,
      dateTime:
          widget.isEditing && widget.expenseToEdit != null
              ? widget.expenseToEdit!.dateTime
              : DateTime.now(),
    );

    if (widget.isEditing && widget.expenseToEdit != null) {
      context.read<GroupBloc>().add(
        UpdateExpense(
          groupId: widget.group.id,
          expenseId: widget.expenseToEdit!.id,
          updatedExpense: newExpense,
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Expense "$title" updated successfully! 🎉'),
          backgroundColor: AppColors.expensePositive,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      context.read<GroupBloc>().add(
        AddExpense(groupId: widget.group.id, expense: newExpense),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Expense "$title" saved successfully! 🎉'),
          backgroundColor: AppColors.expensePositive,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    Navigator.of(context).pop();
  }

  void _deleteExpense() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.expenseToEdit != null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(AppSizes.xl),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF7F1D1D).withValues(alpha: 0.4)
                          : const Color(0xFFFEF2F2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFEF4444),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: AppSizes.l),
                  Text(
                    'Delete Expense',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: AppSizes.s),
                  Text(
                    'Are you sure you want to delete "${widget.expenseToEdit!.title}"? This action cannot be undone.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSizes.xl),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            side: BorderSide(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'No',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSizes.m),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            context.read<GroupBloc>().add(
                              DeleteExpense(
                                groupId: widget.group.id,
                                expenseId: widget.expenseToEdit!.id,
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Expense "${widget.expenseToEdit!.title}" deleted successfully! 🗑️',
                                ),
                                backgroundColor: const Color(0xFFEF4444),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Yes',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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

            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.xxl,
                AppSizes.s,
                AppSizes.xxl,
                AppSizes.xxl,
              ),
              child: ElevatedButton(
                onPressed: _saveExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  elevation: 2,
                  shadowColor: AppColors.primary.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                  ),
                ),
                child: Text(
                  widget.isEditing ? 'Save Changes' : 'Save',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
                  color: Theme.of(context).cardColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  size: 20,
                ),
              ),
            ),

            // Title
            Text(
              widget.isEditing ? 'Edit Expense' : 'Add Expense',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),

            // Delete button or empty spacer
            if (widget.isEditing && widget.expenseToEdit != null)
              GestureDetector(
                onTap: _deleteExpense,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF7F1D1D).withValues(alpha: 0.4)
                        : const Color(0xFFFEF2F2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDarkMode ? const Color(0xFF991B1B) : const Color(0xFFFCA5A5),
                    ),
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                ),
              )
            else
              const SizedBox(width: 40),
          ],
        ),
      ],
    );
  }

  Widget _buildTitleInputField() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: TextField(
        controller: _titleController,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: 'Enter Expense Title',
          hintStyle: TextStyle(
            color: isDarkMode ? const Color(0xFF64748B) : AppColors.textLight,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
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
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildCategoryRow() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final categories = [
      {
        'label': 'Food',
        'emoji': '🍽️',
        'color': isDarkMode ? const Color(0xFF312E81).withValues(alpha: 0.4) : const Color(0xFFEEF2FF),
      },
      {
        'label': 'Transport',
        'emoji': '🚗',
        'color': isDarkMode ? const Color(0xFF064E3B).withValues(alpha: 0.4) : const Color(0xFFECFDF5),
      },
      {
        'label': 'Stay',
        'emoji': '🏨',
        'color': isDarkMode ? const Color(0xFF78350F).withValues(alpha: 0.4) : const Color(0xFFFEF3C7),
      },
      {
        'label': 'Activity',
        'emoji': '🎯',
        'color': isDarkMode ? const Color(0xFF881337).withValues(alpha: 0.4) : const Color(0xFFFFF1F2),
      },
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children:
          categories.map((cat) {
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
                    color: isSelected
                        ? color
                        : (isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          isSelected
                              ? AppColors.primary
                              : (isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(emoji, style: const TextStyle(fontSize: 24)),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color:
                              isSelected
                                  ? AppColors.primary
                                  : (isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: _showPaidByPicker,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.l,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
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
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_drop_down_rounded,
              color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
      backgroundColor: Theme.of(context).cardColor,
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
              Text(
                'Paid By',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    member['name'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final types = ['Equal', '%', 'Custom'];

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children:
            types.map((type) {
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
                      color:
                          isSelected ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      type,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color:
                            isSelected
                                ? Colors.white
                                : (isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children:
          _members.map((member) {
            final isSelected = member['selected'] as bool;
            final share = isSelected ? _individualShare : 0.0;
            final amountText = '₹${share.toStringAsFixed(2)}';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isSelected
                          ? (isDarkMode ? AppColors.primary.withValues(alpha: 0.5) : const Color(0xFFEEF2FF))
                          : (isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
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
                        color:
                            isSelected
                                ? AppColors.primary
                                : (isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color:
                              isSelected
                                  ? AppColors.primary
                                  : (isDarkMode ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child:
                          isSelected
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
                    backgroundColor:
                        isSelected
                            ? member['color'] as Color
                            : (isDarkMode ? const Color(0xFF475569) : const Color(0xFF94A3B8)),
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
                      color:
                          isSelected
                              ? Theme.of(context).colorScheme.onSurface
                              : (isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                    ),
                  ),
                  const Spacer(),

                  // Share amount
                  Text(
                    amountText,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color:
                          isSelected
                              ? AppColors.primary
                              : (isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }
}
