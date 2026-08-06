import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/chordpro_parser.dart';

class LiveSongPreview extends StatelessWidget {
  const LiveSongPreview({
    super.key,
    required this.content,
    this.title,
    this.artist,
    this.keyName,
    this.capo,
    this.bpm,
    this.timeSignature,
    this.fontSize = 18,
  });

  final String content;
  final String? title;
  final String? artist;
  final String? keyName;
  final String? capo;
  final String? bpm;
  final String? timeSignature;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final parsedSong = ChordProParser.parse(content);

    final displayTitle =
    parsedSong.title?.trim().isNotEmpty == true
        ? parsedSong.title!
        : title?.trim() ?? '';

    final displayArtist =
    parsedSong.artist?.trim().isNotEmpty == true
        ? parsedSong.artist!
        : artist?.trim() ?? '';

    final displayKey =
    parsedSong.key?.trim().isNotEmpty == true
        ? parsedSong.key
        : keyName;

    final displayCapo =
        parsedSong.capo?.toString() ?? capo;

    final displayBpm =
        parsedSong.tempo?.toString() ?? bpm;

    final displayTimeSignature =
    parsedSong.timeSignature?.trim().isNotEmpty == true
        ? parsedSong.timeSignature
        : timeSignature;

    final body = parsedSong.body.trim().isNotEmpty
        ? parsedSong.body
        : content;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.visibility_outlined,
                color: Theme.of(context)
                    .colorScheme
                    .primary,
              ),
              const SizedBox(width: 10),
              Text(
                'Live preview',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (displayTitle.isNotEmpty) ...[
            Text(
              displayTitle,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
          ],
          if (displayArtist.isNotEmpty) ...[
            Text(
              displayArtist,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium,
            ),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (displayKey != null &&
                  displayKey.trim().isNotEmpty)
                _PreviewChip(
                  icon: Icons.piano,
                  label: 'Key $displayKey',
                ),
              if (displayCapo != null &&
                  displayCapo.trim().isNotEmpty)
                _PreviewChip(
                  icon: Icons.tune,
                  label: 'Capo $displayCapo',
                ),
              if (displayBpm != null &&
                  displayBpm.trim().isNotEmpty)
                _PreviewChip(
                  icon: Icons.speed,
                  label: '$displayBpm BPM',
                ),
              if (displayTimeSignature != null &&
                  displayTimeSignature.trim().isNotEmpty)
                _PreviewChip(
                  icon: Icons.music_note,
                  label: displayTimeSignature,
                ),
            ],
          ),
          if (displayKey != null ||
              displayCapo != null ||
              displayBpm != null ||
              displayTimeSignature != null)
            const SizedBox(height: 18),
          if (body.trim().isEmpty)
            Text(
              'Begin met typen om de preview te zien.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
              ),
            )
          else
            ...body.split('\n').map(
                  (line) => _PreviewLine(
                line: line,
                fontSize: fontSize,
              ),
            ),
        ],
      ),
    );
  }
}

class _PreviewChip extends StatelessWidget {
  const _PreviewChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      avatar: Icon(
        icon,
        size: 16,
      ),
      label: Text(label),
    );
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({
    required this.line,
    required this.fontSize,
  });

  final String line;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    if (line.trim().isEmpty) {
      return SizedBox(
        height: fontSize * 0.9,
      );
    }

    if (_isComment(line)) {
      return Container(
        margin: const EdgeInsets.only(
          bottom: 12,
        ),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .tertiaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          line
              .replaceFirst('[Comment:', '')
              .replaceFirst(']', '')
              .trim(),
          style: const TextStyle(
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    final isSection =
        line.startsWith('[') &&
            line.endsWith(']') &&
            !_looksLikeChord(line);

    if (isSection) {
      return Padding(
        padding: const EdgeInsets.only(
          top: 16,
          bottom: 8,
        ),
        child: Text(
          line
              .replaceAll('[', '')
              .replaceAll(']', '')
              .toUpperCase(),
          style: TextStyle(
            fontSize: fontSize * 0.75,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: Theme.of(context)
                .colorScheme
                .primary,
          ),
        ),
      );
    }

    return _PreviewChordLine(
      line: line,
      fontSize: fontSize,
    );
  }

  bool _isComment(String value) {
    return value.startsWith('[Comment:') &&
        value.endsWith(']');
  }

  bool _looksLikeChord(String value) {
    final content = value
        .replaceAll('[', '')
        .replaceAll(']', '');

    return RegExp(
      r'^[A-G](#|b)?(m|maj|min|sus|dim|aug|add|[0-9])*(/[A-G](#|b)?)?$',
    ).hasMatch(content);
  }
}

class _PreviewChordLine extends StatelessWidget {
  const _PreviewChordLine({
    required this.line,
    required this.fontSize,
  });

  final String line;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final chordRegex =
    RegExp(r'\[([^\]]+)\]');

    final matches =
    chordRegex.allMatches(line).toList();

    if (matches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(
          bottom: 10,
        ),
        child: Text(
          line,
          style: TextStyle(
            fontSize: fontSize,
            height: 1.4,
          ),
        ),
      );
    }

    final segments = <Widget>[];
    var currentIndex = 0;

    for (var index = 0;
    index < matches.length;
    index++) {
      final match = matches[index];
      final chord = match.group(1) ?? '';

      final textBeforeChord = line.substring(
        currentIndex,
        match.start,
      );

      if (textBeforeChord.isNotEmpty) {
        segments.add(
          Padding(
            padding: EdgeInsets.only(
              top: fontSize * 0.78,
            ),
            child: Text(
              textBeforeChord,
              style: TextStyle(
                fontSize: fontSize,
                height: 1.35,
              ),
            ),
          ),
        );
      }

      final lyricEnd =
      index + 1 < matches.length
          ? matches[index + 1].start
          : line.length;

      final lyric = line.substring(
        match.end,
        lyricEnd,
      );

      segments.add(
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              chord,
              style: GoogleFonts.robotoMono(
                fontSize: fontSize * 0.78,
                fontWeight: FontWeight.bold,
                color: Theme.of(context)
                    .colorScheme
                    .primary,
              ),
            ),
            Text(
              lyric.isEmpty ? ' ' : lyric,
              style: TextStyle(
                fontSize: fontSize,
                height: 1.35,
              ),
            ),
          ],
        ),
      );

      currentIndex = lyricEnd;
    }

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 14,
      ),
      child: Wrap(
        crossAxisAlignment:
        WrapCrossAlignment.end,
        children: segments,
      ),
    );
  }
}