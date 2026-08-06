import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/setlist.dart';
import '../models/song.dart';
import '../utils/chordpro_parser.dart';

class SetlistPdfService {
  static Future<void> exportSetlist({
    required Setlist setlist,
    required List<Song> songs,
  }) async {
    final bytes = await _buildPdf(
      setlist: setlist,
      songs: songs,
    );

    await Printing.sharePdf(
      bytes: bytes,
      filename: '${_safeFileName(setlist.name)}.pdf',
    );
  }

  static Future<Uint8List> _buildPdf({
    required Setlist setlist,
    required List<Song> songs,
  }) async {
    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(
          40,
          40,
          40,
          50,
        ),
        footer: (context) {
          return pw.Container(
            alignment: pw.Alignment.center,
            margin: const pw.EdgeInsets.only(top: 12),
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
          final widgets = <pw.Widget>[
            _buildSetlistHeader(
              setlist: setlist,
              songCount: songs.length,
            ),
            pw.SizedBox(height: 24),
            _buildOverview(songs),
            pw.SizedBox(height: 30),
          ];

          for (var index = 0; index < songs.length; index++) {
            widgets.add(
              _buildSongSection(
                song: songs[index],
                index: index,
                total: songs.length,
              ),
            );

            if (index < songs.length - 1) {
              widgets.add(
                pw.SizedBox(height: 26),
              );
            }
          }

          return widgets;
        },
      ),
    );

    return document.save();
  }

  static pw.Widget _buildSetlistHeader({
    required Setlist setlist,
    required int songCount,
  }) {
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
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            setlist.name,
            style: pw.TextStyle(
              fontSize: 26,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.indigo900,
            ),
          ),
          if (setlist.description.trim().isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              setlist.description,
              style: const pw.TextStyle(
                fontSize: 13,
                color: PdfColors.grey800,
              ),
            ),
          ],
          pw.SizedBox(height: 14),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(20),
              border: pw.Border.all(
                color: PdfColors.indigo200,
              ),
            ),
            child: pw.Text(
              songCount == 1
                  ? '1 lied'
                  : '$songCount liedjes',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildOverview(
      List<Song> songs,
      ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Volgorde',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        ...songs.asMap().entries.map((entry) {
          final index = entry.key;
          final song = entry.value;

          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 6),
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            decoration: pw.BoxDecoration(
              color: index.isEven
                  ? PdfColors.grey100
                  : PdfColors.white,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(
              children: [
                pw.SizedBox(
                  width: 28,
                  child: pw.Text(
                    '${index + 1}.',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    song.title,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                if (song.artist.trim().isNotEmpty)
                  pw.Text(
                    song.artist,
                    style: const pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey700,
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  static pw.Widget _buildSongSection({
    required Song song,
    required int index,
    required int total,
  }) {
    final parsed = ChordProParser.parse(
      song.content,
    );

    final title =
    parsed.title?.trim().isNotEmpty == true
        ? parsed.title!
        : song.title;

    final artist =
    parsed.artist?.trim().isNotEmpty == true
        ? parsed.artist!
        : song.artist;

    final keyName =
        parsed.key ?? song.originalKey;

    final body = parsed.body.trim().isNotEmpty
        ? parsed.body
        : song.content;

    final metadata = <String>[];

    if (keyName != null &&
        keyName.trim().isNotEmpty) {
      metadata.add('Key $keyName');
    }

    if (parsed.capo != null) {
      metadata.add('Capo ${parsed.capo}');
    }

    if (parsed.tempo != null) {
      metadata.add('${parsed.tempo} BPM');
    }

    if (parsed.timeSignature != null &&
        parsed.timeSignature!.trim().isNotEmpty) {
      metadata.add(parsed.timeSignature!);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(10),
            border: pw.Border.all(
              color: PdfColors.grey300,
            ),
          ),
          child: pw.Column(
            crossAxisAlignment:
            pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Lied ${index + 1} van $total',
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo900,
                ),
              ),
              if (artist.trim().isNotEmpty) ...[
                pw.SizedBox(height: 3),
                pw.Text(
                  artist,
                  style: const pw.TextStyle(
                    fontSize: 11,
                    color: PdfColors.grey800,
                  ),
                ),
              ],
              if (metadata.isNotEmpty) ...[
                pw.SizedBox(height: 10),
                pw.Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: metadata.map((value) {
                    return pw.Container(
                      padding:
                      const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius:
                        pw.BorderRadius.circular(20),
                        border: pw.Border.all(
                          color: PdfColors.grey300,
                        ),
                      ),
                      child: pw.Text(
                        value,
                        style: const pw.TextStyle(
                          fontSize: 9,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        pw.SizedBox(height: 16),
        ...body.split('\n').map(_buildSongLine),
      ],
    );
  }

  static pw.Widget _buildSongLine(String line) {
    if (line.trim().isEmpty) {
      return pw.SizedBox(height: 12);
    }

    if (_isComment(line)) {
      final comment = line
          .replaceFirst('[Comment:', '')
          .replaceFirst(']', '')
          .trim();

      return pw.Container(
        width: double.infinity,
        margin: const pw.EdgeInsets.only(
          bottom: 10,
        ),
        padding: const pw.EdgeInsets.all(9),
        decoration: pw.BoxDecoration(
          color: PdfColors.amber50,
          borderRadius:
          pw.BorderRadius.circular(6),
          border: pw.Border.all(
            color: PdfColors.amber300,
          ),
        ),
        child: pw.Text(
          comment,
          style: pw.TextStyle(
            fontSize: 9,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      );
    }

    if (_isSection(line)) {
      return pw.Container(
        margin: const pw.EdgeInsets.only(
          top: 12,
          bottom: 7,
        ),
        padding: const pw.EdgeInsets.only(left: 8),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
            left: pw.BorderSide(
              color: PdfColors.indigo,
              width: 4,
            ),
          ),
        ),
        child: pw.Text(
          line
              .replaceAll('[', '')
              .replaceAll(']', '')
              .toUpperCase(),
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.indigo,
          ),
        ),
      );
    }

    return _buildChordLine(line);
  }

  static pw.Widget _buildChordLine(String line) {
    final chordPattern =
    RegExp(r'\[([^\]]+)\]');

    final matches =
    chordPattern.allMatches(line).toList();

    if (matches.isEmpty) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(
          bottom: 6,
        ),
        child: pw.Text(
          line,
          style: const pw.TextStyle(
            fontSize: 11,
            lineSpacing: 2,
          ),
        ),
      );
    }

    final parts = <pw.Widget>[];
    var currentPosition = 0;

    for (var index = 0;
    index < matches.length;
    index++) {
      final match = matches[index];

      final textBefore = line.substring(
        currentPosition,
        match.start,
      );

      if (textBefore.isNotEmpty) {
        parts.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(
              top: 11,
            ),
            child: pw.Text(
              textBefore,
              style: const pw.TextStyle(
                fontSize: 11,
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

      parts.add(
        pw.Column(
          crossAxisAlignment:
          pw.CrossAxisAlignment.start,
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Text(
              chord,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.indigo,
              ),
            ),
            pw.Text(
              lyric.isEmpty ? ' ' : lyric,
              style: const pw.TextStyle(
                fontSize: 11,
              ),
            ),
          ],
        ),
      );

      currentPosition = lyricEnd;
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.only(
        bottom: 9,
      ),
      child: pw.Wrap(
        spacing: 0,
        runSpacing: 4,
        crossAxisAlignment:
        pw.WrapCrossAlignment.end,
        children: parts,
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
        .replaceAll(
      RegExp(r'\s+'),
      '_',
    );

    return cleaned.isEmpty
        ? 'chordflow_setlist'
        : cleaned;
  }
}
