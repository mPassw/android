class User {
  final String? id;
  final int? passwords;
  final String? email;
  final String? username;
  final bool verified;
  final bool admin;
  final String? createdAt;
  final String? updatedAt;

  User({
    this.id,
    this.passwords,
    this.email,
    this.username,
    this.verified = true,
    this.admin = false,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String?,
      passwords: json['passwords'] as int?,
      email: json['email'] as String?,
      username: json['username'] as String?,
      verified: json['verified'] as bool? ?? false,
      admin: json['admin'] as bool? ?? false,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  User copy({
    String? id,
    int? passwords,
    String? email,
    String? username,
    bool? verified,
    bool? admin,
    String? createdAt,
    String? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      passwords: passwords ?? this.passwords,
      email: email ?? this.email,
      username: username ?? this.username,
      verified: verified ?? this.verified,
      admin: admin ?? this.admin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
