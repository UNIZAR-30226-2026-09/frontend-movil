class UserModel {
  final String username;
  final String email;

  UserModel({
    required this.username,
    required this.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      username: json['username'] as String,
      email: json['email'] as String,
    );
  }
}