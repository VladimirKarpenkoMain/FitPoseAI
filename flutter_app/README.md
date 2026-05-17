# FitPose AI - Flutter Client

Flutter mobile app for AI-powered fitness tracking.

## Setup

### 1. Install Dependencies

```bash
cd flutter_app
flutter pub get
```

### 2. Configure API URL

Edit `lib/config/api_config.dart`:

```dart
// For Android emulator:
static const String baseUrl = 'http://10.0.2.2:8000';

// For iOS simulator:
static const String baseUrl = 'http://localhost:8000';

// For real device (use your computer's IP):
static const String baseUrl = 'http://192.168.x.x:8000';
```

### 3. Run the App

```bash
flutter run
```

### 4. Add Beep Sound Asset (Optional but Recommended)

The app works perfectly without the beep sound (uses online fallback). To add a custom beep:

1. Download a short beep sound (0.2-0.5 seconds) from:
   - [FreeSound.org](https://freesound.org/search/?q=beep) - Free sound library
   - [Online Tone Generator](https://www.szynalski.com/tone-generator/) - Generate custom beep

2. Save it as `assets/sounds/beep.mp3`

3. Uncomment the assets section in `pubspec.yaml`:
   ```yaml
   flutter:
     uses-material-design: true
     assets:
       - assets/sounds/beep.mp3
   ```

4. Run `flutter pub get` and rebuild the app

See `assets/sounds/README.md` for detailed instructions.

## Project Structure

```
lib/
├── main.dart                    # Entry point
├── config/
│   └── api_config.dart          # API configuration
├── models/
│   ├── user.dart                # User model
│   └── workout.dart             # Workout model
├── services/
│   ├── api_service.dart         # Dio HTTP client
│   ├── feedback_manager.dart    # TTS & sound effects (Singleton)
│   └── workout_feedback_coordinator.dart  # Coordinates feedback
├── providers/
│   ├── api_provider.dart        # API service provider
│   ├── auth_provider.dart       # Authentication state
│   ├── workout_provider.dart    # Workouts state
│   └── feedback_provider.dart   # Feedback manager provider
├── logic/
│   ├── exercise_counter.dart    # Abstract base class
│   ├── squat_counter.dart       # Squat counting logic
│   ├── pushup_counter.dart      # Push-up counting logic
│   ├── jumping_jack_counter.dart # Jumping jack counting logic
│   └── exercise_counters.dart   # Export file
├── utils/
│   └── pose_geometry.dart       # Angle calculation utilities
├── router/
│   └── app_router.dart          # GoRouter navigation
├── screens/
│   ├── auth_screen.dart         # Login/Register screen
│   ├── home_screen.dart         # Home screen with workout list
│   └── workout/
│       ├── workout_screen.dart  # Main workout screen
│       ├── pose_detector_view.dart
│       └── painters/
│           └── pose_painter.dart
└── examples/
    └── feedback_example.dart    # Usage examples
```

## Features

### Authentication & Backend
- ✅ User Registration
- ✅ User Login (JWT)
- ✅ Secure token storage
- ✅ View workout history

### AI-Powered Exercise Tracking
- ✅ **Exercise Counting Logic**
  - Squat counter (Hip-Knee-Ankle angle, anti-cheat)
  - Push-up counter (Shoulder-Elbow-Wrist angle, body alignment check)
  - Jumping jack counter (arm & leg coordination)
- ✅ **Feedback System (Section 3)**
  - Text-to-Speech (English/Russian)
  - Rep count announcements ("One", "Two", etc.)
  - Form corrections ("Go Lower", "Fix your back!")
  - Success beep sound on each rep
  - Non-overlapping speech with priority system
- 🔜 Camera integration with ML Kit
- 🔜 Real-time pose detection UI

## Exercise Counting (Section 2)

### Squats
- **Angle:** Hip → Knee → Ankle (at knee joint)
- **State UP:** Angle > 160° (standing)
- **State DOWN:** Angle < 85° (squat)
- **Anti-cheat:** Hip Y-coordinate must move down

### Push-ups
- **Angle:** Shoulder → Elbow → Wrist (at elbow)
- **State UP:** Angle > 160° (arms extended)
- **State DOWN:** Angle < 90° (chest to floor)
- **Body check:** Shoulder → Hip → Ankle > 160° (straight back)

### Jumping Jacks
- **Arms:** Shoulder → Elbow → Wrist
- **Legs:** Angle between legs (via hip-knee)
- **State CLOSED:** Arms < 30°, Legs < 20°
- **State OPEN:** Arms > 150°, Legs > 45°

## Feedback System (Section 3)

### Text-to-Speech
- Speaks rep counts in words ("One", "Two", ...)
- Provides real-time corrections
- Configurable language (English/Russian)
- Non-overlapping speech (priority system)
- Automatic cooldown to prevent repetition

### Sound Effects
- Beep sound on successful rep completion
- Fallback mechanism if sound file missing

### Usage Example
```dart
import 'package:fitness_ai/logic/exercise_counters.dart';
import 'package:fitness_ai/services/feedback_manager.dart';
import 'package:fitness_ai/services/workout_feedback_coordinator.dart';

final counter = SquatCounter();
final coordinator = WorkoutFeedbackCoordinator(FeedbackManager());

// Process pose
final result = counter.calculate(pose);
await coordinator.processFeedback(result);
// Automatically speaks feedback and plays beep on rep!
```

See `lib/services/FEEDBACK_USAGE.md` for detailed documentation.

## Dependencies

### State Management & Navigation
- `flutter_riverpod` - State management
- `go_router` - Navigation

### Backend Communication
- `dio` - HTTP client
- `flutter_secure_storage` - Secure JWT storage

### AI & Computer Vision
- `camera` - Camera access
- `google_mlkit_pose_detection` - On-device pose detection

### Feedback System
- `flutter_tts` - Text-to-Speech
- `audioplayers` - Sound effects

## Workout analysis redesign

- Squat and push-up tracking now expects a side view for readiness and rep analysis.
- Jumping jack tracking now expects a front view.
- Tracking starts only after a 10-second readiness countdown while the start pose stays stable.
- Workout history can store session quality score and per-rep analytics payloads.

## UI/UX redesign flow

- Home now leads with a weekly progress dashboard and quick-start workout actions.
- Workout history lives on a separate screen and links into session analysis.
- Completing a workout opens a dedicated success screen before the analysis view.
- Analysis prioritizes motivation and progress summary before detailed technique fixes.
