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
import '../../providers/workout_provider.dart';
import '../../services/feedback_manager.dart';
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
    _feedbackCoordinator = WorkoutFeedbackCoordinator(FeedbackManager());

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
    final shouldStartActive = _phase == WorkoutSessionPhase.preparation &&
        result.readiness.canStartTracking;
    final repUpdate = result.repUpdate;

    if (repUpdate != null) {
      _sessionRecorder.recordRepUpdate(repUpdate);
    }

    setState(() {
      _readiness = result.readiness;
      _systemStatus = result.systemStatus;
      _liveCue = result.liveCue ?? '';
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
            averageQualityScore: _sessionRecorder.hasRepAnalyses
                ? _sessionRecorder.averageQualityScore
                : null,
            analysis: _sessionRecorder.hasRepAnalyses
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
      case 'Keep one full side visible':
        return l10n.turnToSide;
      case 'Hold the start position':
        return l10n.holdStartPose;
      case 'Tracking active':
        return l10n.trackingActive;
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
        return l10n.getReadyCountdown(readiness.remainingSeconds);
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
      return '${l10n.goal}: ${_goalText(l10n)}';
    }
    return '$_repCount ${l10n.reps}';
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
            top: MediaQuery.of(context).size.height * 0.12,
            left: 16,
            right: 16,
            child: WorkoutProgressCard(
              goalText: '${l10n.goal}: ${_goalText(l10n)}',
              primaryValue: _primaryCounterValue(),
              primaryLabel: _primaryCounterLabel(l10n),
              secondaryText: _counterDetails(l10n),
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
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: ElevatedButton(
              onPressed: _isSaving ? null : () => _finishWorkout(l10n),
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
