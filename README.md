# 🎸 ChordFlow 2

**ChordFlow 2** is a modern Flutter application for musicians, bands, singers and worship teams.

It combines song and chord management, live performance tools, setlists, PDF export, offline storage and Gemini-powered AI assistance in one responsive application.

Built with **Flutter, Dart, Firebase and Gemini AI**.

---

## 📱 Screenshots

<p align="center">
  <img src="screenshots/home.jpg" width="250" alt="ChordFlow Home">
  <img src="screenshots/song.jpg" width="250" alt="Song Editor">
  <img src="screenshots/songviewer.jpg" width="250" alt="Song Viewer">
</p>

<p align="center">
  <img src="screenshots/setlist.jpg" width="250" alt="Setlists">
  <img src="screenshots/ai_assistent.jpg" width="250" alt="AI Assistant">
</p>

---

## ✨ Key Features

### 🎵 Song Management

- Create and edit songs
- ChordPro support
- Live chord transposition
- Genres and tags
- Favorites
- Smart search
- Recently played songs
- Most played songs
- ChordPro import/export

### 🎸 Live Performance

- Performance Mode
- Setlist Performance Mode
- Auto-scroll
- Live transpose
- Setlists
- Responsive interface for phone and tablet

### 🤖 ChordFlow AI

Powered by **Firebase AI Logic + Gemini**.

ChordFlow AI can:

- Suggest better song keys
- Give vocal range advice
- Recommend capo positions
- Suggest alternative chords
- Analyse chord progressions
- Generate intro and outro ideas
- Create piano accompaniment ideas
- Simplify chords for beginners
- Summarize songs
- Translate lyrics while preserving chord markers where possible
- Answer questions about the current song

The application also includes:

- AI Assistant
- AI Chat
- Conversation memory during the active chat
- AI Quick Actions
- Favorite AI prompts
- Copy AI results
- Create a new song from an AI result
- Replace the current song with an AI result

---

## 💾 Storage & Export

ChordFlow 2 supports:

- Local Hive storage
- JSON backup and restore
- ChordPro import/export
- Song PDF export
- Setlist PDF export

Core songbook functionality remains available locally when cloud features are unavailable.

---

## 🔐 Firebase

ChordFlow 2 uses:

- Firebase Core
- Firebase Authentication
- Firebase App Check
- Firebase AI Logic
- Gemini

---

## 🛠️ Tech Stack

- Flutter
- Dart
- Material 3
- Firebase
- Gemini AI
- Hive
- Shared Preferences
- Google Fonts
- PDF / Printing
- File Picker
- Share Plus

---

## 🖥️ Main Screens

- Authentication
- Home
- Song Editor
- Song Viewer
- Performance Mode
- Setlists
- Setlist Performance Mode
- Settings
- AI Assistant
- AI Chat

---

## 🧱 Architecture

The project separates the application into models, screens, services, utilities and reusable widgets.

```text
lib/
├── models/
│   ├── ai_prompt.dart
│   ├── setlist.dart
│   └── song.dart
│
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
│
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
│
├── utils/
│   ├── chord_transposer.dart
│   └── chordpro_parser.dart
│
├── widgets/
│   ├── chord_line.dart
│   ├── chord_lyric_line.dart
│   ├── live_song_preview.dart
│   └── song_card.dart
│
├── firebase_options.dart
└── main.dart
```

---

## 🚀 Project Goal

ChordFlow 2 was built as a portfolio project to demonstrate the development of a complete Flutter application with local storage, Firebase integration, AI functionality, responsive UI and tools designed for real-world use.

The project demonstrates experience with:

- Flutter application architecture
- State and data management
- Local persistent storage
- Firebase integration
- Authentication
- AI integration with Gemini
- File import and export
- PDF generation
- Responsive Flutter UI
- Building reusable widgets and services

---

## 📌 Status

ChordFlow 2 is actively developed and may receive additional improvements and features.

---

## 👨‍💻 Developer

Developed by **Eithrick Koeks**

Flutter / Dart Developer
