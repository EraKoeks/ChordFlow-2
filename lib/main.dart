import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'services/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.initFlutter();
  await StorageService.initialize();

  final savedThemeMode =
  await ThemeService.loadThemeMode();

  runApp(
    ChordFlowApp(
      initialThemeMode: savedThemeMode,
    ),
  );
}

class ChordFlowApp extends StatefulWidget {
  const ChordFlowApp({
    super.key,
    required this.initialThemeMode,
  });

  final ThemeMode initialThemeMode;

  @override
  State<ChordFlowApp> createState() =>
      _ChordFlowAppState();
}

class _ChordFlowAppState
    extends State<ChordFlowApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
  }

  Future<void> _changeThemeMode(
      ThemeMode themeMode,
      ) async {
    setState(() {
      _themeMode = themeMode;
    });

    await ThemeService.saveThemeMode(
      themeMode,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChordFlow',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      home: StreamBuilder<User?>(
        stream: AuthService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const _AuthLoadingScreen();
          }

          if (snapshot.data == null) {
            return const AuthScreen();
          }

          return HomeScreen(
            themeMode: _themeMode,
            onThemeChanged: _changeThemeMode,
          );
        },
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: Colors.indigo,
      textTheme: GoogleFonts.interTextTheme(),
      scaffoldBackgroundColor:
      const Color(0xFFF6F7FB),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme:
      InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed:
      const Color(0xFF4FE1FF),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ),
      scaffoldBackgroundColor:
      const Color(0xFF0D0F12),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme:
      InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
