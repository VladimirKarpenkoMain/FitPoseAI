# FeedbackManager Usage Guide

This guide explains how to use the FeedbackManager and WorkoutFeedbackCoordinator for providing audio feedback during workouts.

## Basic Usage

### 1. Using FeedbackManager Directly (Singleton)

```dart
import 'package:fitness_ai/services/feedback_manager.dart';

// Get the singleton instance
final feedbackManager = FeedbackManager();

// Speak a message
await feedbackManager.speak("Go Lower");

// Speak a rep count
await feedbackManager.speakRepCount(5); // Says "Five"

// Play a beep sound
await feedbackManager.playBeep();

// Stop current speech
await feedbackManager.stop();

// Change language
await feedbackManager.setRussian();
await feedbackManager.setEnglish();
```

### 2. Using with Riverpod Provider (Recommended)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitness_ai/providers/feedback_provider.dart';

class WorkoutScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedbackManager = ref.watch(feedbackProvider);
    
    return ElevatedButton(
      onPressed: () async {
        await feedbackManager.speak("Good job!");
      },
      child: Text('Test TTS'),
    );
  }
}
```

### 3. Using WorkoutFeedbackCoordinator with Exercise Counters

```dart
import 'package:fitness_ai/logic/exercise_counters.dart';
import 'package:fitness_ai/services/feedback_manager.dart';
import 'package:fitness_ai/services/workout_feedback_coordinator.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class SquatWorkout {
  final SquatCounter counter = SquatCounter();
  final WorkoutFeedbackCoordinator coordinator;
  
  SquatWorkout() : coordinator = WorkoutFeedbackCoordinator(FeedbackManager());
  
  Future<void> processPose(Pose pose) async {
    // Calculate counter result
    final result = counter.calculate(pose);
    
    // Provide feedback automatically
    await coordinator.processFeedback(result);
    
    // The coordinator will:
    // - Play beep on successful rep
    // - Speak the rep count ("One", "Two", etc.)
    // - Speak corrections ("Go Lower", "Stand Up", etc.)
  }
  
  void startWorkout() {
    coordinator.speakCustom("Ready to start!", priority: true);
  }
  
  void reset() {
    counter.reset();
    coordinator.reset();
  }
}
```

## Complete Example: Workout Screen with Feedback

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:fitness_ai/logic/exercise_counters.dart';
import 'package:fitness_ai/providers/feedback_provider.dart';
import 'package:fitness_ai/services/workout_feedback_coordinator.dart';

class SquatWorkoutScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<SquatWorkoutScreen> createState() => _SquatWorkoutScreenState();
}

class _SquatWorkoutScreenState extends ConsumerState<SquatWorkoutScreen> {
  final SquatCounter _counter = SquatCounter();
  late WorkoutFeedbackCoordinator _coordinator;
  String _currentFeedback = "Ready";
  int _repCount = 0;
  
  @override
  void initState() {
    super.initState();
    _coordinator = WorkoutFeedbackCoordinator(FeedbackManager());
    _startCountdown();
  }
  
  Future<void> _startCountdown() async {
    await _coordinator.speakCustom("Get ready", priority: true);
    await Future.delayed(Duration(seconds: 2));
    await _coordinator.speakCustom("Start!", priority: true);
  }
  
  Future<void> _processPose(Pose pose) async {
    final result = _counter.calculate(pose);
    
    // Update UI
    setState(() {
      _repCount = result.count;
      _currentFeedback = result.feedback;
    });
    
    // Provide audio feedback
    await _coordinator.processFeedback(result);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Squat Workout')),
      body: Column(
        children: [
          // Camera view would go here
          Text('Reps: $_repCount', style: TextStyle(fontSize: 48)),
          Text('Feedback: $_currentFeedback', style: TextStyle(fontSize: 24)),
          
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _coordinator.stop();
    super.dispose();
  }
}
```

### App language and TTS

The app language is now controlled from `SettingsScreen`.

- `System default` follows the device language.
- `English` forces `en-US`.
- `Russian` forces `ru-RU`.

Android Google TTS follows the effective app language automatically, so there is no separate in-app TTS language selector anymore.

## Features

### Text-to-Speech (TTS)

1. **Non-overlapping Speech**: New important messages cancel previous ones
2. **Cooldown**: Prevents rapid-fire repetition of the same message
3. **Number-to-Words**: Converts rep counts to natural speech ("One", "Two", etc.)
4. **Multi-language**: Supports English and Russian

### Sound Effects

1. **Success Beep**: Plays on each successful repetition
2. **Fallback**: Gracefully handles missing sound files

### Smart Feedback

1. **Context-aware**: Only speaks important corrections
2. **Prioritization**: Rep counts and critical warnings take priority
3. **Cooldown**: Avoids annoying repetition

## Configuration

### Change Speech Rate

```dart
// In FeedbackManager._initializeTTS(), modify:
await _flutterTts.setSpeechRate(0.5); // 0.5 = slower, 1.0 = normal, 2.0 = faster
```

### Change Cooldown Duration

```dart
// In FeedbackManager
static const int speechCooldownMs = 1500; // milliseconds

// In WorkoutFeedbackCoordinator
static const int feedbackCooldownMs = 2000; // milliseconds
```

### Add Custom Feedback Messages

In `WorkoutFeedbackCoordinator._shouldSpeakFeedback()`, add to the list:

```dart
const importantFeedback = [
  'Go Lower',
  'Your custom message here',
  // ... other messages
];
```

## Troubleshooting

### TTS Not Working
- Ensure device has TTS engine installed (Google TTS on Android)
- Check device volume settings
- Try different speech rate values

### Beep Not Playing
- Add `beep.mp3` to `assets/sounds/` directory
- Run `flutter pub get`
- Rebuild the app

### Speech Overlapping
- Increase `speechCooldownMs` value
- Use `priority: true` for important messages
- Call `stop()` before critical announcements
