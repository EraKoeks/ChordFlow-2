class ChordTransposer {
  static const List<String> _sharpScale = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];

  static const List<String> _flatScale = [
    'C',
    'Db',
    'D',
    'Eb',
    'E',
    'F',
    'Gb',
    'G',
    'Ab',
    'A',
    'Bb',
    'B',
  ];

  static const Map<String, int> _noteIndexes = {
    'C': 0,
    'B#': 0,
    'C#': 1,
    'Db': 1,
    'D': 2,
    'D#': 3,
    'Eb': 3,
    'E': 4,
    'Fb': 4,
    'E#': 5,
    'F': 5,
    'F#': 6,
    'Gb': 6,
    'G': 7,
    'G#': 8,
    'Ab': 8,
    'A': 9,
    'A#': 10,
    'Bb': 10,
    'B': 11,
    'Cb': 11,
  };

  static final RegExp _chordPattern = RegExp(
    r'\[([A-G](?:#|b|♯|♭)?)([^/\]]*)(?:/([A-G](?:#|b|♯|♭)?))?\]',
  );

  static String transposeText(
      String text,
      int steps,
      ) {
    if (steps == 0 || text.isEmpty) {
      return text;
    }

    return text.replaceAllMapped(
      _chordPattern,
          (match) {
        final root = match.group(1);
        final chordType = match.group(2) ?? '';
        final bassNote = match.group(3);

        if (root == null) {
          return match.group(0) ?? '';
        }

        final preferFlats = _shouldPreferFlats(
          root,
          bassNote,
        );

        final transposedRoot = _transposeNote(
          root,
          steps,
          preferFlats: preferFlats,
        );

        if (bassNote == null) {
          return '[$transposedRoot$chordType]';
        }

        final transposedBass = _transposeNote(
          bassNote,
          steps,
          preferFlats: preferFlats,
        );

        return '[$transposedRoot$chordType/$transposedBass]';
      },
    );
  }

  static String transposeChord(
      String chord,
      int steps,
      ) {
    if (chord.trim().isEmpty || steps == 0) {
      return chord;
    }

    final hasBrackets =
        chord.startsWith('[') && chord.endsWith(']');

    final wrappedChord = hasBrackets
        ? chord
        : '[$chord]';

    final transposed = transposeText(
      wrappedChord,
      steps,
    );

    if (hasBrackets) {
      return transposed;
    }

    return transposed
        .replaceFirst('[', '')
        .replaceFirst(RegExp(r'\]$'), '');
  }

  static String transposeKey(
      String? originalKey,
      int steps,
      ) {
    if (originalKey == null ||
        originalKey.trim().isEmpty) {
      return 'Onbekend';
    }

    final normalizedKey = originalKey.trim();

    return _transposeNote(
      normalizedKey,
      steps,
      preferFlats: _containsFlat(normalizedKey),
    );
  }

  static String _transposeNote(
      String note,
      int steps, {
        required bool preferFlats,
      }) {
    final normalizedNote = _normalizeAccidentals(
      note.trim(),
    );

    final currentIndex = _noteIndexes[normalizedNote];

    if (currentIndex == null) {
      return note;
    }

    final normalizedSteps = steps % 12;

    final newIndex =
        (currentIndex + normalizedSteps) % 12;

    final safeIndex = newIndex < 0
        ? newIndex + 12
        : newIndex;

    final scale =
    preferFlats ? _flatScale : _sharpScale;

    return scale[safeIndex];
  }

  static bool _shouldPreferFlats(
      String root,
      String? bassNote,
      ) {
    if (_containsFlat(root)) {
      return true;
    }

    if (bassNote != null &&
        _containsFlat(bassNote)) {
      return true;
    }

    return false;
  }

  static bool _containsFlat(String note) {
    return note.contains('b') ||
        note.contains('♭');
  }

  static String _normalizeAccidentals(
      String note,
      ) {
    return note
        .replaceAll('♯', '#')
        .replaceAll('♭', 'b');
  }
}
