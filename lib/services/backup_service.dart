import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/setlist.dart';
import '../models/song.dart';
import 'storage_service.dart';

class BackupResult {
  const BackupResult({
    required this.success,
    required this.message,
    this.songCount = 0,
    this.setlistCount = 0,
  });

  final bool success;
  final String message;
  final int songCount;
  final int setlistCount;
}

class BackupService {
  static const int _backupVersion = 1;

  static Future<BackupResult> exportBackup() async {
    try {
      final songs = StorageService.getSongs();
      final setlists = StorageService.getSetlists();

      final backupData = <String, dynamic>{
        'app': 'ChordFlow',
        'version': _backupVersion,
        'createdAt': DateTime.now().toIso8601String(),
        'songs': songs.map((song) => song.toMap()).toList(),
        'setlists': setlists
            .map((setlist) => setlist.toMap())
            .toList(),
      };

      final formattedJson = const JsonEncoder.withIndent(
        '  ',
      ).convert(backupData);

      final temporaryDirectory =
      await getTemporaryDirectory();

      final now = DateTime.now();

      final fileName =
          'chordflow_backup_'
          '${now.year}-'
          '${_twoDigits(now.month)}-'
          '${_twoDigits(now.day)}_'
          '${_twoDigits(now.hour)}-'
          '${_twoDigits(now.minute)}.json';

      final backupFile = File(
        '${temporaryDirectory.path}${Platform.pathSeparator}$fileName',
      );

      await backupFile.writeAsString(
        formattedJson,
        flush: true,
      );

      final shareResult =
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              backupFile.path,
              mimeType: 'application/json',
            ),
          ],
          subject: 'ChordFlow back-up',
          text:
          'ChordFlow back-up met '
              '${songs.length} liedjes en '
              '${setlists.length} setlists.',
        ),
      );

      if (shareResult.status ==
          ShareResultStatus.dismissed) {
        return BackupResult(
          success: false,
          message: 'Het delen van de back-up is gesloten.',
          songCount: songs.length,
          setlistCount: setlists.length,
        );
      }

      return BackupResult(
        success: true,
        message: 'Back-up is aangemaakt.',
        songCount: songs.length,
        setlistCount: setlists.length,
      );
    } catch (error) {
      return BackupResult(
        success: false,
        message: 'Back-up maken is mislukt: $error',
      );
    }
  }

  static Future<BackupResult> importBackup() async {
    try {
      final pickedResult = await FilePicker.platform.pickFiles(
        dialogTitle: 'Kies een ChordFlow back-up',
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
        withData: true,
      );

      if (pickedResult == null ||
          pickedResult.files.isEmpty) {
        return const BackupResult(
          success: false,
          message: 'Geen back-up gekozen.',
        );
      }

      final pickedFile = pickedResult.files.single;

      String jsonText;

      if (pickedFile.bytes != null) {
        jsonText = utf8.decode(
          pickedFile.bytes!,
        );
      } else if (pickedFile.path != null) {
        jsonText = await File(
          pickedFile.path!,
        ).readAsString();
      } else {
        return const BackupResult(
          success: false,
          message:
          'Het gekozen bestand kon niet worden gelezen.',
        );
      }

      final decodedData = jsonDecode(jsonText);

      if (decodedData is! Map) {
        return const BackupResult(
          success: false,
          message:
          'Dit is geen geldige ChordFlow back-up.',
        );
      }

      final backupMap =
      Map<String, dynamic>.from(decodedData);

      if (backupMap['app'] != 'ChordFlow') {
        return const BackupResult(
          success: false,
          message:
          'Dit bestand is geen ChordFlow back-up.',
        );
      }

      final version = backupMap['version'];

      if (version is! int ||
          version > _backupVersion) {
        return const BackupResult(
          success: false,
          message:
          'Deze back-up is gemaakt met een nieuwere '
              'versie van ChordFlow.',
        );
      }

      final rawSongs = backupMap['songs'];
      final rawSetlists = backupMap['setlists'];

      if (rawSongs is! List ||
          rawSetlists is! List) {
        return const BackupResult(
          success: false,
          message:
          'De back-up bevat geen geldige gegevens.',
        );
      }

      final songs = rawSongs.map((item) {
        if (item is! Map) {
          throw const FormatException(
            'Ongeldig lied in back-up.',
          );
        }

        return Song.fromMap(
          Map<dynamic, dynamic>.from(item),
        );
      }).toList();

      final setlists = rawSetlists.map((item) {
        if (item is! Map) {
          throw const FormatException(
            'Ongeldige setlist in back-up.',
          );
        }

        return Setlist.fromMap(
          Map<dynamic, dynamic>.from(item),
        );
      }).toList();

      await StorageService.replaceAllData(
        songs: songs,
        setlists: setlists,
      );

      return BackupResult(
        success: true,
        message:
        '${songs.length} liedjes en '
            '${setlists.length} setlists zijn hersteld.',
        songCount: songs.length,
        setlistCount: setlists.length,
      );
    } on FormatException catch (error) {
      return BackupResult(
        success: false,
        message:
        'De back-up is beschadigd: ${error.message}',
      );
    } catch (error) {
      return BackupResult(
        success: false,
        message:
        'Back-up herstellen is mislukt: $error',
      );
    }
  }

  static String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }
}