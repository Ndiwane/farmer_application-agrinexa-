import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:agrinexa/l10n/app_localizations.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';

/// Handle background FCM messages when app is terminated
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Load saved preferences
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('darkMode') ?? false;
  final language = prefs.getString('language') ?? 'en';

  runApp(AgriNexaApp(
    initialDarkMode: isDarkMode,
    initialLanguage: language,
  ));
}

class AgriNexaApp extends StatefulWidget {
  final bool initialDarkMode;
  final String initialLanguage;

  const AgriNexaApp({
    super.key,
    this.initialDarkMode = false,
    this.initialLanguage = 'en',
  });

  @override
  State<AgriNexaApp> createState() => _AgriNexaAppState();

  /// Allow child widgets to access app state
  static _AgriNexaAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_AgriNexaAppState>();
}

class _AgriNexaAppState extends State<AgriNexaApp> {
  late bool _isDarkMode;
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.initialDarkMode;
    _locale = Locale(widget.initialLanguage);
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    await NotificationService().initialize();
  }

  // Getters
  bool get isDarkMode => _isDarkMode;
  String get language => _locale.languageCode;

  /// Toggle between light and dark mode
  void toggleTheme() async {
    setState(() => _isDarkMode = !_isDarkMode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _isDarkMode);
  }

  /// Set language — 'en' or 'fr'
  void setLanguage(String lang) async {
    setState(() => _locale = Locale(lang));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
  }

  @override
  Widget build(BuildContext context) {
    const pageTransitions = PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    );

    return MaterialApp(
      title: 'AgriNexa',
      debugShowCheckedModeBanner: false,

      // ── Localization setup ────────────────────────────────────────────
      locale: _locale,
      localizationsDelegates: [
        AppLocalizations.delegate,              // Our translations
        GlobalMaterialLocalizations.delegate,   // Material widgets
        GlobalWidgetsLocalizations.delegate,    // Base widgets
        GlobalCupertinoLocalizations.delegate,  // iOS style widgets
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('fr'), // French
      ],

      theme: AppTheme.lightTheme.copyWith(
        pageTransitionsTheme: pageTransitions,
      ),
      darkTheme: AppTheme.darkTheme.copyWith(
        pageTransitionsTheme: pageTransitions,
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}