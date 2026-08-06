class Setlist {
  const Setlist({
    required this.id,
    required this.name,
    required this.songIds,
    required this.createdAt,
    required this.updatedAt,
    this.description = '',
  });

  final String id;
  final String name;
  final String description;
  final List<String> songIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  Setlist copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? songIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Setlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      songIds: songIds ?? this.songIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'songIds': songIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Setlist.fromMap(Map<dynamic, dynamic> map) {
    return Setlist(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      songIds: List<String>.from(
        map['songIds'] as List? ?? [],
      ),
      createdAt: DateTime.parse(
        map['createdAt'] as String,
      ),
      updatedAt: DateTime.parse(
        map['updatedAt'] as String,
      ),
    );
  }
}