import 'package:flutter/material.dart';
import 'package:splitico/core/models/expense.dart';

class GroupModel {
  final String id;
  final String name;
  final String type;
  final List<Map<String, dynamic>> members;
  final List<ExpenseModel> expenses;

  GroupModel({
    String? id,
    required this.name,
    required this.type,
    required this.members,
    this.expenses = const [],
  }) : id = id ?? ''; // Leave empty for Supabase to auto-generate UUID

  Map<String, dynamic> toJson() {
    final serializedMembers = members.map((m) {
      final Map<String, dynamic> copy = Map.from(m);
      if (copy['avatarBgColor'] is Color) {
        copy['avatarBgColor'] = (copy['avatarBgColor'] as Color).value;
      }
      return copy;
    }).toList();

    final data = {
      'name': name,
      'type': type,
      'members': serializedMembers,
      'expenses': expenses.map((e) => e.toJson()).toList(),
    };
    if (id.isNotEmpty) {
      data['id'] = id;
    }
    return data;
  }

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    final rawMembers = List<Map<String, dynamic>>.from(json['members']);
    final parsedMembers = rawMembers.map((m) {
      final Map<String, dynamic> copy = Map.from(m);
      if (copy['avatarBgColor'] is int) {
        copy['avatarBgColor'] = Color(copy['avatarBgColor'] as int);
      } else if (copy['avatarBgColor'] is String) {
        final hexCode = (copy['avatarBgColor'] as String).replaceAll('#', '');
        copy['avatarBgColor'] = Color(int.parse('FF$hexCode', radix: 16));
      }
      return copy;
    }).toList();

    return GroupModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      members: parsedMembers,
      expenses: (json['expenses'] as List? ?? [])
          .map((e) => ExpenseModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
