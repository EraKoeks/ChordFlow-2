class AiPrompt {
  const AiPrompt({
    required this.id,
    required this.name,
    required this.prompt,
    required this.createdAt,
    required this.lastUsed,
  });

  final String id;
  final String name;
  final String prompt;
  final DateTime createdAt;
  final DateTime lastUsed;

  AiPrompt copyWith({
    String? id,
    String? name,
    String? prompt,
    DateTime? createdAt,
    DateTime? lastUsed,
  }) {
    return AiPrompt(
      id: id ?? this.id,
      name: name ?? this.name,
      prompt: prompt ?? this.prompt,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'prompt': prompt,
      'createdAt': createdAt.toIso8601String(),
      'lastUsed': lastUsed.toIso8601String(),
    };
  }

  factory AiPrompt.fromMap(Map<dynamic, dynamic> map) {
    return AiPrompt(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      prompt: map['prompt'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
      lastUsed: DateTime.parse(map['lastUsed'] as String),
    );
  }
}