import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  bool get _isRussian => locale.languageCode == 'ru';

  String _text(String en, String ru) => _isRussian ? ru : en;

  String get welcomeBack => _text('Welcome back!', 'С возвращением!');
  String get loginSubtitle => _text(
        'Sign in to continue your training',
        'Войдите, чтобы продолжить тренировку',
      );
  String get email => 'Email';
  String get password => _text('Password', 'Пароль');
  String get login => _text('Login', 'Войти');
  String get dontHaveAccount => _text('No account yet?', 'Еще нет аккаунта?');
  String get register => _text('Register', 'Регистрация');
  String get alreadyHaveAccount =>
      _text('Already have an account?', 'Уже есть аккаунт?');
  String get createAccount => _text('Create account', 'Создать аккаунт');
  String get registerSubtitle => _text(
        'Create an account and track your progress',
        'Создайте аккаунт и отслеживайте прогресс',
      );
  String get loggingIn => _text('Signing in...', 'Выполняется вход...');
  String get registering => _text('Registering...', 'Создание аккаунта...');
  String get loginError => _text('Login error', 'Ошибка входа');
  String get registerError => _text('Registration error', 'Ошибка регистрации');

  String get fitnessAI => 'FITNESS AI';
  String get navHome => _text('Home', 'Главная');
  String get navHistory => _text('Workout history', 'История тренировок');
  String get trackProgress =>
      _text('Track your progress', 'Следите за прогрессом');
  String get logout => _text('Logout', 'Выйти');
  String get startWorkout => _text('START WORKOUT', 'НАЧАТЬ ТРЕНИРОВКУ');
  String get aiPoweredRepCounting =>
      _text('AI-powered rep counting', 'Подсчет повторений с AI');
  String get workoutHistory => _text('WORKOUT HISTORY', 'ИСТОРИЯ ТРЕНИРОВОК');
  String get noCamerasAvailable =>
      _text('No cameras available', 'Камеры недоступны');
  String get noWorkoutsYet => _text('No workouts yet', 'Тренировок пока нет');
  String get startFirstWorkout =>
      _text('Start your first workout', 'Начните первую тренировку');
  String get reps => _text('reps', 'повт.');
  String get today => _text('Today', 'Сегодня');
  String get yesterday => _text('Yesterday', 'Вчера');
  String daysAgo(int days) => _text('$days days ago', '$days дн. назад');
  String get retry => _text('Retry', 'Повторить');
  String get dashboardHeroTitle => _text('Your AI coach for cleaner reps',
      'Ваш AI-тренер для более чистых повторений');
  String get homeCoachHeroTitle =>
      _text('Train with cleaner form', 'Тренируйся чище');
  String get homeCoachHeroSubtitle => _text(
        'Choose an exercise and the camera will help you keep form and pace.',
        'Выбери упражнение, а камера поможет держать технику и темп.',
      );
  String get workoutsThisWeek =>
      _text('workouts this week', 'тренировки за неделю');
  String get exerciseCount => _text('5 exercises', '5 упражнений');
  String get dashboardHeroSubtitle => _text(
        'Start fast, stay consistent, and see your weekly progress clearly.',
        'Начинайте быстро, держите ритм и ясно видьте недельный прогресс.',
      );
  String get thisWeek => _text('This week', 'Эта неделя');
  String get weeklySessions => _text('sessions', 'сессий');
  String get weeklyReps => _text('total reps', 'всего повторений');
  String get averageQuality => _text('Average quality', 'Среднее качество');
  String get seeFullHistory => _text('See full history', 'Открыть всю историю');
  String get aiWillTrack => _text(
        'AI will track your form, pace, and repeat quality live.',
        'AI будет отслеживать технику, темп и качество повторений в реальном времени.',
      );
  String get historyTitle => _text('Workout history', 'История тренировок');
  String get historySubtitle => _text(
        'Recent sessions and technique quality',
        'Последние тренировки и качество техники',
      );
  String get historyWorkoutCount => _text('Workouts', 'Тренировок');
  String get allTime => _text('all time', 'за всё время');
  String get noWeeklyProgress => _text(
        'Complete a workout to unlock your weekly progress view.',
        'Завершите тренировку, чтобы открыть недельный прогресс.',
      );
  String get startNow => _text('Start now', 'Начать сейчас');
  String get viewDetails => _text('View details', 'Посмотреть детали');
  String get historyEmptyTitle =>
      _text('No completed sessions yet', 'Пока нет завершенных тренировок');
  String get historyEmptySubtitle => _text(
        'Start a workout and your session archive will appear here.',
        'Начните тренировку, и архив сессий появится здесь.',
      );
  String get chooseTarget => _text('Choose your target', 'Выберите цель');
  String get repsShort => _text('Reps', 'Повторы');
  String get timeShort => _text('Time', 'Время');
  String get startWorkoutNow => _text('Start workout', 'Начать тренировку');
  String get setupCoachSubtitle => _text(
        'AI will track your form, pace, and repeat quality live.',
        'AI будет отслеживать технику, темп и качество повторений в реальном времени.',
      );
  String get setupHeroEyebrow =>
      _text('Get ready for the exercise', 'Подготовьтесь к упражнению');
  String get setupHeroGuidance => _text(
        'AI will start analyzing once your body is clearly visible and you settle into the start position.',
        'AI начнет анализ, когда тело будет хорошо видно и вы займете стартовую позицию.',
      );
  String get setupPositionTab => _text('Position', 'Позиция');
  String get setupTechniqueTab => _text('Technique', 'Техника');
  String get setupMistakesTab => _text('Mistakes', 'Ошибки');
  String get setupBeforeStart => _text('Before you start', 'Перед стартом');
  String get setupCameraTitle => _text('Set the camera', 'Поставьте камеру');
  String get setupCameraBody => _text(
        'Keep your whole body in frame so the app can see shoulders, hips, knees, and feet.',
        'Тело должно полностью попадать в кадр, чтобы приложение видело плечи, таз, колени и стопы.',
      );
  String get setupCameraTipOne => _text(
        'Place the phone around chest or waist height.',
        'Поставьте телефон примерно на уровне груди или пояса.',
      );
  String get setupCameraTipTwo => _text(
        'Leave some space above your head and below your feet.',
        'Оставьте немного места над головой и под стопами.',
      );
  String get setupStartStanceTitle =>
      _text('Take the start position', 'Займите стартовую позицию');
  String get setupStartStanceBody => _text(
        'Do not rush the first rep. Hold the start position briefly so tracking can lock on.',
        'Не спешите с первым повтором. Коротко удержите стартовую позицию, чтобы отслеживание зафиксировалось.',
      );
  String get setupStanceTipOne => _text(
        'Move knees in the same direction as your toes.',
        'Ведите колени в сторону носков.',
      );
  String get setupStanceTipTwo => _text(
        'Keep your weight across the whole foot, not only on the toes.',
        'Держите вес на всей стопе, не только на носках.',
      );
  String get setupControlledRepTitle =>
      _text('Move with control', 'Двигайтесь контролируемо');
  String get setupControlledRepBody => _text(
        'Lower to a comfortable depth, then stand back up without collapsing your chest forward.',
        'Опускайтесь до комфортной глубины, затем вставайте без сильного завала корпуса вперед.',
      );
  String get setupAiChecksTitle => _text('What AI checks', 'Что AI проверяет');
  String get setupAiChecksBody => _text(
        'Depth, stable base, body alignment, and excessive forward lean.',
        'Глубину, устойчивую опору, положение корпуса и слишком сильный наклон вперед.',
      );
  String get howToStart => _text('How to start', 'Как начать');
  String get viewAnalysis => _text('View analysis', 'Посмотреть анализ');
  String get backToHome => _text('Back to home', 'На главную');
  String get sessionAnalysis => _text('Session analysis', 'Анализ тренировки');
  String get whatWentWell => _text('What went well', 'Что получилось хорошо');
  String get whatToImproveNext =>
      _text('What to improve next', 'Что улучшить дальше');
  String get qualityLabelText => _text('Quality', 'Качество');
  String get latestRepBreakdown =>
      _text('Latest rep breakdown', 'Разбор последних повторений');
  String get analysisUnavailable =>
      _text('Analysis unavailable', 'Анализ недоступен');
  String repsTracked(int repsCount) =>
      _text('$repsCount reps tracked', '$repsCount повт. засчитано');
  String get techniqueDataNotRecorded => _text(
        'Technique data was not recorded for this workout, so there is no per-rep form breakdown.',
        'Данные техники не были записаны для этой тренировки, поэтому разбора по повторам нет.',
      );
  String techniqueSamples(int samples) =>
      _text('$samples technique samples', '$samples сэмплов техники');
  String get noTechniqueSamples =>
      _text('No technique samples', 'Нет сэмплов техники');
  String get holdBreakdown => _text('Hold breakdown', 'Разбор удержания');
  String holdBreakdownSummary(int seconds, int samples) => _text(
        '$seconds sec hold - $samples analysis samples',
        '$seconds сек удержания - $samples сэмплов анализа',
      );
  String get reachedYourGoal =>
      _text('You reached your goal', 'Вы достигли цели');

  String get workout => _text('WORKOUT', 'ТРЕНИРОВКА');
  String get workoutSetup => _text('Workout setup', 'Подготовка тренировки');
  String get back => _text('Back', 'Назад');
  String get poseDetectionActive =>
      _text('Pose detection active', 'Определение позы активно');
  String get standInFrame => _text('Stand so your whole body stays in frame',
      'Встаньте так, чтобы тело полностью было в кадре');
  String get leftSide => _text('Left side', 'Левый бок');
  String get rightSide => _text('Right side', 'Правый бок');
  String get initializingCamera =>
      _text('Initializing camera...', 'Инициализация камеры...');
  String get failedToInitializeCamera => _text(
      'Failed to initialize camera', 'Не удалось инициализировать камеру');
  String get failedToStartCamera =>
      _text('Failed to start camera', 'Не удалось запустить камеру');
  String get switchCamera => _text('Switch camera', 'Сменить камеру');
  String get stateUp => _text('UP', 'ВВЕРХ');
  String get stateDown => _text('DOWN', 'ВНИЗ');
  String get start => _text('START', 'СТАРТ');
  String get finishWorkout => _text('FINISH', 'ЗАВЕРШИТЬ');
  String get exitWorkoutTitle =>
      _text('Finish workout?', 'Завершить тренировку?');
  String exitWorkoutMessage(int repsCount) => _text(
        'You have $repsCount reps. Save the result?',
        'У вас $repsCount повторений. Сохранить результат?',
      );
  String get exitWithoutSaving =>
      _text('Exit without saving', 'Выйти без сохранения');
  String get saveAndExit => _text('Save', 'Сохранить');
  String get chooseGoal => _text('CHOOSE GOAL', 'ВЫБЕРИТЕ ЦЕЛЬ');
  String get byReps => _text('BY REPS', 'ПО ПОВТОРЕНИЯМ');
  String get byTime => _text('BY TIME', 'ПО ВРЕМЕНИ');
  String get targetReps => _text('TARGET REPS', 'ЦЕЛЬ ПО ПОВТОРЕНИЯМ');
  String get durationSeconds => _text('DURATION (SEC)', 'ДЛИТЕЛЬНОСТЬ (СЕК)');
  String get startPositionTitle => _text('START POSITION', 'СТАРТОВАЯ ПОЗИЦИЯ');
  String get workoutTimerHint => _text(
        'The workout timer starts after you hold the correct start position.',
        'Таймер тренировки стартует после удержания правильной стартовой позы.',
      );
  String get goal => _text('Goal', 'Цель');
  String get timeLeft => _text('TIME LEFT', 'ОСТАЛОСЬ ВРЕМЕНИ');
  String get workoutComplete =>
      _text('Workout complete', 'Тренировка завершена');
  String repsGoalValue(int repsCount) =>
      _text('$repsCount reps', '$repsCount повторений');
  String durationGoalValue(int seconds) =>
      _text('$seconds sec', '$seconds сек');

  String get squats => _text('SQUATS', 'ПРИСЕДАНИЯ');
  String get pushups => _text('PUSH-UPS', 'ОТЖИМАНИЯ');
  String get jumpingJacks => _text('JUMPING JACKS', 'ДЖАМПИНГ-ДЖЕКИ');
  String get plank => _text('PLANK', 'ПЛАНКА');
  String get shoulderPress => _text('DUMBBELL PRESS', 'ЖИМ ГАНТЕЛЕЙ');
  String get lunges => _text('LUNGES', 'ВЫПАДЫ');

  String get positionYourselfInFrame =>
      _text('Position yourself in frame', 'Займите позицию в кадре');
  String get stepIntoFrame => _text('Step into frame', 'Встаньте в кадр');
  String get faceCamera => _text('Face the camera', 'Повернитесь к камере');
  String get goLower => _text('Go lower', 'Ниже');
  String get goDown => _text('Go down', 'Опускайтесь');
  String get standUp => _text('Stand up', 'Поднимайтесь');
  String get fixYourBack => _text('Fix your back', 'Исправьте спину');
  String get pushUp => _text('Push up', 'Поднимайтесь');
  String get good => _text('Good', 'Хорошо');
  String get getReady => _text('Get ready', 'Приготовьтесь');
  String get jump => _text('Jump', 'Прыгайте');
  String get raiseArms => _text('Raise arms', 'Поднимите руки');
  String get spreadLegs => _text('Spread legs', 'Разведите ноги');
  String get ready => _text('Ready', 'Готово');
  String get returnToStart =>
      _text('Return to start', 'Вернитесь в исходное положение');
  String get lowerArms => _text('Lower arms', 'Опустите руки');
  String get feetTogether => _text('Feet together', 'Ноги вместе');
  String get turnToSide => _text('Turn to your side', 'Повернитесь боком');
  String get keepFullSideVisible => _text(
        'Keep one full side visible',
        'Держите одну сторону тела полностью в кадре',
      );
  String get holdStartPose =>
      _text('Hold the start position', 'Удерживайте стартовую позу');
  String get holdStartPoseToStart => _text(
        'Hold still in the start position',
        'Замрите в стартовой позе',
      );
  String get trackingActive => _text('Tracking active', 'Отслеживание активно');
  String getReadyCountdown(int seconds) =>
      _text('Start in $seconds', 'Старт через $seconds');
  String holdStillCountdown(int seconds) => _text(
        'Hold still - start in $seconds',
        'Не двигайтесь - старт через $seconds',
      );
  String get startGuideFindFrame => _text(
        'Step into frame, then hold the start position before the first rep.',
        'Встаньте в кадр, затем удерживайте стартовую позу перед первым повтором.',
      );
  String get startGuideSideView => _text(
        'Turn sideways to the camera. The first rep starts only after the countdown.',
        'Повернитесь боком к камере. Первый повтор начинайте только после отсчета.',
      );
  String get startGuideFrontView => _text(
        'Face the camera. The first rep starts only after the countdown.',
        'Повернитесь лицом к камере. Первый повтор начинайте только после отсчета.',
      );
  String get startGuideBodyVisible => _text(
        'Keep the required joints visible and do not start the first rep yet.',
        'Держите нужные точки тела в кадре и пока не начинайте первый повтор.',
      );
  String get startGuideHoldStart => _text(
        'Hold the start position without moving until the countdown appears.',
        'Удерживайте стартовую позу без движения, пока не появится отсчет.',
      );
  String get startGuideCountdown => _text(
        'Start the first rep after the countdown finishes.',
        'Начинайте первый повтор после окончания отсчета.',
      );
  String repQualitySummary(int score, String issue) => _text(
        'Rep counted: $score/100, $issue',
        'Повтор засчитан: $score/100, $issue',
      );

  String get error => _text('Error', 'Ошибка');
  String get loading => _text('Loading...', 'Загрузка...');
  String get cancel => _text('Cancel', 'Отмена');
  String get ok => 'OK';
  String get settings => _text('Settings', 'Настройки');
  String get language => _text('Language', 'Язык');
  String get systemDefault => _text('System default', 'Системный');
  String get appLanguageDescription => _text(
        'Voice feedback follows the selected app language automatically.',
        'Голосовая озвучка автоматически следует выбранному языку приложения.',
      );
  String get languageEnglish => 'English';
  String get languageRussian => 'Русский';

  String get homeHeroBadge => _text('AI coach', 'AI-тренер');
  String get authWelcomeTitle => _text('Train smarter', 'Тренируйся умнее');
  String get authValueLine => _text(
        'Live cues, clear progress, and fast starts without extra friction.',
        'Живые подсказки, понятный прогресс и быстрый старт без лишних экранов.',
      );
  String get authBenefitLive => _text('Live AI coaching', 'Живые AI-подсказки');
  String get authBenefitProgress =>
      _text('Weekly progress', 'Недельный прогресс');
  String get authBenefitHistory =>
      _text('Workout history', 'История тренировок');
  String get emailRequiredError => _text('Enter your email', 'Введите email');
  String get emailInvalidError =>
      _text('Enter a valid email', 'Введите корректный email');
  String get passwordRequiredError =>
      _text('Enter your password', 'Введите пароль');
  String get passwordLengthError => _text(
        'Password must be at least 6 characters long',
        'Пароль должен содержать минимум 6 символов',
      );
  String get authErrorEmailTaken =>
      _text('Email already registered', 'Этот email уже зарегистрирован');
  String get authErrorInvalidCredentials =>
      _text('Invalid email or password', 'Неверный email или пароль');
  String get authErrorConnection => _text(
        'Connection error. Check your network.',
        'Ошибка соединения. Проверьте сеть.',
      );
  String completedWorkoutSummary(int repsCount, String quality) => _text(
        '$repsCount reps • Quality $quality',
        '$repsCount повторений • Качество $quality',
      );
  String analysisWinSummary(int repsCount) => _text(
        'You completed $repsCount reps and kept the session moving.',
        'Вы выполнили $repsCount повторений и сохранили хороший ритм тренировки.',
      );
  String noMajorIssueDetected() => _text(
        'No major technique issue was detected in this session.',
        'В этой тренировке не обнаружено выраженной технической ошибки.',
      );
  String repBreakdownTitle(int repIndex) =>
      _text('Rep $repIndex', 'Повтор $repIndex');
  String repBreakdownSubtitle(int score, String issue) =>
      _text('Score $score: $issue', 'Оценка $score: $issue');
  String exerciseName(String apiValue) {
    switch (apiValue.toLowerCase()) {
      case 'squat':
      case 'squats':
        return _text('Squats', 'Приседания');
      case 'pushup':
      case 'pushups':
      case 'push-up':
      case 'push-ups':
        return _text('Push-ups', 'Отжимания');
      case 'jumpingjack':
      case 'jumping_jack':
      case 'jumping-jack':
      case 'jumping_jacks':
        return _text('Jumping jacks', 'Джампинг-джеки');
      case 'plank':
      case 'planks':
        return _text('Plank', 'Планка');
      case 'shoulderpress':
      case 'shoulder_press':
      case 'shoulder-press':
      case 'shoulder_presses':
      case 'shoulder-presses':
        return _text('Dumbbell shoulder press', 'Жим гантелей стоя');
      default:
        return apiValue;
    }
  }

  String exerciseStartPositionHint(String apiValue) {
    switch (apiValue.toLowerCase()) {
      case 'squat':
      case 'squats':
        return _text(
          'Stand sideways to the camera with feet shoulder-width apart.',
          'Встаньте боком к камере, поставив стопы на ширину плеч.',
        );
      case 'pushup':
      case 'pushups':
      case 'push-up':
      case 'push-ups':
        return _text(
          'Turn sideways and hold a straight-arm plank before the first rep.',
          'Повернитесь боком и удерживайте планку на прямых руках перед первым повтором.',
        );
      case 'jumpingjack':
      case 'jumping_jack':
      case 'jumping-jack':
      case 'jumping_jacks':
        return _text(
          'Face the camera with feet together and arms relaxed at your sides.',
          'Встаньте лицом к камере, ноги вместе, руки свободно опущены вдоль корпуса.',
        );
      case 'plank':
      case 'planks':
        return _text(
          'Turn sideways and hold a forearm plank with shoulders over elbows.',
          'Повернитесь боком и удерживайте планку на предплечьях: плечи над локтями.',
        );
      case 'shoulderpress':
      case 'shoulder_press':
      case 'shoulder-press':
      case 'shoulder_presses':
      case 'shoulder-presses':
        return _text(
          'Turn sideways with dumbbells near shoulder height and elbows slightly forward.',
          'Встаньте боком к камере: гантели у плеч, локти чуть впереди.',
        );
      default:
        return apiValue;
    }
  }

  String techniqueIssue(String apiValue) {
    switch (apiValue) {
      case 'depth_too_shallow':
        return _text('depth too shallow', 'недостаточная глубина');
      case 'excessive_forward_lean':
        return _text('excessive forward lean', 'слишком сильный наклон вперед');
      case 'unstable_base':
        return _text('unstable base', 'нестабильная опора');
      case 'incomplete_lockout':
        return _text('incomplete lockout', 'неполная фиксация');
      case 'asymmetric_motion':
        return _text('asymmetric motion', 'асимметричное движение');
      case 'insufficient_depth':
        return _text('insufficient depth', 'недостаточная глубина');
      case 'hip_sag':
        return _text('hip sag', 'провисание таза');
      case 'pike_position':
        return _text('pike position', 'слишком высокая позиция таза');
      case 'incomplete_top_lockout':
        return _text(
          'incomplete top lockout',
          'неполная фиксация в верхней точке',
        );
      case 'head_dropping':
        return _text('head dropping', 'опускание головы');
      case 'arms_incomplete_overhead':
        return _text('arms incomplete overhead', 'руки не доведены вверх');
      case 'legs_not_wide_enough':
        return _text(
          'legs not wide enough',
          'ноги разведены недостаточно широко',
        );
      case 'poor_synchronization':
        return _text('poor synchronization', 'плохая синхронизация');
      case 'failed_return_to_closed':
        return _text(
          'failed return to closed',
          'нет возврата в исходное положение',
        );
      case 'left_right_asymmetry':
        return _text(
            'left-right asymmetry', 'асимметрия левой и правой стороны');
      case 'hips_too_high':
        return _text('hips too high', 'таз слишком высоко');
      case 'shoulders_not_over_elbows':
        return _text('shoulders not over elbows', 'плечи не над локтями');
      case 'unstable_position':
        return _text('unstable position', 'нестабильное положение');
      case 'incomplete_extension':
        return _text('incomplete extension', 'неполное выпрямление');
      case 'asymmetry':
        return _text('asymmetry', 'асимметрия');
      case 'elbows_too_wide':
        return _text('elbows too wide', 'локти слишком широко');
      case 'poor_lockout':
        return _text('poor lockout', 'плохая фиксация сверху');
      case 'excessive_back_lean':
        return _text('excessive back lean', 'сильный завал корпуса назад');
      case 'bar_path_forward':
        return _text('bar path forward', 'гриф уходит вперед');
      case 'dumbbells_forward':
        return _text('dumbbells drift forward', 'гантели уходят вперед');
      case 'knee_drive':
        return _text('knee drive', 'жим с помощью ног');
      case 'wrist_bent_back':
        return _text('wrist bent back', 'запястье заломлено назад');
      default:
        return apiValue.replaceAll('_', ' ');
    }
  }

  String workoutTileSummary(int repsCount, String quality) => _text(
        '$repsCount reps • Quality $quality',
        '$repsCount повт. • Качество $quality',
      );
  String historySessionTime(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  String historyDateLabel(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return _isRussian ? '$day.$month.${date.year}' : '$month/$day/${date.year}';
  }

  String workoutFocusLabel(String issue) =>
      _text('Focus: $issue', 'Фокус: $issue');
  String cameraInitializationError(String error) => _text(
      '$failedToInitializeCamera: $error', '$failedToInitializeCamera: $error');
  String cameraStartError(String error) =>
      _text('$failedToStartCamera: $error', '$failedToStartCamera: $error');
  String workoutReadyPrompt(String exerciseName, String hint) => _text(
        'Get ready for $exerciseName. $hint',
        'Подготовьтесь к упражнению $exerciseName. $hint',
      );
  String pageNotFound(Object? error) =>
      _text('Page not found: $error', 'Страница не найдена: $error');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['ru', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final supported = isSupported(locale) ? locale : const Locale('en');
    return AppLocalizations(supported);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
