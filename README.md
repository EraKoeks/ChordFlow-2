ChordFlow 2

ChordFlow 2 is a modern Flutter app for musicians, bands, worship teams and singers.

The app combines song and chord management, setlists, performance tools, PDF export, local storage, Firebase Authentication and Gemini-powered AI assistance in one responsive application.

Highlights

Modern Flutter + Material 3 interface

Responsive layout for phone, tablet, web and desktop

Light and dark mode

Firebase Authentication

Firebase App Check

Firebase AI Logic with Gemini

Local Hive storage

ChordPro support

Live transpose

Performance Mode

Setlists

Auto-scroll

Favorites

Recently played songs

Most played songs

Genres and tags

Smart search

PDF export

ChordPro import/export

JSON backup and restore

AI Assistant

AI Chat with conversation memory

AI Quick Actions

Favorite AI prompts

AI-generated key, capo, vocal and chord advice

AI intro/outro generation

Copy AI results

Create a new song from an AI result

Replace the current song with an AI result

AI Features

ChordFlow AI can help musicians with tasks such as:

Suggesting a better key

Giving vocal range advice

Giving capo advice

Suggesting alternative chords

Generating an intro

Generating an outro

Summarizing a song

Simplifying chords for beginners

Creating piano accompaniment ideas

Analysing chord progressions

Translating lyrics while preserving chord markers where possible

Answering free-form questions about the current song

The AI Chat keeps the context of the current song and remembers previous messages within the active chat session.

Main Screens

Authentication

Home

Song Editor

Song Viewer

Performance Mode

Setlists

Setlist Performance Mode

Settings

AI Assistant

AI Chat

Tech Stack

Flutter

Dart

Material 3

Hive

Shared Preferences

Firebase Core

Firebase Authentication

Firebase App Check

Firebase AI Logic

Gemini

Google Fonts

PDF

Printing

File Picker

Share Plus

Project Structure

lib/
├── models/
│   ├── ai_prompt.dart
│   ├── setlist.dart
│   └── song.dart
├── screens/
│   ├── ai_assistant_screen.dart
│   ├── ai_chat_screen.dart
│   ├── auth_screen.dart
│   ├── home_screen.dart
│   ├── performance_screen.dart
│   ├── setlist_performance_screen.dart
│   ├── setlists_screen.dart
│   ├── settings_screen.dart
│   ├── song_editor_screen.dart
│   └── song_viewer_screen.dart
├── services/
│   ├── ai_prompt_service.dart
│   ├── ai_service.dart
│   ├── auth_service.dart
│   ├── backup_service.dart
│   ├── chordpro_export_service.dart
│   ├── chordpro_import_service.dart
│   ├── play_count_service.dart
│   ├── recent_service.dart
│   ├── setlist_pdf_service.dart
│   ├── song_pdf_service.dart
│   ├── storage_service.dart
│   └── theme_service.dart
├── utils/
│   ├── chord_transposer.dart
│   └── chordpro_parser.dart
├── widgets/
│   ├── chord_line.dart
│   ├── chord_lyric_line.dart
│   ├── live_song_preview.dart
│   └── song_card.dart
├── firebase_options.dart
└── main.dart

ChordPro Example

{title: Amazing Grace}
{artist: Traditional}
{key: G}
{tempo: 72}
{time: 4/4}

{start_of_verse: Verse 1}
[G]Amazing [C]grace
How [G]sweet the [D]sound
{end_of_verse}

Getting Started

Clone the repository:

git clone https://github.com/EraKoeks/ChordFlow-2.git
cd ChordFlow-2

Install packages:

flutter pub get

Check the project:

flutter analyze

Run the app:

flutter run

Firebase Setup

ChordFlow 2 uses Firebase Authentication, App Check and Firebase AI Logic.

For your own fork:

flutterfire configure

Then configure:

Firebase Authentication

App Check

Firebase AI Logic

Gemini Developer API or another supported Firebase AI provider

Use your own Firebase project configuration.

Local Storage

Songs, setlists and AI prompt favorites are stored locally with Hive.

The application is designed to keep core songbook functionality available even when cloud features are unavailable.

Backup and Export

ChordFlow 2 supports:

JSON backup

JSON restore

ChordPro import

ChordPro export

Song PDF export

Setlist PDF export

Android Release

The Android application ID is:

com.erakoeks.chordflow2

Create a release build with:

flutter build appbundle --release

or:

flutter build apk --release

Never commit your keystore or android/key.properties.

Roadmap

Full multi-device cloud sync

Persisted AI chat history

Shared setlists

More AI arranging tools

Additional accessibility improvements

Developer

Built by Eithrick Koeks with Flutter and Dart.

GitHub: EraKoeks

Status

ChordFlow 2 is an active portfolio project and release candidate.