import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/ai_service.dart';
import '../models/ai_prompt.dart';
import '../services/ai_prompt_service.dart';
import 'package:uuid/uuid.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({
    super.key,
    required this.song,
  });

  final Song song;

  @override
  State<AiChatScreen> createState() =>
      _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller =
  TextEditingController();

  final ScrollController _scrollController =
  ScrollController();

  final List<_ChatMessage> _messages = [];

  late final ChatSession _chat;

  bool _isSending = false;
  final List<AiPrompt> _favoritePrompts = [];

  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();

    _chat = AiService.startSongChat(
      widget.song,
    );
    _loadFavorites();

    _messages.add(
      _ChatMessage(
        text:
        'Hoi! Ik ben ChordFlow AI. Vraag me iets over "${widget.song.title}". Ik onthoud wat we in deze chat bespreken.',
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendQuickPrompt(
      String prompt,
      ) {
    if (_isSending) {
      return;
    }

    _controller.text = prompt;
    _sendMessage();
  }

  Future<void> _loadFavorites() async {
    _favoritePrompts
      ..clear()
      ..addAll(
        AiPromptService.getAllPrompts(),
      );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveFavorite({
    required String name,
    required String prompt,
  }) async {
    final existing = _favoritePrompts.where(
          (favorite) =>
      favorite.prompt.trim().toLowerCase() ==
          prompt.trim().toLowerCase(),
    );

    if (existing.isNotEmpty) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Deze prompt staat al bij je favorieten.',
          ),
        ),
      );
      return;
    }

    final favorite = AiPrompt(
      id: _uuid.v4(),
      name: name,
      prompt: prompt,
      createdAt: DateTime.now(),
      lastUsed: DateTime.now(),
    );

    await AiPromptService.savePrompt(favorite);

    await _loadFavorites();
  }

  Future<void> _renameFavorite(
      AiPrompt favorite,
      ) async {
    final controller = TextEditingController(
      text: favorite.name,
    );

    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Favoriet hernoemen',
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Naam',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Annuleren'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  controller.text.trim(),
                );
              },
              child: const Text('Opslaan'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (newName == null || newName.isEmpty) {
      return;
    }

    await AiPromptService.savePrompt(
      favorite.copyWith(
        name: newName,
        lastUsed: DateTime.now(),
      ),
    );

    await _loadFavorites();
  }

  Future<void> _deleteFavorite(
      AiPrompt favorite,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.delete_outline,
          ),
          title: const Text(
            'Favoriet verwijderen',
          ),
          content: Text(
            'Weet je zeker dat je "${favorite.name}" wilt verwijderen?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Annuleren'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
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

    await AiPromptService.deletePrompt(
      favorite.id,
    );

    await _loadFavorites();
  }

  Future<void> _showFavoriteMenu(
      AiPrompt favorite,
      ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
              bottom: 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.edit_outlined,
                  ),
                  title: const Text(
                    'Hernoemen',
                  ),
                  onTap: () {
                    Navigator.pop(
                      bottomSheetContext,
                      'rename',
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context)
                        .colorScheme
                        .error,
                  ),
                  title: Text(
                    'Verwijderen',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .error,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(
                      bottomSheetContext,
                      'delete',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) {
      return;
    }

    if (action == 'rename') {
      await _renameFavorite(favorite);
    } else if (action == 'delete') {
      await _deleteFavorite(favorite);
    }
  }

  Future<void> _sendMessage() async {
    final question = _controller.text.trim();

    if (question.isEmpty || _isSending) {
      return;
    }

    setState(() {
      _messages.add(
        _ChatMessage(
          text: question,
          isUser: true,
        ),
      );

      _controller.clear();
      _isSending = true;
    });

    _scrollToBottom();

    try {
      final response = await _chat.sendMessage(
        Content.text(question),
      );

      final answer = response.text?.trim();

      if (!mounted) {
        return;
      }

      setState(() {
        _messages.add(
          _ChatMessage(
            text: answer == null || answer.isEmpty
                ? 'Gemini gaf geen antwoord terug.'
                : answer,
            isUser: false,
          ),
        );
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _messages.add(
          _ChatMessage(
            text:
            'De AI-aanvraag is mislukt. Probeer het opnieuw.\n\n$error',
            isUser: false,
            isError: true,
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });

        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback(
          (_) {
        if (!_scrollController.hasClients) {
          return;
        }

        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration:
          const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const Text(
              'ChordFlow AI Chat',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.song.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
              Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding:
                const EdgeInsets.fromLTRB(
                  14,
                  16,
                  14,
                  20,
                ),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _MessageBubble(
                    message: _messages[index],
                  );
                },
              ),
            ),
            if (_favoritePrompts.isNotEmpty)
              SizedBox(
                height: 52,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _favoritePrompts.length,
                  itemBuilder: (context, index) {
                    final favorite = _favoritePrompts[index];

                    return Padding(
                      padding: const EdgeInsets.only(
                        right: 8,
                      ),
                      child: GestureDetector(
                        onLongPress: () {
                          _showFavoriteMenu(
                            favorite,
                          );
                        },
                        child: ActionChip(
                          avatar: const Icon(
                            Icons.star,
                            size: 18,
                          ),
                          label: Text(
                            favorite.name,
                          ),
                          onPressed: _isSending
                              ? null
                              : () async {
                            await AiPromptService
                                .updateLastUsed(
                              favorite,
                            );

                            _sendQuickPrompt(
                              favorite.prompt,
                            );

                            await _loadFavorites();
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),

            _QuickActions(
              enabled: !_isSending,
              onPromptSelected: _sendQuickPrompt,
              onSaveFavorite: _saveFavorite,
            ),
            if (_isSending)
              const LinearProgressIndicator(),
            _ChatInput(
              controller: _controller,
              enabled: !_isSending,
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.enabled,
    required this.onPromptSelected,
    required this.onSaveFavorite,
  });

  final bool enabled;
  final ValueChanged<String> onPromptSelected;
  final Future<void> Function({
  required String name,
  required String prompt,
  }) onSaveFavorite;

  @override
  Widget build(BuildContext context) {
    const actions = [
      (
      icon: Icons.music_note_outlined,
      label: 'Maak makkelijker',
      prompt:
      'Maak de akkoorden makkelijker voor een beginner.',
      ),
      (
      icon: Icons.piano_outlined,
      label: 'Piano',
      prompt:
      'Maak een eenvoudige pianobegeleiding voor dit lied.',
      ),
      (
      icon: Icons.mic_none_outlined,
      label: 'Zangtips',
      prompt:
      'Geef praktische zangtips voor dit lied.',
      ),
      (
      icon: Icons.analytics_outlined,
      label: 'Analyse',
      prompt:
      'Analyseer de akkoordprogressie en leg eenvoudig uit waarom die werkt.',
      ),
      (
      icon: Icons.translate,
      label: 'Vertalen',
      prompt:
      'Vertaal de songtekst naar het Engels zonder de betekenis te veranderen. Behoud akkoordmarkeringen waar mogelijk.',
      ),
    ];

    return Material(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          12,
          8,
          12,
          6,
        ),
        child: Row(
          children: [
            for (final action in actions)
              Padding(
                padding: const EdgeInsets.only(
                  right: 8,
                ),
                child: GestureDetector(
                  onLongPress: enabled
                      ? () async {
                    final controller = TextEditingController(
                      text: action.label,
                    );

                    final name = await showDialog<String>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: const Text(
                            'Opslaan als favoriet',
                          ),
                          content: TextField(
                            controller: controller,
                            decoration: const InputDecoration(
                              labelText: 'Naam',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('Annuleren'),
                            ),
                            FilledButton(
                              onPressed: () {
                                Navigator.pop(
                                  context,
                                  controller.text.trim(),
                                );
                              },
                              child: const Text('Opslaan'),
                            ),
                          ],
                        );
                      },
                    );

                    if (name != null && name.isNotEmpty) {
                      await onSaveFavorite(
                        name: name,
                        prompt: action.prompt,
                      );
                    }
                  }
                      : null,
                  child: ActionChip(
                    avatar: Icon(
                      action.icon,
                      size: 18,
                    ),
                    label: Text(action.label),
                    onPressed: enabled
                        ? () {
                      onPromptSelected(
                        action.prompt,
                      );
                    }
                        : null,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  const _ChatInput({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          12,
          10,
          12,
          12,
        ),
        child: Row(
          crossAxisAlignment:
          CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 5,
                textInputAction:
                TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText:
                  'Vraag iets over dit lied...',
                  prefixIcon:
                  Icon(Icons.auto_awesome),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              onPressed: enabled ? onSend : null,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
  });

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final alignment = message.isUser
        ? Alignment.centerRight
        : Alignment.centerLeft;

    final color = message.isError
        ? Theme.of(context)
        .colorScheme
        .errorContainer
        : message.isUser
        ? Theme.of(context)
        .colorScheme
        .primaryContainer
        : Theme.of(context)
        .colorScheme
        .surfaceContainerHighest;

    return Align(
      alignment: alignment,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 700,
        ),
        margin: const EdgeInsets.only(
          bottom: 10,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius:
          BorderRadius.circular(18),
        ),
        child: SelectableText(
          message.text,
          style: const TextStyle(
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
  });

  final String text;
  final bool isUser;
  final bool isError;
}
