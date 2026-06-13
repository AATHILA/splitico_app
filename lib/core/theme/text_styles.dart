import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Welcome / Subtitle in Header
  static const TextStyle welcome = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: Colors.white70,
  );

  // Username in Header
  static const TextStyle userName = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    letterSpacing: -0.5,
  );

  // Balance Card Labels
  static const TextStyle balanceLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: Colors.white70,
  );

  // Balance Card Amounts
  static const TextStyle oweAmount = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.oweAmount,
  );

  static const TextStyle owedAmount = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.owedAmount,
  );

  static const TextStyle netBalance = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.netBalance,
  );

  // Section Headers
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  // Group Chip Text
  static const TextStyle groupChipText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  // Expense Card Titles
  static const TextStyle expenseTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.1,
  );

  // Expense Card Subtitles
  static const TextStyle expenseSubtitle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  // Expense Card Amounts
  static TextStyle expenseNegative = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: AppColors.expenseNegative,
  );

  static TextStyle expensePositive = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: AppColors.expensePositive,
  );

  // Bottom Navigation Bar Text
  static const TextStyle navItemLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
  );
}
