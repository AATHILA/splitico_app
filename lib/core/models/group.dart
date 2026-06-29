class GroupModel {
  final String name;
  final String type; // e.g., 'Travel', 'Home'
  final List<Map<String, dynamic>> members;

  GroupModel({
    required this.name,
    required this.type,
    required this.members,
  });
}
