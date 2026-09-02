import 'package:splitico/core/models/group.dart';

abstract class GroupState {}
class GroupsInitial extends GroupState {}
class GroupsLoading extends GroupState {}
class GroupsLoaded extends GroupState {
  final List<GroupModel> groups;
  GroupsLoaded(this.groups);
}
class GroupsError extends GroupState {
  final String message;
  GroupsError(this.message);
}
