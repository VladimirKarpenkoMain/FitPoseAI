import '../analysis/rep_analyzer.dart';
import '../logic/counter_result.dart';
import '../models/workout_analysis.dart';
import 'feedback_output.dart';

/// Coordinates feedback between exercise counters and the FeedbackManager
/// Handles TTS announcements based on counter results.
class WorkoutFeedbackCoordinator {
  final FeedbackOutput _feedbackManager;
  final DateTime Function() _now;

  // Track the last feedback to avoid repetition
  String? _lastFeedback;
  int? _lastStartCountdownSeconds;
  String? _lastReadinessPrompt;

  // Cooldown for feedback messages (milliseconds)
  static const int feedbackCooldownMs = 2000;
  static const int readinessPromptCooldownMs = 4000;
  DateTime? _lastFeedbackTime;
  DateTime? _lastReadinessPromptTime;

  WorkoutFeedbackCoordinator(
    this._feedbackManager, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  Future<void> processRepUpdate(
    RepUpdate update, {
    bool speakCount = true,
  }) async {
    if (!update.countIncremented) {
      await _provideCriticalIssueFeedback(update);
      return;
    }

    if (speakCount) {
      await _feedbackManager.speakRepCount(update.repCount);
    }

    _lastFeedback = null;
  }

  Future<void> announceStartCountdown(int remainingSeconds) async {
    if (remainingSeconds <= 0 ||
        remainingSeconds == _lastStartCountdownSeconds) {
      return;
    }

    _lastStartCountdownSeconds = remainingSeconds;
    await _feedbackManager.speakStartCountdown(
      remainingSeconds,
      priority: true,
    );
  }

  void resetStartCountdown() {
    _lastStartCountdownSeconds = null;
  }

  Future<void> announceReadinessPrompt(String message) async {
    final prompt = message.trim();
    if (prompt.isEmpty) {
      return;
    }

    final now = _now();
    if (_lastReadinessPrompt == prompt && _lastReadinessPromptTime != null) {
      final timeSince = now.difference(_lastReadinessPromptTime!);
      if (timeSince.inMilliseconds < readinessPromptCooldownMs) {
        return;
      }
    }

    _lastReadinessPrompt = prompt;
    _lastReadinessPromptTime = now;
    await _feedbackManager.speak(prompt);
  }

  void resetReadinessPrompt() {
    _lastReadinessPrompt = null;
    _lastReadinessPromptTime = null;
  }

  Future<void> _provideCriticalIssueFeedback(RepUpdate update) async {
    for (final issue in update.issueEvents) {
      if (issue.severity != IssueSeverity.critical) {
        continue;
      }
      await _provideCorrectionFeedback(issue.message, force: true);
      return;
    }
  }

  /// Processes a counter result and provides appropriate feedback
  ///
  /// [result] The result from an exercise counter
  /// [speakCount] Whether to speak the rep count on successful rep
  Future<void> processFeedback(
    CounterResult result, {
    bool speakCount = true,
  }) async {
    if (result.countIncremented) {
      if (speakCount) {
        await _feedbackManager.speakRepCount(result.count);
      }

      _lastFeedback = null;
      return;
    }

    await _provideCorrectionFeedback(result.feedback);
  }

  /// Provides correction feedback with cooldown
  Future<void> _provideCorrectionFeedback(
    String feedback, {
    bool force = false,
  }) async {
    if (_lastFeedback == feedback) {
      if (_lastFeedbackTime != null) {
        final timeSince = DateTime.now().difference(_lastFeedbackTime!);
        if (timeSince.inMilliseconds < feedbackCooldownMs) {
          return;
        }
      }
    }

    if (force || _shouldSpeakFeedback(feedback)) {
      await _feedbackManager.speak(feedback);
      _lastFeedback = feedback;
      _lastFeedbackTime = DateTime.now();
    }
  }

  /// Determines if a feedback message should be spoken
  bool _shouldSpeakFeedback(String feedback) {
    const importantFeedback = [
      'Go Lower',
      'Go Down',
      'Stand Up',
      'Fix your back!',
      'Push Up',
      'Jump!',
      'Raise arms',
      'Spread legs',
      'Return to start',
      'Lower arms',
      'Feet together',
    ];

    return importantFeedback.contains(feedback);
  }

  /// Speaks a custom message (e.g., "Ready", "Get set")
  Future<void> speakCustom(String message, {bool priority = false}) async {
    await _feedbackManager.speak(message, priority: priority);
  }

  /// Resets the feedback tracking (useful when starting a new set)
  void reset() {
    _lastFeedback = null;
    _lastFeedbackTime = null;
    resetStartCountdown();
    resetReadinessPrompt();
  }

  /// Stops any ongoing speech
  Future<void> stop() async {
    await _feedbackManager.stop();
  }
}
