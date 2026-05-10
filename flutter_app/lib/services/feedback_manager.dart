import 'dart:io' show Platform;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'feedback_output.dart';
import 'speech_text_formatter.dart';

/// Singleton class that manages audio feedback for exercises
/// Provides Text-to-Speech for corrections and rep counts,
/// and sound effects for successful reps
class FeedbackManager implements FeedbackOutput {
  // Singleton instance
  static final FeedbackManager _instance = FeedbackManager._internal();

  factory FeedbackManager() {
    return _instance;
  }

  FeedbackManager._internal();

  // TTS instance
  final FlutterTts _flutterTts = FlutterTts();

  // Audio player for beep sound
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Track if TTS is currently speaking to prevent overlap
  bool _isSpeaking = false;

  // Last spoken text to avoid repeating same feedback
  String? _lastSpokenText;

  // Timestamp of last speech to implement cooldown
  DateTime? _lastSpeechTime;

  // Minimum time between speech utterances (milliseconds)
  static const int speechCooldownMs = 1500;

  // Language settings
  String _currentLanguage = 'en-US';
  bool _isInitialized = false;
  bool _handlersConfigured = false;
  Future<void>? _initializationFuture;

  /// Initialize TTS with proper settings
  Future<void> _initializeTTS() async {
    if (_isInitialized) {
      return;
    }

    final pendingInitialization = _initializationFuture;
    if (pendingInitialization != null) {
      await pendingInitialization;
      return;
    }

    final initialization = _doInitializeTTS();
    _initializationFuture = initialization;
    try {
      await initialization;
    } finally {
      _initializationFuture = null;
    }
  }

  Future<void> _doInitializeTTS() async {
    try {
      if (Platform.isAndroid) {
        try {
          await _flutterTts.setEngine('com.google.android.tts');
        } catch (e) {
          print('Google TTS engine not available - using default engine: $e');
        }
      } else if (Platform.isIOS) {
        await _flutterTts.setSharedInstance(true);
        await _flutterTts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
          ],
          IosTextToSpeechAudioMode.defaultMode,
        );
      }

      await _applyCurrentLanguage();
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      _configureHandlers();
      _isInitialized = true;
    } catch (e) {
      print('Error initializing TTS: $e');
    }
  }

  void _configureHandlers() {
    if (_handlersConfigured) {
      return;
    }

    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
    });

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
    });

    _flutterTts.setErrorHandler((msg) {
      _isSpeaking = false;
      print('TTS Error: $msg');
    });

    _flutterTts.setCancelHandler(() {
      _isSpeaking = false;
    });

    _handlersConfigured = true;
  }

  Future<void> _applyCurrentLanguage() async {
    try {
      await _flutterTts.setLanguage(_currentLanguage);
    } catch (e) {
      print('Error setting TTS language $_currentLanguage: $e');
    }
  }

  /// Speaks the given text using Text-to-Speech
  ///
  /// Features:
  /// - Cancels previous speech if new important feedback comes
  /// - Implements cooldown to prevent rapid-fire speech
  /// - Avoids repeating the same text consecutively
  ///
  /// [text] The text to speak
  /// [priority] If true, cancels current speech immediately
  @override
  Future<void> speak(String text, {bool priority = false}) async {
    if (!_isInitialized) {
      await _initializeTTS();
    }
    await _applyCurrentLanguage();

    if (_lastSpokenText == text && !priority) {
      return;
    }

    if (!priority && _lastSpeechTime != null) {
      final timeSinceLastSpeech = DateTime.now().difference(_lastSpeechTime!);
      if (timeSinceLastSpeech.inMilliseconds < speechCooldownMs) {
        return;
      }
    }

    if (_isSpeaking && priority) {
      await _flutterTts.stop();
    }

    if (_isSpeaking && !priority) {
      return;
    }

    try {
      _lastSpokenText = text;
      _lastSpeechTime = DateTime.now();
      await _flutterTts.speak(text);
    } catch (e) {
      print('Error speaking: $e');
      _isSpeaking = false;
    }
  }

  /// Speaks a rep count number using the active TTS language.
  @override
  Future<void> speakRepCount(int count, {bool priority = false}) async {
    final text = repCountSpeechText(count, _currentLanguage);
    await speak(text, priority: priority);
  }

  /// Speaks the remaining preparation countdown using the active TTS language.
  @override
  Future<void> speakStartCountdown(
    int remainingSeconds, {
    bool priority = false,
  }) async {
    final text = startCountdownSpeechText(remainingSeconds, _currentLanguage);
    await speak(text, priority: priority);
  }

  /// Plays a beep sound for successful rep completion
  @override
  Future<void> playBeep() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/beep.mp3'));
    } catch (e) {
      print('Beep sound not available - skipping (asset file not found)');
    }
  }

  /// Stops any currently playing speech
  @override
  Future<void> stop() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      _isSpeaking = false;
    }
  }

  /// Changes the TTS language
  ///
  /// [languageCode] Language code (e.g., 'en-US', 'ru-RU')
  Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    if (!_isInitialized) {
      await _initializeTTS();
    }
    await _applyCurrentLanguage();
  }

  Future<void> setEnglish() async {
    await setLanguage('en-US');
  }

  Future<void> setRussian() async {
    await setLanguage('ru-RU');
  }

  String get currentLanguage => _currentLanguage;

  bool get isSpeaking => _isSpeaking;

  Future<void> dispose() async {
    await _flutterTts.stop();
    await _audioPlayer.dispose();
  }
}
