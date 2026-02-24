
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

  @HiveField(9)
  bool isStealth;

  PasswordEntry({
    String? id,
    required this.title,
    required this.username,
    required this.encryptedPassword,
    this.website,
    this.notes,
    this.category = 'General',
    this.isStealth = false,
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
    'isStealth': isStealth,
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
      isStealth: json['isStealth'] ?? false,
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

  @HiveField(6)
  bool isStealth;

  SecureNote({
    String? id,
    required this.title,
    required this.encryptedContent,
    this.category = 'Personal',
    this.isStealth = false,
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
    'isStealth': isStealth,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory SecureNote.fromJson(Map<String, dynamic> json) => SecureNote(
    id: json['id'],
    title: json['title'],
    encryptedContent: json['encryptedContent'],
    category: json['category'],
    isStealth: json['isStealth'] ?? false,
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );
}

@HiveType(typeId: 2)
class SecureMedia extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String fileName; // The random UUID name on disk

  @HiveField(3)
  String mediaType; // 'image', 'video', 'audio'

  @HiveField(4)
  bool isStealth;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  String? thumbnailPath; // For video/images if needed

  SecureMedia({
    String? id,
    required this.title,
    required this.fileName,
    required this.mediaType,
    this.isStealth = false,
    DateTime? createdAt,
    this.thumbnailPath,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'fileName': fileName,
    'mediaType': mediaType,
    'isStealth': isStealth,
    'createdAt': createdAt.toIso8601String(),
    'thumbnailPath': thumbnailPath,
  };

  factory SecureMedia.fromJson(Map<String, dynamic> json) => SecureMedia(
    id: json['id'],
    title: json['title'],
    fileName: json['fileName'],
    mediaType: json['mediaType'],
    isStealth: json['isStealth'] ?? false,
    createdAt: DateTime.parse(json['createdAt']),
    thumbnailPath: json['thumbnailPath'],
  );
}
