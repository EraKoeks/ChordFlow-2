import 'package:shared_preferences/shared_preferences.dart';

class RecentService {
  RecentService._();

  static const String _key =
      'recent_song_ids';

  static const int _maximumItems = 20;

  static Future<List<String>>
  getRecentSongIds() async {
    final preferences =
    await SharedPreferences.getInstance();

    return preferences.getStringList(_key) ??
        <String>[];
  }

  static Future<void> addRecentSong(
      String songId,
      ) async {
    final preferences =
    await SharedPreferences.getInstance();

    final recentIds =
        preferences.getStringList(_key) ??
            <String>[];

    recentIds.remove(songId);
    recentIds.insert(0, songId);

    if (recentIds.length > _maximumItems) {
      recentIds.removeRange(
        _maximumItems,
        recentIds.length,
      );
    }

    await preferences.setStringList(
      _key,
      recentIds,
    );
  }

  static Future<void> clear() async {
    final preferences =
    await SharedPreferences.getInstance();

    await preferences.remove(_key);
  }
}
