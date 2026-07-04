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

    on<AddExpense>((event,emit) {
      final currentState = state;
      if (currentState is GroupsLoaded) {

          // Map groups and append the new expense to the matching group

          final updatedGroups = currentState.groups.map((group) {
            if (group.name == event.groupName) {
              return GroupModel(
                name : group.name,
                type : group.type,
                members : group.members,
                expenses : List.from(group.expenses)..add(event.expense),
              );
            }
            return group;
          }).toList();

          emit(GroupsLoaded(updatedGroups));
      }
    });
  }
}
