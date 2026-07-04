import 'package:splitico/core/models/expense.dart';
import 'package:splitico/core/models/group.dart';

abstract class GroupEvent {}
class AddGroup extends GroupEvent {
  final GroupModel group;
  AddGroup(this.group);
}


class AddExpense extends GroupEvent {
  final String groupName;
  final ExpenseModel expense;
  AddExpense({required this.groupName, required this.expense});
}