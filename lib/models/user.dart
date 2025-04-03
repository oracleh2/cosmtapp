class User {
  final int id;
  final String name;
  final String email;
  final String? avatar;
  final String? skinType;
  final List<String>? skinConcerns;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.skinType,
    this.skinConcerns,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(List<dynamic>? data) {
      if (data == null) return [];
      return data.map((item) => item.toString()).toList();
    }

    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      avatar: json['avatar'],
      skinType: json['skin_type'],
      skinConcerns: json['skin_concerns'] != null
          ? parseStringList(json['skin_concerns'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'skin_type': skinType,
      'skin_concerns': skinConcerns,
      'created_at': createdAt.toIso8601String(),
    };
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? avatar,
    String? skinType,
    List<String>? skinConcerns,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      skinType: skinType ?? this.skinType,
      skinConcerns: skinConcerns ?? this.skinConcerns,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}