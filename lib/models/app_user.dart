class AppUser {
  final String username;
  final String password;
  final String role;

  const AppUser({
    required this.username,
    required this.password,
    this.role = '',
  });

  bool matches(String enteredUsername, String enteredPassword) =>
      username.trim().toUpperCase() == enteredUsername.trim().toUpperCase() &&
      password.trim() == enteredPassword.trim();

  bool get isMechanic {
    final identity = '$username $role'.toUpperCase();
    return identity.contains('MEC') || identity.contains('MECHANIC');
  }
}
