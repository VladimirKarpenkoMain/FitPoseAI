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

## Feedback System

### Text-to-Speech
- Speaks rep counts in words ("One", "Two", ...)
- Provides real-time corrections
- Configurable language (English/Russian)
- Non-overlapping speech (priority system)
- Automatic cooldown to prevent repetition

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
