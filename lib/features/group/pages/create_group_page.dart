import 'package:flutter/material.dart';
import 'package:splitico/core/models/group.dart';
import 'dart:math';
import 'dart:ui' show ImageFilter;
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _nameController = TextEditingController(text: '');
  String _selectedType = 'Travel';

  final List<Map<String, String>> _groupTypes = [
    {'label': 'Travel', 'emoji': '✈️'},
    {'label': 'Home', 'emoji': '🏠'},
    {'label': 'Friends', 'emoji': '👥'},
    {'label': 'Family', 'emoji': '👪'},
  ];

  final List<Map<String, dynamic>> _members = [];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                        color: const Color(0xFFF8FAFC),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Color(0xFF1E293B),
                        size: 20,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Create Group',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter Group Name',
                        hintStyle: TextStyle(color: AppColors.textLight),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.l,
                          vertical: AppSizes.l,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusL),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
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
                    const Text(
                      'Invite via link or add by email',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: AppSizes.xl),
                  ],
                ),
              ),
            ),
            // Bottom Action Button
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
                  // 1. Create the new group model
                  final newGroup = GroupModel(
                    name: _nameController.text.trim(),
                    type: _selectedType,
                    members: _members,
                  );
                     // 2. Pop the main page and pass the newGroup back to the HomePage
                 
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Group "${_nameController.text}" created successfully! 🎉',
                      ),
                      backgroundColor: AppColors.expensePositive,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                   Navigator.of(context).pop(newGroup); 
              
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
                child: const Text(
                  'Create Group 🎉',
                  style: TextStyle(
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
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: AppColors.textSecondary,
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

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = label;
        });
      },
      child: Container(
        height: 108,
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusXL),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow:
              isSelected
                  ? []
                  : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
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
                color: isSelected ? AppColors.primary : const Color(0xFF475569),
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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.m,
        vertical: AppSizes.s,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusXL),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 12,
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
          Text(
            member['name'] as String,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(width: AppSizes.xs + 2),
          GestureDetector(
            onTap: () {
              setState(() {
                _members.remove(member);
              });
            },
            child: const Icon(
              Icons.close_rounded,
              color: Color(0xFF94A3B8),
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
            backgroundColor: Colors.white,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
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
    super.dispose();
  }

  void _addCurrentInput() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final isAlreadyAdded = widget.existingMembers.any((m) => m['name'].toString().toLowerCase() == name.toLowerCase()) ||
        _tempMembers.any((m) => m['name'].toString().toLowerCase() == name.toLowerCase());

    if (isAlreadyAdded) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$name" is already added.'),
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

    final colorIndex = (widget.existingMembers.length + _tempMembers.length) % avatarColors.length;
    final color = avatarColors[colorIndex];
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    setState(() {
      _tempMembers.add({
        'name': name,
        'initial': initial,
        'avatarBgColor': color,
      });
      _nameController.clear();
    });
  }

  Widget _buildTempMemberRow(Map<String, dynamic> member, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(30),
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
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              member['name'] as String,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _tempMembers.removeAt(index);
              });
            },
            child: const Icon(
              Icons.check_circle,
              color: AppColors.expensePositive,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add a member',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Enter their name or nickname',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary,
                width: 2.0,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter their name or nickname',
                      hintStyle: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 16,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    onSubmitted: (_) => _addCurrentInput(),
                  ),
                ),
                if (_nameController.text.trim().isNotEmpty)
                  GestureDetector(
                    onTap: _addCurrentInput,
                    child: const Icon(
                      Icons.check_circle,
                      color: AppColors.expensePositive,
                      size: 24,
                    ),
                  ),
              ],
            ),
          ),
          if (_tempMembers.isNotEmpty) ...[
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.3,
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: _tempMembers
                      .asMap()
                      .map((index, member) => MapEntry(
                            index,
                            _buildTempMemberRow(member, index),
                          ))
                      .values
                      .toList(),
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
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
              disabledBackgroundColor: const Color(0xFFE2E8F0),
              disabledForegroundColor: const Color(0xFF94A3B8),
              minimumSize: const Size(double.infinity, 56),
              elevation: _tempMembers.isEmpty ? 0 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_tempMembers.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
