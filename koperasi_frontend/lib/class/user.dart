class User {
  
  final int id;
  final String name;
  final String email;
  final String password;
  final String phoneNumber;
  final String dateOfBirth;
  final String gender;
  final String role;
  final int points;
  final int annualSpend;
  final String membershipLevel;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.phoneNumber,
    required this.dateOfBirth,
    required this.gender,
    required this.role,
    required this.points,
    required this.annualSpend,
    required this.membershipLevel,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      dateOfBirth: json['date_of_birth'] ?? '',
      gender: json['gender'] ?? '',
      role: json['role'] ?? '',
      points: int.tryParse(json['points'].toString()) ?? 0,
      annualSpend: int.tryParse(json['annual_spend'].toString()) ?? 0,
      membershipLevel: json['membership_level'] ?? 'Bronze',
    );
  }

}
