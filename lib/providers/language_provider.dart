import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medical_app/models/language_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageState {
  final Locale locale;
  final List<LanguageModel> supportedLanguages;

  LanguageState({
    required this.locale,
    required this.supportedLanguages,
  });

  LanguageState copyWith({
    Locale? locale,
    List<LanguageModel>? supportedLanguages,
  }) {
    return LanguageState(
      locale: locale ?? this.locale,
      supportedLanguages: supportedLanguages ?? this.supportedLanguages,
    );
  }
}

class LanguageNotifier extends StateNotifier<LanguageState> {
  final SharedPreferences prefs;
  static const String _languageCodeKey = 'languageCode';
  static const String _defaultLanguageCode = 'en';

  LanguageNotifier(this.prefs)
      : super(
          LanguageState(
            locale: Locale(
              prefs.getString(_languageCodeKey) ?? _defaultLanguageCode,
            ),
            supportedLanguages: [
              const LanguageModel(
                code: 'en',
                name: 'English',
                flag: '🇺🇸',
              ),
              const LanguageModel(
                code: 'hi',
                name: 'हिंदी',
                flag: '🇮🇳',
              ),
            ],
          ),
        );

  Future<void> setLanguage(String languageCode) async {
    await prefs.setString(_languageCodeKey, languageCode);
    state = state.copyWith(locale: Locale(languageCode));
  }

  LanguageModel getCurrentLanguage() {
    return state.supportedLanguages.firstWhere(
      (language) => language.code == state.locale.languageCode,
      orElse: () => state.supportedLanguages.first,
    );
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Should be overridden in main.dart');
});

final languageProvider =
    StateNotifierProvider<LanguageNotifier, LanguageState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LanguageNotifier(prefs);
});