/// Result of processing a pose, containing count and feedback.
class CounterResult {
  final int count;
  final String feedback;
  final bool countIncremented;

  CounterResult({
    required this.count,
    required this.feedback,
    this.countIncremented = false,
  });
}
