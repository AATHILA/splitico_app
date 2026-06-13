import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary palette
  static const Color primary = Color(0xFF4C49ED);
  static const Color primaryLight = Color(0xFFEEF2FF);
  
  // Neutral palette
  static const Color background = Color(0xFFF6F8FC);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFE2E8F0);
  
  // Status Colors
  static const Color expenseNegative = Color(0xFFEF4444); 
  static const Color expensePositive = Color(0xFF10B981); 
  
  // Card balance colors
  static const Color oweAmount = Color(0xFFFFA726); // orange/peach
  static const Color owedAmount = Color(0xFF4ADE80); // green
  static const Color netBalance = Colors.white;
  
  // Custom group colors
  // Goa Trip
  static const Color groupGoaBg = Color(0xFFEEF2FF);
  static const Color groupGoaText = Color(0xFF4C49ED);
  // Flat
  static const Color groupFlatBg = Color(0xFFECFDF5);
  static const Color groupFlatText = Color(0xFF059669);
  // Friends
  static const Color groupFriendsBg = Color(0xFFEFF6FF);
  static const Color groupFriendsText = Color(0xFF2563EB);
  
  // Icon bg colors
  static const Color iconBgFood = Color(0xFFEEF2FF);
  static const Color iconBgElectricity = Color(0xFFECFDF5);
  static const Color iconBgTransport = Color(0xFFFEF3C7);
}
