import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/song.dart';
import '../services/storage_service.dart';
import '../services/chordpro_export_service.dart';
import '../utils/chord_transposer.dart';
import '../utils/chordpro_parser.dart';
import 'song_editor_screen.dart';
import 'performance_screen.dart';
import 'ai_assistant_screen.dart';
import '../services/song_pdf_service.dart';

class SongViewerScreen extends StatefulWidget {
  const SongViewerScreen({
    super.key,
    required this.song,
  });

  final Song song;

  @override
  State<SongViewerScreen> createState() =>
      _SongViewerScreenState();
}

class _SongViewerScreenState extends State<SongViewerScreen> {
  late Song _song;

  final ScrollController _scrollController = ScrollController();

  Timer? _scrollTimer;

  int _transposeSteps = 0;
  double _fontSize = 20;
  double _scrollSpeed = 25;

  bool _isScrolling = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _song = widget.song;
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
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

        final currentOffset = _scrollController.offset;
        final maximumOffset =
            _scrollController.position.maxScrollExtent;

        final nextOffset =
            currentOffset + (_scrollSpeed / 10);

        if (nextOffset >= maximumOffset) {
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

  Future<void> _toggleFavorite() async {
    final updatedSong = _song.copyWith(
      favorite: !_song.favorite,
      updatedAt: DateTime.now(),
    );

    await StorageService.saveSong(updatedSong);

    if (!mounted) {
      return;
    }

    setState(() {
      _song = updatedSong;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updatedSong.favorite
              ? 'Toegevoegd aan favorieten'
              : 'Verwijderd uit favorieten',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _openEditor() async {
    _stopAutoScroll();

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SongEditorScreen(
          song: _song,
        ),
      ),
    );

    if (result != true) {
      return;
    }

    final updatedSongs = StorageService.getSongs();

    final matches = updatedSongs.where(
          (song) => song.id == _song.id,
    );

    if (matches.isEmpty || !mounted) {
      return;
    }

    setState(() {
      _song = matches.first;
    });
  }

  Future<void> _exportChordPro() async {
    _stopAutoScroll();

    try {
      await ChordProExportService.exportSong(
        _song,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ChordPro exporteren is niet gelukt: $error',
          ),
        ),
      );
    }
  }

  Future<void> _exportPdf() async {
    _stopAutoScroll();

    try {
      await SongPdfService.exportSong(_song);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PDF maken is niet gelukt: $error',
          ),
        ),
      );
    }
  }

  Future<void> _openAiAssistant() async {
    _stopAutoScroll();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiAssistantScreen(
          song: _song,
        ),
      ),
    );
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isTablet = screenWidth >= 700;

    final parsedSong = ChordProParser.parse(
      _song.content,
    );

    final songBody = parsedSong.body.isEmpty
        ? _song.content
        : parsedSong.body;

    final transposedText =
    ChordTransposer.transposeText(
      songBody,
      _transposeSteps,
    );

    final originalKey =
        parsedSong.key ?? _song.originalKey;

    final currentKey =
    ChordTransposer.transposeKey(
      originalKey,
      _transposeSteps,
    );

    final displayTitle = parsedSong.title?.trim().isNotEmpty == true
        ? parsedSong.title!
        : _song.title;

    final displayArtist =
    parsedSong.artist?.trim().isNotEmpty == true
        ? parsedSong.artist!
        : _song.artist;

    return Scaffold(
      appBar: _showControls
          ? AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (displayArtist.isNotEmpty)
              Text(
                displayArtist,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall,
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'AI Assistant',
            onPressed: _openAiAssistant,
            icon: const Icon(
              Icons.smart_toy_outlined,
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Exporteren',
            onSelected: (value) {
              if (value == 'pdf') {
                _exportPdf();
              }

              if (value == 'chordpro') {
                _exportChordPro();
              }
            },
            itemBuilder: (_) {
              return const [
                PopupMenuItem(
                  value: 'pdf',
                  child: Row(
                    children: [
                      Icon(
                        Icons.picture_as_pdf_outlined,
                      ),
                      SizedBox(width: 10),
                      Text('PDF exporteren'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'chordpro',
                  child: Row(
                    children: [
                      Icon(
                        Icons.file_upload_outlined,
                      ),
                      SizedBox(width: 10),
                      Text('ChordPro exporteren'),
                    ],
                  ),
                ),
              ];
            },
            icon: const Icon(
              Icons.ios_share_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Performance Mode',
            onPressed: () {
              _stopAutoScroll();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PerformanceScreen(
                    song: _song,
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.slideshow_outlined,
            ),
          ),
          IconButton(
            tooltip: _song.favorite
                ? 'Verwijder uit favorieten'
                : 'Voeg toe aan favorieten',
            onPressed: _toggleFavorite,
            icon: Icon(
              _song.favorite
                  ? Icons.favorite
                  : Icons.favorite_border,
            ),
          ),
          IconButton(
            tooltip: 'Lied bewerken',
            onPressed: _openEditor,
            icon: const Icon(
              Icons.edit_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Bediening verbergen',
            onPressed: _toggleControls,
            icon: const Icon(
              Icons.fullscreen,
            ),
          ),
        ],
      )
          : null,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _showControls
            ? null
            : _toggleControls,
        child: SafeArea(
          child: Column(
            children: [
              AnimatedSwitcher(
                duration: const Duration(
                  milliseconds: 250,
                ),
                child: _showControls
                    ? _ViewerControls(
                  transposeSteps:
                  _transposeSteps,
                  currentKey: currentKey,
                  fontSize: _fontSize,
                  scrollSpeed: _scrollSpeed,
                  isScrolling: _isScrolling,
                  onTransposeDown: () {
                    _changeTranspose(-1);
                  },
                  onTransposeUp: () {
                    _changeTranspose(1);
                  },
                  onResetTranspose:
                  _resetTranspose,
                  onFontSizeChanged: (value) {
                    setState(() {
                      _fontSize = value;
                    });
                  },
                  onScrollSpeedChanged:
                      (value) {
                    setState(() {
                      _scrollSpeed = value;
                    });
                  },
                  onToggleScroll:
                  _toggleAutoScroll,
                )
                    : const SizedBox.shrink(),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet
                          ? 1000
                          : double.infinity,
                    ),
                    child: ListView(
                      controller: _scrollController,
                      padding: EdgeInsets.fromLTRB(
                        isTablet ? 40 : 18,
                        24,
                        isTablet ? 40 : 18,
                        180,
                      ),
                      children: [
                        _ChordProHeaderCard(
                          title: displayTitle,
                          artist: displayArtist,
                          subtitle: parsedSong.subtitle,
                          currentKey: currentKey,
                          transposeSteps:
                          _transposeSteps,
                          capo: parsedSong.capo,
                          tempo: parsedSong.tempo,
                          timeSignature:
                          parsedSong.timeSignature,
                        ),
                        const SizedBox(height: 24),
                        ..._buildSongLines(
                          transposedText,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: !_showControls
          ? FloatingActionButton.small(
        onPressed: _toggleControls,
        child: const Icon(
          Icons.fullscreen_exit,
        ),
      )
          : null,
    );
  }

  List<Widget> _buildSongLines(String songText) {
    final lines = songText.split('\n');

    return lines.map((line) {
      return _SongLine(
        line: line,
        fontSize: _fontSize,
      );
    }).toList();
  }
}

class _ViewerControls extends StatelessWidget {
  const _ViewerControls({
    required this.transposeSteps,
    required this.currentKey,
    required this.fontSize,
    required this.scrollSpeed,
    required this.isScrolling,
    required this.onTransposeDown,
    required this.onTransposeUp,
    required this.onResetTranspose,
    required this.onFontSizeChanged,
    required this.onScrollSpeedChanged,
    required this.onToggleScroll,
  });

  final int transposeSteps;
  final String currentKey;
  final double fontSize;
  final double scrollSpeed;
  final bool isScrolling;

  final VoidCallback onTransposeDown;
  final VoidCallback onTransposeUp;
  final VoidCallback onResetTranspose;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<double> onScrollSpeedChanged;
  final VoidCallback onToggleScroll;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 1,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(
          12,
          12,
          12,
          14,
        ),
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment:
              WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                IconButton.filledTonal(
                  tooltip: 'Halve toon lager',
                  onPressed: onTransposeDown,
                  icon: const Icon(Icons.remove),
                ),
                InkWell(
                  borderRadius:
                  BorderRadius.circular(14),
                  onTap: onResetTranspose,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 105,
                    ),
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer,
                      borderRadius:
                      BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Toonsoort $currentKey',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          transposeSteps == 0
                              ? 'Origineel'
                              : transposeSteps > 0
                              ? '+$transposeSteps'
                              : '$transposeSteps',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Halve toon hoger',
                  onPressed: onTransposeUp,
                  icon: const Icon(Icons.add),
                ),
                FilledButton.icon(
                  onPressed: onToggleScroll,
                  icon: Icon(
                    isScrolling
                        ? Icons.pause
                        : Icons.play_arrow,
                  ),
                  label: Text(
                    isScrolling
                        ? 'Pauze'
                        : 'Scroll',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.text_fields,
                  size: 20,
                ),
                Expanded(
                  child: Slider(
                    min: 14,
                    max: 32,
                    divisions: 18,
                    label:
                    fontSize.round().toString(),
                    value: fontSize,
                    onChanged:
                    onFontSizeChanged,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.speed,
                  size: 20,
                ),
                Expanded(
                  child: Slider(
                    min: 5,
                    max: 60,
                    divisions: 11,
                    label:
                    scrollSpeed.round().toString(),
                    value: scrollSpeed,
                    onChanged:
                    onScrollSpeedChanged,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChordProHeaderCard extends StatelessWidget {
  const _ChordProHeaderCard({
    required this.title,
    required this.artist,
    required this.subtitle,
    required this.currentKey,
    required this.transposeSteps,
    required this.capo,
    required this.tempo,
    required this.timeSignature,
  });

  final String title;
  final String artist;
  final String? subtitle;
  final String currentKey;
  final int transposeSteps;
  final int? capo;
  final int? tempo;
  final String? timeSignature;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context)
                .colorScheme
                .primaryContainer,
            Theme.of(context)
                .colorScheme
                .secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 650;

          final information = Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (artist.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  artist,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium,
                ),
              ],
              if (subtitle != null &&
                  subtitle!.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(subtitle!),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MetadataChip(
                    icon: Icons.piano,
                    label: transposeSteps == 0
                        ? 'Key $currentKey'
                        : 'Key $currentKey '
                        '(${transposeSteps > 0 ? '+' : ''}'
                        '$transposeSteps)',
                  ),
                  if (capo != null)
                    _MetadataChip(
                      icon: Icons.tune,
                      label: 'Capo $capo',
                    ),
                  if (tempo != null)
                    _MetadataChip(
                      icon: Icons.speed,
                      label: '$tempo BPM',
                    ),
                  if (timeSignature != null &&
                      timeSignature!
                          .trim()
                          .isNotEmpty)
                    _MetadataChip(
                      icon: Icons.music_note,
                      label: timeSignature!,
                    ),
                ],
              ),
            ],
          );

          final icon = CircleAvatar(
            radius: 32,
            backgroundColor:
            Theme.of(context).colorScheme.primary,
            foregroundColor:
            Theme.of(context).colorScheme.onPrimary,
            child: const Icon(
              Icons.library_music,
              size: 32,
            ),
          );

          if (isWide) {
            return Row(
              children: [
                icon,
                const SizedBox(width: 20),
                Expanded(child: information),
              ],
            );
          }

          return Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              icon,
              const SizedBox(height: 18),
              information,
            ],
          );
        },
      ),
    );
  }
}

class _MetadataChip extends StatelessWidget {
  const _MetadataChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        icon,
        size: 17,
      ),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _SongLine extends StatelessWidget {
  const _SongLine({
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
      return _CommentLine(
        text: line,
      );
    }

    final isSectionTitle =
        line.startsWith('[') &&
            line.endsWith(']') &&
            !line.contains(RegExp(r'\]\S'));

    if (isSectionTitle &&
        !_looksLikeChord(line)) {
      return _SectionHeader(
        title: line
            .replaceAll('[', '')
            .replaceAll(']', ''),
      );
    }

    return _ChordLyricLine(
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 22,
        bottom: 12,
      ),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 28,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primary,
              borderRadius:
              BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context)
                    .colorScheme
                    .primary,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentLine extends StatelessWidget {
  const _CommentLine({
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
        bottom: 14,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              cleanedText,
              style: const TextStyle(
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChordLyricLine extends StatelessWidget {
  const _ChordLyricLine({
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
          bottom: 12,
        ),
        child: Text(
          line,
          style: TextStyle(
            fontSize: fontSize,
            height: 1.45,
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
          _LyricSegment(
            text: textBeforeChord,
            fontSize: fontSize,
          ),
        );
      }

      final lyricEnd =
      index + 1 < matches.length
          ? matches[index + 1].start
          : line.length;

      final lyricAfterChord = line.substring(
        match.end,
        lyricEnd,
      );

      segments.add(
        _ChordSegment(
          chord: chord,
          lyric: lyricAfterChord,
          fontSize: fontSize,
        ),
      );

      currentIndex = lyricEnd;
    }

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 16,
      ),
      child: Wrap(
        crossAxisAlignment:
        WrapCrossAlignment.end,
        children: segments,
      ),
    );
  }
}

class _ChordSegment extends StatelessWidget {
  const _ChordSegment({
    required this.chord,
    required this.lyric,
    required this.fontSize,
  });

  final String chord;
  final String lyric;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final chordColor =
        Theme.of(context).colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          chord,
          style: GoogleFonts.robotoMono(
            fontSize: fontSize * 0.8,
            fontWeight: FontWeight.bold,
            color: chordColor,
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
    );
  }
}

class _LyricSegment extends StatelessWidget {
  const _LyricSegment({
    required this.text,
    required this.fontSize,
  });

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: fontSize * 0.8,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          height: 1.35,
        ),
      ),
    );
  }
}