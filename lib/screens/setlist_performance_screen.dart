import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/setlist.dart';
import '../models/song.dart';
import '../utils/chord_transposer.dart';
import '../utils/chordpro_parser.dart';

class SetlistPerformanceScreen extends StatefulWidget {
  const SetlistPerformanceScreen({
    super.key,
    required this.setlist,
    required this.songs,
    this.initialIndex = 0,
  });

  final Setlist setlist;
  final List<Song> songs;
  final int initialIndex;

  @override
  State<SetlistPerformanceScreen> createState() =>
      _SetlistPerformanceScreenState();
}

class _SetlistPerformanceScreenState
    extends State<SetlistPerformanceScreen> {
  late final PageController _pageController;

  late int _currentIndex;

  bool _showControls = true;

  @override
  void initState() {
    super.initState();

    _currentIndex = widget.initialIndex.clamp(
      0,
      widget.songs.length - 1,
    );

    _pageController = PageController(
      initialPage: _currentIndex,
    );

    _enterPerformanceMode();
  }

  Future<void> _enterPerformanceMode() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _leavePerformanceMode() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );

    await SystemChrome.setPreferredOrientations(
      DeviceOrientation.values,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _leavePerformanceMode();
    super.dispose();
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  Future<void> _goToPreviousSong() async {
    if (_currentIndex <= 0) {
      return;
    }

    await _pageController.previousPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _goToNextSong() async {
    if (_currentIndex >= widget.songs.length - 1) {
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _close() async {
    await _leavePerformanceMode();

    if (!mounted) {
      return;
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = widget.songs[_currentIndex];

    final nextSong =
    _currentIndex < widget.songs.length - 1
        ? widget.songs[_currentIndex + 1]
        : null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (
          didPop,
          result,
          ) async {
        if (!didPop) {
          await _close();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleControls,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: widget.songs.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _SetlistSongPage(
                    key: ValueKey(
                      widget.songs[index].id,
                    ),
                    song: widget.songs[index],
                  );
                },
              ),
              AnimatedPositioned(
                duration: const Duration(
                  milliseconds: 220,
                ),
                top: _showControls ? 12 : -130,
                left: 12,
                right: 12,
                child: SafeArea(
                  child: _TopSetlistControls(
                    setlistName: widget.setlist.name,
                    songTitle: currentSong.title,
                    currentIndex: _currentIndex,
                    totalSongs: widget.songs.length,
                    onClose: _close,
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(
                  milliseconds: 220,
                ),
                left: 12,
                right: 12,
                bottom: _showControls ? 12 : -150,
                child: SafeArea(
                  top: false,
                  child: _BottomSetlistControls(
                    hasPrevious: _currentIndex > 0,
                    hasNext: _currentIndex <
                        widget.songs.length - 1,
                    nextSongTitle: nextSong?.title,
                    onPrevious: _goToPreviousSong,
                    onNext: _goToNextSong,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SetlistSongPage extends StatefulWidget {
  const _SetlistSongPage({
    super.key,
    required this.song,
  });

  final Song song;

  @override
  State<_SetlistSongPage> createState() =>
      _SetlistSongPageState();
}

class _SetlistSongPageState
    extends State<_SetlistSongPage>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController =
  ScrollController();

  int _transposeSteps = 0;
  double _fontSize = 27;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _transposeDown() {
    setState(() {
      _transposeSteps--;
    });
  }

  void _transposeUp() {
    setState(() {
      _transposeSteps++;
    });
  }

  void _resetTranspose() {
    setState(() {
      _transposeSteps = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final parsedSong = ChordProParser.parse(
      widget.song.content,
    );

    final body = parsedSong.body.isEmpty
        ? widget.song.content
        : parsedSong.body;

    final transposedBody =
    ChordTransposer.transposeText(
      body,
      _transposeSteps,
    );

    final originalKey =
        parsedSong.key ?? widget.song.originalKey;

    final currentKey =
    ChordTransposer.transposeKey(
      originalKey,
      _transposeSteps,
    );

    final title =
    parsedSong.title?.trim().isNotEmpty == true
        ? parsedSong.title!
        : widget.song.title;

    final artist =
    parsedSong.artist?.trim().isNotEmpty == true
        ? parsedSong.artist!
        : widget.song.artist;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(
                24,
                115,
                24,
                160,
              ),
              children: [
                _PerformanceSongHeader(
                  title: title,
                  artist: artist,
                  currentKey: currentKey,
                  transposeSteps: _transposeSteps,
                  capo: parsedSong.capo,
                  tempo: parsedSong.tempo,
                  timeSignature:
                  parsedSong.timeSignature,
                  onTransposeDown: _transposeDown,
                  onTransposeUp: _transposeUp,
                  onResetTranspose: _resetTranspose,
                  fontSize: _fontSize,
                  onFontSizeChanged: (value) {
                    setState(() {
                      _fontSize = value;
                    });
                  },
                ),
                const SizedBox(height: 30),
                ...transposedBody.split('\n').map(
                      (line) => _PerformanceSongLine(
                    line: line,
                    fontSize: _fontSize,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopSetlistControls extends StatelessWidget {
  const _TopSetlistControls({
    required this.setlistName,
    required this.songTitle,
    required this.currentIndex,
    required this.totalSongs,
    required this.onClose,
  });

  final String setlistName;
  final String songTitle;
  final int currentIndex;
  final int totalSongs;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        8,
        8,
        14,
        8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xEE171717),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white24,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Performance Mode sluiten',
            onPressed: onClose,
            color: Colors.white,
            icon: const Icon(Icons.close),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  setlistName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                Text(
                  songTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              '${currentIndex + 1} / $totalSongs',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomSetlistControls
    extends StatelessWidget {
  const _BottomSetlistControls({
    required this.hasPrevious,
    required this.hasNext,
    required this.nextSongTitle,
    required this.onPrevious,
    required this.onNext,
  });

  final bool hasPrevious;
  final bool hasNext;
  final String? nextSongTitle;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        12,
        10,
        12,
        10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xEE171717),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white24,
        ),
      ),
      child: Row(
        children: [
          IconButton.filledTonal(
            tooltip: 'Vorig lied',
            onPressed:
            hasPrevious ? onPrevious : null,
            icon: const Icon(
              Icons.arrow_back,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'Swipe links of rechts',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (nextSongTitle != null)
                  Text(
                    'Volgende: $nextSongTitle',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  )
                else
                  const Text(
                    'Laatste lied van de setlist',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filled(
            tooltip: 'Volgend lied',
            onPressed: hasNext ? onNext : null,
            icon: const Icon(
              Icons.arrow_forward,
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceSongHeader
    extends StatelessWidget {
  const _PerformanceSongHeader({
    required this.title,
    required this.artist,
    required this.currentKey,
    required this.transposeSteps,
    required this.capo,
    required this.tempo,
    required this.timeSignature,
    required this.onTransposeDown,
    required this.onTransposeUp,
    required this.onResetTranspose,
    required this.fontSize,
    required this.onFontSizeChanged,
  });

  final String title;
  final String artist;
  final String currentKey;
  final int transposeSteps;
  final int? capo;
  final int? tempo;
  final String? timeSignature;

  final VoidCallback onTransposeDown;
  final VoidCallback onTransposeUp;
  final VoidCallback onResetTranspose;

  final double fontSize;
  final ValueChanged<double> onFontSizeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (artist.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            artist,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 18,
            ),
          ),
        ],
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _DarkChip(
              icon: Icons.piano,
              label: 'Key $currentKey',
            ),
            if (capo != null)
              _DarkChip(
                icon: Icons.tune,
                label: 'Capo $capo',
              ),
            if (tempo != null)
              _DarkChip(
                icon: Icons.speed,
                label: '$tempo BPM',
              ),
            if (timeSignature != null &&
                timeSignature!.trim().isNotEmpty)
              _DarkChip(
                icon: Icons.music_note,
                label: timeSignature!,
              ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white24,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: onTransposeDown,
                    color: Colors.white,
                    icon: const Icon(Icons.remove),
                  ),
                  InkWell(
                    onTap: onResetTranspose,
                    borderRadius:
                    BorderRadius.circular(12),
                    child: Padding(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Key $currentKey',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                          Text(
                            transposeSteps == 0
                                ? 'Origineel'
                                : transposeSteps > 0
                                ? '+$transposeSteps'
                                : '$transposeSteps',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onTransposeUp,
                    color: Colors.white,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(
                    Icons.text_fields,
                    color: Colors.white70,
                  ),
                  Expanded(
                    child: Slider(
                      min: 18,
                      max: 42,
                      divisions: 24,
                      value: fontSize,
                      onChanged:
                      onFontSizeChanged,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DarkChip extends StatelessWidget {
  const _DarkChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: Colors.white24,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white70,
            size: 17,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceSongLine
    extends StatelessWidget {
  const _PerformanceSongLine({
    required this.line,
    required this.fontSize,
  });

  final String line;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    if (line.trim().isEmpty) {
      return SizedBox(height: fontSize);
    }

    if (_isComment(line)) {
      return _PerformanceComment(
        text: line,
      );
    }

    final isSection =
        line.startsWith('[') &&
            line.endsWith(']') &&
            !_looksLikeChord(line);

    if (isSection) {
      return Padding(
        padding: const EdgeInsets.only(
          top: 24,
          bottom: 12,
        ),
        child: Text(
          line
              .replaceAll('[', '')
              .replaceAll(']', ''),
          style: TextStyle(
            color: const Color(0xFF4FE1FF),
            fontSize: fontSize * 0.75,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      );
    }

    return _PerformanceChordLine(
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

class _PerformanceChordLine
    extends StatelessWidget {
  const _PerformanceChordLine({
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
          bottom: 14,
        ),
        child: Text(
          line,
          style: TextStyle(
            color: Colors.white,
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
              top: fontSize * 0.8,
            ),
            child: Text(
              textBeforeChord,
              style: TextStyle(
                color: Colors.white,
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
                color:
                const Color(0xFF4FE1FF),
                fontSize: fontSize * 0.78,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              lyric.isEmpty ? ' ' : lyric,
              style: TextStyle(
                color: Colors.white,
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
        bottom: 18,
      ),
      child: Wrap(
        crossAxisAlignment:
        WrapCrossAlignment.end,
        children: segments,
      ),
    );
  }
}

class _PerformanceComment
    extends StatelessWidget {
  const _PerformanceComment({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    final cleanedText = text
        .replaceFirst('[Comment:', '')
        .replaceFirst(']', '')
        .trim();

    return Container(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white24,
        ),
      ),
      child: Text(
        cleanedText,
        style: const TextStyle(
          color: Colors.white70,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}