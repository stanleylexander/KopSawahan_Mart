class User {
  
  final int id;
  final String name;
  final String email;
  final String password;
  final String phoneNumber;
  final String dateOfBirth;
  final String gender;
  final String image;
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
    required this.image,
    required this.role,
    required this.points,
    required this.annualSpend,
    required this.membershipLevel,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    String parseString(dynamic value, {String fallback = ''}) {
      if (value == null) {
        return fallback;
      }

      final text = '$value';
      if (text == 'null' || text == 'undefined') {
        return fallback;
      }

      return text;
    }

    int parseInt(dynamic value) {
      if (value == null) {
        return 0;
      }

      if (value is int) {
        return value;
      }

      if (value is double) {
        return value.toInt();
      }

      return int.tryParse('$value') ?? 0;
    }

    return User(
      id: json['id'],
      name: parseString(json['name']),
      email: parseString(json['email']),
      password: parseString(json['password']),
      phoneNumber: parseString(json['phone_number']),
      dateOfBirth: parseString(json['date_of_birth']),
      gender: parseString(json['gender']),
      image: parseString(json['image']),
      role: parseString(json['role']),
      points: parseInt(json['points']),
      annualSpend: parseInt(json['annual_spend']),
      membershipLevel: parseString(json['membership_level'], fallback: 'Bronze'),
    );
  }

}
