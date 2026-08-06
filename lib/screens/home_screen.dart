import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/storage_service.dart';
import '../services/recent_service.dart';
import '../services/play_count_service.dart';
import '../services/chordpro_import_service.dart';
import 'settings_screen.dart';
import 'setlists_screen.dart';
import 'song_editor_screen.dart';
import 'song_viewer_screen.dart';

enum SongFilter {
  all,
  favorites,
  recent,
  mostPlayed,
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController =
  TextEditingController();

  List<Song> _songs = [];
  String _searchQuery = '';
  SongFilter _selectedFilter = SongFilter.all;
  bool _isRefreshing = false;
  List<String> _recentSongIds = [];
  Map<String, int> _playCounts = {};

  @override
  void initState() {
    super.initState();
    _loadSongs();
    _loadRecentSongs();
    _loadPlayCounts();
  }

  Future<void> _loadPlayCounts() async {
    final counts =
    await PlayCountService.getPlayCounts();

    if (!mounted) {
      return;
    }

    setState(() {
      _playCounts = counts;
    });
  }

  Future<void> _loadRecentSongs() async {
    final recentSongIds =
    await RecentService.getRecentSongIds();

    if (!mounted) {
      return;
    }

    setState(() {
      _recentSongIds = recentSongIds;
    });
  }

  void _loadSongs() {
    setState(() {
      _songs = StorageService.getSongs();
    });
  }

  Future<void> _refreshSongs() async {
    if (_isRefreshing) {
      return;
    }

    setState(() {
      _isRefreshing = true;
    });

    await Future<void>.delayed(
      const Duration(milliseconds: 350),
    );

    if (!mounted) {
      return;
    }

    final recentSongIds =
    await RecentService.getRecentSongIds();

    final playCounts =
    await PlayCountService.getPlayCounts();

    if (!mounted) {
      return;
    }

    setState(() {
      _songs = StorageService.getSongs();
      _recentSongIds = recentSongIds;
      _playCounts = playCounts;
      _isRefreshing = false;
    });
  }

  List<Song> get _filteredSongs {
    final query = _searchQuery.trim().toLowerCase();

    return _songs.where((song) {
      final searchableText = [
        song.title,
        song.artist,
        song.content,
        song.originalKey ?? '',
        song.genre,
        ...song.tags,
      ].join(' ').toLowerCase();

      final matchesSearch = searchableText.contains(query);

      final matchesFilter = switch (
      _selectedFilter
      ) {
        SongFilter.all => true,
        SongFilter.favorites => song.favorite,
        SongFilter.recent =>
            _recentSongIds.contains(song.id),
        SongFilter.mostPlayed =>
        (_playCounts[song.id] ?? 0) > 0,
      };

      return matchesSearch && matchesFilter;
    }).toList()
      ..sort((a, b) {
        if (_selectedFilter ==
            SongFilter.recent) {
          final aIndex =
          _recentSongIds.indexOf(a.id);
          final bIndex =
          _recentSongIds.indexOf(b.id);

          return aIndex.compareTo(bIndex);
        }

        if (_selectedFilter ==
            SongFilter.mostPlayed) {
          final aCount =
              _playCounts[a.id] ?? 0;
          final bCount =
              _playCounts[b.id] ?? 0;

          final countCompare =
          bCount.compareTo(aCount);

          if (countCompare != 0) {
            return countCompare;
          }
        }

        return b.updatedAt.compareTo(
          a.updatedAt,
        );
      });
  }

  int get _favoriteCount {
    return _songs.where((song) => song.favorite).length;
  }

  Future<void> _importChordPro() async {
    final result =
    await ChordProImportService.pickAndImportSong();

    if (!mounted) return;

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      return;
    }

    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SongEditorScreen(
          song: result.song,
        ),
      ),
    );

    if (saved == true) {
      _loadSongs();
    }
  }

  Future<void> _openEditor([Song? song]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SongEditorScreen(
          song: song,
        ),
      ),
    );

    if (result == true) {
      _loadSongs();
    }
  }

  Future<void> _openViewer(Song song) async {
    await RecentService.addRecentSong(song.id);
    await PlayCountService.increment(song.id);

    await Future.wait([
      _loadRecentSongs(),
      _loadPlayCounts(),
    ]);

    if (!mounted) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SongViewerScreen(
          song: song,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    _loadSongs();
  }

  Future<void> _openSetlists() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SetlistsScreen(),
      ),
    );

    _loadSongs();
  }

  Future<void> _openSettings() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          themeMode: widget.themeMode,
          onThemeChanged:
          widget.onThemeChanged,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (result == true) {
      _loadSongs();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'De herstelde gegevens zijn geladen.',
          ),
        ),
      );
    } else {
      setState(() {});
    }
  }

  Future<void> _toggleFavorite(Song song) async {
    final updatedSong = song.copyWith(
      favorite: !song.favorite,
      updatedAt: DateTime.now(),
    );

    await StorageService.saveSong(updatedSong);

    if (!mounted) {
      return;
    }

    _loadSongs();
  }

  Future<void> _deleteSong(Song song) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.delete_outline),
          title: const Text('Lied verwijderen'),
          content: Text(
            'Weet je zeker dat je "${song.title}" '
                'wilt verwijderen?',
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

    await StorageService.deleteSong(song.id);

    if (!mounted) {
      return;
    }

    _loadSongs();

    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 6),
        content: Text(
          '"${song.title}" is verwijderd.',
        ),
        action: SnackBarAction(
          label: 'Ongedaan maken',
          onPressed: () async {
            await StorageService.saveSong(
              song.copyWith(
                updatedAt: DateTime.now(),
              ),
            );

            if (!mounted) {
              return;
            }

            _loadSongs();

            ScaffoldMessenger.of(context)
                .hideCurrentSnackBar();

            ScaffoldMessenger.of(context)
                .showSnackBar(
              SnackBar(
                content: Text(
                  '"${song.title}" is hersteld.',
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();

    setState(() {
      _searchQuery = '';
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth =
        MediaQuery.sizeOf(context).width;

    final displayedSongs = _filteredSongs;

    final crossAxisCount = switch (screenWidth) {
      >= 1100 => 3,
      >= 700 => 2,
      _ => 1,
    };

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68,
        titleSpacing: 16,
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ChordFlow',
              maxLines: 1,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 23,
                height: 1.05,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Your music, always in sync',
              maxLines: 1,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.normal,
                height: 1.1,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              8,
              0,
              8,
              8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _HomeActionButton(
                    icon: Icons.settings_outlined,
                    label: 'Instellingen',
                    onPressed: _openSettings,
                  ),
                ),
                Expanded(
                  child: _HomeActionButton(
                    icon: Icons.queue_music,
                    label: 'Setlists',
                    onPressed: _openSetlists,
                  ),
                ),
                Expanded(
                  child: _HomeActionButton(
                    icon: Icons.file_upload_outlined,
                    label: 'Importeren',
                    onPressed: _importChordPro,
                  ),
                ),
                Expanded(
                  child: _HomeActionButton(
                    icon: Icons.refresh,
                    label: 'Vernieuwen',
                    onPressed: _refreshSongs,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton:
      FloatingActionButton.extended(
        onPressed: () {
          _openEditor();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nieuw lied'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshSongs,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 1200,
              ),
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      screenWidth >= 700 ? 28 : 16,
                      16,
                      screenWidth >= 700 ? 28 : 16,
                      0,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          _SyncStatusCard(
                            isRefreshing: _isRefreshing,
                            onRefresh: _refreshSongs,
                          ),
                          const SizedBox(height: 14),
                          _WelcomeCard(
                            totalSongs: _songs.length,
                            favoriteSongs:
                            _favoriteCount,
                            onCreateSong: () {
                              _openEditor();
                            },
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller:
                            _searchController,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            decoration:
                            InputDecoration(
                              hintText: 'Zoek op titel, artiest, genre, tags of akkoorden',
                              prefixIcon:
                              const Icon(
                                Icons.search,
                              ),
                              suffixIcon:
                              _searchQuery.isNotEmpty
                                  ? IconButton(
                                onPressed:
                                _clearSearch,
                                icon:
                                const Icon(
                                  Icons.close,
                                ),
                              )
                                  : null,
                              filled: true,
                              border:
                              OutlineInputBorder(
                                borderRadius:
                                BorderRadius
                                    .circular(18),
                                borderSide:
                                BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              FilterChip(
                                label: const Text(
                                  'Alle liedjes',
                                ),
                                avatar: const Icon(
                                  Icons
                                      .library_music_outlined,
                                  size: 18,
                                ),
                                selected:
                                _selectedFilter ==
                                    SongFilter.all,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedFilter =
                                        SongFilter.all;
                                  });
                                },
                              ),
                              FilterChip(
                                label: Text(
                                  'Favorieten '
                                      '($_favoriteCount)',
                                ),
                                avatar: const Icon(
                                  Icons
                                      .favorite_outline,
                                  size: 18,
                                ),
                                selected:
                                _selectedFilter ==
                                    SongFilter
                                        .favorites,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedFilter =
                                        SongFilter
                                            .favorites;
                                  });
                                },
                              ),
                              FilterChip(
                                label: Text(
                                  'Recent '
                                      '(${_recentSongIds.length})',
                                ),
                                avatar: const Icon(
                                  Icons.history,
                                  size: 18,
                                ),
                                selected:
                                _selectedFilter ==
                                    SongFilter.recent,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedFilter =
                                        SongFilter.recent;
                                  });
                                },
                              ),
                              FilterChip(
                                label: const Text(
                                  'Meest gespeeld',
                                ),
                                avatar: const Icon(
                                  Icons.bar_chart,
                                  size: 18,
                                ),
                                selected:
                                _selectedFilter ==
                                    SongFilter.mostPlayed,
                                onSelected: (_) {
                                  setState(() {
                                    _selectedFilter =
                                        SongFilter.mostPlayed;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  switch (
                                  _selectedFilter
                                  ) {
                                    SongFilter.all =>
                                    'Mijn liedjes',
                                    SongFilter.favorites =>
                                    'Mijn favorieten',
                                    SongFilter.recent =>
                                    'Recent afgespeeld',
                                    SongFilter.mostPlayed =>
                                    'Meest afgespeeld',
                                  },
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                    fontWeight:
                                    FontWeight
                                        .bold,
                                  ),
                                ),
                              ),
                              Text(
                                '${displayedSongs.length} '
                                    'gevonden',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  if (displayedSongs.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(
                        hasSearchQuery:
                        _searchQuery.isNotEmpty,
                        isFavoritesFilter:
                        _selectedFilter ==
                            SongFilter.favorites,
                        isRecentFilter:
                        _selectedFilter ==
                            SongFilter.recent,
                        isMostPlayedFilter:
                        _selectedFilter ==
                            SongFilter.mostPlayed,
                        onCreateSong: () {
                          _openEditor();
                        },
                      ),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        screenWidth >= 700 ? 28 : 16,
                        0,
                        screenWidth >= 700 ? 28 : 16,
                        110,
                      ),
                      sliver: SliverGrid(
                        gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                          crossAxisCount,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          mainAxisExtent: 270,
                        ),
                        delegate:
                        SliverChildBuilderDelegate(
                              (context, index) {
                            final song =
                            displayedSongs[index];

                            return TweenAnimationBuilder<double>(
                              duration: Duration(
                                milliseconds: 220 + (index * 35),
                              ),
                              tween: Tween<double>(
                                begin: 0,
                                end: 1,
                              ),
                              curve: Curves.easeOutCubic,
                              builder: (
                                  context,
                                  value,
                                  child,
                                  ) {
                                return Opacity(
                                  opacity: value,
                                  child: Transform.translate(
                                    offset: Offset(
                                      0,
                                      18 * (1 - value),
                                    ),
                                    child: child,
                                  ),
                                );
                              },
                              child: _SongCard(
                                song: song,
                                playCount:
                                _playCounts[song.id] ?? 0,
                                onTap: () {
                                  _openViewer(song);
                                },
                                onEdit: () {
                                  _openEditor(song);
                                },
                                onDelete: () {
                                  _deleteSong(song);
                                },
                                onToggleFavorite: () {
                                  _toggleFavorite(song);
                                },
                              ),
                            );
                          },
                          childCount:
                          displayedSongs.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SyncStatusCard extends StatelessWidget {
  const _SyncStatusCard({
    required this.isRefreshing,
    required this.onRefresh,
  });

  final bool isRefreshing;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isRefreshing
                ? const SizedBox(
              key: ValueKey('loading'),
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
                : Icon(
              key: const ValueKey('ready'),
              Icons.cloud_done_outlined,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  isRefreshing
                      ? 'Bibliotheek vernieuwen'
                      : 'Bibliotheek beschikbaar',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isRefreshing
                      ? 'Even geduld...'
                      : 'Je liedjes en setlists staan lokaal opgeslagen.',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Vernieuwen',
            onPressed:
            isRefreshing ? null : onRefresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}

class _HomeActionButton extends StatelessWidget {
  const _HomeActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 2,
          vertical: 6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 21,
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({
    required this.totalSongs,
    required this.favoriteSongs,
    required this.onCreateSong,
  });

  final int totalSongs;
  final int favoriteSongs;
  final VoidCallback onCreateSong;

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
          final isWide =
              constraints.maxWidth >= 650;

          final information = Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                'Welkom bij ChordFlow',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Beheer je songteksten, akkoorden '
                    'en favoriete nummers op één plek.',
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatisticChip(
                    icon: Icons
                        .library_music_outlined,
                    label: '$totalSongs liedjes',
                  ),
                  _StatisticChip(
                    icon: Icons.favorite,
                    label:
                    '$favoriteSongs favorieten',
                  ),
                ],
              ),
            ],
          );

          final button = FilledButton.icon(
            onPressed: onCreateSong,
            icon: const Icon(Icons.add),
            label: const Text('Nieuw lied'),
          );

          if (isWide) {
            return Row(
              children: [
                Expanded(child: information),
                const SizedBox(width: 24),
                button,
              ],
            );
          }

          return Column(
            crossAxisAlignment:
            CrossAxisAlignment.stretch,
            children: [
              information,
              const SizedBox(height: 20),
              button,
            ],
          );
        },
      ),
    );
  }
}

class _StatisticChip extends StatelessWidget {
  const _StatisticChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
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
          Icon(icon, size: 18),
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

class _SongCard extends StatelessWidget {
  const _SongCard({
    required this.song,
    required this.playCount,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleFavorite,
  });

  final Song song;
  final int playCount;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final titleLetter = song.title.trim().isEmpty
        ? '?'
        : song.title.trim()[0].toUpperCase();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
          Row(
          children: [
          CircleAvatar(
          radius: 24,
            backgroundColor:
            Theme.of(context)
                .colorScheme
                .primaryContainer,
            child: Text(
              titleLetter,
              style: const TextStyle(
                fontSize: 20,
                fontWeight:
                FontWeight.bold,
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: song.favorite
                ? 'Verwijder uit favorieten'
                : 'Voeg toe aan favorieten',
            onPressed:
            onToggleFavorite,
            icon: Icon(
              song.favorite
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: song.favorite
                  ? Theme.of(context)
                  .colorScheme
                  .primary
                  : null,
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                onEdit();
              }

              if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (_) {
              return const [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                      ),
                      SizedBox(width: 10),
                      Text('Bewerken'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons
                            .delete_outline,
                      ),
                      SizedBox(width: 10),
                      Text('Verwijderen'),
                    ],
                  ),
                ),
              ];
            },
          ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          song.title,
          maxLines: 1,
          overflow:
          TextOverflow.ellipsis,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          song.artist.trim().isEmpty
              ? 'Onbekende artiest'
              : song.artist,
          maxLines: 1,
          overflow:
          TextOverflow.ellipsis,
        ),
        const Spacer(),
        Row(
          crossAxisAlignment:
          CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (song.genre.trim().isNotEmpty)
                    Chip(
                      visualDensity:
                      VisualDensity.compact,
                      avatar: const Icon(
                        Icons.category_outlined,
                        size: 16,
                      ),
                      label: Text(
                        song.genre,
                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,
                      ),
                    ),
                  if (song.originalKey != null &&
                      song.originalKey!.isNotEmpty)
                    Chip(
                      visualDensity:
                      VisualDensity.compact,
                      avatar: const Icon(
                        Icons.piano,
                        size: 16,
                      ),
                      label: Text(
                        'Key ${song.originalKey}',
                      ),
                    ),
                  if (playCount > 0)
                    Chip(
                      visualDensity:
                      VisualDensity.compact,
                      avatar: const Icon(
                        Icons.play_arrow,
                        size: 16,
                      ),
                      label: Text('$playCount'),
                    ),
                  for (final tag in song.tags.take(2))
                    Chip(
                      visualDensity:
                      VisualDensity.compact,
                      avatar: const Icon(
                        Icons.sell_outlined,
                        size: 15,
                      ),
                      label: Text(
                        tag,
                        maxLines: 1,
                        overflow:
                        TextOverflow.ellipsis,
                      ),
                    ),
                  if (song.tags.length > 2)
                    Chip(
                      visualDensity:
                      VisualDensity.compact,
                      label: Text(
                        '+${song.tags.length - 2}',
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(
                bottom: 8,
              ),
              child: Icon(
                Icons.arrow_forward,
                color: Theme.of(context)
                    .colorScheme
                    .primary,
              ),
            ),
          ],
        ),
      ],
    ),
    ),
    ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.hasSearchQuery,
    required this.isFavoritesFilter,
    required this.isRecentFilter,
    required this.isMostPlayedFilter,
    required this.onCreateSong,
  });

  final bool hasSearchQuery;
  final bool isFavoritesFilter;
  final bool isRecentFilter;
  final bool isMostPlayedFilter;
  final VoidCallback onCreateSong;

  @override
  Widget build(BuildContext context) {
    String title;
    String description;
    IconData icon;

    if (hasSearchQuery) {
      title = 'Geen liedjes gevonden';
      description =
      'Probeer een andere titel of artiest.';
      icon = Icons.search_off;
    } else if (isFavoritesFilter) {
      title = 'Nog geen favorieten';
      description =
      'Tik op het hartje bij een lied om '
          'het hier terug te vinden.';
      icon = Icons.favorite_border;
    } else if (isRecentFilter) {
      title = 'Nog niets afgespeeld';
      description =
      'Open een lied en het verschijnt '
          'automatisch in deze lijst.';
      icon = Icons.history;
    } else if (isMostPlayedFilter) {
      title = 'Nog geen afspeelgegevens';
      description =
      'Open liedjes om je meest afgespeelde '
          'nummers hier te zien.';
      icon = Icons.bar_chart;
    } else {
      title = 'Je bibliotheek is leeg';
      description =
      'Voeg je eerste lied met songtekst '
          'en akkoorden toe.';
      icon = Icons.library_music_outlined;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 76,
              color: Theme.of(context)
                  .colorScheme
                  .primary,
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(
                fontWeight:
                FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
            ),
            if (!hasSearchQuery &&
                !isFavoritesFilter &&
                !isRecentFilter &&
                !isMostPlayedFilter) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onCreateSong,
                icon: const Icon(Icons.add),
                label: const Text(
                  'Eerste lied maken',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}