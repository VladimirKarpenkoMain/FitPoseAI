import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../analysis/readiness_evaluator.dart';
import '../../analysis/workout_analyzer.dart';
import '../../l10n/app_localizations.dart';
import '../../models/exercise_type.dart';
import '../../models/workout_analysis.dart';
import '../../models/workout_plan.dart';
import '../../models/workout_session_progress.dart';
import '../../providers/feedback_provider.dart';
import '../../providers/workout_provider.dart';
import '../../services/workout_feedback_coordinator.dart';
import '../../services/workout_session_recorder.dart';
import 'pose_detector_view.dart';
import 'workout_route_args.dart';
import 'widgets/workout_live_header.dart';
import 'widgets/workout_progress_card.dart';
import 'widgets/workout_status_stack.dart';

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({
    super.key,
    required this.plan,
  });

  final WorkoutPlan plan;

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  late final WorkoutAnalyzer _workoutAnalyzer;
  late final WorkoutSessionRecorder _sessionRecorder;
  late final WorkoutFeedbackCoordinator _feedbackCoordinator;
  final Stopwatch _activeWorkoutStopwatch = Stopwatch();

  Timer? _activeTicker;
  int _repCount = 0;
  bool _isSaving = false;
  bool _goalCompletionTriggered = false;
  ReadinessResult? _readiness;
  RepAnalysis? _lastRepAnalysis;
  String _systemStatus = '';
  String _liveCue = '';
  WorkoutSessionPhase _phase = WorkoutSessionPhase.preparation;

  ExerciseType get _exerciseType => widget.plan.exerciseType;

  WorkoutSessionProgress get _progress => WorkoutSessionProgress(
        plan: widget.plan,
        phase: _phase,
        repCount: _repCount,
        activeElapsed: _activeWorkoutStopwatch.elapsed,
      );

  @override
  void initState() {
    super.initState();
    _workoutAnalyzer = WorkoutAnalyzer(_exerciseType);
    _sessionRecorder = WorkoutSessionRecorder(
      requiredView: _workoutAnalyzer.profile.requiredView,
      thresholds: _workoutAnalyzer.profile.thresholds,
    );
    _feedbackCoordinator = WorkoutFeedbackCoordinator(
      ref.read(feedbackManagerWithLocaleProvider),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) {
        return;
      }
      final l10n = AppLocalizations.of(context);
      await _feedbackCoordinator.speakCustom(
        l10n.workoutReadyPrompt(
          l10n.exerciseName(_exerciseType.apiValue),
          l10n.exerciseStartPositionHint(_exerciseType.apiValue),
        ),
        priority: true,
      );
    });
  }

  @override
  void dispose() {
    _activeTicker?.cancel();
    _activeWorkoutStopwatch.stop();
    _feedbackCoordinator.stop();
    super.dispose();
  }

  void _onAnalysisFrame(WorkoutFrameResult result) {
    final l10n = AppLocalizations.of(context);
    final shouldStartActive = _phase == WorkoutSessionPhase.preparation &&
        result.readiness.canStartTracking;
    final repUpdate = result.repUpdate;
    final holdUpdate = result.holdUpdate;

    if (repUpdate != null) {
      _sessionRecorder.recordRepUpdate(repUpdate);
      unawaited(_feedbackCoordinator.processRepUpdate(repUpdate));
    }
    if (holdUpdate != null) {
      _sessionRecorder.recordHoldUpdate(holdUpdate);
    }

    _handlePreparationSpeech(l10n, result.readiness);

    setState(() {
      _readiness = result.readiness;
      _systemStatus = result.systemStatus;
      _liveCue = _liveAnalysisCue(l10n, result);
      if (repUpdate?.countIncremented ?? false) {
        _repCount = repUpdate!.repCount;
        _lastRepAnalysis = repUpdate.repAnalysis;
      }
    });

    if (shouldStartActive) {
      _startActivePhase();
    }

    if (_phase == WorkoutSessionPhase.active &&
        widget.plan.isRepBased &&
        _progress.hasReachedGoal) {
      _completeGoalWorkout();
    }
  }

  void _handlePreparationSpeech(
    AppLocalizations l10n,
    ReadinessResult readiness,
  ) {
    if (_phase != WorkoutSessionPhase.preparation) {
      return;
    }

    if (readiness.state == ReadinessState.countdownReady) {
      unawaited(
        _feedbackCoordinator.announceStartCountdown(
          readiness.remainingSeconds,
        ),
      );
      return;
    }

    _feedbackCoordinator.resetStartCountdown();

    final blocker = readiness.blocker;
    if (blocker == null || blocker.isEmpty || readiness.canStartTracking) {
      return;
    }

    unawaited(
      _feedbackCoordinator.announceReadinessPrompt(
        _translateSystemStatus(l10n, blocker),
      ),
    );
  }

  void _startActivePhase() {
    if (_phase != WorkoutSessionPhase.preparation) {
      return;
    }

    setState(() {
      _phase = WorkoutSessionPhase.active;
    });

    _activeWorkoutStopwatch.start();
    if (widget.plan.isTimeBased) {
      _activeTicker?.cancel();
      _activeTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || _phase != WorkoutSessionPhase.active) {
          return;
        }
        if (_progress.hasReachedGoal) {
          _completeGoalWorkout();
          return;
        }
        setState(() {});
      });
    }
  }

  void _completeGoalWorkout() {
    if (_goalCompletionTriggered || _isSaving || !mounted) {
      return;
    }
    _goalCompletionTriggered = true;
    unawaited(
      _finishWorkout(
        AppLocalizations.of(context),
        saveZeroReps: widget.plan.isTimeBased,
      ),
    );
  }

  Future<void> _finishWorkout(
    AppLocalizations l10n, {
    bool saveZeroReps = false,
  }) async {
    if (_isSaving) {
      return;
    }

    _activeTicker?.cancel();
    _activeWorkoutStopwatch.stop();

    if (_repCount == 0 && !saveZeroReps) {
      if (mounted) {
        context.pop();
      }
      return;
    }

    setState(() {
      _isSaving = true;
      _phase = WorkoutSessionPhase.completed;
    });

    try {
      final workout = await ref.read(workoutProvider.notifier).createWorkout(
            exerciseType: _exerciseType.apiValue,
            repCount: _repCount,
            averageQualityScore: _sessionRecorder.hasAnalysis
                ? _sessionRecorder.averageQualityScore
                : null,
            analysis: _sessionRecorder.hasAnalysis
                ? _sessionRecorder.buildAnalysisPayload(
                    readinessTimeSeconds: widget.plan.preparationSeconds,
                  )
                : null,
          );

      if (!mounted) {
        return;
      }

      context.go(
        '/workout-complete',
        extra: WorkoutCompleteArgs(
          workout: workout,
          goalLabel: widget.plan.isTimeBased
              ? '${widget.plan.targetValue} sec'
              : '${widget.plan.targetValue} reps',
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.error}: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String _translateSystemStatus(AppLocalizations l10n, String status) {
    switch (status) {
      case 'Step into frame':
        return l10n.stepIntoFrame;
      case 'Face the camera':
        return l10n.faceCamera;
      case 'Turn to your side':
        return l10n.turnToSide;
      case 'Stand fully in frame':
        return l10n.standInFrame;
      case 'Keep one full side visible':
        return l10n.keepFullSideVisible;
      case 'Hold the start position':
        return l10n.holdStartPoseToStart;
      case 'Tracking active':
        return l10n.trackingActive;
      case 'holding_good':
        return l10n.good;
      case 'hip_sag':
      case 'hips_too_high':
      case 'lost_position':
        return l10n.techniqueIssue(status);
      case 'Get ready':
        return l10n.getReady;
      default:
        if (status.endsWith(' is not visible')) {
          return l10n.standInFrame;
        }
        return status;
    }
  }

  String _statusText(AppLocalizations l10n) {
    if (_phase == WorkoutSessionPhase.completed) {
      return l10n.workoutComplete;
    }

    final readiness = _readiness;
    if (_phase == WorkoutSessionPhase.preparation) {
      if (readiness == null) {
        return l10n.positionYourselfInFrame;
      }
      if (readiness.state == ReadinessState.countdownReady) {
        return l10n.holdStillCountdown(readiness.remainingSeconds);
      }
      return _translateSystemStatus(l10n, _systemStatus);
    }

    if (readiness != null &&
        !readiness.canStartTracking &&
        _systemStatus.isNotEmpty) {
      return _translateSystemStatus(l10n, _systemStatus);
    }

    return widget.plan.isTimeBased
        ? '${l10n.timeLeft}: ${WorkoutSessionProgress.formatClock(_progress.remainingDuration)}'
        : l10n.trackingActive;
  }

  String _repSummary(AppLocalizations l10n) {
    if (_lastRepAnalysis == null) {
      return '';
    }

    final issueText = _lastRepAnalysis!.issues.isEmpty
        ? l10n.good
        : l10n.techniqueIssue(_lastRepAnalysis!.issues.first.apiValue);
    return l10n.repQualitySummary(_lastRepAnalysis!.qualityScore, issueText);
  }

  String _liveAnalysisCue(
    AppLocalizations l10n,
    WorkoutFrameResult result,
  ) {
    final holdUpdate = result.holdUpdate;
    if (holdUpdate != null) {
      if (holdUpdate.issues.isEmpty) {
        return l10n.good;
      }
      return l10n.techniqueIssue(holdUpdate.issues.first.apiValue);
    }

    final repUpdate = result.repUpdate;
    if (repUpdate != null && repUpdate.issueEvents.isNotEmpty) {
      return l10n.techniqueIssue(repUpdate.issueEvents.first.code);
    }

    return result.liveCue ?? '';
  }

  String _startGuide(AppLocalizations l10n) {
    if (_phase != WorkoutSessionPhase.preparation) {
      return '';
    }

    final readiness = _readiness;
    if (readiness == null) {
      return l10n.startGuideFindFrame;
    }

    switch (readiness.state) {
      case ReadinessState.viewAlignment:
        return _workoutAnalyzer.profile.requiredView == ExerciseView.side
            ? l10n.startGuideSideView
            : l10n.startGuideFrontView;
      case ReadinessState.bodyVisibilityCheck:
        return l10n.startGuideBodyVisible;
      case ReadinessState.startPoseCheck:
        return l10n.startGuideHoldStart;
      case ReadinessState.countdownReady:
        return l10n.startGuideCountdown;
      case ReadinessState.activeTracking:
        return '';
    }
  }

  String _goalText(AppLocalizations l10n) {
    if (widget.plan.isRepBased) {
      return l10n.repsGoalValue(widget.plan.targetValue);
    }
    return l10n.durationGoalValue(widget.plan.targetValue);
  }

  String _primaryCounterValue() {
    if (widget.plan.isTimeBased) {
      return WorkoutSessionProgress.formatClock(_progress.remainingDuration);
    }
    return '$_repCount';
  }

  String _primaryCounterLabel(AppLocalizations l10n) {
    if (widget.plan.isTimeBased) {
      return l10n.timeLeft;
    }
    return l10n.reps;
  }

  String _counterDetails(AppLocalizations l10n) {
    if (widget.plan.isRepBased) {
      return '${_progress.remainingReps} ${l10n.reps}';
    }
    return '$_repCount ${l10n.reps}';
  }

  double _progressFraction() {
    final target = widget.plan.targetValue;
    if (target <= 0) {
      return 0;
    }
    if (widget.plan.isRepBased) {
      return (_repCount / target).clamp(0.0, 1.0);
    }
    return (_activeWorkoutStopwatch.elapsed.inSeconds / target).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PoseDetectorView(
            exerciseType: _exerciseType,
            preparationSeconds: widget.plan.preparationSeconds,
            enforceReadinessChecks: true,
            onAnalysisFrame: _onAnalysisFrame,
          ),
          WorkoutLiveHeader(
            title: l10n.exerciseName(_exerciseType.apiValue),
            onBack: () => _showExitConfirmation(l10n),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.115,
            left: 16,
            right: 16,
            child: WorkoutProgressCard(
              goalText: '${l10n.goal}: ${_goalText(l10n)}',
              primaryValue: _primaryCounterValue(),
              primaryLabel: _primaryCounterLabel(l10n),
              secondaryText: _counterDetails(l10n),
              progressFraction: _progressFraction(),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 110,
            child: WorkoutStatusStack(
              systemStatus: _statusText(l10n),
              liveCue: _liveCue,
              repSummary: _repSummary(l10n),
              startGuide: _startGuide(l10n),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: ElevatedButton(
              onPressed: _isSaving
                  ? null
                  : () => _finishWorkout(
                        l10n,
                        saveZeroReps: widget.plan.isTimeBased,
                      ),
              child: Text(_isSaving ? l10n.loading : l10n.finishWorkout),
            ),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmation(AppLocalizations l10n) {
    final hasNoSessionData =
        _repCount == 0 && _phase == WorkoutSessionPhase.preparation;
    if (hasNoSessionData) {
      context.pop();
      return;
    }

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.exitWorkoutTitle),
        content: Text(l10n.exitWorkoutMessage(_repCount)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.pop();
            },
            child: Text(l10n.exitWithoutSaving),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _finishWorkout(l10n, saveZeroReps: widget.plan.isTimeBased);
            },
            child: Text(l10n.saveAndExit),
          ),
        ],
      ),
    );
  }
}
