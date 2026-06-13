import 'package:flutter/material.dart';
import 'dart:math';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _nameController = TextEditingController(text: 'Goa Trip 2024 ✈️');
  String _selectedType = 'Travel';

  final List<Map<String, String>> _groupTypes = [
    {'label': 'Travel', 'emoji': '✈️'},
    {'label': 'Home', 'emoji': '🏠'},
    {'label': 'Friends', 'emoji': '👥'},
    {'label': 'Family', 'emoji': '👪'},
  ];

  final List<Map<String, dynamic>> _members = [
    {
      'name': 'Athila',
      'initial': 'A',
      'avatarBgColor': const Color(0xFF7C3AED), // purple
    },
    {
      'name': 'Riya',
      'initial': 'R',
      'avatarBgColor': const Color(0xFFEC4899), // pink
    },
    {
      'name': 'Kiran',
      'initial': 'K',
      'avatarBgColor': const Color(0xFF10B981), // green
    },
  ];

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
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.xxl, vertical: AppSizes.m),
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
                        hintText: 'Enter group name',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.l,
                          vertical: AppSizes.l,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusL),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusL),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Group "${_nameController.text}" created successfully! 🎉'),
                      backgroundColor: AppColors.expensePositive,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  Navigator.of(context).pop();
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
        color: Color(0xFF64748B),
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
          color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusXL),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
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
            Text(
              emoji,
              style: const TextStyle(fontSize: 32),
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.m, vertical: AppSizes.s),
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
        ],
      ),
    );
  }

  Widget _buildAddMemberButton() {
    return CustomPaint(
      painter: DashedCirclePainter(
        color: AppColors.primary,
        strokeWidth: 1.5,
        dashes: 15,
        gapSize: 3.5,
      ),
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.add,
          color: AppColors.primary,
          size: 20,
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
    final Paint paint = Paint()
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
        Rect.fromCircle(center: Offset(radius, radius), radius: radius - (strokeWidth / 2)),
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
