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
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRhdnJrcmJ3cmlzb3ptdWV1bHRqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjIwNzg3OTUsImV4cCI6MjA3NzY1NDc5NX0._KeimHNHSjOw-LHejt2pvrDrh6h-N-9p7FR7LOBJKTw',
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
      title: 'Medical App',
      locale: languageState.locale,
      localizationsDelegates: [
        app_localizations.AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: app_localizations.AppLocalizations.supportedLocales,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF1976D2),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1976D2),
          secondary: const Color(0xFF03A9F4),
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}
