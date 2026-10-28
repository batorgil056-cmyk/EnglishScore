import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

abstract class SpeechBackend {
  /// Completes only when real speech finishes; onStarted is a native event.
  Future<void> speak(String text, {required VoidCallback onStarted});
  Future<void> stop();
}

class TtsSpeechBackend implements SpeechBackend {
  final FlutterTts _tts = FlutterTts();
  Completer<void>? _pending;
  int _generation = 0;

  @override
  Future<void> speak(String text, {required VoidCallback onStarted}) async {
    final stopping = stop();
    final generation = _generation;
    await stopping;
    if (generation != _generation) return;
    final completion = Completer<void>();
    _pending = completion;
    Timer? startTimeout;
    var started = false;
    bool getCurrent() => generation == _generation;
    void fail(Object error) {
      if (getCurrent() && !completion.isCompleted) {
        completion.completeError(error);
      }
    }

    _tts.setStartHandler(() {
      if (!getCurrent() || completion.isCompleted || started) return;
      started = true;
      startTimeout?.cancel();
      onStarted();
    });
    _tts.setCompletionHandler(() {
      if (!getCurrent() || completion.isCompleted) return;
      if (started) {
        completion.complete();
      } else {
        fail(StateError('Speech completed without starting.'));
      }
    });
    _tts.setErrorHandler((message) => fail(StateError(message)));
    _tts.setCancelHandler(() => fail(StateError('Speech was interrupted.')));
    // Observe errors immediately, including events arriving during configuration.
    final outcome = completion.future
        .then<Object?>((_) => null, onError: (Object error) => error);
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        await _tts.setSharedInstance(true);
        await _tts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback,
            [], IosTextToSpeechAudioMode.defaultMode);
      }
      await _tts.setLanguage('en-GB');
      await _tts.setSpeechRate(.44);
      await _tts.setVolume(1);
      await _tts.setPitch(1);
      await _tts.awaitSpeakCompletion(false);
      if (!getCurrent()) return;
      startTimeout = Timer(const Duration(seconds: 12),
          () => fail(StateError('No English speech was started.')));
      final result =
          await _tts.speak(text).timeout(const Duration(seconds: 12));
      if (result != 1) {
        fail(StateError('The speech engine could not play this recording.'));
      }
      final error = await outcome.timeout(
          Duration(seconds: math.max(45, text.split(' ').length + 20)));
      if (error != null) throw error;
    } finally {
      startTimeout?.cancel();
      if (getCurrent()) {
        _pending = null;
        // Also stop the engine on timeout/error; never leave speech running.
        await _tts.stop();
      }
    }
  }

  @override
  Future<void> stop() async {
    _generation++;
    final pending = _pending;
    _pending = null;
    if (pending != null && !pending.isCompleted) pending.complete();
    try {
      await _tts.stop();
    } catch (_) {/* Safe even before a plugin is ready. */}
  }
}

/// Playback state is derived from speech callbacks, never from a fake waveform.
class ListeningAudioController extends ChangeNotifier {
  ListeningAudioController(this._backend);
  final SpeechBackend _backend;
  int _generation = 0;
  int _playsUsed = 0;
  bool _busy = false;
  bool _playing = false;
  bool _heard = false;
  bool _started = false;
  bool _disposed = false;
  String? _error;
  final Stopwatch _elapsed = Stopwatch();
  Timer? _ticker;

  int get playsLeft => 2 - _playsUsed;
  bool get busy => _busy;
  bool get playing => _playing;
  bool get heard => _heard;

  /// Navigation unlocks on the first accepted Play press, not speech completion.
  bool get started => _started;
  String? get error => _error;
  Duration get elapsed => _elapsed.elapsed;
  bool get canPlay => !_disposed && !_busy && playsLeft > 0;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> play(String script) async {
    if (!canPlay) return;
    final generation = ++_generation;
    _busy = true;
    _started = true;
    _error = null;
    _elapsed.reset();
    _notify();
    try {
      await _backend.speak(script, onStarted: () {
        if (_disposed || generation != _generation || _playing) return;
        _playsUsed++;
        _playing = true;
        _elapsed.start();
        _ticker =
            Timer.periodic(const Duration(milliseconds: 120), (_) => _notify());
        _notify();
      });
      if (_disposed || generation != _generation) return;
      if (!_playing) throw StateError('Audio did not start.');
      _heard = true;
    } catch (_) {
      if (_disposed || generation != _generation) return;
      _error =
          'Audio could not be played. Check the device volume and English speech voice, then retry.';
    } finally {
      if (!_disposed && generation == _generation) {
        _busy = false;
        _playing = false;
        _elapsed.stop();
        _ticker?.cancel();
        _notify();
      }
    }
  }

  Future<void> interrupt() async {
    _generation++;
    final wasBusy = _busy;
    _busy = false;
    _playing = false;
    _elapsed.stop();
    _ticker?.cancel();
    if (wasBusy) {
      _error =
          'Playback interrupted. Each started play counts toward the two-play limit.';
    }
    _notify();
    await _backend.stop();
  }

  Future<void> reset() async {
    // Reset synchronously before awaiting stop, so stale events cannot leak.
    final stopped = interrupt();
    _playsUsed = 0;
    _heard = false;
    _started = false;
    _error = null;
    _elapsed.reset();
    _notify();
    await stopped;
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _ticker?.cancel();
    _elapsed.stop();
    unawaited(_backend.stop());
    super.dispose();
  }
}
