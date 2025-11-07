import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medical_app/routes/app_router.dart';
import 'package:medical_app/services/notification_service.dart';
import 'package:medical_app/providers/language_provider.dart';
import 'package:medical_app/l10n/app_localizations.dart' as app_localizations;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://tavrkrbwrisozmueultj.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRhdnJrcmJ3cmlzb3ptdWV1bHRqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIwNzg3OTUsImV4cCI6MjA3NzY1NDc5NX0._KeimHNHSjOw-LHejt2pvrDrh6h-N-9p7FR7LOBJKTw',
  );

  // Initialize notifications
  await NotificationService.initialize();

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const MedicalApp(),
    ),
  );
}

class MedicalApp extends ConsumerWidget {
  const MedicalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final languageState = ref.watch(languageProvider);

    return MaterialApp.router(
      title: 'CareBridge',
      locale: languageState.locale,
      localizationsDelegates: [
        app_localizations.AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: app_localizations.AppLocalizations.supportedLocales,
      theme: ThemeData(
        primarySwatch: Colors.indigo, // Matches dark blue tone
        primaryColor: const Color(0xFF0D47A1), // Deep Dark Blue
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D47A1), // Core brand color
          secondary: const Color(0xFF1565C0), // Slightly lighter blue
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D47A1), // Dark Blue for main titles
          ),
          headlineMedium: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D47A1),
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            color: Colors.black87,
          ),
          labelLarge: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w600,
            color: Color(0xFF0D47A1),
          ),
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
