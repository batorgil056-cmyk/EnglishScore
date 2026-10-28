import 'dart:async';
import 'package:englishscore_intro/core_test/listening_audio.dart';
import 'package:flutter/foundation.dart';

class TestSpeechBackend implements SpeechBackend {
  int calls = 0;
  int stops = 0;
  VoidCallback? started;
  Completer<void>? pending;
  bool failBeforeStart = false;
  bool instant = false;
  final List<String> scripts = [];
  @override
  Future<void> speak(String text, {required VoidCallback onStarted}) async {
    calls++;
    scripts.add(text);
    if (failBeforeStart) throw StateError('No voice');
    started = onStarted;
    if (instant) {
      onStarted();
      return;
    }
    pending = Completer<void>();
    await pending!.future;
  }

  void begin() => started!();
  void finish() => pending!.complete();
  void fail() => pending!.completeError(StateError('Audio device lost'));
  @override
  Future<void> stop() async {
    stops++;
    if (pending != null && !pending!.isCompleted) pending!.complete();
  }
}
