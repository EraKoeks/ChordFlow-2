import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChordLine extends StatelessWidget {
  const ChordLine({
    super.key,
    required this.line,
    required this.fontSize,
  });

  final String line;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final chordRegex = RegExp(r'\[([^\]]+)\]');
    final matches = chordRegex.allMatches(line).toList();

    if (matches.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          line,
          style: TextStyle(
            fontSize: fontSize,
            height: 1.45,
          ),
        ),
      );
    }

    final widgets = <Widget>[];
    int currentIndex = 0;

    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];

      final textBefore = line.substring(
        currentIndex,
        match.start,
      );

      if (textBefore.isNotEmpty) {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(
              top: fontSize * 0.78,
            ),
            child: Text(
              textBefore,
              style: TextStyle(
                fontSize: fontSize,
                height: 1.35,
              ),
            ),
          ),
        );
      }

      final chord = match.group(1)!;

      final lyricEnd = i + 1 < matches.length
          ? matches[i + 1].start
          : line.length;

      final lyric = line.substring(
        match.end,
        lyricEnd,
      );

      widgets.add(
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 3,
                vertical: 1,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer,
                borderRadius:
                BorderRadius.circular(4),
              ),
              child: Text(
                chord,
                style: GoogleFonts.robotoMono(
                  fontSize: fontSize * 0.75,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context)
                      .colorScheme
                      .primary,
                ),
              ),
            ),
            const SizedBox(height: 2),
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
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        spacing: 0,
        runSpacing: 0,
        crossAxisAlignment:
        WrapCrossAlignment.end,
        children: widgets,
      ),
    );
  }
}