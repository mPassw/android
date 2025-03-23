import 'package:hive_ce/hive.dart';

class Password extends HiveObject {
  String? id;
  String? title;
  String? username;
  String? password;
  String? note;
  List<String> tags;
  List<String> websites;
  String? createdAt;
  String? updatedAt;
  bool inTrash;
  bool decrypted;

  Password({
    this.id,
    this.title,
    this.username,
    this.password,
    this.note,
    List<String>? tags,
    List<String>? websites,
    this.createdAt,
    this.updatedAt,
    this.inTrash = false,
    this.decrypted = false,
  })  : tags = tags ?? [],
        websites = websites ?? [];

  factory Password.fromJson(Map<String, dynamic> json) {
    return Password(
        id: json['id'] as String,
        title: json['title'] as String,
        username: json['username'] as String?,
        password: json['password'] as String?,
        note: json['note'] as String?,
        tags: (json['tags'] as List<dynamic>).cast<String>(),
        websites: (json['websites'] as List<dynamic>).cast<String>(),
        createdAt: json['createdAt'] as String?,
        updatedAt: json['updatedAt'] as String?,
        inTrash: json['inTrash'] as bool,
        decrypted: false);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'username': username,
      'password': password,
      'note': note,
      'tags': tags,
      'websites': websites,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'inTrash': inTrash,
    };
  }

  Password copy({
    String? id,
    String? title,
    String? username,
    String? password,
    String? note,
    List<String>? tags,
    List<String>? websites,
    String? createdAt,
    String? updatedAt,
    bool? inTrash,
    bool? decrypted,
  }) {
    return Password(
      id: id ?? this.id,
      title: title ?? this.title,
      username: username ?? this.username,
      password: password ?? this.password,
      note: note ?? this.note,
      tags: tags?.toList() ?? this.tags.toList(),
      websites: websites?.toList() ?? this.websites.toList(),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      inTrash: inTrash ?? this.inTrash,
      decrypted: decrypted ?? this.decrypted,
    );
  }
}
