
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'data_models.g.dart';

@HiveType(typeId: 0)
class PasswordEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String username;

  @HiveField(3)
  String encryptedPassword; // Encrypted string

  @HiveField(4)
  String? website;

  @HiveField(5)
  String? notes;

  @HiveField(6)
  String category;

  @HiveField(7)
  DateTime createdAt;

  @HiveField(8)
  DateTime updatedAt;

  PasswordEntry({
    String? id,
    required this.title,
    required this.username,
    required this.encryptedPassword,
    this.website,
    this.notes,
    this.category = 'General',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'username': username,
    'encryptedPassword': encryptedPassword,
    'website': website,
    'notes': notes,
    'category': category,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory PasswordEntry.fromJson(Map<String, dynamic> json) => PasswordEntry(
      id: json['id'],
      title: json['title'],
      username: json['username'],
      encryptedPassword: json['encryptedPassword'],
      website: json['website'],
      notes: json['notes'],
      category: json['category'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
  );
}

@HiveType(typeId: 1)
class SecureNote extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String encryptedContent;

  @HiveField(3)
  String category;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime updatedAt;

  SecureNote({
    String? id,
    required this.title,
    required this.encryptedContent,
    this.category = 'Personal',
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'encryptedContent': encryptedContent,
    'category': category,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory SecureNote.fromJson(Map<String, dynamic> json) => SecureNote(
    id: json['id'],
    title: json['title'],
    encryptedContent: json['encryptedContent'],
    category: json['category'],
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );
}
