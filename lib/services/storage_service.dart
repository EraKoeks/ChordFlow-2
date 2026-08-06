import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/setlist.dart';
import '../models/song.dart';

class StorageService {
  static const String songsBoxName = 'songs';
  static const String setlistsBoxName = 'setlists';

  static FirebaseFirestore get _firestore {
    return FirebaseFirestore.instance;
  }

  static User? get _currentUser {
    return FirebaseAuth.instance.currentUser;
  }

  static CollectionReference<Map<String, dynamic>>?
  get _cloudSongs {
    final user = _currentUser;

    if (user == null) {
      return null;
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('songs');
  }

  static CollectionReference<Map<String, dynamic>>?
  get _cloudSetlists {
    final user = _currentUser;

    if (user == null) {
      return null;
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('setlists');
  }

  static Future<void> initialize() async {
    if (!Hive.isBoxOpen(songsBoxName)) {
      await Hive.openBox<Map>(songsBoxName);
    }

    if (!Hive.isBoxOpen(setlistsBoxName)) {
      await Hive.openBox<Map>(setlistsBoxName);
    }

    debugPrint(
      'Hive gestart. Liedjes: ${_songsBox.length}, '
          'setlists: ${_setlistsBox.length}',
    );
  }

  static Box<Map> get _songsBox {
    return Hive.box<Map>(songsBoxName);
  }

  static Box<Map> get _setlistsBox {
    return Hive.box<Map>(setlistsBoxName);
  }

  static List<Song> getSongs() {
    try {
      final songs = _songsBox.values
          .map((data) => Song.fromMap(data))
          .toList();

      songs.sort(
            (a, b) => b.updatedAt.compareTo(a.updatedAt),
      );

      return songs;
    } catch (error, stackTrace) {
      debugPrint(
        'Fout tijdens laden van liedjes: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      return [];
    }
  }

  static Future<void> saveSong(
      Song song,
      ) async {
    try {
      await _songsBox.put(
        song.id,
        song.toMap(),
      );
      await _songsBox.flush();

      await _saveSongToCloud(song);

      debugPrint(
        'Lied lokaal en online opgeslagen: '
            '${song.title}',
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Fout tijdens opslaan van lied: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  static Future<void> _saveSongToCloud(
      Song song,
      ) async {
    final cloudSongs = _cloudSongs;

    if (cloudSongs == null) {
      return;
    }

    final data = Map<String, dynamic>.from(
      song.toMap(),
    );

    data['ownerId'] = _currentUser!.uid;
    data['syncedAt'] =
        FieldValue.serverTimestamp();

    try {
      await cloudSongs.doc(song.id).set(
        data,
        SetOptions(merge: true),
      );
    } on FirebaseException catch (error) {
      debugPrint(
        'Cloud-opslag overgeslagen: ${error.code}',
      );
    }
  }

  static Future<void> deleteSong(
      String songId,
      ) async {
    try {
      await _songsBox.delete(songId);
      await _songsBox.flush();

      final cloudSongs = _cloudSongs;

      if (cloudSongs != null) {
        try {
          await cloudSongs.doc(songId).delete();
        } on FirebaseException catch (error) {
          debugPrint(
            'Cloud-verwijdering overgeslagen: ${error.code}',
          );
        }
      }

      final setlists = getSetlists();

      for (final setlist in setlists) {
        if (!setlist.songIds.contains(songId)) {
          continue;
        }

        final updatedSetlist = setlist.copyWith(
          songIds: setlist.songIds
              .where((id) => id != songId)
              .toList(),
          updatedAt: DateTime.now(),
        );

        await saveSetlist(updatedSetlist);
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Fout tijdens verwijderen van lied: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  static List<Setlist> getSetlists() {
    try {
      final setlists = _setlistsBox.values
          .map((data) => Setlist.fromMap(data))
          .toList();

      setlists.sort(
            (a, b) => b.updatedAt.compareTo(a.updatedAt),
      );

      return setlists;
    } catch (error, stackTrace) {
      debugPrint(
        'Fout tijdens laden van setlists: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      return [];
    }
  }

  static Future<void> saveSetlist(
      Setlist setlist,
      ) async {
    try {
      await _setlistsBox.put(
        setlist.id,
        setlist.toMap(),
      );
      await _setlistsBox.flush();

      await _saveSetlistToCloud(setlist);

      debugPrint(
        'Setlist lokaal en online opgeslagen: '
            '${setlist.name}',
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Fout tijdens opslaan van setlist: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  static Future<void> _saveSetlistToCloud(
      Setlist setlist,
      ) async {
    final cloudSetlists = _cloudSetlists;

    if (cloudSetlists == null) {
      return;
    }

    final data = Map<String, dynamic>.from(
      setlist.toMap(),
    );

    data['ownerId'] = _currentUser!.uid;
    data['syncedAt'] =
        FieldValue.serverTimestamp();

    try {
      await cloudSetlists.doc(setlist.id).set(
        data,
        SetOptions(merge: true),
      );
    } on FirebaseException catch (error) {
      debugPrint(
        'Cloud-opslag overgeslagen: ${error.code}',
      );
    }
  }

  static Future<void> deleteSetlist(
      String setlistId,
      ) async {
    try {
      await _setlistsBox.delete(setlistId);
      await _setlistsBox.flush();

      final cloudSetlists = _cloudSetlists;

      if (cloudSetlists != null) {
        try {
          await cloudSetlists
              .doc(setlistId)
              .delete();
        } on FirebaseException catch (error) {
          debugPrint(
            'Cloud-verwijdering overgeslagen: ${error.code}',
          );
        }
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Fout tijdens verwijderen van setlist: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  static Future<void> syncWithCloud() async {
    final cloudSongs = _cloudSongs;
    final cloudSetlists = _cloudSetlists;

    if (cloudSongs == null ||
        cloudSetlists == null) {
      return;
    }

    try {
      final songSnapshot =
      await cloudSongs.get();
      final setlistSnapshot =
      await cloudSetlists.get();

      final mergedSongs = <String, Song>{
        for (final song in getSongs())
          song.id: song,
      };

      for (final document
      in songSnapshot.docs) {
        final cloudSong = Song.fromMap(
          document.data(),
        );

        final localSong =
        mergedSongs[cloudSong.id];

        if (localSong == null ||
            cloudSong.updatedAt.isAfter(
              localSong.updatedAt,
            )) {
          mergedSongs[cloudSong.id] =
              cloudSong;
        }
      }

      final mergedSetlists =
      <String, Setlist>{
        for (final setlist in getSetlists())
          setlist.id: setlist,
      };

      for (final document
      in setlistSnapshot.docs) {
        final cloudSetlist =
        Setlist.fromMap(
          document.data(),
        );

        final localSetlist =
        mergedSetlists[cloudSetlist.id];

        if (localSetlist == null ||
            cloudSetlist.updatedAt.isAfter(
              localSetlist.updatedAt,
            )) {
          mergedSetlists[
          cloudSetlist.id] = cloudSetlist;
        }
      }

      await _replaceLocalData(
        songs: mergedSongs.values.toList(),
        setlists:
        mergedSetlists.values.toList(),
      );

      for (final song
      in mergedSongs.values) {
        await _saveSongToCloud(song);
      }

      for (final setlist
      in mergedSetlists.values) {
        await _saveSetlistToCloud(setlist);
      }

      debugPrint(
        'Cloud-sync voltooid: '
            '${mergedSongs.length} liedjes en '
            '${mergedSetlists.length} setlists.',
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Cloud-sync mislukt: $error',
      );
      debugPrintStack(
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  static Future<void> replaceAllData({
    required List<Song> songs,
    required List<Setlist> setlists,
  }) async {
    try {
      await _replaceLocalData(
        songs: songs,
        setlists: setlists,
      );

      await _replaceCloudData(
        songs: songs,
        setlists: setlists,
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Fout tijdens herstellen van back-up: '
            '$error',
      );
      debugPrintStack(
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  static Future<void> _replaceLocalData({
    required List<Song> songs,
    required List<Setlist> setlists,
  }) async {
    await _songsBox.clear();
    await _setlistsBox.clear();

    final songData =
    <dynamic, Map<dynamic, dynamic>>{
      for (final song in songs)
        song.id: Map<dynamic, dynamic>.from(
          song.toMap(),
        ),
    };

    final setlistData =
    <dynamic, Map<dynamic, dynamic>>{
      for (final setlist in setlists)
        setlist.id:
        Map<dynamic, dynamic>.from(
          setlist.toMap(),
        ),
    };

    if (songData.isNotEmpty) {
      await _songsBox.putAll(songData);
    }

    if (setlistData.isNotEmpty) {
      await _setlistsBox.putAll(setlistData);
    }

    await _songsBox.flush();
    await _setlistsBox.flush();
  }

  static Future<void> _replaceCloudData({
    required List<Song> songs,
    required List<Setlist> setlists,
  }) async {
    final cloudSongs = _cloudSongs;
    final cloudSetlists = _cloudSetlists;

    if (cloudSongs == null ||
        cloudSetlists == null) {
      return;
    }

    await _deleteCollection(cloudSongs);
    await _deleteCollection(cloudSetlists);

    for (final song in songs) {
      await _saveSongToCloud(song);
    }

    for (final setlist in setlists) {
      await _saveSetlistToCloud(setlist);
    }
  }

  static Future<void> _deleteCollection(
      CollectionReference<Map<String, dynamic>>
      collection,
      ) async {
    const batchSize = 400;

    while (true) {
      final snapshot =
      await collection.limit(batchSize).get();

      if (snapshot.docs.isEmpty) {
        break;
      }

      final batch = _firestore.batch();

      for (final document in snapshot.docs) {
        batch.delete(document.reference);
      }

      await batch.commit();
    }
  }

  static Future<void> clearLocalData() async {
    await _songsBox.clear();
    await _setlistsBox.clear();

    await _songsBox.flush();
    await _setlistsBox.flush();
  }
}
