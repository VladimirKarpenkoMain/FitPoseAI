import '../models/workout_analysis.dart';
import 'exercise_profile.dart';
import 'pose_frame.dart';
import 'quality_evaluator.dart';
import 'rep_attempt.dart';

class RepUpdate {
  final int repCount;
  final bool countIncremented;
  final RepAnalysis? repAnalysis;
  final MotionPhase phase;
  final MotionPhase detectedPhase;
  final List<RepIssueEvent> issueEvents;
  final List<RepEvent> repEvents;
  final List<PhaseTimelineEvent> phaseTimeline;
  final bool hasActiveAttempt;
  final int? activeRepIndex;
  final int? activeRepFrameCount;
  final bool visitedTargetPhase;
  final int cooldownFramesRemaining;
  final int completionFrames;
  final String? pendingReason;

  const RepUpdate({
    required this.repCount,
    required this.countIncremented,
    required this.repAnalysis,
    required this.phase,
    required this.detectedPhase,
    this.issueEvents = const <RepIssueEvent>[],
    this.repEvents = const <RepEvent>[],
    this.phaseTimeline = const <PhaseTimelineEvent>[],
    this.hasActiveAttempt = false,
    this.activeRepIndex,
    this.activeRepFrameCount,
    this.visitedTargetPhase = false,
    this.cooldownFramesRemaining = 0,
    this.completionFrames = 0,
    this.pendingReason,
  });
}

class RepAnalyzer {
  RepAnalyzer({required this.profile})
      : _phase = profile.trackingConfig.startPhase;

  final ExerciseProfile profile;
  final QualityEvaluator _qualityEvaluator = const QualityEvaluator();

  MotionPhase _phase;
  MotionPhase? _pendingPhase;
  int _pendingPhaseFrames = 0;
  int _repCount = 0;
  int _cooldownFramesRemaining = 0;
  int _completionFrames = 0;
  int _returnToStartFrames = 0;
  RepAttempt? _activeAttempt;

  RepUpdate process(PoseFrame frame) {
    final config = profile.trackingConfig;
    if (_cooldownFramesRemaining > 0) {
      _cooldownFramesRemaining--;
    }

    final issueEvents = <RepIssueEvent>[];
    final repEvents = <RepEvent>[];
    final phaseTimeline = <PhaseTimelineEvent>[];
    final detectedPhase = profile.detectPhase(frame, _phase);

    if (_activeAttempt == null &&
        _cooldownFramesRemaining == 0 &&
        _phase == config.startPhase &&
        detectedPhase != config.startPhase) {
      _activeAttempt = RepAttempt(
        repIndex: _repCount + 1,
        startedFrame: frame.frameIndex,
        startedTimestampMs: frame.timestampMs,
        startPhase: config.startPhase,
      );
      _returnToStartFrames = 0;
      repEvents.add(
        RepEvent(
          type: RepEventType.started,
          repIndex: _activeAttempt!.repIndex,
          frameIndex: frame.frameIndex,
          timestampMs: frame.timestampMs,
          phase: detectedPhase,
          visitedTargetPhase: false,
          valid: false,
        ),
      );
    }

    final phaseChanged =
        _confirmStablePhase(detectedPhase, config.phaseDwellFrames);
    if (phaseChanged) {
      phaseTimeline.add(
        PhaseTimelineEvent(
          repIndex: _activeAttempt?.repIndex ?? (_repCount + 1),
          frameIndex: frame.frameIndex,
          timestampMs: frame.timestampMs,
          phase: _phase,
        ),
      );
    }

    final attempt = _activeAttempt;
    if (attempt == null) {
      return RepUpdate(
        repCount: _repCount,
        countIncremented: false,
        repAnalysis: null,
        phase: _phase,
        detectedPhase: detectedPhase,
        cooldownFramesRemaining: _cooldownFramesRemaining,
        completionFrames: _completionFrames,
        pendingReason: _cooldownFramesRemaining > 0
            ? 'completion_cooldown'
            : 'awaiting_departure_from_start',
      );
    }

    final frameMetrics = profile.captureFrameMetrics(frame);
    final analysisPhase = _phase == config.startPhase && detectedPhase != _phase
        ? detectedPhase
        : _phase;
    attempt.addFrame(
      frame,
      phase: analysisPhase,
      metrics: frameMetrics,
    );

    if (config.targetPhases.contains(_phase)) {
      attempt.visitedTargetPhase = true;
    }

    for (final trigger
        in profile.detectLiveIssues(frame: frame, phase: analysisPhase)) {
      if (!attempt.shouldRecordIssue(
        code: trigger.code,
        frameIndex: frame.frameIndex,
        cooldownFrames: config.duplicateIssueCooldownFrames,
      )) {
        continue;
      }

      final event = RepIssueEvent(
        code: trigger.code,
        message: trigger.message,
        exerciseType: profile.id,
        repIndex: attempt.repIndex,
        frameIndex: frame.frameIndex,
        timestampMs: frame.timestampMs,
        phase: analysisPhase,
        metricName: trigger.metricName,
        actualValue: trigger.actualValue,
        threshold: trigger.threshold,
        severity: trigger.severity,
        metricsSnapshot: Map<String, double>.from(frameMetrics),
      );
      attempt.issueEvents.add(event);
      issueEvents.add(event);
    }

    final finishObserved = config.finishPhases.contains(detectedPhase);
    if (attempt.visitedTargetPhase && finishObserved) {
      _completionFrames++;
      if (attempt.frameCount >= config.minRepFrames &&
          _completionFrames >= config.completionDebounceFrames) {
        attempt.finishedFrame = frame.frameIndex;
        attempt.finishedTimestampMs = frame.timestampMs;
        attempt.isCompleted = true;
        attempt.isValid = true;

        final metrics = profile.summarizeRep(attempt.frames);
        final issues = profile.detectFinalIssues(metrics);
        final repAnalysis = _qualityEvaluator.buildRepAnalysis(
          repIndex: attempt.repIndex,
          metrics: metrics,
          issues: issues,
          issueEvents: List<RepIssueEvent>.unmodifiable(attempt.issueEvents),
          startedTimestampMs: attempt.startedTimestampMs,
          finishedTimestampMs: attempt.finishedTimestampMs,
          visitedPhases:
              attempt.visitedPhases.map((phase) => phase.name).toList(),
          minMetrics: Map<String, double>.from(attempt.minMetrics),
          maxMetrics: Map<String, double>.from(attempt.maxMetrics),
          avgMetrics: Map<String, double>.from(attempt.avgMetrics),
        );

        _repCount++;
        _activeAttempt = null;
        _completionFrames = 0;
        _returnToStartFrames = 0;
        _cooldownFramesRemaining = config.completionCooldownFrames;
        repEvents.add(
          RepEvent(
            type: RepEventType.completed,
            repIndex: repAnalysis.repIndex,
            frameIndex: frame.frameIndex,
            timestampMs: frame.timestampMs,
            phase: detectedPhase,
            visitedTargetPhase: true,
            valid: true,
          ),
        );

        return RepUpdate(
          repCount: _repCount,
          countIncremented: true,
          repAnalysis: repAnalysis,
          phase: detectedPhase,
          detectedPhase: detectedPhase,
          issueEvents: issueEvents,
          repEvents: repEvents,
          phaseTimeline: phaseTimeline,
          cooldownFramesRemaining: _cooldownFramesRemaining,
          completionFrames: _completionFrames,
          pendingReason: 'rep_completed',
        );
      }
    } else {
      _completionFrames = 0;
    }

    final hasMovedAwayFromStart =
        attempt.visitedPhases.any((phase) => phase != config.startPhase);
    if (!attempt.visitedTargetPhase &&
        hasMovedAwayFromStart &&
        finishObserved) {
      _returnToStartFrames++;
    } else {
      _returnToStartFrames = 0;
    }

    if (!attempt.visitedTargetPhase &&
        hasMovedAwayFromStart &&
        finishObserved &&
        _returnToStartFrames >= config.completionDebounceFrames) {
      repEvents.add(
        RepEvent(
          type: RepEventType.discarded,
          repIndex: attempt.repIndex,
          frameIndex: frame.frameIndex,
          timestampMs: frame.timestampMs,
          phase: _phase,
          visitedTargetPhase: false,
          valid: false,
        ),
      );
      _activeAttempt = null;
      _completionFrames = 0;
      _returnToStartFrames = 0;
    }

    return RepUpdate(
      repCount: _repCount,
      countIncremented: false,
      repAnalysis: null,
      phase: _phase,
      detectedPhase: detectedPhase,
      issueEvents: issueEvents,
      repEvents: repEvents,
      phaseTimeline: phaseTimeline,
      hasActiveAttempt: _activeAttempt != null,
      activeRepIndex: _activeAttempt?.repIndex,
      activeRepFrameCount: _activeAttempt?.frameCount,
      visitedTargetPhase: _activeAttempt?.visitedTargetPhase ?? false,
      cooldownFramesRemaining: _cooldownFramesRemaining,
      completionFrames: _completionFrames,
      pendingReason: _pendingReason(
        config: config,
        detectedPhase: detectedPhase,
        attempt: _activeAttempt,
      ),
    );
  }

  bool _confirmStablePhase(MotionPhase detectedPhase, int dwellFrames) {
    if (detectedPhase == _phase) {
      _pendingPhase = null;
      _pendingPhaseFrames = 0;
      return false;
    }

    if (_pendingPhase != detectedPhase) {
      _pendingPhase = detectedPhase;
      _pendingPhaseFrames = 1;
      return false;
    }

    _pendingPhaseFrames++;
    if (_pendingPhaseFrames < dwellFrames) {
      return false;
    }

    _phase = detectedPhase;
    _pendingPhase = null;
    _pendingPhaseFrames = 0;
    return true;
  }

  String _pendingReason({
    required RepTrackingConfig config,
    required MotionPhase detectedPhase,
    required RepAttempt? attempt,
  }) {
    if (attempt == null) {
      if (_cooldownFramesRemaining > 0) {
        return 'completion_cooldown';
      }
      return detectedPhase == config.startPhase
          ? 'awaiting_departure_from_start'
          : 'waiting_for_rep_start';
    }
    if (!attempt.visitedTargetPhase) {
      return 'awaiting_target_phase';
    }
    if (!config.finishPhases.contains(detectedPhase) &&
        !config.finishPhases.contains(_phase)) {
      return 'awaiting_finish_phase';
    }
    if (attempt.frameCount < config.minRepFrames) {
      return 'min_rep_frames_not_reached';
    }
    if (_completionFrames < config.completionDebounceFrames) {
      return 'completion_debounce';
    }
    return 'ready_to_complete';
  }
}
