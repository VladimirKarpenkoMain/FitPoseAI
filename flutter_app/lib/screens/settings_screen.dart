import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_locale_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentOption = ref.watch(appLanguageProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: RadioGroup<AppLanguageOption>(
        groupValue: currentOption,
        onChanged: (value) {
          if (value != null) {
            ref.read(appLanguageProvider.notifier).setOption(value);
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              l10n.language,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.appLanguageDescription,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            RadioListTile<AppLanguageOption>(
              key: const Key('app-language-system'),
              value: AppLanguageOption.system,
              title: Text(l10n.systemDefault),
            ),
            RadioListTile<AppLanguageOption>(
              key: const Key('app-language-english'),
              value: AppLanguageOption.english,
              title: Text(l10n.languageEnglish),
            ),
            RadioListTile<AppLanguageOption>(
              key: const Key('app-language-russian'),
              value: AppLanguageOption.russian,
              title: Text(l10n.languageRussian),
            ),
          ],
        ),
      ),
    );
  }
}
