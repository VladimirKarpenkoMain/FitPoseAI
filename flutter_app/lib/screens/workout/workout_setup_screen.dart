import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../models/exercise_type.dart';
import '../../models/workout_plan.dart';

class WorkoutSetupScreen extends StatefulWidget {
  const WorkoutSetupScreen({
    super.key,
    required this.exerciseType,
  });

  final ExerciseType exerciseType;

  @override
  State<WorkoutSetupScreen> createState() => _WorkoutSetupScreenState();
}

class _WorkoutSetupScreenState extends State<WorkoutSetupScreen> {
  late final TextEditingController _targetController;
  late WorkoutGoalMode _goalMode;
  _SetupGuideTab _guideTab = _SetupGuideTab.position;

  bool get _isHoldExercise => widget.exerciseType == ExerciseType.plank;

  bool get _usesSquatPoseAsset => widget.exerciseType == ExerciseType.squat;

  @override
  void initState() {
    super.initState();
    _goalMode = _isHoldExercise ? WorkoutGoalMode.time : WorkoutGoalMode.reps;
    _targetController = TextEditingController(
      text: _goalMode == WorkoutGoalMode.reps ? '10' : '60',
    );
    _targetController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  int? get _targetValue {
    final value = int.tryParse(_targetController.text);
    if (value == null || value <= 0) {
      return null;
    }
    return value;
  }

  void _setGoalMode(WorkoutGoalMode mode) {
    if (_isHoldExercise && mode == WorkoutGoalMode.reps) {
      return;
    }
    if (_goalMode == mode) {
      return;
    }
    setState(() {
      _goalMode = mode;
      _targetController.text = mode == WorkoutGoalMode.reps ? '10' : '60';
    });
  }

  void _setGuideTab(_SetupGuideTab tab) {
    if (_guideTab == tab) {
      return;
    }
    setState(() => _guideTab = tab);
  }

  void _startWorkout() {
    final targetValue = _targetValue;
    if (targetValue == null) {
      return;
    }

    context.push(
      '/workout/${widget.exerciseType.apiValue}',
      extra: WorkoutPlan(
        exerciseType: widget.exerciseType,
        goalMode: _goalMode,
        targetValue: targetValue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomSafeArea = MediaQuery.paddingOf(context).bottom;
    final guideCopy = _SetupGuideCopy.forExercise(
      l10n: l10n,
      exerciseType: widget.exerciseType,
      tab: _guideTab,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
        scrolledUnderElevation: 0,
        title: Text(l10n.workoutSetup),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 28 + bottomSafeArea),
        children: [
          _SetupHero(
            exerciseName: l10n.exerciseName(widget.exerciseType.apiValue),
            eyebrow: l10n.setupHeroEyebrow,
            subtitle: l10n.setupHeroGuidance,
            coachSubtitle: l10n.setupCoachSubtitle,
            usesSquatPoseAsset: _usesSquatPoseAsset,
            fallbackIcon: widget.exerciseType.icon,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _GuidePill(
                  label: l10n.setupPositionTab,
                  isSelected: _guideTab == _SetupGuideTab.position,
                  onTap: () => _setGuideTab(_SetupGuideTab.position),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _GuidePill(
                  label: l10n.setupTechniqueTab,
                  isSelected: _guideTab == _SetupGuideTab.technique,
                  onTap: () => _setGuideTab(_SetupGuideTab.technique),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _GuidePill(
                  label: l10n.setupMistakesTab,
                  isSelected: _guideTab == _SetupGuideTab.mistakes,
                  onTap: () => _setGuideTab(_SetupGuideTab.mistakes),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            guideCopy.sectionTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          for (var index = 0; index < guideCopy.cards.length; index++) ...[
            _GuideCard(
              number: '${index + 1}',
              title: guideCopy.cards[index].title,
              body: guideCopy.cards[index].body,
              bullets: guideCopy.cards[index].bullets,
              tone: guideCopy.cards[index].tone,
            ),
            if (index != guideCopy.cards.length - 1) const SizedBox(height: 10),
          ],
          const SizedBox(height: 12),
          _AiChecksPanel(
            title: l10n.setupAiChecksTitle,
            body: guideCopy.aiChecks,
          ),
          const SizedBox(height: 20),
          Text(
            l10n.chooseTarget,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (!_isHoldExercise) ...[
                Expanded(
                  child: _GoalModeButton(
                    label: l10n.repsShort,
                    isSelected: _goalMode == WorkoutGoalMode.reps,
                    onTap: () => _setGoalMode(WorkoutGoalMode.reps),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: _GoalModeButton(
                  label: l10n.timeShort,
                  isSelected: _goalMode == WorkoutGoalMode.time,
                  onTap: () => _setGoalMode(WorkoutGoalMode.time),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _targetController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: _goalMode == WorkoutGoalMode.reps
                  ? l10n.targetReps
                  : l10n.durationSeconds,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _targetValue == null ? null : _startWorkout,
              child: Text(l10n.startWorkoutNow),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupHero extends StatelessWidget {
  const _SetupHero({
    required this.exerciseName,
    required this.eyebrow,
    required this.subtitle,
    required this.coachSubtitle,
    required this.usesSquatPoseAsset,
    required this.fallbackIcon,
  });

  final String exerciseName;
  final String eyebrow;
  final String subtitle;
  final String coachSubtitle;
  final bool usesSquatPoseAsset;
  final String fallbackIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF18212F),
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF18212F),
            Color(0xFF2F405D),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      style: const TextStyle(
                        color: Color(0xB3FFFFFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      exerciseName,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                              ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Container(
                width: 82,
                height: 82,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7A00),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 20,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: usesSquatPoseAsset
                    ? Image.asset(
                        'assets/images/squat_pose.png',
                        fit: BoxFit.contain,
                      )
                    : Center(
                        child: Text(
                          fallbackIcon,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xCCFFFFFF),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            coachSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xB3FFFFFF),
                ),
          ),
        ],
      ),
    );
  }
}

class _GuidePill extends StatelessWidget {
  const _GuidePill({
    required this.label,
    required this.onTap,
    this.isSelected = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF1E4) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected ? const Color(0xFFFF7A00) : const Color(0xFFD9E2EE),
          ),
        ),
        child: Center(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFFFF7A00)
                  : const Color(0xFF18212F),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

enum _SetupGuideTab { position, technique, mistakes }

enum _GuideTone { blue, orange, green }

class _SetupGuideCopy {
  const _SetupGuideCopy({
    required this.sectionTitle,
    required this.cards,
    required this.aiChecks,
  });

  final String sectionTitle;
  final List<_GuideCardCopy> cards;
  final String aiChecks;

  static _SetupGuideCopy forExercise({
    required AppLocalizations l10n,
    required ExerciseType exerciseType,
    required _SetupGuideTab tab,
  }) {
    final isRussian = l10n.locale.languageCode == 'ru';
    String t(String en, String ru) => isRussian ? ru : en;

    return switch (tab) {
      _SetupGuideTab.position => _positionCopy(t, exerciseType),
      _SetupGuideTab.technique => _techniqueCopy(t, exerciseType),
      _SetupGuideTab.mistakes => _mistakesCopy(t, exerciseType),
    };
  }

  static _SetupGuideCopy _positionCopy(
    String Function(String en, String ru) t,
    ExerciseType exerciseType,
  ) {
    final exerciseHint = switch (exerciseType) {
      ExerciseType.squat => t(
          'Stand sideways to the camera with feet shoulder-width apart.',
          'Встаньте боком к камере, стопы на ширине плеч.',
        ),
      ExerciseType.pushup => t(
          'Turn sideways and hold a straight-arm plank before the first rep.',
          'Повернитесь боком и удерживайте планку на прямых руках перед первым повтором.',
        ),
      ExerciseType.jumpingJack => t(
          'Face the camera with feet together and arms relaxed at your sides.',
          'Встаньте лицом к камере, ноги вместе, руки свободно опущены.',
        ),
      ExerciseType.plank => t(
          'Turn sideways and hold a forearm plank with shoulders over elbows.',
          'Повернитесь боком и удерживайте планку на предплечьях: плечи над локтями.',
        ),
      ExerciseType.shoulderPress => t(
          'Turn sideways with dumbbells near shoulder height and elbows slightly forward.',
          'Встаньте боком к камере: локти чуть впереди, кисти рядом с плечами.',
        ),
    };

    return _SetupGuideCopy(
      sectionTitle: t('Before you start', 'Перед стартом'),
      aiChecks: _aiChecks(t, exerciseType),
      cards: [
        _GuideCardCopy(
          title: t('Set the camera', 'Поставьте камеру'),
          body: t(
            'Keep your whole body in frame so the app can see the key joints.',
            'Тело должно полностью попадать в кадр, чтобы приложение видело ключевые суставы.',
          ),
          bullets: [
            t(
              'Place the phone around chest or waist height.',
              'Поставьте телефон примерно на уровне груди или пояса.',
            ),
            t(
              'Leave some space above your head and below your feet.',
              'Оставьте немного места над головой и под стопами.',
            ),
          ],
          tone: _GuideTone.blue,
        ),
        _GuideCardCopy(
          title: t('Take the start position', 'Займите стартовую позицию'),
          body: t(
            'Hold the setup briefly before starting so tracking can lock on.',
            'Коротко удержите позицию перед стартом, чтобы отслеживание зафиксировалось.',
          ),
          bullets: [exerciseHint],
          tone: _GuideTone.orange,
        ),
      ],
    );
  }

  static _SetupGuideCopy _techniqueCopy(
    String Function(String en, String ru) t,
    ExerciseType exerciseType,
  ) {
    final cards = switch (exerciseType) {
      ExerciseType.squat => [
          _GuideCardCopy(
            title: t('Technique cues', 'Подсказки по технике'),
            body: t(
              'Send your hips back first, keep your chest open, and let the knees follow the toes.',
              'Сначала отведите таз назад, держите грудь раскрытой и ведите колени в сторону носков.',
            ),
            bullets: [
              t(
                'Lower under control, then stand tall to finish the rep.',
                'Опускайтесь контролируемо, затем полностью выпрямляйтесь для завершения повтора.',
              ),
            ],
            tone: _GuideTone.orange,
          ),
        ],
      ExerciseType.pushup => [
          _GuideCardCopy(
            title: t('Technique cues', 'Подсказки по технике'),
            body: t(
              'Keep a straight line from shoulders to heels and lower your chest without dropping the hips.',
              'Держите прямую линию от плеч до пяток и опускайте грудь без провала таза.',
            ),
            bullets: [
              t(
                'Push the floor away until your elbows are extended.',
                'Отталкивайтесь от пола до выпрямления локтей.',
              ),
            ],
            tone: _GuideTone.orange,
          ),
        ],
      ExerciseType.jumpingJack => [
          _GuideCardCopy(
            title: t('Technique cues', 'Подсказки по технике'),
            body: t(
              'Move arms and legs together: feet go wide as hands travel overhead.',
              'Двигайте руки и ноги синхронно: стопы расходятся, пока руки идут вверх.',
            ),
            bullets: [
              t(
                'Return feet together and arms down before the next rep.',
                'Верните ноги вместе и руки вниз перед следующим повтором.',
              ),
            ],
            tone: _GuideTone.orange,
          ),
        ],
      ExerciseType.plank => [
          _GuideCardCopy(
            title: t('Technique cues', 'Подсказки по технике'),
            body: t(
              'Hold a straight line from shoulders through hips to heels.',
              'Держите прямую линию от плеч через таз до пяток.',
            ),
            bullets: [
              t(
                'Brace your core and keep hips from sagging or rising too high.',
                'Напрягите корпус и не допускайте провала или слишком высокого подъема таза.',
              ),
            ],
            tone: _GuideTone.orange,
          ),
        ],
      ExerciseType.shoulderPress => [
          _GuideCardCopy(
            title: t('Technique cues', 'Подсказки по технике'),
            body: t(
              'Press the dumbbells upward until both arms are extended, then return to shoulder height.',
              'Выжимайте руки вверх до выпрямления, затем возвращайте кисти к уровню плеч.',
            ),
            bullets: [
              t(
                'Keep the dumbbells over the shoulders and press both arms evenly.',
                'Держите локти под кистями и не отклоняйтесь назад.',
              ),
            ],
            tone: _GuideTone.orange,
          ),
        ],
    };

    return _SetupGuideCopy(
      sectionTitle: t('Technique cues', 'Техника выполнения'),
      cards: cards,
      aiChecks: _aiChecks(t, exerciseType),
    );
  }

  static _SetupGuideCopy _mistakesCopy(
    String Function(String en, String ru) t,
    ExerciseType exerciseType,
  ) {
    final cards = switch (exerciseType) {
      ExerciseType.squat => [
          _GuideCardCopy(
            title: t('Common mistakes', 'Частые ошибки'),
            body: t(
              'Avoid shallow reps, knees collapsing inward, and excessive forward lean.',
              'Избегайте неглубоких повторов, завала коленей внутрь и сильного наклона вперед.',
            ),
            bullets: [
              t(
                'If the app misses reps, step farther from the camera.',
                'Если приложение пропускает повторы, отойдите дальше от камеры.',
              ),
            ],
            tone: _GuideTone.green,
          ),
        ],
      ExerciseType.pushup => [
          _GuideCardCopy(
            title: t('Common mistakes', 'Частые ошибки'),
            body: t(
              'Avoid sagging hips, half-depth reps, and turning your body out of the side view.',
              'Избегайте провала таза, неполной глубины и разворота корпуса из бокового ракурса.',
            ),
            bullets: const [],
            tone: _GuideTone.green,
          ),
        ],
      ExerciseType.jumpingJack => [
          _GuideCardCopy(
            title: t('Common mistakes', 'Частые ошибки'),
            body: t(
              'Avoid unsynchronized arms and legs, incomplete overhead reach, and missing the closed position.',
              'Избегайте несинхронных рук и ног, неполного подъема рук и отсутствия возврата в закрытую позицию.',
            ),
            bullets: const [],
            tone: _GuideTone.green,
          ),
        ],
      ExerciseType.plank => [
          _GuideCardCopy(
            title: t('Common mistakes', 'Частые ошибки'),
            body: t(
              'Avoid hips sagging, hips too high, and shoulders drifting away from the elbows.',
              'Избегайте провала таза, слишком высокого таза и ухода плеч от линии локтей.',
            ),
            bullets: const [],
            tone: _GuideTone.green,
          ),
        ],
      ExerciseType.shoulderPress => [
          _GuideCardCopy(
            title: t('Common mistakes', 'Частые ошибки'),
            body: t(
              'Avoid incomplete lockout, dumbbells drifting forward, leg drive, and one arm lagging behind.',
              'Избегайте неполного выпрямления, слишком широких локтей и отклонения назад в конце повтора.',
            ),
            bullets: const [],
            tone: _GuideTone.green,
          ),
        ],
    };

    return _SetupGuideCopy(
      sectionTitle: t('Common mistakes', 'Частые ошибки'),
      cards: cards,
      aiChecks: _aiChecks(t, exerciseType),
    );
  }

  static String _aiChecks(
    String Function(String en, String ru) t,
    ExerciseType exerciseType,
  ) {
    return switch (exerciseType) {
      ExerciseType.squat => t(
          'Depth, stable base, knee path, and excessive forward lean.',
          'Глубину, устойчивую опору, траекторию коленей и слишком сильный наклон вперед.',
        ),
      ExerciseType.pushup => t(
          'Body line, depth, elbow extension, and hip position.',
          'Линию тела, глубину, выпрямление локтей и положение таза.',
        ),
      ExerciseType.jumpingJack => t(
          'Arm reach, leg width, synchronization, and return to start.',
          'Подъем рук, ширину постановки ног, синхронность и возврат в исходное положение.',
        ),
      ExerciseType.plank => t(
          'Hold time, hip height, shoulder position, and body stability.',
          'Время удержания, высоту таза, положение плеч и стабильность корпуса.',
        ),
      ExerciseType.shoulderPress => t(
          'Overhead extension, elbow path, symmetry, and body lean.',
          'Выпрямление над головой, траекторию локтей, симметрию и наклон корпуса.',
        ),
    };
  }
}

class _GuideCardCopy {
  const _GuideCardCopy({
    required this.title,
    required this.body,
    required this.bullets,
    required this.tone,
  });

  final String title;
  final String body;
  final List<String> bullets;
  final _GuideTone tone;
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.number,
    required this.title,
    required this.body,
    required this.bullets,
    required this.tone,
  });

  final String number;
  final String title;
  final String body;
  final List<String> bullets;
  final _GuideTone tone;

  Color get _backgroundColor {
    switch (tone) {
      case _GuideTone.blue:
        return const Color(0xFFEEF6FF);
      case _GuideTone.orange:
        return const Color(0xFFFFF1E4);
      case _GuideTone.green:
        return const Color(0xFFEDF8F0);
    }
  }

  Color get _foregroundColor {
    switch (tone) {
      case _GuideTone.blue:
        return const Color(0xFF12B3FF);
      case _GuideTone.orange:
        return const Color(0xFFFF7A00);
      case _GuideTone.green:
        return const Color(0xFF159947);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD9E2EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  number,
                  style: TextStyle(
                    color: _foregroundColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(body),
          if (bullets.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final bullet in bullets) _GuideBullet(text: bullet),
          ],
        ],
      ),
    );
  }
}

class _GuideBullet extends StatelessWidget {
  const _GuideBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text(
              '•',
              style: TextStyle(
                color: Color(0xFFFF7A00),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF18212F),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiChecksPanel extends StatelessWidget {
  const _AiChecksPanel({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF18212F),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xCCFFFFFF),
                ),
          ),
        ],
      ),
    );
  }
}

class _GoalModeButton extends StatelessWidget {
  const _GoalModeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF1E4) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                isSelected ? const Color(0xFFFF7A00) : const Color(0xFFD9E2EE),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFFFF7A00)
                  : const Color(0xFF18212F),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
