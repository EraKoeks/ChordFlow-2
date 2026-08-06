import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/backup_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  @override
  State<SettingsScreen> createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState
    extends State<SettingsScreen> {
  bool _isExporting = false;
  bool _isImporting = false;

  Future<void> _exportBackup() async {
    if (_isExporting || _isImporting) {
      return;
    }

    setState(() {
      _isExporting = true;
    });

    final result =
    await BackupService.exportBackup();

    if (!mounted) {
      return;
    }

    setState(() {
      _isExporting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
      ),
    );
  }

  Future<void> _importBackup() async {
    if (_isExporting || _isImporting) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.restore,
          ),
          title: const Text(
            'Back-up herstellen',
          ),
          content: const Text(
            'Je huidige liedjes en setlists worden '
                'vervangen door de gegevens uit de back-up.\n\n'
                'Maak eventueel eerst een nieuwe back-up.',
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
              child: const Text('Doorgaan'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isImporting = true;
    });

    final result =
    await BackupService.importBackup();

    if (!mounted) {
      return;
    }

    setState(() {
      _isImporting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
      ),
    );

    if (result.success) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.logout),
          title: const Text('Uitloggen'),
          content: const Text(
            'Weet je zeker dat je wilt uitloggen?',
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
                Navigator.pop(dialogContext, true);
              },
              icon: const Icon(Icons.logout),
              label: const Text('Uitloggen'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await AuthService.signOut();

    if (!mounted) {
      return;
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isBusy =
        _isExporting || _isImporting;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Instellingen',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 750,
            ),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SettingsHeader(
                  themeMode: widget.themeMode,
                ),
                const SizedBox(height: 24),
                _SectionTitle(
                  title: 'Account',
                ),
                const SizedBox(height: 12),
                _AccountCard(
                  user: FirebaseAuth.instance.currentUser,
                  onSignOut: _signOut,
                ),
                const SizedBox(height: 24),
                _SectionTitle(
                  title: 'Weergave',
                ),
                const SizedBox(height: 12),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: RadioGroup<ThemeMode>(
                    groupValue: widget.themeMode,
                    onChanged: (
                        ThemeMode? value,
                        ) {
                      if (value != null) {
                        widget.onThemeChanged(
                          value,
                        );
                      }
                    },
                    child: const Column(
                      children: [
                        RadioListTile<ThemeMode>(
                          value: ThemeMode.system,
                          secondary: Icon(
                            Icons.brightness_auto,
                          ),
                          title: Text(
                            'Systeeminstelling',
                          ),
                          subtitle: Text(
                            'Volgt het thema van je apparaat.',
                          ),
                        ),
                        Divider(height: 1),
                        RadioListTile<ThemeMode>(
                          value: ThemeMode.light,
                          secondary: Icon(
                            Icons.light_mode_outlined,
                          ),
                          title: Text(
                            'Lichte modus',
                          ),
                          subtitle: Text(
                            'Een lichte achtergrond voor overdag.',
                          ),
                        ),
                        Divider(height: 1),
                        RadioListTile<ThemeMode>(
                          value: ThemeMode.dark,
                          secondary: Icon(
                            Icons.dark_mode_outlined,
                          ),
                          title: Text(
                            'Donkere modus',
                          ),
                          subtitle: Text(
                            'Rustiger tijdens repetities en optredens.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _SectionTitle(
                  title: 'Back-up en herstel',
                ),
                const SizedBox(height: 12),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      ListTile(
                        enabled: !isBusy,
                        leading: _isExporting
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child:
                          CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(
                          Icons.upload_file,
                        ),
                        title: const Text(
                          'Back-up exporteren',
                        ),
                        subtitle: const Text(
                          'Bewaar alle liedjes en setlists '
                              'in één JSON-bestand.',
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                        ),
                        onTap:
                        isBusy ? null : _exportBackup,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        enabled: !isBusy,
                        leading: _isImporting
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child:
                          CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(
                          Icons.restore,
                        ),
                        title: const Text(
                          'Back-up herstellen',
                        ),
                        subtitle: const Text(
                          'Herstel liedjes en setlists uit '
                              'een eerder exportbestand.',
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                        ),
                        onTap:
                        isBusy ? null : _importBackup,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius:
                    BorderRadius.circular(16),
                  ),
                  child: const Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Bewaar je back-up bijvoorbeeld '
                              'in Google Drive, OneDrive of e-mail.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _SectionTitle(
                  title: 'Over ChordFlow',
                ),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      const ListTile(
                        leading: Icon(
                          Icons.music_note,
                        ),
                        title: Text('ChordFlow'),
                        subtitle: Text(
                          'Songteksten, akkoorden en '
                              'setlists op één plek.',
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.code,
                        ),
                        title: const Text(
                          'Gebouwd met Flutter',
                        ),
                        subtitle: const Text(
                          'App van Eithrick',
                        ),
                        trailing: Icon(
                          Icons.flutter_dash,
                          color: Theme.of(context)
                              .colorScheme
                              .primary,
                        ),
                      ),
                      const Divider(height: 1),
                      const ListTile(
                        leading: Icon(
                          Icons.info_outline,
                        ),
                        title: Text('Versie'),
                        subtitle: Text('2.0.0'),
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

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.user,
    required this.onSignOut,
  });

  final User? user;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final email = user?.email?.trim();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(
              18,
              14,
              18,
              14,
            ),
            leading: CircleAvatar(
              radius: 26,
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .primaryContainer,
              child: Icon(
                Icons.person_outline,
                color: Theme.of(context)
                    .colorScheme
                    .primary,
              ),
            ),
            title: const Text(
              'Ingelogd account',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              email == null || email.isEmpty
                  ? 'Geen e-mailadres beschikbaar'
                  : email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Uitloggen'),
            subtitle: const Text(
              'Ga terug naar het inlogscherm.',
            ),
            trailing: const Icon(
              Icons.chevron_right,
            ),
            onTap: onSignOut,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({
    required this.themeMode,
  });

  final ThemeMode themeMode;

  String get _themeName {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Lichte modus';
      case ThemeMode.dark:
        return 'Donkere modus';
      case ThemeMode.system:
        return 'Systeeminstelling';
    }
  }

  IconData get _themeIcon {
    switch (themeMode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

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
        borderRadius:
        BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor:
            Theme.of(context)
                .colorScheme
                .primary,
            foregroundColor:
            Theme.of(context)
                .colorScheme
                .onPrimary,
            child: Icon(
              _themeIcon,
              size: 30,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Pas ChordFlow aan',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(
                    fontWeight:
                    FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Huidige keuze: $_themeName',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}