import 'package:splitico/core/models/expense.dart';

class GroupModel {
  final String id;
  final String name;
  final String type; // e.g., 'Travel', 'Home'
  final List<Map<String, dynamic>> members;
  final List<ExpenseModel> expenses;

  GroupModel({
    String? id,
    required this.name,
    required this.type,
    required this.members,
    this.expenses = const [],
  }) : id = id ?? name;
}

