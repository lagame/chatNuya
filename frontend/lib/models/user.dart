class User {
  final int id;
  final String username;
  final String email;
  final String? birthDate;
  final String? gender;
  final String? avatarUrl;
  final String? language;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.birthDate,
    this.gender,
    this.avatarUrl,
    this.language,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      birthDate: json['birthDate'] as String?,
      gender: json['gender'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      language: json['language'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'birthDate': birthDate,
      'gender': gender,
      'avatarUrl': avatarUrl,
      'language': language,
    };
  }

  User copyWith({
    int? id,
    String? username,
    String? email,
    String? birthDate,
    String? gender,
    String? avatarUrl,
    String? language,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      language: language ?? this.language,
    );
  }
}
