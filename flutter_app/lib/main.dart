import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_localizations.dart';
import 'providers/app_locale_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/feedback_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const FitPoseAIApp(),
    ),
  );
}

class FitPoseAIApp extends ConsumerStatefulWidget {
  const FitPoseAIApp({super.key});

  @override
  ConsumerState<FitPoseAIApp> createState() => _FitPoseAIAppState();
}

class _FitPoseAIAppState extends ConsumerState<FitPoseAIApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(authProvider.notifier).checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final effectiveLocale = ref.watch(effectiveAppLocaleProvider);
    ref.watch(feedbackManagerWithLocaleProvider);

    return MaterialApp.router(
      title: 'FitPose AI',
      debugShowCheckedModeBanner: false,
      locale: effectiveLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: supportedAppLocales,
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) {
          return const Locale('en', 'US');
        }
        return normalizeSupportedLocale(locale);
      },
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
