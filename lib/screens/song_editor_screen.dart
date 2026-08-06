import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/song.dart';
import '../services/storage_service.dart';
import '../utils/chordpro_parser.dart';
import '../widgets/live_song_preview.dart';

class SongEditorScreen extends StatefulWidget {
  const SongEditorScreen({super.key, this.song});

  final Song? song;

  @override
  State<SongEditorScreen> createState() => _SongEditorScreenState();
}

class _SongEditorScreenState extends State<SongEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _artistController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _capoController;
  late final TextEditingController _bpmController;
  late final TextEditingController _contentController;
  late final TextEditingController _tagsController;

  String? _selectedKey;
  String _selectedTimeSignature = '4/4';
  String _selectedGenre = '';

  bool _isSaving = false;
  bool _favorite = false;

  static const List<String> _keys = [
    'C',
    'C#',
    'Db',
    'D',
    'D#',
    'Eb',
    'E',
    'F',
    'F#',
    'Gb',
    'G',
    'G#',
    'Ab',
    'A',
    'A#',
    'Bb',
    'B',
  ];

  static const List<String> _timeSignatures = [
    '2/4',
    '3/4',
    '4/4',
    '5/4',
    '6/8',
    '7/8',
    '9/8',
    '12/8',
  ];

  static const List<String> _genres = [
    '',
    'Worship',
    'Gospel',
    'Pop',
    'Rock',
    'Ballad',
    'Akoestisch',
    'Kerst',
    'Jeugd',
    'Bachata',
    'Salsa',
    'Merengue',
    'Kizomba',
    'Overig',
  ];

  static const List<String> _chordQualities = [
    '',
    'm',
    '7',
    'm7',
    'maj7',
    'sus2',
    'sus4',
    'add9',
    'dim',
    'aug',
  ];

  bool get _isEditing => widget.song != null;

  @override
  void initState() {
    super.initState();

    final song = widget.song;
    final parsedSong = ChordProParser.parse(song?.content ?? '');

    _titleController = TextEditingController(
      text: parsedSong.title ?? song?.title ?? '',
    );

    _artistController = TextEditingController(
      text: parsedSong.artist ?? song?.artist ?? '',
    );

    _subtitleController = TextEditingController(
      text: parsedSong.subtitle ?? '',
    );

    _capoController = TextEditingController(
      text: parsedSong.capo?.toString() ?? '',
    );

    _bpmController = TextEditingController(
      text: parsedSong.tempo?.toString() ?? '',
    );

    _selectedKey = parsedSong.key ?? song?.originalKey;

    final savedTimeSignature = parsedSong.timeSignature;

    if (savedTimeSignature != null &&
        _timeSignatures.contains(savedTimeSignature)) {
      _selectedTimeSignature = savedTimeSignature;
    }

    _favorite = song?.favorite ?? false;
    _selectedGenre = song?.genre ?? '';

    _tagsController = TextEditingController(
      text: song?.tags.join(', ') ?? '',
    );

    final editorBody = _removeMetadataDirectives(song?.content ?? '');

    _contentController = TextEditingController(
      text: editorBody.trim().isNotEmpty
          ? editorBody.trim()
          : '''{start_of_verse: Verse 1}
[C]Typ hier je songtekst
[G]Plaats akkoorden tussen blokhaken
[Am]Bijvoorbeeld [F]zoals dit
{end_of_verse}

{start_of_chorus}
[C]Dit is het refrein
[G]Met tekst en akkoorden
{end_of_chorus}''',
    );

    _titleController.addListener(_refreshPreview);
    _artistController.addListener(_refreshPreview);
    _subtitleController.addListener(_refreshPreview);
    _capoController.addListener(_refreshPreview);
    _bpmController.addListener(_refreshPreview);
    _contentController.addListener(_refreshPreview);
    _tagsController.addListener(_refreshPreview);
  }

  void _refreshPreview() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_refreshPreview);
    _artistController.removeListener(_refreshPreview);
    _subtitleController.removeListener(_refreshPreview);
    _capoController.removeListener(_refreshPreview);
    _bpmController.removeListener(_refreshPreview);
    _contentController.removeListener(_refreshPreview);
    _tagsController.removeListener(_refreshPreview);

    _titleController.dispose();
    _artistController.dispose();
    _subtitleController.dispose();
    _capoController.dispose();
    _bpmController.dispose();
    _contentController.dispose();
    _tagsController.dispose();

    super.dispose();
  }

  Future<void> _saveSong() async {
    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final now = DateTime.now();
    final existingSong = widget.song;

    final title = _titleController.text.trim();
    final artist = _artistController.text.trim();
    final subtitle = _subtitleController.text.trim();
    final capo = _capoController.text.trim();
    final bpm = _bpmController.text.trim();
    final body = _removeMetadataDirectives(_contentController.text.trim());

    final tags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList();

    final completeChordProContent = _buildChordProContent(
      title: title,
      artist: artist,
      subtitle: subtitle,
      keyName: _selectedKey,
      capo: capo,
      bpm: bpm,
      timeSignature: _selectedTimeSignature,
      body: body,
    );

    final song = Song(
      id: existingSong?.id ?? now.microsecondsSinceEpoch.toString(),
      title: title,
      artist: artist,
      content: completeChordProContent,
      originalKey: _selectedKey,
      favorite: _favorite,
      genre: _selectedGenre,
      tags: tags,
      createdAt: existingSong?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      await StorageService.saveSong(song);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Lied is bijgewerkt' : 'Lied is opgeslagen',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opslaan is niet gelukt. Probeer het opnieuw.'),
        ),
      );
    }
  }

  String _buildChordProContent({
    required String title,
    required String artist,
    required String subtitle,
    required String? keyName,
    required String capo,
    required String bpm,
    required String timeSignature,
    required String body,
  }) {
    final metadata = <String>['{title: $title}'];

    if (artist.isNotEmpty) {
      metadata.add('{artist: $artist}');
    }

    if (subtitle.isNotEmpty) {
      metadata.add('{subtitle: $subtitle}');
    }

    if (keyName != null && keyName.isNotEmpty) {
      metadata.add('{key: $keyName}');
    }

    if (capo.isNotEmpty) {
      metadata.add('{capo: $capo}');
    }

    if (bpm.isNotEmpty) {
      metadata.add('{tempo: $bpm}');
    }

    if (timeSignature.isNotEmpty) {
      metadata.add('{time: $timeSignature}');
    }

    return '${metadata.join('\n')}\n\n$body'.trim();
  }

  String _removeMetadataDirectives(String text) {
    final metadataPattern = RegExp(
      r'^\s*\{(?:title|t|artist|author|subtitle|st|key|capo|tempo|bpm|time|time_signature)\s*:\s*.*\}\s*$',
      caseSensitive: false,
    );

    return text
        .replaceAll('\r\n', '\n')
        .split('\n')
        .where((line) => !metadataPattern.hasMatch(line))
        .join('\n')
        .replaceAll(RegExp(r'^\s*\n'), '')
        .trim();
  }

  void _insertText(String value) {
    final text = _contentController.text;
    final selection = _contentController.selection;

    final start = selection.start < 0 ? text.length : selection.start;
    final end = selection.end < 0 ? text.length : selection.end;

    final newText = text.replaceRange(start, end, value);

    _contentController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + value.length),
    );
  }

  void _insertChord(String chord) {
    _insertText('[$chord]');
  }

  void _insertSection({
    required String startDirective,
    required String endDirective,
    required String title,
  }) {
    final value =
    '''
{$startDirective: $title}

{$endDirective}
''';

    _insertText(value);
  }

  Future<void> _showChordPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (bottomSheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Akkoord invoegen',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              'Kies een akkoord. Het komt op de huidige cursorpositie.',
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(bottomSheetContext);
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
                    children: [
                      for (final root in _keys) ...[
                        Text(
                          root,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final quality in _chordQualities)
                              ActionChip(
                                label: Text('$root$quality'),
                                onPressed: () {
                                  Navigator.pop(bottomSheetContext);

                                  _insertChord('$root$quality');
                                },
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSectionPicker() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Sectie invoegen',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                ListTile(
                  leading: const Icon(Icons.notes),
                  title: const Text('Verse'),
                  subtitle: const Text('Voegt een nieuw couplet toe'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);

                    _insertSection(
                      startDirective: 'start_of_verse',
                      endDirective: 'end_of_verse',
                      title: 'Verse',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.queue_music),
                  title: const Text('Chorus'),
                  subtitle: const Text('Voegt een nieuw refrein toe'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);

                    _insertSection(
                      startDirective: 'start_of_chorus',
                      endDirective: 'end_of_chorus',
                      title: 'Chorus',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.alt_route),
                  title: const Text('Bridge'),
                  subtitle: const Text('Voegt een bridge toe'),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);

                    _insertSection(
                      startDirective: 'start_of_bridge',
                      endDirective: 'end_of_bridge',
                      title: 'Bridge',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Opmerking'),
                  subtitle: const Text(
                    'Voegt een aanwijzing voor muzikanten toe',
                  ),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    _insertText('{comment: Schrijf hier je opmerking}\n');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showChordProPreview() {
    final title = _titleController.text.trim();
    final artist = _artistController.text.trim();
    final subtitle = _subtitleController.text.trim();
    final body = _removeMetadataDirectives(_contentController.text);

    final preview = _buildChordProContent(
      title: title.isEmpty ? 'Geen titel' : title,
      artist: artist,
      subtitle: subtitle,
      keyName: _selectedKey,
      capo: _capoController.text.trim(),
      bpm: _bpmController.text.trim(),
      timeSignature: _selectedTimeSignature,
      body: body,
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (bottomSheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'ChordPro-preview',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Kopiëren',
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: preview));

                        if (!mounted) {
                          return;
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('ChordPro-code is gekopieerd'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(bottomSheetContext);
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: SelectableText(
                    preview,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWideScreen = screenWidth >= 1050;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Lied bewerken' : 'Nieuw lied',
          style: const TextStyle(
            fontSize: 11, // Pas dit aan, bijvoorbeeld 18 of 20
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'ChordPro-preview',
            onPressed: _showChordProPreview,
            icon: const Icon(Icons.visibility_outlined),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _saveSong,
              icon: _isSaving
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.save_outlined),
              label: Text(_isSaving ? 'Opslaan...' : 'Opslaan'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1500),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isWideScreen ? 28 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _EditorHeader(isEditing: _isEditing),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: isWideScreen
                            ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 320,
                              child: _buildSongInformation(),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 5,
                              child: _buildSongContent(
                                showLivePreview: false,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(flex: 4, child: _buildLivePreview()),
                          ],
                        )
                            : Column(
                          children: [
                            _buildSongInformation(),
                            const SizedBox(height: 24),
                            _buildSongContent(showLivePreview: true),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _saveSong,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(
                        _isEditing ? 'Wijzigingen opslaan' : 'Lied opslaan',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSongInformation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Liedinformatie',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              tooltip: _favorite ? 'Verwijder uit favorieten' : 'Maak favoriet',
              onPressed: () {
                setState(() {
                  _favorite = !_favorite;
                });
              },
              icon: Icon(
                _favorite ? Icons.favorite : Icons.favorite_border,
                color: _favorite ? Theme.of(context).colorScheme.primary : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _titleController,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Titel',
            hintText: 'Bijvoorbeeld: Above All',
            prefixIcon: Icon(Icons.music_note),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vul een titel in';
            }

            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _artistController,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Artiest',
            hintText: 'Bijvoorbeeld: Michael W. Smith',
            prefixIcon: Icon(Icons.person_outline),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _subtitleController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Ondertitel',
            hintText: 'Bijvoorbeeld: Worship Classic',
            prefixIcon: Icon(Icons.subtitles_outlined),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _selectedGenre,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Genre',
            prefixIcon: Icon(
              Icons.category_outlined,
            ),
          ),
          items: _genres.map((genre) {
            return DropdownMenuItem<String>(
              value: genre,
              child: Text(
                genre.isEmpty
                    ? 'Geen genre'
                    : genre,
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedGenre = value ?? '';
            });
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _tagsController,
          textInputAction: TextInputAction.next,
          textCapitalization:
          TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Tags',
            hintText:
            'Bijvoorbeeld: worship, zondag, rustig',
            prefixIcon: Icon(
              Icons.sell_outlined,
            ),
            helperText:
            'Scheid meerdere tags met komma’s.',
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _selectedKey,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Originele toonsoort',
            prefixIcon: Icon(Icons.piano),
          ),
          items: _keys.map((keyName) {
            return DropdownMenuItem(value: keyName, child: Text(keyName));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedKey = value;
            });
          },
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _capoController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                decoration: const InputDecoration(
                  labelText: 'Capo',
                  hintText: '0',
                  prefixIcon: Icon(Icons.tune),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null;
                  }

                  final capo = int.tryParse(value.trim());

                  if (capo == null || capo < 0 || capo > 24) {
                    return '0 t/m 24';
                  }

                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _bpmController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                decoration: const InputDecoration(
                  labelText: 'BPM',
                  hintText: '72',
                  prefixIcon: Icon(Icons.speed),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null;
                  }

                  final bpm = int.tryParse(value.trim());

                  if (bpm == null || bpm < 20 || bpm > 300) {
                    return '20 t/m 300';
                  }

                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _selectedTimeSignature,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Maatsoort',
            prefixIcon: Icon(Icons.music_note_outlined),
          ),
          items: _timeSignatures.map((timeSignature) {
            return DropdownMenuItem(
              value: timeSignature,
              child: Text(timeSignature),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) {
              return;
            }

            setState(() {
              _selectedTimeSignature = value;
            });
          },
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome_outlined, size: 20),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'ChordFlow voegt titel, artiest, key, capo, BPM en maatsoort automatisch als ChordPro-metadata toe.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLivePreview() {
    return LiveSongPreview(
      content: _contentController.text,
      title: _titleController.text,
      artist: _artistController.text,
      keyName: _selectedKey,
      capo: _capoController.text,
      bpm: _bpmController.text,
      timeSignature: _selectedTimeSignature,
    );
  }

  Widget _buildSongContent({required bool showLivePreview}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            Text(
              'Tekst en akkoorden',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _showSectionPicker,
                  icon: const Icon(Icons.segment),
                  label: const Text('Sectie'),
                ),
                FilledButton.tonalIcon(
                  onPressed: _showChordPicker,
                  icon: const Icon(Icons.add),
                  label: const Text('Akkoord'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _contentController,
          minLines: 20,
          maxLines: 34,
          keyboardType: TextInputType.multiline,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            alignLabelWithHint: true,
            labelText: 'Songtekst',
            hintText: '[C]Amazing [G]grace\n\n{start_of_chorus}',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Vul een songtekst in';
            }

            return null;
          },
        ),
        const SizedBox(height: 12),
        const _ChordHelpCard(),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _showChordProPreview,
          icon: const Icon(Icons.visibility_outlined),
          label: const Text('Bekijk ChordPro-code'),
        ),
        if (showLivePreview) ...[
          const SizedBox(height: 20),
          _buildLivePreview(),
        ],
      ],
    );
  }
}

class _EditorHeader extends StatelessWidget {
  const _EditorHeader({required this.isEditing});

  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            child: Icon(
              isEditing ? Icons.edit_note : Icons.library_music_outlined,
              size: 30,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Werk je lied bij' : 'Voeg een nieuw lied toe',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Voeg muziekgegevens toe en schrijf akkoorden tussen blokhaken.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChordHelpCard extends StatelessWidget {
  const _ChordHelpCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Voorbeeld: [C]Amazing [G]grace. Gebruik Sectie voor Verse, Chorus, Bridge of opmerkingen.',
            ),
          ),
        ],
      ),
    );
  }
}
