import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/song.dart';
import '../utils/chordpro_parser.dart';

class SongPdfService {
  static Future<void> exportSong(Song song) async {
    final pdfBytes = await _buildSongPdf(song);

    final safeTitle = _safeFileName(song.title);

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: '$safeTitle.pdf',
    );
  }

  static Future<Uint8List> _buildSongPdf(
      Song song,
      ) async {
    final document = pw.Document();

    final parsedSong = ChordProParser.parse(
      song.content,
    );

    final title =
    parsedSong.title?.trim().isNotEmpty == true
        ? parsedSong.title!
        : song.title;

    final artist =
    parsedSong.artist?.trim().isNotEmpty == true
        ? parsedSong.artist!
        : song.artist;

    final keyName =
        parsedSong.key ?? song.originalKey;

    final songBody = parsedSong.body.trim().isNotEmpty
        ? parsedSong.body
        : song.content;

    final lines = songBody.split('\n');

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(
          42,
          42,
          42,
          50,
        ),
        header: (context) {
          if (context.pageNumber == 1) {
            return pw.SizedBox();
          }

          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(
              bottom: 12,
            ),
            child: pw.Text(
              title,
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey700,
              ),
            ),
          );
        },
        footer: (context) {
          return pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(
              top: 12,
            ),
            child: pw.Text(
              'ChordFlow • Pagina '
                  '${context.pageNumber} van '
                  '${context.pagesCount}',
              style: const pw.TextStyle(
                fontSize: 8,
                color: PdfColors.grey600,
              ),
            ),
          );
        },
        build: (context) {
          return [
            _buildHeader(
              title: title,
              artist: artist,
              subtitle: parsedSong.subtitle,
              keyName: keyName,
              capo: parsedSong.capo,
              tempo: parsedSong.tempo,
              timeSignature:
              parsedSong.timeSignature,
            ),
            pw.SizedBox(height: 26),
            ...lines.map(_buildSongLine),
          ];
        },
      ),
    );

    return document.save();
  }

  static pw.Widget _buildHeader({
    required String title,
    required String artist,
    required String? subtitle,
    required String? keyName,
    required int? capo,
    required int? tempo,
    required String? timeSignature,
  }) {
    final metadata = <String>[];

    if (keyName != null && keyName.isNotEmpty) {
      metadata.add('Key $keyName');
    }

    if (capo != null) {
      metadata.add('Capo $capo');
    }

    if (tempo != null) {
      metadata.add('$tempo BPM');
    }

    if (timeSignature != null &&
        timeSignature.trim().isNotEmpty) {
      metadata.add(timeSignature);
    }

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.indigo50,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(
          color: PdfColors.indigo200,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment:
        pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 26,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.indigo900,
            ),
          ),
          if (artist.trim().isNotEmpty) ...[
            pw.SizedBox(height: 5),
            pw.Text(
              artist,
              style: const pw.TextStyle(
                fontSize: 15,
                color: PdfColors.grey800,
              ),
            ),
          ],
          if (subtitle != null &&
              subtitle.trim().isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              subtitle,
              style: const pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey700,
              ),
            ),
          ],
          if (metadata.isNotEmpty) ...[
            pw.SizedBox(height: 14),
            pw.Wrap(
              spacing: 8,
              runSpacing: 8,
              children: metadata.map((value) {
                return pw.Container(
                  padding:
                  const pw.EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius:
                    pw.BorderRadius.circular(20),
                    border: pw.Border.all(
                      color: PdfColors.indigo200,
                    ),
                  ),
                  child: pw.Text(
                    value,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight:
                      pw.FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildSongLine(String line) {
    if (line.trim().isEmpty) {
      return pw.SizedBox(height: 14);
    }

    if (_isComment(line)) {
      final comment = line
          .replaceFirst('[Comment:', '')
          .replaceFirst(']', '')
          .trim();

      return pw.Container(
        width: double.infinity,
        margin: const pw.EdgeInsets.only(
          bottom: 12,
        ),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColors.amber50,
          borderRadius:
          pw.BorderRadius.circular(7),
          border: pw.Border.all(
            color: PdfColors.amber300,
          ),
        ),
        child: pw.Text(
          comment,
          style: pw.TextStyle(
            fontSize: 10,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      );
    }

    if (_isSection(line)) {
      final sectionTitle = line
          .replaceAll('[', '')
          .replaceAll(']', '')
          .toUpperCase();

      return pw.Container(
        margin: const pw.EdgeInsets.only(
          top: 14,
          bottom: 8,
        ),
        padding: const pw.EdgeInsets.only(
          left: 9,
        ),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            left: pw.BorderSide(
              color: PdfColors.indigo,
              width: 4,
            ),
          ),
        ),
        child: pw.Text(
          sectionTitle,
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.indigo,
            letterSpacing: 1,
          ),
        ),
      );
    }

    return _buildChordAndLyricLine(line);
  }

  static pw.Widget _buildChordAndLyricLine(
      String line,
      ) {
    final chordPattern =
    RegExp(r'\[([^\]]+)\]');

    final matches =
    chordPattern.allMatches(line).toList();

    if (matches.isEmpty) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(
          bottom: 7,
        ),
        child: pw.Text(
          line,
          style: const pw.TextStyle(
            fontSize: 12,
            lineSpacing: 3,
          ),
        ),
      );
    }

    final segments = <pw.Widget>[];
    var currentPosition = 0;

    for (var index = 0;
    index < matches.length;
    index++) {
      final match = matches[index];

      final textBeforeChord = line.substring(
        currentPosition,
        match.start,
      );

      if (textBeforeChord.isNotEmpty) {
        segments.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(
              top: 12,
            ),
            child: pw.Text(
              textBeforeChord,
              style: const pw.TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        );
      }

      final chord = match.group(1) ?? '';

      final lyricEnd =
      index + 1 < matches.length
          ? matches[index + 1].start
          : line.length;

      final lyric = line.substring(
        match.end,
        lyricEnd,
      );

      segments.add(
        pw.Column(
          crossAxisAlignment:
          pw.CrossAxisAlignment.start,
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Text(
              chord,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.indigo,
              ),
            ),
            pw.Text(
              lyric.isEmpty ? ' ' : lyric,
              style: const pw.TextStyle(
                fontSize: 12,
              ),
            ),
          ],
        ),
      );

      currentPosition = lyricEnd;
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.only(
        bottom: 10,
      ),
      child: pw.Wrap(
        spacing: 0,
        runSpacing: 5,
        crossAxisAlignment:
        pw.WrapCrossAlignment.end,
        children: segments,
      ),
    );
  }

  static bool _isComment(String line) {
    return line.startsWith('[Comment:') &&
        line.endsWith(']');
  }

  static bool _isSection(String line) {
    if (!line.startsWith('[') ||
        !line.endsWith(']')) {
      return false;
    }

    final content = line
        .replaceAll('[', '')
        .replaceAll(']', '');

    return !RegExp(
      r'^[A-G](#|b)?(m|maj|min|sus|dim|aug|add|[0-9])*(/[A-G](#|b)?)?$',
    ).hasMatch(content);
  }

  static String _safeFileName(String value) {
    final cleaned = value
        .trim()
        .replaceAll(
      RegExp(r'[<>:"/\\|?*]'),
      '',
    )
        .replaceAll(RegExp(r'\s+'), '_');

    if (cleaned.isEmpty) {
      return 'chordflow_song';
    }

    return cleaned;
  }
}