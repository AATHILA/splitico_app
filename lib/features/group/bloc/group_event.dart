import 'package:splitico/core/models/expense.dart';
import 'package:splitico/core/models/group.dart';

abstract class GroupEvent {}

class AddGroup extends GroupEvent {
  final GroupModel group;
  AddGroup(this.group);
}

class UpdateGroup extends GroupEvent {
  final String groupId;
  final GroupModel updatedGroup;
  UpdateGroup({required this.groupId, required this.updatedGroup});
}

class DeleteGroup extends GroupEvent {
  final String groupId;
  DeleteGroup(this.groupId);
}

class AddExpense extends GroupEvent {
  final String groupId;
  final ExpenseModel expense;
  AddExpense({required this.groupId, required this.expense});
}

class UpdateExpense extends GroupEvent {
  final String groupId;
  final String expenseId;
  final ExpenseModel updatedExpense;
  UpdateExpense({
    required this.groupId,
    required this.expenseId,
    required this.updatedExpense,
  });
}

class DeleteExpense extends GroupEvent {
  final String groupId;
  final String expenseId;
  DeleteExpense({required this.groupId, required this.expenseId});
}