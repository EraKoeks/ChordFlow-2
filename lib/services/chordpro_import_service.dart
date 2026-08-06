import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

import '../models/song.dart';
import '../utils/chordpro_parser.dart';

class ChordProImportResult {
  const ChordProImportResult({
    required this.success,
    required this.message,
    this.song,
  });

  final bool success;
  final String message;
  final Song? song;
}

class ChordProImportService {
  static Future<ChordProImportResult>
  pickAndImportSong() async {
    try {
      final result =
      await FilePicker.platform.pickFiles(
        dialogTitle: 'Kies een ChordPro-bestand',
        type: FileType.custom,
        allowedExtensions: [
          'cho',
          'chordpro',
          'pro',
          'crd',
          'txt',
        ],
        allowMultiple: false,
        withData: true,
      );

      if (result == null ||
          result.files.isEmpty) {
        return const ChordProImportResult(
          success: false,
          message: 'Geen bestand gekozen.',
        );
      }

      final pickedFile = result.files.single;

      final content =
      await _readPickedFile(pickedFile);

      if (content.trim().isEmpty) {
        return const ChordProImportResult(
          success: false,
          message: 'Het gekozen bestand is leeg.',
        );
      }

      final parsedSong =
      ChordProParser.parse(content);

      final fileNameTitle =
      _titleFromFileName(pickedFile.name);

      final title =
      parsedSong.title?.trim().isNotEmpty ==
          true
          ? parsedSong.title!.trim()
          : fileNameTitle;

      final artist =
          parsedSong.artist?.trim() ?? '';

      final now = DateTime.now();

      final song = Song(
        id: now.microsecondsSinceEpoch.toString(),
        title: title.isEmpty
            ? 'Geïmporteerd lied'
            : title,
        artist: artist,
        content: content.trim(),
        originalKey: parsedSong.key,
        favorite: false,
        createdAt: now,
        updatedAt: now,
      );

      return ChordProImportResult(
        success: true,
        message:
        '"${song.title}" is klaar om te importeren.',
        song: song,
      );
    } on FormatException catch (error) {
      return ChordProImportResult(
        success: false,
        message:
        'Het bestand bevat ongeldige tekst: '
            '${error.message}',
      );
    } catch (error) {
      return ChordProImportResult(
        success: false,
        message:
        'Importeren is niet gelukt: $error',
      );
    }
  }

  static Future<String> _readPickedFile(
      PlatformFile pickedFile,
      ) async {
    if (pickedFile.bytes != null) {
      return utf8.decode(
        pickedFile.bytes!,
        allowMalformed: true,
      );
    }

    final path = pickedFile.path;

    if (path == null || path.isEmpty) {
      throw const FormatException(
        'Het bestand kon niet worden geopend.',
      );
    }

    return File(path).readAsString();
  }

  static String _titleFromFileName(
      String fileName,
      ) {
    final withoutExtension =
    fileName.replaceFirst(
      RegExp(
        r'\.(cho|chordpro|pro|crd|txt)$',
        caseSensitive: false,
      ),
      '',
    );

    return withoutExtension
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(
      RegExp(r'\s+'),
      ' ',
    )
        .trim();
  }
}