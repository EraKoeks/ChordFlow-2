import 'package:flutter/material.dart';

import '../models/setlist.dart';
import '../models/song.dart';
import '../services/storage_service.dart';
import '../services/setlist_pdf_service.dart';
import 'song_viewer_screen.dart';
import 'setlist_performance_screen.dart';

class SetlistsScreen extends StatefulWidget {
  const SetlistsScreen({super.key});

  @override
  State<SetlistsScreen> createState() => _SetlistsScreenState();
}

class _SetlistsScreenState extends State<SetlistsScreen> {
  List<Setlist> _setlists = [];
  List<Song> _songs = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _setlists = StorageService.getSetlists();
      _songs = StorageService.getSongs();
    });
  }

  Future<void> _createSetlist() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.queue_music),
          title: const Text('Nieuwe setlist'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Naam',
                    hintText: 'Bijvoorbeeld: Zondagdienst',
                    prefixIcon: Icon(Icons.title),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Beschrijving',
                    hintText: 'Bijvoorbeeld: Ochtenddienst 10:00',
                    prefixIcon: Icon(Icons.notes),
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Annuleren'),
            ),
            FilledButton.icon(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Vul eerst een naam voor de setlist in.',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(Icons.add),
              label: const Text('Maken'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final now = DateTime.now();

      final setlist = Setlist(
        id: now.microsecondsSinceEpoch.toString(),
        name: nameController.text.trim(),
        description: descriptionController.text.trim(),
        songIds: const [],
        createdAt: now,
        updatedAt: now,
      );

      await StorageService.saveSetlist(setlist);

      if (mounted) {
        _loadData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Setlist "${setlist.name}" is gemaakt.',
            ),
          ),
        );
      }
    }

    nameController.dispose();
    descriptionController.dispose();
  }

  Future<void> _deleteSetlist(Setlist setlist) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.delete_outline),
          title: const Text('Setlist verwijderen'),
          content: Text(
            'Weet je zeker dat je "${setlist.name}" wilt verwijderen?\n\n'
                'De liedjes zelf blijven in je bibliotheek staan.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Annuleren'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Verwijderen'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await StorageService.deleteSetlist(setlist.id);

    if (!mounted) {
      return;
    }

    _loadData();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Setlist "${setlist.name}" is verwijderd.',
        ),
      ),
    );
  }

  Future<void> _openSetlist(Setlist setlist) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SetlistDetailScreen(
          setlist: setlist,
        ),
      ),
    );

    _loadData();
  }

  int _songCount(Setlist setlist) {
    return setlist.songIds.where((songId) {
      return _songs.any(
            (song) => song.id == songId,
      );
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth >= 700 ? 28.0 : 16.0;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Setlists',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Organiseer je liedjes',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createSetlist,
        icon: const Icon(Icons.add),
        label: const Text('Nieuwe setlist'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1000,
            ),
            child: _setlists.isEmpty
                ? _EmptySetlists(
              onCreate: _createSetlist,
            )
                : ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                16,
                horizontalPadding,
                110,
              ),
              children: [
                _SetlistsHeader(
                  setlistCount: _setlists.length,
                  totalSongs: _songs.length,
                  onCreate: _createSetlist,
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Mijn setlists',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '${_setlists.length} totaal',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._setlists.map((setlist) {
                  final songCount = _songCount(setlist);

                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child: _SetlistCard(
                      setlist: setlist,
                      songCount: songCount,
                      onTap: () {
                        _openSetlist(setlist);
                      },
                      onDelete: () {
                        _deleteSetlist(setlist);
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SetlistsHeader extends StatelessWidget {
  const _SetlistsHeader({
    required this.setlistCount,
    required this.totalSongs,
    required this.onCreate,
  });

  final int setlistCount;
  final int totalSongs;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 600;

          final information = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bereid je muziek voor',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Maak een vaste volgorde voor een optreden, '
                    'repetitie of kerkdienst.',
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _InformationChip(
                    icon: Icons.queue_music,
                    label: '$setlistCount setlists',
                  ),
                  _InformationChip(
                    icon: Icons.library_music_outlined,
                    label: '$totalSongs liedjes',
                  ),
                ],
              ),
            ],
          );

          final createButton = FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Nieuwe setlist'),
          );

          if (isWide) {
            return Row(
              children: [
                Expanded(child: information),
                const SizedBox(width: 20),
                createButton,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              information,
              const SizedBox(height: 20),
              createButton,
            ],
          );
        },
      ),
    );
  }
}

class _InformationChip extends StatelessWidget {
  const _InformationChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surface
            .withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SetlistCard extends StatelessWidget {
  const _SetlistCard({
    required this.setlist,
    required this.songCount,
    required this.onTap,
    required this.onDelete,
  });

  final Setlist setlist;
  final int songCount;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor:
                Theme.of(context).colorScheme.primaryContainer,
                child: const Icon(
                  Icons.queue_music,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      setlist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (setlist.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        setlist.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.music_note,
                          size: 17,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          songCount == 1
                              ? '1 lied'
                              : '$songCount liedjes',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Meer opties',
                onSelected: (value) {
                  if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (_) {
                  return const [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline),
                          SizedBox(width: 10),
                          Text('Verwijderen'),
                        ],
                      ),
                    ),
                  ];
                },
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class SetlistDetailScreen extends StatefulWidget {
  const SetlistDetailScreen({
    super.key,
    required this.setlist,
  });

  final Setlist setlist;

  @override
  State<SetlistDetailScreen> createState() =>
      _SetlistDetailScreenState();
}

class _SetlistDetailScreenState
    extends State<SetlistDetailScreen> {
  late Setlist _setlist;
  List<Song> _allSongs = [];

  @override
  void initState() {
    super.initState();
    _setlist = widget.setlist;
    _loadSongs();
  }

  void _loadSongs() {
    setState(() {
      _allSongs = StorageService.getSongs();
    });
  }

  List<Song> get _setlistSongs {
    final songs = <Song>[];

    for (final songId in _setlist.songIds) {
      final matches = _allSongs.where(
            (song) => song.id == songId,
      );

      if (matches.isNotEmpty) {
        songs.add(matches.first);
      }
    }

    return songs;
  }

  Future<void> _addSongs() async {
    final selectedIds = Set<String>.from(
      _setlist.songIds,
    );

    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SizedBox(
                height:
                MediaQuery.sizeOf(context).height * 0.78,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        20,
                        8,
                        16,
                        12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Liedjes kiezen',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                    fontWeight:
                                    FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${selectedIds.length} geselecteerd',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall,
                                ),
                              ],
                            ),
                          ),
                          FilledButton(
                            onPressed: () {
                              Navigator.pop(
                                bottomSheetContext,
                                selectedIds,
                              );
                            },
                            child: const Text('Opslaan'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _allSongs.isEmpty
                          ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'Je hebt nog geen liedjes in '
                                'je bibliotheek.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                          : ListView.builder(
                        itemCount: _allSongs.length,
                        itemBuilder: (context, index) {
                          final song = _allSongs[index];
                          final isSelected =
                          selectedIds.contains(song.id);

                          return CheckboxListTile(
                            value: isSelected,
                            secondary: CircleAvatar(
                              child: Text(
                                song.title.trim().isEmpty
                                    ? '?'
                                    : song.title
                                    .trim()[0]
                                    .toUpperCase(),
                              ),
                            ),
                            title: Text(
                              song.title,
                              maxLines: 1,
                              overflow:
                              TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              song.artist.trim().isEmpty
                                  ? 'Onbekende artiest'
                                  : song.artist,
                              maxLines: 1,
                              overflow:
                              TextOverflow.ellipsis,
                            ),
                            onChanged: (selected) {
                              setModalState(() {
                                if (selected == true) {
                                  selectedIds.add(song.id);
                                } else {
                                  selectedIds.remove(song.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null) {
      return;
    }

    final existingOrder = _setlist.songIds.where(
      result.contains,
    );

    final newlySelected = result.where(
          (songId) => !_setlist.songIds.contains(songId),
    );

    final updatedSetlist = _setlist.copyWith(
      songIds: [
        ...existingOrder,
        ...newlySelected,
      ],
      updatedAt: DateTime.now(),
    );

    await StorageService.saveSetlist(updatedSetlist);

    if (!mounted) {
      return;
    }

    setState(() {
      _setlist = updatedSetlist;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'De setlist is bijgewerkt.',
        ),
      ),
    );
  }

  Future<void> _removeSong(Song song) async {
    final updatedSetlist = _setlist.copyWith(
      songIds: _setlist.songIds
          .where((songId) => songId != song.id)
          .toList(),
      updatedAt: DateTime.now(),
    );

    await StorageService.saveSetlist(updatedSetlist);

    if (!mounted) {
      return;
    }

    setState(() {
      _setlist = updatedSetlist;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '"${song.title}" is uit de setlist verwijderd.',
        ),
      ),
    );
  }

  Future<void> _reorderSongs(
      int oldIndex,
      int newIndex,
      ) async {
    final songs = List<Song>.from(_setlistSongs);

    final movedSong = songs.removeAt(oldIndex);
    songs.insert(newIndex, movedSong);

    final updatedSetlist = _setlist.copyWith(
      songIds: songs.map((song) => song.id).toList(),
      updatedAt: DateTime.now(),
    );

    setState(() {
      _setlist = updatedSetlist;
    });

    await StorageService.saveSetlist(updatedSetlist);
  }

  Future<void> _exportSetlistPdf() async {
    final songs = _setlistSongs;

    if (songs.isEmpty) {
      return;
    }

    try {
      await SetlistPdfService.exportSetlist(
        setlist: _setlist,
        songs: songs,
      );
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

  Future<void> _openSong(Song song) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SongViewerScreen(
          song: song,
        ),
      ),
    );

    _loadSongs();
  }

  @override
  Widget build(BuildContext context) {
    final songs = _setlistSongs;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth >= 700 ? 28.0 : 16.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _setlist.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      floatingActionButton: songs.isEmpty
          ? FloatingActionButton.extended(
        onPressed: _addSongs,
        icon: const Icon(Icons.playlist_add),
        label: const Text('Liedjes kiezen'),
      )
          : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1000,
            ),
            child: songs.isEmpty
                ? _EmptySetlistDetail(
              setlist: _setlist,
              onAddSongs: _addSongs,
            )
                : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      16,
                      horizontalPadding,
                      110,
                    ),
                    children: [
                      _SetlistDetailHeader(
                        setlist: _setlist,
                        songCount: songs.length,
                        onStartPerformance: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SetlistPerformanceScreen(
                                    setlist: _setlist,
                                    songs: songs,
                                  ),
                            ),
                          );
                        },
                        onManageSongs: _addSongs,
                        onExportPdf: _exportSetlistPdf,
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Volgorde',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            'Sleep om te verplaatsen',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics:
                        const NeverScrollableScrollPhysics(),
                        buildDefaultDragHandles: false,
                        itemCount: songs.length,
                        onReorderItem: _reorderSongs,
                        itemBuilder: (context, index) {
                          final song = songs[index];

                          return Card(
                            key: ValueKey(song.id),
                            margin: const EdgeInsets.only(
                              bottom: 10,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              contentPadding:
                              const EdgeInsets.fromLTRB(
                                14,
                                8,
                                8,
                                8,
                              ),
                              leading: CircleAvatar(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    fontWeight:
                                    FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                song.title,
                                maxLines: 1,
                                overflow:
                                TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                song.artist.trim().isEmpty
                                    ? 'Onbekende artiest'
                                    : song.artist,
                                maxLines: 1,
                                overflow:
                                TextOverflow.ellipsis,
                              ),
                              onTap: () {
                                _openSong(song);
                              },
                              trailing: Row(
                                mainAxisSize:
                                MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip:
                                    'Verwijder uit setlist',
                                    onPressed: () {
                                      _removeSong(song);
                                    },
                                    icon: const Icon(
                                      Icons
                                          .remove_circle_outline,
                                    ),
                                  ),
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: const Padding(
                                      padding:
                                      EdgeInsets.all(10),
                                      child: Icon(
                                        Icons.drag_handle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
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

class _SetlistDetailHeader extends StatelessWidget {
  const _SetlistDetailHeader({
    required this.setlist,
    required this.songCount,
    required this.onStartPerformance,
    required this.onManageSongs,
    required this.onExportPdf,
  });

  final Setlist setlist;
  final int songCount;
  final VoidCallback onStartPerformance;
  final VoidCallback onManageSongs;
  final VoidCallback onExportPdf;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
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
        borderRadius: BorderRadius.circular(28),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 650;

          final information = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                setlist.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (setlist.description.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  setlist.description,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge,
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _InformationChip(
                    icon: Icons.music_note,
                    label: songCount == 1
                        ? '1 lied'
                        : '$songCount liedjes',
                  ),
                  const _InformationChip(
                    icon: Icons.slideshow_outlined,
                    label: 'Klaar voor optreden',
                  ),
                ],
              ),
            ],
          );

          final actions = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: onStartPerformance,
                icon: const Icon(
                  Icons.play_arrow,
                ),
                label: const Text(
                  'Start optreden',
                ),
              ),
              OutlinedButton.icon(
                onPressed: onExportPdf,
                icon: const Icon(
                  Icons.picture_as_pdf_outlined,
                ),
                label: const Text(
                  'PDF',
                ),
              ),
              OutlinedButton.icon(
                onPressed: onManageSongs,
                icon: const Icon(
                  Icons.playlist_add,
                ),
                label: const Text(
                  'Liedjes beheren',
                ),
              ),
            ],
          );

          if (isWide) {
            return Row(
              crossAxisAlignment:
              CrossAxisAlignment.center,
              children: [
                Expanded(child: information),
                const SizedBox(width: 24),
                actions,
              ],
            );
          }

          return Column(
            crossAxisAlignment:
            CrossAxisAlignment.stretch,
            children: [
              information,
              const SizedBox(height: 20),
              actions,
            ],
          );
        },
      ),
    );
  }
}


class _EmptySetlists extends StatelessWidget {
  const _EmptySetlists({
    required this.onCreate,
  });

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.queue_music,
              size: 78,
              color:
              Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 18),
            Text(
              'Nog geen setlists',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Maak een setlist voor een optreden, '
                  'repetitie of kerkdienst.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label:
              const Text('Eerste setlist maken'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySetlistDetail extends StatelessWidget {
  const _EmptySetlistDetail({
    required this.setlist,
    required this.onAddSongs,
  });

  final Setlist setlist;
  final VoidCallback onAddSongs;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.playlist_add,
              size: 76,
              color:
              Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 18),
            Text(
              setlist.name,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Deze setlist is nog leeg. Voeg liedjes '
                  'uit je bibliotheek toe.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAddSongs,
              icon: const Icon(Icons.playlist_add),
              label: const Text('Liedjes toevoegen'),
            ),
          ],
        ),
      ),
    );
  }
}