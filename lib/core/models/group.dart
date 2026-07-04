import 'package:splitico/core/models/expense.dart';

class GroupModel {
  final String name;
  final String type; // e.g., 'Travel', 'Home'
  final List<Map<String, dynamic>> members;
  final List<ExpenseModel> expenses;

  GroupModel({
    required this.name,
    required this.type,
    required this.members,
    this.expenses = const [],
  });
}
