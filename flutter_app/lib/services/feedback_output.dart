abstract class FeedbackOutput {
  Future<void> speak(String text, {bool priority = false});
  Future<void> speakRepCount(int count, {bool priority = false});
  Future<void> speakStartCountdown(
    int remainingSeconds, {
    bool priority = false,
  });
  Future<void> playBeep();
  Future<void> stop();
}
