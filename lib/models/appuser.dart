class AppUser {
  AppUser({required this.email, required this.role});

  final String email;
  final String role; // 'admin' or 'employee'

  Map<String, dynamic> toMap() => {
    'email': email,
    'role': role,
  };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
    email: map['email'] as String,
    role: map['role'] as String,
  );
}