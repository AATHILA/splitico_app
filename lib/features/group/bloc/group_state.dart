import 'package:splitico/core/models/group.dart';

abstract class GroupState {}
class GroupsInitial extends GroupState {}
class GroupsLoaded extends GroupState {
  final List<GroupModel> groups;
  GroupsLoaded(this.groups);
}
