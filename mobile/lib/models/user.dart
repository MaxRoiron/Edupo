class User {
  final int id;
  final String username;
  final String email;
  final String role;
  final String createdAt;
  final int? age;
  final String? gender;
  final String? profession;
  final String? phoneNumber;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.createdAt,
    this.age,
    this.gender,
    this.profession,
    this.phoneNumber,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      role: json['role'] ?? 'user',
      createdAt: json['created_at'] ?? '',
      age: json['age'],
      gender: json['gender'],
      profession: json['profession'],
      phoneNumber: json['phone_number'],
    );
  }
}
