import '../analysis/rep_analyzer.dart';
import '../logic/counter_result.dart';
import '../models/workout_analysis.dart';
import 'feedback_output.dart';

/// Coordinates feedback between exercise counters and the FeedbackManager
/// Handles both TTS announcements and sound effects based on counter results
class WorkoutFeedbackCoordinator {
  final FeedbackOutput _feedbackManager;

  // Track the last feedback to avoid repetition
  String? _lastFeedback;
  int? _lastStartCountdownSeconds;

  // Cooldown for feedback messages (milliseconds)
  static const int feedbackCooldownMs = 2000;
  DateTime? _lastFeedbackTime;

  WorkoutFeedbackCoordinator(this._feedbackManager);

  Future<void> processRepUpdate(
    RepUpdate update, {
    bool speakCount = true,
  }) async {
    if (!update.countIncremented) {
      await _provideCriticalIssueFeedback(update);
      return;
    }

    await _feedbackManager.playBeep();

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
    // If rep was counted, play beep and speak the count
    if (result.countIncremented) {
      await _feedbackManager.playBeep();

      if (speakCount) {
        await _feedbackManager.speakRepCount(result.count);
      }

      // Reset feedback tracking on new rep
      _lastFeedback = null;
      return;
    }

    // Provide correction feedback if needed
    await _provideCorrectionFeedback(result.feedback);
  }

  /// Provides correction feedback with cooldown
  Future<void> _provideCorrectionFeedback(
    String feedback, {
    bool force = false,
  }) async {
    // Skip if same as last feedback
    if (_lastFeedback == feedback) {
      // Check cooldown before repeating
      if (_lastFeedbackTime != null) {
        final timeSince = DateTime.now().difference(_lastFeedbackTime!);
        if (timeSince.inMilliseconds < feedbackCooldownMs) {
          return;
        }
      }
    }

    // Speak important corrections
    if (force || _shouldSpeakFeedback(feedback)) {
      await _feedbackManager.speak(feedback);
      _lastFeedback = feedback;
      _lastFeedbackTime = DateTime.now();
    }
  }

  /// Determines if a feedback message should be spoken
  bool _shouldSpeakFeedback(String feedback) {
    // List of important feedback messages that should be spoken
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
  }

  /// Stops any ongoing speech
  Future<void> stop() async {
    await _feedbackManager.stop();
  }
}
