import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/song.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';
import 'ai_chat_screen.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({
    super.key,
    required this.song,
  });

  final Song song;

  @override
  State<AiAssistantScreen> createState() =>
      _AiAssistantScreenState();
}

class _AiAssistantScreenState
    extends State<AiAssistantScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final actions = <_AiAction>[
      const _AiAction(
        icon: Icons.music_note_outlined,
        title: 'Betere toonsoort',
        subtitle: 'Krijg advies voor een prettigere toonsoort.',
      ),
      const _AiAction(
        icon: Icons.mic_none_outlined,
        title: 'Zangbereik',
        subtitle: 'Bekijk welke toonsoort beter bij een stem past.',
      ),
      const _AiAction(
        icon: Icons.tune,
        title: 'Capo advies',
        subtitle: 'Vind een eenvoudige capo-positie voor gitaar.',
      ),
      const _AiAction(
        icon: Icons.piano_outlined,
        title: 'Akkoordsuggesties',
        subtitle: 'Krijg ideeën voor alternatieve of volgende akkoorden.',
      ),
      const _AiAction(
        icon: Icons.auto_awesome_outlined,
        title: 'Intro genereren',
        subtitle: 'Laat een passend intro-idee voor dit lied maken.',
      ),
      const _AiAction(
        icon: Icons.queue_music_outlined,
        title: 'Outro genereren',
        subtitle: 'Laat een passend einde voor het lied voorstellen.',
      ),
      const _AiAction(
        icon: Icons.summarize_outlined,
        title: 'Lied samenvatten',
        subtitle: 'Maak een korte muzikale samenvatting van het lied.',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Assistant',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              children: [
                _AiHeaderCard(song: widget.song),
                const SizedBox(height: 14),
                _AiChatCard(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AiChatScreen(
                          song: widget.song,
                        ),
                      ),
                    );
                  },
                ),
                if (_isLoading) ...[
                  const SizedBox(height: 14),
                  const LinearProgressIndicator(),
                ],
                const SizedBox(height: 22),
                Text(
                  'Wat wil je doen?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...actions.map(
                      (action) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AiActionCard(
                      action: action,
                      onTap: () {
                        _runAiAction(action.title);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Future<void> _runAiAction(
      String actionTitle,
      ) async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      late final String result;
      late final String resultTitle;
      late final IconData resultIcon;

      switch (actionTitle) {
        case 'Betere toonsoort':
          result = await AiService.suggestBetterKey(widget.song);
          resultTitle = 'Toonsoortadvies';
          resultIcon = Icons.music_note_outlined;
          break;
        case 'Zangbereik':
          result = await AiService.vocalRangeAdvice(widget.song);
          resultTitle = 'Zangbereikadvies';
          resultIcon = Icons.mic_none_outlined;
          break;
        case 'Capo advies':
          result = await AiService.capoAdvice(widget.song);
          resultTitle = 'Capo advies';
          resultIcon = Icons.tune;
          break;
        case 'Akkoordsuggesties':
          result = await AiService.chordSuggestions(widget.song);
          resultTitle = 'Akkoordsuggesties';
          resultIcon = Icons.piano_outlined;
          break;
        case 'Intro genereren':
          result = await AiService.generateIntro(widget.song);
          resultTitle = 'AI Intro';
          resultIcon = Icons.auto_awesome_outlined;
          break;
        case 'Outro genereren':
          result = await AiService.generateOutro(widget.song);
          resultTitle = 'AI Outro';
          resultIcon = Icons.queue_music_outlined;
          break;
        case 'Lied samenvatten':
          result = await AiService.summarizeSong(widget.song);
          resultTitle = 'AI-samenvatting';
          resultIcon = Icons.summarize_outlined;
          break;
        default:
          throw Exception('Deze AI-functie is nog niet beschikbaar.');
      }

      if (!mounted) return;

      await _showAiResult(
        title: resultTitle,
        icon: resultIcon,
        result: result,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('AI-aanvraag mislukt: $error'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _replaceCurrentSong(
      String result,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.warning_amber_rounded,
          ),
          title: const Text(
            'Huidig lied vervangen?',
          ),
          content: const Text(
            'De huidige songtekst en akkoorden worden vervangen door het AI-resultaat.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Annuleren',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Vervangen',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final updatedSong = widget.song.copyWith(
      content: result,
      updatedAt: DateTime.now(),
    );

    await StorageService.saveSong(
      updatedSong,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Lied bijgewerkt met AI-resultaat.',
        ),
      ),
    );

    Navigator.pop(
      context,
      true,
    );
  }

  Future<void> _createAiSong(
      String result,
      ) async {
    final now = DateTime.now();

    final newSong = widget.song.copyWith(
      id: '${widget.song.id}_ai_${now.millisecondsSinceEpoch}',
      title: '${widget.song.title} (AI versie)',
      content: result,
      favorite: false,
      createdAt: now,
      updatedAt: now,
    );

    await StorageService.saveSong(
      newSong,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '"${newSong.title}" is opgeslagen.',
        ),
      ),
    );
  }

  Future<void> _showAiResult({
    required String title,
    required IconData icon,
    required String result,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (bottomSheetContext) {
        return FractionallySizedBox(
          heightFactor: 0.78,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                4,
                20,
                24,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        icon,
                        color: Theme.of(context)
                            .colorScheme
                            .primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(
                            bottomSheetContext,
                          );
                        },
                        icon: const Icon(
                          Icons.close,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final useFullWidth =
                          constraints.maxWidth < 520;

                      Widget wrapButton(Widget child) {
                        if (!useFullWidth) {
                          return child;
                        }

                        return SizedBox(
                          width: double.infinity,
                          child: child,
                        );
                      }

                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          wrapButton(
                            FilledButton.tonalIcon(
                              onPressed: () async {
                                await Clipboard.setData(
                                  ClipboardData(
                                    text: result,
                                  ),
                                );

                                if (!mounted) {
                                  return;
                                }

                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'AI-resultaat gekopieerd.',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.copy_outlined,
                              ),
                              label: const Text(
                                'Kopiëren',
                              ),
                            ),
                          ),
                          wrapButton(
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(
                                  bottomSheetContext,
                                );

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        AiChatScreen(
                                          song: widget.song,
                                        ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.chat_bubble_outline,
                              ),
                              label: const Text(
                                'Verder in AI Chat',
                              ),
                            ),
                          ),
                          wrapButton(
                            FilledButton.tonalIcon(
                              onPressed: () async {
                                Navigator.pop(
                                  bottomSheetContext,
                                );

                                await _createAiSong(
                                  result,
                                );
                              },
                              icon: const Icon(
                                Icons.library_add_outlined,
                              ),
                              label: const Text(
                                'Nieuw lied maken',
                              ),
                            ),
                          ),
                          wrapButton(
                            FilledButton.icon(
                              onPressed: () async {
                                Navigator.pop(
                                  bottomSheetContext,
                                );

                                await _replaceCurrentSong(
                                  result,
                                );
                              },
                              icon: const Icon(
                                Icons.edit_document,
                              ),
                              label: const Text(
                                'Huidig lied vervangen',
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: SelectableText(
                        result,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

}

class _AiHeaderCard extends StatelessWidget {
  const _AiHeaderCard({
    required this.song,
  });

  final Song song;

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
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 31,
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            child: const Icon(
              Icons.smart_toy_outlined,
              size: 32,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ChordFlow AI',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (song.artist.trim().isNotEmpty)
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiChatCard extends StatelessWidget {
  const _AiChatCard({
    required this.onTap,
  });

  final VoidCallback onTap;

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
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .tertiaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.chat_bubble_outline,
                  color: Theme.of(context)
                      .colorScheme
                      .tertiary,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Open AI Chat',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text('Stel zelf vragen over dit lied.'),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiActionCard extends StatelessWidget {
  const _AiActionCard({
    required this.action,
    required this.onTap,
  });

  final _AiAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  action.icon,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      action.subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiAction {
  const _AiAction({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}
