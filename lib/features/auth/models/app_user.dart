class AppUser {
  final String uid;
  final String email;
  final String? displayName;

  const AppUser({
    required this.uid,
    required this.email,
    this.displayName,
  });

  String get resolvedDisplayName {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!.trim();
    }
    if (email.trim().isNotEmpty && email.contains('@')) {
      return email.split('@').first.trim();
    }
    return 'User';
  }
}
