import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/song.dart';
import '../utils/chord_transposer.dart';
import '../utils/chordpro_parser.dart';

class PerformanceScreen extends StatefulWidget {
  const PerformanceScreen({
    super.key,
    required this.song,
  });

  final Song song;

  @override
  State<PerformanceScreen> createState() =>
      _PerformanceScreenState();
}

class _PerformanceScreenState
    extends State<PerformanceScreen> {
  final ScrollController _scrollController =
  ScrollController();

  Timer? _scrollTimer;

  int _transposeSteps = 0;
  double _fontSize = 26;
  double _scrollSpeed = 20;

  bool _isScrolling = false;
  bool _showControls = true;
  double _scrollProgress = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollProgress);
    _enterFullscreen();
  }

  void _updateScrollProgress() {
    if (!_scrollController.hasClients) {
      return;
    }

    final maxScroll =
        _scrollController.position.maxScrollExtent;

    final progress = maxScroll <= 0
        ? 0.0
        : (_scrollController.offset / maxScroll)
        .clamp(0.0, 1.0);

    if ((progress - _scrollProgress).abs() < 0.001) {
      return;
    }

    if (mounted) {
      setState(() {
        _scrollProgress = progress;
      });
    }
  }

  Future<void> _scrollToTop() async {
    _stopAutoScroll();

    if (!_scrollController.hasClients) {
      return;
    }

    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _enterFullscreen() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _leaveFullscreen() async {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );

    await SystemChrome.setPreferredOrientations(
      DeviceOrientation.values,
    );
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.removeListener(
      _updateScrollProgress,
    );
    _scrollController.dispose();
    _leaveFullscreen();
    super.dispose();
  }

  void _changeTranspose(int difference) {
    setState(() {
      _transposeSteps += difference;
    });
  }

  void _resetTranspose() {
    setState(() {
      _transposeSteps = 0;
    });
  }

  void _startAutoScroll() {
    if (_isScrolling) {
      return;
    }

    setState(() {
      _isScrolling = true;
    });

    _scrollTimer = Timer.periodic(
      const Duration(milliseconds: 50),
          (_) {
        if (!_scrollController.hasClients) {
          return;
        }

        final currentOffset =
            _scrollController.offset;

        final maxOffset =
            _scrollController.position.maxScrollExtent;

        final nextOffset =
            currentOffset + (_scrollSpeed / 12);

        if (nextOffset >= maxOffset) {
          _stopAutoScroll();
          return;
        }

        _scrollController.jumpTo(nextOffset);
      },
    );
  }

  void _stopAutoScroll() {
    _scrollTimer?.cancel();

    if (!mounted) {
      return;
    }

    setState(() {
      _isScrolling = false;
    });
  }

  void _toggleAutoScroll() {
    if (_isScrolling) {
      _stopAutoScroll();
    } else {
      _startAutoScroll();
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  Future<void> _closePerformanceMode() async {
    _stopAutoScroll();
    await _leaveFullscreen();

    if (!mounted) {
      return;
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final parsedSong = ChordProParser.parse(
      widget.song.content,
    );

    final songBody = parsedSong.body.isEmpty
        ? widget.song.content
        : parsedSong.body;

    final transposedText =
    ChordTransposer.transposeText(
      songBody,
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (
          didPop,
          result,
          ) async {
        if (!didPop) {
          await _closePerformanceMode();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleControls,
          onDoubleTap: _scrollToTop,
          child: SafeArea(
            child: Stack(
              children: [
                ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    90,
                    24,
                    180,
                  ),
                  children: [
                    _PerformanceHeader(
                      title: title,
                      artist: artist,
                      keyName: currentKey,
                      capo: parsedSong.capo,
                      tempo: parsedSong.tempo,
                      timeSignature:
                      parsedSong.timeSignature,
                    ),
                    const SizedBox(height: 30),
                    ...transposedText
                        .split('\n')
                        .map(
                          (line) => _PerformanceLine(
                        line: line,
                        fontSize: _fontSize,
                      ),
                    ),
                  ],
                ),
                AnimatedPositioned(
                  duration: const Duration(
                    milliseconds: 220,
                  ),
                  top: _showControls ? 8 : -90,
                  left: 12,
                  right: 12,
                  child: _TopControls(
                    currentKey: currentKey,
                    transposeSteps: _transposeSteps,
                    onClose: _closePerformanceMode,
                    onTransposeDown: () {
                      _changeTranspose(-1);
                    },
                    onTransposeUp: () {
                      _changeTranspose(1);
                    },
                    onReset: _resetTranspose,
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    value: _scrollProgress,
                    minHeight: 3,
                    backgroundColor: Colors.white10,
                    valueColor:
                    const AlwaysStoppedAnimation<Color>(
                      Color(0xFF4FE1FF),
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(
                    milliseconds: 220,
                  ),
                  right: _showControls ? 18 : -70,
                  bottom: 170,
                  child: FloatingActionButton.small(
                    heroTag: 'performance_top',
                    onPressed: _scrollToTop,
                    backgroundColor:
                    const Color(0xEE171717),
                    foregroundColor: Colors.white,
                    child: const Icon(
                      Icons.vertical_align_top,
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
                  child: _BottomControls(
                    fontSize: _fontSize,
                    scrollSpeed: _scrollSpeed,
                    isScrolling: _isScrolling,
                    onFontSizeChanged: (value) {
                      setState(() {
                        _fontSize = value;
                      });
                    },
                    onScrollSpeedChanged: (value) {
                      setState(() {
                        _scrollSpeed = value;
                      });
                    },
                    onToggleScroll: _toggleAutoScroll,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PerformanceHeader extends StatelessWidget {
  const _PerformanceHeader({
    required this.title,
    required this.artist,
    required this.keyName,
    required this.capo,
    required this.tempo,
    required this.timeSignature,
  });

  final String title;
  final String artist;
  final String keyName;
  final int? capo;
  final int? tempo;
  final String? timeSignature;

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
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _PerformanceChip(
              label: 'Key $keyName',
              icon: Icons.piano,
            ),
            if (capo != null)
              _PerformanceChip(
                label: 'Capo $capo',
                icon: Icons.tune,
              ),
            if (tempo != null)
              _PerformanceChip(
                label: '$tempo BPM',
                icon: Icons.speed,
              ),
            if (timeSignature != null &&
                timeSignature!.trim().isNotEmpty)
              _PerformanceChip(
                label: timeSignature!,
                icon: Icons.music_note,
              ),
          ],
        ),
      ],
    );
  }
}

class _PerformanceChip extends StatelessWidget {
  const _PerformanceChip({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

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

class _TopControls extends StatelessWidget {
  const _TopControls({
    required this.currentKey,
    required this.transposeSteps,
    required this.onClose,
    required this.onTransposeDown,
    required this.onTransposeUp,
    required this.onReset,
  });

  final String currentKey;
  final int transposeSteps;
  final VoidCallback onClose;
  final VoidCallback onTransposeDown;
  final VoidCallback onTransposeUp;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xEE171717),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white24,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              SizedBox(
                width: 42,
                child: IconButton(
                  tooltip: 'Sluiten',
                  onPressed: onClose,
                  color: Colors.white,
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 42,
                      child: IconButton(
                        tooltip: 'Halve toon lager',
                        onPressed: onTransposeDown,
                        color: Colors.white,
                        padding: EdgeInsets.zero,
                        visualDensity:
                        VisualDensity.compact,
                        icon: const Icon(Icons.remove),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        borderRadius:
                        BorderRadius.circular(12),
                        onTap: onReset,
                        child: Padding(
                          padding:
                          const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 6,
                          ),
                          child: Column(
                            mainAxisSize:
                            MainAxisSize.min,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Key $currentKey',
                                  maxLines: 1,
                                  style:
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight:
                                    FontWeight.bold,
                                  ),
                                ),
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  transposeSteps == 0
                                      ? 'Origineel'
                                      : transposeSteps > 0
                                      ? '+$transposeSteps'
                                      : '$transposeSteps',
                                  maxLines: 1,
                                  style:
                                  const TextStyle(
                                    color:
                                    Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 42,
                      child: IconButton(
                        tooltip: 'Halve toon hoger',
                        onPressed: onTransposeUp,
                        color: Colors.white,
                        padding: EdgeInsets.zero,
                        visualDensity:
                        VisualDensity.compact,
                        icon: const Icon(Icons.add),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 42),
            ],
          );
        },
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  const _BottomControls({
    required this.fontSize,
    required this.scrollSpeed,
    required this.isScrolling,
    required this.onFontSizeChanged,
    required this.onScrollSpeedChanged,
    required this.onToggleScroll,
  });

  final double fontSize;
  final double scrollSpeed;
  final bool isScrolling;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<double> onScrollSpeedChanged;
  final VoidCallback onToggleScroll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        14,
        10,
        14,
        12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xEE171717),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white24,
        ),
      ),
      child: Column(
        children: [
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
                  onChanged: onFontSizeChanged,
                ),
              ),
              const Icon(
                Icons.speed,
                color: Colors.white70,
              ),
              Expanded(
                child: Slider(
                  min: 5,
                  max: 60,
                  divisions: 11,
                  value: scrollSpeed,
                  onChanged:
                  onScrollSpeedChanged,
                ),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onToggleScroll,
              icon: Icon(
                isScrolling
                    ? Icons.pause
                    : Icons.play_arrow,
              ),
              label: Text(
                isScrolling
                    ? 'Auto-scroll pauzeren'
                    : 'Auto-scroll starten',
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Dubbel tikken brengt je terug naar boven',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceLine extends StatelessWidget {
  const _PerformanceLine({
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

class _PerformanceChordLine extends StatelessWidget {
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
                color: const Color(0xFF4FE1FF),
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

class _PerformanceComment extends StatelessWidget {
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