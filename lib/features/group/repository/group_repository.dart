import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/group.dart';

class GroupRepository {
  final _supabase = Supabase.instance.client;

  // Fetch all groups
  Future<List<GroupModel>>getGroups() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      return [];
    }

    final response = await _supabase.from('groups').select().eq('created_by',
    currentUser.id).order('created_at',ascending: false);
    return (response as List).map((group) => GroupModel.fromJson(group)).toList();
  }
  // Create a new group
  Future<GroupModel> createGroup(GroupModel group) async {
     final currentUser = _supabase.auth.currentUser;
 final groupData = group.toJson();
    if (currentUser != null) {
      groupData['created_by'] = currentUser.id; // Explicitly assign owner
    }
    final response = await _supabase
        .from('groups')
        .insert(groupData)
        .select()
        .single();
    return GroupModel.fromJson(response);
  }

  // Update a group
  Future<GroupModel> updateGroup(String groupId, GroupModel group) async {
    final response = await _supabase
        .from('groups')
        .update(group.toJson())
        .eq('id', groupId)
        .select()
        .single();
    return GroupModel.fromJson(response);
  }

  // Delete a group
  Future<void> deleteGroup(String groupId) async {
    await _supabase.from('groups').delete().eq('id', groupId);
  }
}
