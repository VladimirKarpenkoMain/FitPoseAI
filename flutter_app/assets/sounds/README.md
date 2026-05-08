# Sound Assets

This folder contains audio files used for workout feedback.

## Required Files

### beep.mp3
A short beep sound played when a repetition is successfully completed.

**Requirements:**
- Duration: 0.2-0.5 seconds
- Format: MP3
- Volume: Moderate (not too loud)
- Type: Simple tone or pleasant notification sound

**How to obtain:**
1. **Option 1 - Download a free beep sound:**
   - Visit [FreeSound.org](https://freesound.org/search/?q=beep)
   - Download a short beep sound (look for "success" or "positive" sounds)
   - Rename it to `beep.mp3`
   - Place it in this directory

2. **Option 2 - Use a sound generator:**
   - Use [Online Tone Generator](https://www.szynalski.com/tone-generator/)
   - Generate a 800-1000 Hz tone for 0.3 seconds
   - Export as MP3
   - Save as `beep.mp3` in this directory

3. **Option 3 - Record your own:**
   - Use any audio recording software
   - Create a short, pleasant beep sound
   - Export as MP3
   - Save as `beep.mp3` in this directory

## Fallback Behavior

If `beep.mp3` is not found, the FeedbackManager will:
- Try to use an online sound source as fallback
- Silently fail without affecting the app functionality
- Continue to provide TTS feedback normally

## Adding the File

After obtaining `beep.mp3`:
1. Place it in this directory (`assets/sounds/beep.mp3`)
2. The file is already referenced in `pubspec.yaml`
3. Run `flutter pub get` to ensure assets are recognized
4. Rebuild your app
