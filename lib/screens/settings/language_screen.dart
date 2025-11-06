import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Removed unused direct import of LanguageModel; accessed via provider state
import 'package:medical_app/providers/language_provider.dart';
import 'package:medical_app/widgets/custom_app_bar.dart';
import 'package:medical_app/l10n/app_localizations.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageState = ref.watch(languageProvider);
    final languageNotifier = ref.read(languageProvider.notifier);
    final currentLanguage = languageNotifier.getCurrentLanguage();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: CustomAppBar(
        title: l10n.selectLanguage,
        showBackButton: true,
      ),
      body: ListView.builder(
        itemCount: languageState.supportedLanguages.length,
        itemBuilder: (context, index) {
          final language = languageState.supportedLanguages[index];
          final isSelected = language.code == currentLanguage.code;
          
          return ListTile(
            leading: Text(
              language.flag,
              style: const TextStyle(fontSize: 24),
            ),
            title: Text(language.name),
            trailing: isSelected 
                ? const Icon(Icons.check, color: Colors.green)
                : null,
            onTap: () {
              languageNotifier.setLanguage(language.code);
            },
          );
        },
      ),
    );
  }
}