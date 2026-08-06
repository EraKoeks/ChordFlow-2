class Song {
  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.originalKey,
    this.favorite = false,
    this.genre = '',
    this.tags = const [],
  });

  final String id;
  final String title;
  final String artist;
  final String content;
  final String? originalKey;
  final bool favorite;
  final String genre;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? content,
    String? originalKey,
    bool? favorite,
    String? genre,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      content: content ?? this.content,
      originalKey: originalKey ?? this.originalKey,
      favorite: favorite ?? this.favorite,
      genre: genre ?? this.genre,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'content': content,
      'originalKey': originalKey,
      'favorite': favorite,
      'genre': genre,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Song.fromMap(Map<dynamic, dynamic> map) {
    return Song(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      artist: map['artist'] as String? ?? '',
      content: map['content'] as String? ?? '',
      originalKey: map['originalKey'] as String?,
      favorite: map['favorite'] as bool? ?? false,
      genre: map['genre'] as String? ?? '',
      tags: (map['tags'] as List?)
          ?.map((e) => e.toString())
          .toList() ??
          [],
      createdAt: DateTime.parse(
        map['createdAt'] as String,
      ),
      updatedAt: DateTime.parse(
        map['updatedAt'] as String,
      ),
    );
  }
}