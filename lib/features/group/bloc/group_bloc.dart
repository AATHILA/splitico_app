import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splitico/core/models/group.dart';
import 'group_event.dart';
import 'group_state.dart';

class GroupBloc extends Bloc<GroupEvent, GroupState> {
  GroupBloc() : super(GroupsInitial()) {
    on<AddGroup>((event, emit) {
      final currentState = state;
      if (currentState is GroupsLoaded) {
        // Emit a new state containing all existing groups + the newly created group
        emit(GroupsLoaded(List.from(currentState.groups)..add(event.group)));
      } else {
        // Emit the first group loaded state
        emit(GroupsLoaded([event.group]));
      }
    });

    on<UpdateGroup>((event, emit) {
      final currentState = state;
      if (currentState is GroupsLoaded) {
        final updatedGroups = currentState.groups.map((group) {
          if (group.id == event.groupId) {
            return event.updatedGroup;
          }
          return group;
        }).toList();
        emit(GroupsLoaded(updatedGroups));
      }
    });

    on<DeleteGroup>((event, emit) {
      final currentState = state;
      if (currentState is GroupsLoaded) {
        final updatedGroups = currentState.groups
            .where((group) => group.id != event.groupId)
            .toList();
        emit(GroupsLoaded(updatedGroups));
      }
    });

    on<AddExpense>((event, emit) {
      final currentState = state;
      if (currentState is GroupsLoaded) {
        // Map groups and append the new expense to the matching group
        final updatedGroups = currentState.groups.map((group) {
          if (group.id == event.groupId) {
            return GroupModel(
              id: group.id,
              name: group.name,
              type: group.type,
              members: group.members,
              expenses: List.from(group.expenses)..add(event.expense),
            );
          }
          return group;
        }).toList();

        emit(GroupsLoaded(updatedGroups));
      }
    });

    on<UpdateExpense>((event, emit) {
      final currentState = state;
      if (currentState is GroupsLoaded) {
        final updatedGroups = currentState.groups.map((group) {
          if (group.id == event.groupId) {
            final updatedExpenses = group.expenses.map((expense) {
              if (expense.id == event.expenseId) {
                return event.updatedExpense;
              }
              return expense;
            }).toList();
            return GroupModel(
              id: group.id,
              name: group.name,
              type: group.type,
              members: group.members,
              expenses: updatedExpenses,
            );
          }
          return group;
        }).toList();
        emit(GroupsLoaded(updatedGroups));
      }
    });

    on<DeleteExpense>((event, emit) {
      final currentState = state;
      if (currentState is GroupsLoaded) {
        final updatedGroups = currentState.groups.map((group) {
          if (group.id == event.groupId) {
            final updatedExpenses = group.expenses
                .where((expense) => expense.id != event.expenseId)
                .toList();
            return GroupModel(
              id: group.id,
              name: group.name,
              type: group.type,
              members: group.members,
              expenses: updatedExpenses,
            );
          }
          return group;
        }).toList();
        emit(GroupsLoaded(updatedGroups));
      }
    });
  }
}

