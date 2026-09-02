import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splitico/core/models/group.dart';
import '../repository/group_repository.dart';
import 'group_event.dart';
import 'group_state.dart';

class GroupBloc extends Bloc<GroupEvent, GroupState> {
  final GroupRepository _groupRepository;

  GroupBloc(this._groupRepository) : super(GroupsInitial()) {
    
    // 1. Handle loading groups from Supabase
    on<LoadGroups>((event, emit) async {
      emit(GroupsLoading()); // Optional: Add GroupsLoading state to group_state.dart if needed
      try {
        final groups = await _groupRepository.getGroups();
        emit(GroupsLoaded(groups));
      } catch (e) {
        emit(GroupsError(e.toString())); // Optional: Add GroupsError state to group_state.dart if needed
      }
    });

    // 2. Handle creating a new group in Supabase
    on<AddGroup>((event, emit) async {
      try {
        final newGroup = await _groupRepository.createGroup(event.group);
        final currentState = state;
        if (currentState is GroupsLoaded) {
          emit(GroupsLoaded(List.from(currentState.groups)..add(newGroup)));
        } else {
          emit(GroupsLoaded([newGroup]));
        }
      } catch (e) {
       print("GroupBloc Error: $e");
      }
    });

    // 3. Handle updating an existing group in Supabase
    on<UpdateGroup>((event, emit) async {
      try {
        final updatedGroup = await _groupRepository.updateGroup(event.groupId, event.updatedGroup);
        final currentState = state;
        if (currentState is GroupsLoaded) {
          final updatedGroups = currentState.groups.map((group) {
            return group.id == event.groupId ? updatedGroup : group;
          }).toList();
          emit(GroupsLoaded(updatedGroups));
        }
      } catch (e) {
       print("GroupBloc Error: $e");
      }
    });

    // 4. Handle deleting a group from Supabase
    on<DeleteGroup>((event, emit) async {
      try {
        await _groupRepository.deleteGroup(event.groupId);
        final currentState = state;
        if (currentState is GroupsLoaded) {
          final updatedGroups = currentState.groups
              .where((group) => group.id != event.groupId)
              .toList();
          emit(GroupsLoaded(updatedGroups));
        }
      } catch (e) {
       print("GroupBloc Error: $e");
      }
    });

    // 5. Handle adding an expense to a group
    on<AddExpense>((event, emit) async {
      final currentState = state;
      if (currentState is GroupsLoaded) {
        try {
          final targetGroup = currentState.groups.firstWhere((g) => g.id == event.groupId);
          final updatedGroup = GroupModel(
            id: targetGroup.id,
            name: targetGroup.name,
            type: targetGroup.type,
            members: targetGroup.members,
            expenses: List.from(targetGroup.expenses)..add(event.expense),
          );
          
          await _groupRepository.updateGroup(event.groupId, updatedGroup);
          
          final updatedGroups = currentState.groups.map((group) {
            return group.id == event.groupId ? updatedGroup : group;
          }).toList();
          
          emit(GroupsLoaded(updatedGroups));
        } catch (e) {
         print("GroupBloc Error: $e");
        }
      }
    });

    // 6. Handle updating an expense in a group
    on<UpdateExpense>((event, emit) async {
      final currentState = state;
      if (currentState is GroupsLoaded) {
        try {
          final targetGroup = currentState.groups.firstWhere((g) => g.id == event.groupId);
          final updatedExpenses = targetGroup.expenses.map((expense) {
            return expense.id == event.expenseId ? event.updatedExpense : expense;
          }).toList();
          
          final updatedGroup = GroupModel(
            id: targetGroup.id,
            name: targetGroup.name,
            type: targetGroup.type,
            members: targetGroup.members,
            expenses: updatedExpenses,
          );

          await _groupRepository.updateGroup(event.groupId, updatedGroup);

          final updatedGroups = currentState.groups.map((group) {
            return group.id == event.groupId ? updatedGroup : group;
          }).toList();

          emit(GroupsLoaded(updatedGroups));
        } catch (e) {
         print("GroupBloc Error: $e");
        }
      }
    });

    // 7. Handle deleting an expense from a group
    on<DeleteExpense>((event, emit) async {
      final currentState = state;
      if (currentState is GroupsLoaded) {
        try {
          final targetGroup = currentState.groups.firstWhere((g) => g.id == event.groupId);
          final updatedExpenses = targetGroup.expenses
              .where((expense) => expense.id != event.expenseId)
              .toList();
          
          final updatedGroup = GroupModel(
            id: targetGroup.id,
            name: targetGroup.name,
            type: targetGroup.type,
            members: targetGroup.members,
            expenses: updatedExpenses,
          );

          await _groupRepository.updateGroup(event.groupId, updatedGroup);

          final updatedGroups = currentState.groups.map((group) {
            return group.id == event.groupId ? updatedGroup : group;
          }).toList();

          emit(GroupsLoaded(updatedGroups));
        } catch (e) {
          print("GroupBloc Error: $e");
        }
      }
    });
  }
}
