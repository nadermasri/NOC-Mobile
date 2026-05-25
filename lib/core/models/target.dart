import 'package:hive/hive.dart';

part 'target.g.dart';

@HiveType(typeId: 0)
class Target extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String host;

  @HiveField(3)
  String notes;

  @HiveField(4)
  List<String> tags;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime updatedAt;

  Target({
    required this.id,
    required this.name,
    required this.host,
    this.notes = '',
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Target copyWith({
    String? name,
    String? host,
    String? notes,
    List<String>? tags,
  }) {
    return Target(
      id: id,
      name: name ?? this.name,
      host: host ?? this.host,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'host': host,
        'notes': notes,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Target.fromJson(Map<String, dynamic> json) => Target(
        id: json['id'] as String,
        name: json['name'] as String,
        host: json['host'] as String,
        notes: json['notes'] as String? ?? '',
        tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
