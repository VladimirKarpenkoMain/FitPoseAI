import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/feedback_manager.dart';
import '../services/speech_text_formatter.dart';
import 'app_locale_provider.dart';

/// Provider for the FeedbackManager singleton
///
/// Usage:
/// ```dart
/// final feedbackManager = ref.read(feedbackProvider);
/// await feedbackManager.speak("Go Lower");
/// ```
final feedbackProvider = Provider<FeedbackManager>((ref) {
  final manager = FeedbackManager();

  // Dispose when provider is disposed
  ref.onDispose(() {
    manager.dispose();
  });

  return manager;
});

/// Provider that keeps the singleton TTS language aligned with the app locale.
final feedbackManagerWithLocaleProvider = Provider<FeedbackManager>((ref) {
  final manager = ref.watch(feedbackProvider);
  final locale = ref.watch(effectiveAppLocaleProvider);

  unawaited(manager.setLanguage(ttsLanguageCodeForLocale(locale)));

  return manager;
});
