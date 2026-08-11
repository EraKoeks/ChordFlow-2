import 'package:hive_flutter/hive_flutter.dart';

import '../models/ai_prompt.dart';

class AiPromptService {
  AiPromptService._();

  static const String _boxName = 'ai_prompts';

  static Box<Map>? _box;

  static Future<void> initialize() async {
    _box ??= await Hive.openBox<Map>(_boxName);
  }

  static List<AiPrompt> getAllPrompts() {
    final prompts = _box!.values
        .map((e) => AiPrompt.fromMap(e))
        .toList();

    prompts.sort(
          (a, b) => b.lastUsed.compareTo(a.lastUsed),
    );

    return prompts;
  }

  static Future<void> savePrompt(
      AiPrompt prompt,
      ) async {
    await _box!.put(
      prompt.id,
      prompt.toMap(),
    );
  }

  static Future<void> deletePrompt(
      String id,
      ) async {
    await _box!.delete(id);
  }

  static Future<void> updateLastUsed(
      AiPrompt prompt,
      ) async {
    final updated = prompt.copyWith(
      lastUsed: DateTime.now(),
    );

    await savePrompt(updated);
  }
}