import 'package:flutter/material.dart';

class ExpenseModel {
  final String id;
  final String title;
  final double amount;
  final String paidBy; // Name or ID of the member who paid
  final String splitType; // e.g., 'Equal', '%', 'Custom'
  final List<Map<String, dynamic>> splitBetween; // Members involved and their selections/shares
  final String category;
  final DateTime dateTime;

  ExpenseModel({
    String? id,
    required this.title,
    required this.amount,
    required this.paidBy,
    required this.splitType,
    required this.splitBetween,
    this.category = 'Food',
    DateTime? dateTime,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
  dateTime = dateTime ?? DateTime.now();

  String get emoji {
    switch (category) {
      case 'Food':
        return '🍽️';
      case 'Transport':
        return '🚗';
      case 'Stay':
        return '🏨';
      case 'Activity':
        return '🎯';
      default:
        return '💸';
    }
  }

  Map<String, dynamic> toJson() {
    final serializedSplitBetween = splitBetween.map((m) {
      final Map<String, dynamic> copy = Map.from(m);
      if (copy['color'] is Color) {
        copy['color'] = (copy['color'] as Color).value;
      }
      return copy;
    }).toList();

    return {
      'id': id,
      'title': title,
      'amount': amount,
      'paidBy': paidBy,
      'splitType': splitType,
      'splitBetween': serializedSplitBetween,
      'category': category,
      'dateTime': dateTime.toIso8601String(),
    };
  }

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    final rawSplit = List<Map<String, dynamic>>.from(json['splitBetween']);
    final parsedSplit = rawSplit.map((m) {
      final Map<String, dynamic> copy = Map.from(m);
      if (copy['color'] is int) {
        copy['color'] = Color(copy['color'] as int);
      } else if (copy['color'] is String) {
        final hexCode = (copy['color'] as String).replaceAll('#', '');
        copy['color'] = Color(int.parse('FF$hexCode', radix: 16));
      }
      return copy;
    }).toList();

    return ExpenseModel(
      id: json['id'] as String?,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      paidBy: json['paidBy'] as String,
      splitType: json['splitType'] as String,
      splitBetween: parsedSplit,
      category: json['category'] as String? ?? 'Food',
      dateTime: DateTime.parse(json['dateTime'] as String),
    );
  }
}


