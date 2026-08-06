import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/song.dart';

class ChordProExportService {
  static Future<void> exportSong(
      Song song,
      ) async {
    final temporaryDirectory =
    await getTemporaryDirectory();

    final fileName =
        '${_safeFileName(song.title)}.cho';

    final file = File(
      '${temporaryDirectory.path}'
          '${Platform.pathSeparator}'
          '$fileName',
    );

    await file.writeAsString(
      song.content,
      flush: true,
    );

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            file.path,
            mimeType: 'text/plain',
          ),
        ],
        subject: 'ChordPro-export',
        text: 'ChordPro-bestand van ${song.title}',
      ),
    );
  }

  static String _safeFileName(
      String value,
      ) {
    final cleaned = value
        .trim()
        .replaceAll(
      RegExp(r'[<>:"/\\|?*]'),
      '',
    )
        .replaceAll(
      RegExp(r'\s+'),
      '_',
    );

    return cleaned.isEmpty
        ? 'chordflow_song'
        : cleaned;
  }
}
