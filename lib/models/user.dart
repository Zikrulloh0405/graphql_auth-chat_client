// dart
class User {
  final String userID;
  final String email;
  final String password;

  User({required this.userID, required this.email, required this.password});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userID: json['userID'],
      email: json['email'],
      password: json['token'],
    );
  }
}