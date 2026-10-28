import 'package:englishscore_intro/core_test/listening_audio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'support/test_speech_backend.dart';

void main() {
  test('only native start animates/consumes a play; at most two actual starts',
      () async {
    final backend = TestSpeechBackend();
    final audio = ListeningAudioController(backend);
    addTearDown(audio.dispose);
    var playing = audio.play('Original English speech.');
    expect(audio.started, isTrue);
    expect(audio.busy, isTrue);
    expect(audio.playing, isFalse);
    expect(audio.playsLeft, 2);
    await audio.play('Duplicate press');
    expect(backend.calls, 1);
    backend.begin();
    backend.begin();
    expect(audio.playing, isTrue);
    expect(audio.playsLeft, 1);
    expect(audio.heard, isFalse);
    backend.finish();
    await playing;
    expect(audio.heard, isTrue);
    expect(audio.playing, isFalse);
    playing = audio.play('Original English speech.');
    backend.begin();
    backend.finish();
    await playing;
    expect(audio.playsLeft, 0);
    expect(audio.canPlay, isFalse);
    await audio.play('Must not play a third time');
    expect(backend.calls, 2);
  });
  test('failure before start offers retry without pretending audio played',
      () async {
    final backend = TestSpeechBackend()..failBeforeStart = true;
    final audio = ListeningAudioController(backend);
    addTearDown(audio.dispose);
    await audio.play('Original speech.');
    expect(audio.error, isNotNull);
    expect(audio.playsLeft, 2);
    expect(audio.heard, isFalse);
    expect(audio.playing, isFalse);
    backend.failBeforeStart = false;
    backend.instant = true;
    await audio.play('Original speech.');
    expect(audio.error, isNull);
    expect(audio.heard, isTrue);
    expect(audio.playsLeft, 1);
  });
  test('failure after start counts the attempt and never exceeds two plays',
      () async {
    final backend = TestSpeechBackend();
    final audio = ListeningAudioController(backend);
    addTearDown(audio.dispose);
    for (var i = 0; i < 2; i++) {
      final playing = audio.play('Original speech.');
      backend.begin();
      backend.fail();
      await playing;
    }
    expect(audio.playsLeft, 0);
    expect(audio.error, isNotNull);
    expect(audio.heard, isFalse);
    await audio.play('A third attempt');
    expect(backend.calls, 2);
  });
  test('interrupt and question reset reject late callbacks and clear playback',
      () async {
    final backend = TestSpeechBackend();
    final audio = ListeningAudioController(backend);
    addTearDown(audio.dispose);
    final playing = audio.play('First question.');
    final oldStarted = backend.started!;
    backend.begin();
    await audio.interrupt();
    await playing;
    expect(audio.playsLeft, 1);
    expect(audio.heard, isFalse);
    expect(audio.playing, isFalse);
    await audio.reset();
    oldStarted();
    expect(audio.playsLeft, 2);
    expect(audio.error, isNull);
    expect(audio.heard, isFalse);
    expect(audio.elapsed, Duration.zero);
    expect(audio.started, isFalse);
    backend.instant = true;
    await audio.play('Second question.');
    expect(audio.playsLeft, 1);
    expect(audio.heard, isTrue);
  });
}
