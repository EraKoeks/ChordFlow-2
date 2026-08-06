import 'package:shared_preferences/shared_preferences.dart';

class PlayCountService {
  PlayCountService._();

  static const String _prefix =
      'song_play_count_';

  static Future<Map<String, int>>
  getPlayCounts() async {
    final preferences =
    await SharedPreferences.getInstance();

    final result = <String, int>{};

    for (final key in preferences.getKeys()) {
      if (!key.startsWith(_prefix)) {
        continue;
      }

      final songId =
      key.substring(_prefix.length);

      result[songId] =
          preferences.getInt(key) ?? 0;
    }

    return result;
  }

  static Future<void> increment(
      String songId,
      ) async {
    final preferences =
    await SharedPreferences.getInstance();

    final key = '$_prefix$songId';
    final current =
        preferences.getInt(key) ?? 0;

    await preferences.setInt(
      key,
      current + 1,
    );
  }

  static Future<void> reset(
      String songId,
      ) async {
    final preferences =
    await SharedPreferences.getInstance();

    await preferences.remove(
      '$_prefix$songId',
    );
  }
}
