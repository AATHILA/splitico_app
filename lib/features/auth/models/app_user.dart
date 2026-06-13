class AppUser {
  final String uid;
  final String email;
  final String? displayName;

  const AppUser({
    required this.uid,
    required this.email,
    this.displayName,
  });
}
