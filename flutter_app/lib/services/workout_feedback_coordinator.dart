import '../logic/exercise_counter.dart';
import 'feedback_manager.dart';

/// Coordinates feedback between exercise counters and the FeedbackManager
/// Handles both TTS announcements and sound effects based on counter results
class WorkoutFeedbackCoordinator {
  final FeedbackManager _feedbackManager;
  
  // Track the last feedback to avoid repetition
  String? _lastFeedback;
  int? _lastCount;
  
  // Cooldown for feedback messages (milliseconds)
  static const int feedbackCooldownMs = 2000;
  DateTime? _lastFeedbackTime;

  WorkoutFeedbackCoordinator(this._feedbackManager);

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
      _lastCount = result.count;
      return;
    }
    
    // Provide correction feedback if needed
    await _provideCorrectionFeedback(result.feedback);
  }

  /// Provides correction feedback with cooldown
  Future<void> _provideCorrectionFeedback(String feedback) async {
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
    if (_shouldSpeakFeedback(feedback)) {
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
    _lastCount = null;
    _lastFeedbackTime = null;
  }

  /// Stops any ongoing speech
  Future<void> stop() async {
    await _feedbackManager.stop();
  }
}
