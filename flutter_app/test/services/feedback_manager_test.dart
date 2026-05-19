import 'package:fitness_ai/services/feedback_manager.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const ttsChannel = MethodChannel('flutter_tts');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, (call) async {
      calls.add(call);
      return true;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ttsChannel, null);
  });

  test('applies Russian TTS language before speaking Russian rep counts',
      () async {
    final manager = FeedbackManager();

    await manager.setEnglish();
    calls.clear();
    await manager.setRussian();
    await manager.speakRepCount(5, priority: true);

    final speakIndex = calls.indexWhere((call) => call.method == 'speak');
    expect(speakIndex, isNot(-1));
    expect(calls[speakIndex].arguments, 'Пять');

    final languageBeforeSpeak = calls
        .take(speakIndex)
        .where((call) => call.method == 'setLanguage')
        .map((call) => call.arguments)
        .last;
    expect(languageBeforeSpeak, 'ru-RU');
    expect(
      calls.where((call) => call.method == 'setLanguage'),
      hasLength(1),
    );
  });

  test('allows repeated non-priority speech after cooldown', () async {
    final manager = FeedbackManager();

    await manager.setEnglish();
    calls.clear();

    await manager.speak('Hold the start position', priority: true);
    await Future<void>.delayed(
      const Duration(milliseconds: FeedbackManager.speechCooldownMs + 50),
    );
    await manager.speak('Hold the start position');

    expect(
      calls.where((call) => call.method == 'speak'),
      hasLength(2),
    );
  });
}
