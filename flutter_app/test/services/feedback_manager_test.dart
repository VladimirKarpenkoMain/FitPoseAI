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

    await manager.setRussian();
    calls.clear();
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
  });
}
