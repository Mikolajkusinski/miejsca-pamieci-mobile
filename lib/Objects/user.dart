class User {
  final int id;
  final String username;
  final String email;
  final String? token;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user_id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      token: json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': id,
      'username': username,
      'email': email,
      'token': token,
    };
  }

  User copyWith({required String jwtToken}) {
    return User(
      id: id,
      username: username,
      email: email,
      token: jwtToken,
    );
  }
}
