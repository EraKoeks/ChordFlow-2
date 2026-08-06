class ChordProSong {
  const ChordProSong({
    required this.body,
    this.title,
    this.artist,
    this.subtitle,
    this.key,
    this.capo,
    this.tempo,
    this.timeSignature,
  });

  final String body;
  final String? title;
  final String? artist;
  final String? subtitle;
  final String? key;
  final int? capo;
  final int? tempo;
  final String? timeSignature;

  bool get hasMetadata {
    return title != null ||
        artist != null ||
        subtitle != null ||
        key != null ||
        capo != null ||
        tempo != null ||
        timeSignature != null;
  }
}

class ChordProParser {
  static final RegExp _directivePattern = RegExp(
    r'^\s*\{([^}:]+)\s*:\s*(.*?)\}\s*$',
    caseSensitive: false,
  );

  static final RegExp _shortDirectivePattern = RegExp(
    r'^\s*\{([^}:]+)\}\s*$',
    caseSensitive: false,
  );

  static ChordProSong parse(String rawText) {
    String? title;
    String? artist;
    String? subtitle;
    String? key;
    int? capo;
    int? tempo;
    String? timeSignature;

    final bodyLines = <String>[];

    final normalizedText = rawText.replaceAll(
      '\r\n',
      '\n',
    );

    for (final originalLine in normalizedText.split('\n')) {
      final line = originalLine.trimRight();

      final directiveMatch =
      _directivePattern.firstMatch(line);

      if (directiveMatch != null) {
        final directive = directiveMatch
            .group(1)
            ?.trim()
            .toLowerCase();

        final value = directiveMatch
            .group(2)
            ?.trim();

        if (directive == null ||
            value == null ||
            value.isEmpty) {
          continue;
        }

        switch (directive) {
          case 'title':
          case 't':
            title = value;

          case 'artist':
          case 'author':
            artist = value;

          case 'subtitle':
          case 'st':
            subtitle = value;

          case 'key':
            key = value;

          case 'capo':
            capo = int.tryParse(value);

          case 'tempo':
          case 'bpm':
            tempo = int.tryParse(value);

          case 'time':
          case 'time_signature':
            timeSignature = value;

          case 'comment':
          case 'c':
            bodyLines.add('[Comment: $value]');

          case 'start_of_chorus':
          case 'soc':
            bodyLines.add('[Chorus]');

          case 'start_of_verse':
          case 'sov':
            bodyLines.add(
              value.isEmpty ? '[Verse]' : '[$value]',
            );

          case 'start_of_bridge':
          case 'sob':
            bodyLines.add(
              value.isEmpty ? '[Bridge]' : '[$value]',
            );

          case 'end_of_chorus':
          case 'eoc':
          case 'end_of_verse':
          case 'eov':
          case 'end_of_bridge':
          case 'eob':
            bodyLines.add('');

          default:
          // Onbekende metadata bewaren we voorlopig
          // niet in de zichtbare songtekst.
            break;
        }

        continue;
      }

      final shortDirectiveMatch =
      _shortDirectivePattern.firstMatch(line);

      if (shortDirectiveMatch != null) {
        final directive = shortDirectiveMatch
            .group(1)
            ?.trim()
            .toLowerCase();

        switch (directive) {
          case 'start_of_chorus':
          case 'soc':
            bodyLines.add('[Chorus]');

          case 'end_of_chorus':
          case 'eoc':
            bodyLines.add('');

          case 'start_of_verse':
          case 'sov':
            bodyLines.add('[Verse]');

          case 'end_of_verse':
          case 'eov':
            bodyLines.add('');

          case 'start_of_bridge':
          case 'sob':
            bodyLines.add('[Bridge]');

          case 'end_of_bridge':
          case 'eob':
            bodyLines.add('');

          default:
            break;
        }

        continue;
      }

      bodyLines.add(line);
    }

    return ChordProSong(
      title: title,
      artist: artist,
      subtitle: subtitle,
      key: key,
      capo: capo,
      tempo: tempo,
      timeSignature: timeSignature,
      body: _cleanBody(bodyLines),
    );
  }

  static String _cleanBody(List<String> lines) {
    final cleanedLines = <String>[];
    var previousLineWasEmpty = false;

    for (final line in lines) {
      final isEmpty = line.trim().isEmpty;

      if (isEmpty && previousLineWasEmpty) {
        continue;
      }

      cleanedLines.add(line);
      previousLineWasEmpty = isEmpty;
    }

    while (cleanedLines.isNotEmpty &&
        cleanedLines.first.trim().isEmpty) {
      cleanedLines.removeAt(0);
    }

    while (cleanedLines.isNotEmpty &&
        cleanedLines.last.trim().isEmpty) {
      cleanedLines.removeLast();
    }

    return cleanedLines.join('\n');
  }
}