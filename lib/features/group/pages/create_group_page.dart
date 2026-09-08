import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splitico/core/models/group.dart';
import 'package:splitico/features/group/bloc/group_bloc.dart';
import 'package:splitico/features/group/bloc/group_event.dart';
import 'dart:math';
import 'dart:ui' show ImageFilter;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';

class CreateGroupPage extends StatefulWidget {
  final GroupModel? groupToEdit;
  const CreateGroupPage({super.key, this.groupToEdit});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  late final TextEditingController _nameController;
  String _selectedType = 'Travel';

  final List<Map<String, String>> _groupTypes = [
    {'label': 'Travel', 'emoji': '✈️'},
    {'label': 'Home', 'emoji': '🏠'},
    {'label': 'Friends', 'emoji': '👥'},
    {'label': 'Family', 'emoji': '👪'},
  ];

  final List<Map<String, dynamic>> _members = [];

  @override
  void initState() {
    super.initState();
    if (widget.groupToEdit != null) {
      _nameController = TextEditingController(text: widget.groupToEdit!.name);
      _selectedType = widget.groupToEdit!.type;
      _members.addAll(widget.groupToEdit!.members.map((m) => Map<String, dynamic>.from(m)));
    } else {
      _nameController = TextEditingController(text: '');
      _selectedType = 'Travel';
      // Retrieve authenticated user's info to add them as a default member
      final authState = context.read<AuthBloc>().state;
      if (authState is AuthAuthenticated && authState.user != null) {
        final userName = authState.user!.resolvedDisplayName;
        final initial = userName.isNotEmpty ? userName[0].toUpperCase() : '?';

        _members.add({
          'name': userName,
          'initial': initial,
          'avatarBgColor': const Color(0xFF7C3AED), // Default violet avatar color
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Navigation Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.xxl,
                vertical: AppSizes.m,
              ),
              child: Row(
                children: [
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
                        Icons.arrow_back_rounded,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 20,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      widget.groupToEdit != null ? 'Edit Group' : 'Create Group',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40), // Spacer to balance back button
                ],
              ),
            ),
            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSizes.l),
                    // Group Name Input
                    _buildSectionHeader('GROUP NAME'),
                    const SizedBox(height: AppSizes.s),
                    TextField(
                      controller: _nameController,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter Group Name',
                        hintStyle: TextStyle(
                          color: isDarkMode ? const Color(0xFF64748B) : AppColors.textLight,
                        ),
                        filled: true,
                        fillColor: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.l,
                          vertical: AppSizes.l,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusL),
                          borderSide: BorderSide(
                            color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusL),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.xxl),

                    // Group Type selector
                    _buildSectionHeader('GROUP TYPE'),
                    const SizedBox(height: AppSizes.m),
                    _buildGroupTypeGrid(),
                    const SizedBox(height: AppSizes.xxl),

                    // Add Members section
                    _buildSectionHeader('ADD MEMBERS'),
                    const SizedBox(height: AppSizes.m),
                    _buildMembersWrap(),
                    const SizedBox(height: AppSizes.m),
                    Text(
                      'Invite via link or add by email',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: AppSizes.xl),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSizes.xxl),
              child: ElevatedButton(
                onPressed: () {
                  final name = _nameController.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a group name! ⚠️'),
                        backgroundColor: Colors.redAccent,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  if (widget.groupToEdit != null) {
                    final updatedGroup = GroupModel(
                      id: widget.groupToEdit!.id,
                      name: name,
                      type: _selectedType,
                      members: _members,
                      expenses: widget.groupToEdit!.expenses,
                    );

                    context.read<GroupBloc>().add(
                      UpdateGroup(
                        groupId: widget.groupToEdit!.id,
                        updatedGroup: updatedGroup,
                      ),
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Group "$name" updated successfully! 🎉'),
                        backgroundColor: AppColors.expensePositive,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    Navigator.of(context).pop(updatedGroup);
                  } else {
                    final newGroup = GroupModel(
                      name: name,
                      type: _selectedType,
                      members: _members,
                    );

                    context.read<GroupBloc>().add(AddGroup(newGroup));

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Group "$name" created successfully! 🎉'),
                        backgroundColor: AppColors.expensePositive,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    Navigator.of(context).pop(newGroup);
                  }
                },

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
                  widget.groupToEdit != null ? 'Save Changes' : 'Create Group 🎉',
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

  Widget _buildSectionHeader(String title) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: isDarkMode ? const Color(0xFF94A3B8) : AppColors.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildGroupTypeGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildGroupTypeCard(_groupTypes[0])),
            const SizedBox(width: AppSizes.m),
            Expanded(child: _buildGroupTypeCard(_groupTypes[1])),
          ],
        ),
        const SizedBox(height: AppSizes.m),
        Row(
          children: [
            Expanded(child: _buildGroupTypeCard(_groupTypes[2])),
            const SizedBox(width: AppSizes.m),
            Expanded(child: _buildGroupTypeCard(_groupTypes[3])),
          ],
        ),
      ],
    );
  }

  Widget _buildGroupTypeCard(Map<String, String> type) {
    final label = type['label']!;
    final emoji = type['emoji']!;
    final isSelected = _selectedType == label;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = label;
        });
      },
      child: Container(
        height: 108,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: isDarkMode ? 0.2 : 0.08)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusXL),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: AppSizes.xs),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected
                    ? AppColors.primary
                    : (isDarkMode ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersWrap() {
    return Wrap(
      spacing: AppSizes.s + 2,
      runSpacing: AppSizes.s + 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ..._members.map((member) => _buildMemberChip(member)),
        _buildAddMemberButton(),
      ],
    );
  }

  Widget _buildMemberChip(Map<String, dynamic> member) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final upiId = member['upiId']?.toString().trim();
    final hasUpi = upiId != null && upiId.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.m,
        vertical: AppSizes.s,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusXL),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.015),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: member['avatarBgColor'] as Color,
            child: Text(
              member['initial'] as String,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.s),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                member['name'] as String,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDarkMode ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                ),
              ),
              if (hasUpi)
                Text(
                  upiId,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSizes.xs + 2),
          GestureDetector(
            onTap: () {
              setState(() {
                _members.remove(member);
              });
            },
            child: Icon(
              Icons.close_rounded,
              color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddMemberButton() {
    return GestureDetector(
      onTap: _showAddMemberDialog,
      child: CustomPaint(
        painter: DashedCirclePainter(
          color: AppColors.primary,
          strokeWidth: 1.5,
          dashes: 15,
          gapSize: 3.5,
        ),
        child: Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: const Icon(Icons.add, color: AppColors.primary, size: 20),
        ),
      ),
    );
  }

  void _showAddMemberDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
          child: Dialog(
            backgroundColor: Theme.of(context).cardColor,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: AddMemberDialog(
              existingMembers: _members,
              onMembersAdded: (newMembers) {
                setState(() {
                  _members.addAll(newMembers);
                });
              },
            ),
          ),
        );
      },
    );
  }
}

class AddMemberDialog extends StatefulWidget {
  final List<Map<String, dynamic>> existingMembers;
  final ValueChanged<List<Map<String, dynamic>>> onMembersAdded;

  const AddMemberDialog({
    super.key,
    required this.existingMembers,
    required this.onMembersAdded,
  });

  @override
  State<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<AddMemberDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _upiController = TextEditingController();
  final List<Map<String, dynamic>> _tempMembers = [];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  void _addCurrentInput() {
    final name = _nameController.text.trim();
    final upiId = _upiController.text.trim();
    if (name.isEmpty) return;

    final isAlreadyAdded =
        widget.existingMembers.any(
          (m) => m['name'].toString().toLowerCase() == name.toLowerCase(),
        ) ||
        _tempMembers.any(
          (m) => m['name'].toString().toLowerCase() == name.toLowerCase(),
        );

    if (isAlreadyAdded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$name" is already in this group.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final avatarColors = [
      const Color(0xFF7C3AED),
      const Color(0xFFEC4899),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF3B82F6),
      const Color(0xFFEF4444),
    ];

    final colorIndex =
        (widget.existingMembers.length + _tempMembers.length) %
        avatarColors.length;
    final color = avatarColors[colorIndex];
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    setState(() {
      _tempMembers.add({
        'name': name,
        'initial': initial,
        'avatarBgColor': color,
        'upiId': upiId.isNotEmpty ? upiId : null,
      });
      _nameController.clear();
      _upiController.clear();
    });
  }

  Widget _buildTempMemberRow(Map<String, dynamic> member, int index) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final upiId = member['upiId']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFDBEAFE),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: member['avatarBgColor'] as Color,
            child: Text(
              member['initial'] as String,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  member['name'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (upiId != null && upiId.isNotEmpty)
                  Text(
                    '💳 $upiId',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _tempMembers.removeAt(index);
              });
            },
            child: Icon(
              Icons.close_rounded,
              color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(22),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Member',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Enter name and optional UPI ID for easy 1-tap settlement.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 18),

            Container(
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      autofocus: true,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Name (e.g. Rahul)',
                        hintStyle: TextStyle(
                          color: isDarkMode ? const Color(0xFF64748B) : AppColors.textLight,
                          fontSize: 14,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      onSubmitted: (_) => _addCurrentInput(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.qr_code_2_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _upiController,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'UPI ID: rahul@upi (optional)',
                        hintStyle: TextStyle(
                          color: isDarkMode ? const Color(0xFF64748B) : AppColors.textLight,
                          fontSize: 14,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      onSubmitted: (_) => _addCurrentInput(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed:
                    _nameController.text.trim().isEmpty ? null : _addCurrentInput,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text(
                  'Add to List',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            if (_tempMembers.isNotEmpty) ...[
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.25,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children:
                        _tempMembers
                            .asMap()
                            .map(
                              (index, member) => MapEntry(
                                index,
                                _buildTempMemberRow(member, index),
                              ),
                            )
                            .values
                            .toList(),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),

            ElevatedButton(
              onPressed:
                  _tempMembers.isEmpty
                      ? null
                      : () {
                        widget.onMembersAdded(_tempMembers);
                        Navigator.of(context).pop();
                      },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    isDarkMode
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFE2E8F0),
                disabledForegroundColor: const Color(0xFF94A3B8),
                minimumSize: const Size(double.infinity, 52),
                elevation: _tempMembers.isEmpty ? 0 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Done',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  if (_tempMembers.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_tempMembers.length} added',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashedCirclePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final int dashes;
  final double gapSize;

  DashedCirclePainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.dashes = 15,
    this.gapSize = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.width / 2;
    final Paint paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;

    final double circumference = 2 * pi * radius;
    final double dashLength = (circumference - (dashes * gapSize)) / dashes;
    final double dashAngle = dashLength / radius;
    final double gapAngle = gapSize / radius;

    double currentAngle = 0;
    for (int i = 0; i < dashes; i++) {
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(radius, radius),
          radius: radius - (strokeWidth / 2),
        ),
        currentAngle,
        dashAngle,
        false,
        paint,
      );
      currentAngle += dashAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
