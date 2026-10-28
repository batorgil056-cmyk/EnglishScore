import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'selfie_camera_backend.dart';

class SelfieCaptureResult {
  const SelfieCaptureResult.demo()
      : simulated = true,
        bytes = null;
  const SelfieCaptureResult.photo(this.bytes) : simulated = false;
  final bool simulated;
  final Uint8List? bytes;
}

/// Simulator preview is deliberately a graphic placeholder, never a fake feed.
/// Device camera access requires Enable camera, then an explicit capture tap.
class SelfieCapture extends StatefulWidget {
  const SelfieCapture(
      {super.key,
      required this.paused,
      required this.onCaptured,
      this.backend});
  final bool paused;
  final ValueChanged<SelfieCaptureResult> onCaptured;
  final SelfieCameraBackend? backend;
  @override
  State<SelfieCapture> createState() => _SelfieCaptureState();
}

class _SelfieCaptureState extends State<SelfieCapture>
    with WidgetsBindingObserver {
  late final SelfieCameraBackend _backend = widget.backend ?? IosSelfieCamera();
  SelfieEnvironment? _environment;
  bool _demo = false;
  bool _busy = false;
  bool _ready = false;
  bool _finishing = false;
  bool _active = true;
  String? _message;
  int _operation = 0;
  static const _teal = Color(0xFF039D8C);
  static const _purple = Color(0xFF210957);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _detect();
  }

  Future<void> _detect() async {
    try {
      final environment = await _backend.environment();
      if (mounted) {
        setState(() {
          _environment = environment;
          _demo = environment == SelfieEnvironment.iosSimulator;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _environment = SelfieEnvironment.unsupported;
          _message = 'Unable to detect camera support. You can use demo mode.';
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (_demo || _environment != SelfieEnvironment.iosDevice) {
      if (mounted) setState(() {});
      return;
    }
    // Permission prompts can briefly make the app inactive while start() is
    // pending. Pause initialized previews, or cancel when fully backgrounded.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        (state == AppLifecycleState.inactive && _ready)) {
      _operation++;
      _ready = false;
      _busy = false;
      if (mounted) {
        setState(() =>
            _message = 'Camera paused. Tap Enable front camera to resume.');
      }
      unawaited(_stopSafely());
    }
    if (_active && mounted) setState(() {});
  }

  Future<void> _stopSafely() async {
    try {
      await _backend.stop();
    } catch (_) {/* No preview is retained. */}
  }

  @override
  void dispose() {
    _operation++;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_stopSafely());
    super.dispose();
  }

  Future<void> _enable() async {
    if (_busy || _demo || widget.paused || !_active) return;
    final operation = ++_operation;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await _backend.start();
      if (mounted && operation == _operation) setState(() => _ready = true);
    } on CameraException catch (error) {
      if (mounted && operation == _operation) {
        setState(() => _message = switch (error.code) {
              'CameraAccessDenied' =>
                'Camera permission denied. Enable access in iPhone Settings → Privacy & Security → Camera.',
              'CameraAccessDeniedWithoutPrompt' =>
                'Camera access was previously denied. Enable it in iPhone Settings → Privacy & Security → Camera.',
              'CameraAccessRestricted' =>
                'Camera access is restricted on this iPhone.',
              'NoFrontCamera' => 'No front camera is available on this device.',
              _ => 'Could not start the front camera. Please try again.',
            });
        await _stopSafely();
      }
    } catch (_) {
      if (mounted && operation == _operation) {
        setState(() =>
            _message = 'Could not start the front camera. Please try again.');
        await _stopSafely();
      }
    } finally {
      if (mounted && operation == _operation) setState(() => _busy = false);
    }
  }

  Future<void> _capture() async {
    if (_busy ||
        _finishing ||
        widget.paused ||
        !_active ||
        (!_demo && !_ready)) {
      return;
    }
    if (_demo) {
      _finishing = true;
      widget.onCaptured(const SelfieCaptureResult.demo());
      return;
    }
    final operation = ++_operation;
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final bytes = await _backend.capture();
      if (!mounted || operation != _operation) return;
      _finishing = true;
      await _stopSafely();
      if (mounted && operation == _operation) {
        widget.onCaptured(SelfieCaptureResult.photo(bytes));
      }
    } catch (_) {
      if (mounted && operation == _operation) {
        setState(() {
          _finishing = false;
          _message = 'Could not capture the photo. Please try again.';
        });
      }
    } finally {
      if (mounted && operation == _operation) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s =
        (MediaQuery.sizeOf(context).width / 375).clamp(.85, 1.15).toDouble();
    TextStyle text(double size,
            {bool bold = false, Color color = const Color(0xFF181818)}) =>
        TextStyle(
            fontFamily: 'Arial',
            fontSize: size * s,
            height: 1.2,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            color: color);
    final enabled =
        !_busy && !_finishing && !widget.paused && _active && (_demo || _ready);
    final label = _environment == null
        ? 'Checking camera support…'
        : _demo
            ? 'Simulated camera preview\nNot a live camera or verified selfie'
            : _ready
                ? 'Live front camera — capture only on tap'
                : _environment == SelfieEnvironment.iosDevice
                    ? 'Front camera is off\nTap Enable front camera below'
                    : 'Camera preview unavailable';
    return LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16 * s, 78 * s, 16 * s, 16 * s),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      minHeight: (box.maxHeight - 94 * s)
                          .clamp(500 * s, double.infinity)),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(children: [
                          ClipRRect(
                              borderRadius: BorderRadius.circular(24 * s),
                              child: SizedBox(
                                  width: 206 * s,
                                  height: 275 * s,
                                  child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Positioned.fill(
                                            child: _ready && !_demo
                                                ? _backend.preview()
                                                : const ColoredBox(
                                                    color: Color(0xFFEDECF1))),
                                        if (_demo)
                                          Icon(Icons.person_outline_rounded,
                                              size: 85 * s,
                                              color: const Color(0xFFB6B0C6)),
                                        IgnorePointer(
                                            child: Container(
                                                width: 125 * s,
                                                height: 180 * s,
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            90 * s),
                                                    border: Border.all(
                                                        color:
                                                            _purple.withValues(
                                                                alpha: .4),
                                                        width: 3 * s)))),
                                        Positioned(
                                            left: 8 * s,
                                            right: 8 * s,
                                            bottom: 10 * s,
                                            child: DecoratedBox(
                                                decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withValues(alpha: .9),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4 * s)),
                                                child: Padding(
                                                    padding:
                                                        EdgeInsets.all(4 * s),
                                                    child: Text(label,
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: text(11))))),
                                      ]))),
                          SizedBox(height: 22 * s),
                          Text('Take a selfie', style: text(23, bold: true)),
                          SizedBox(height: 10 * s),
                          Text('to test your camera', style: text(19)),
                          if (_message != null)
                            Padding(
                                padding: EdgeInsets.only(top: 8 * s),
                                child: Text(_message!,
                                    textAlign: TextAlign.center,
                                    style: text(12))),
                          if (!_demo && !_ready && _environment != null) ...[
                            if (_environment == SelfieEnvironment.iosDevice)
                              TextButton(
                                  onPressed:
                                      _busy || widget.paused ? null : _enable,
                                  child: const Text('Enable front camera')),
                            TextButton(
                                onPressed: _busy || widget.paused
                                    ? null
                                    : () => setState(() {
                                          _demo = true;
                                          _message = null;
                                        }),
                                child: const Text('Use demo camera')),
                          ],
                        ]),
                        Padding(
                            padding: EdgeInsets.only(top: 35 * s),
                            child: SizedBox(
                                width: 85 * s,
                                height: 85 * s,
                                child: IconButton(
                                    onPressed: enabled ? _capture : null,
                                    tooltip: _demo
                                        ? 'Capture demo image'
                                        : 'Capture selfie',
                                    padding: EdgeInsets.zero,
                                    icon: Container(
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: enabled
                                                ? _teal
                                                : _teal.withValues(alpha: .45)),
                                        padding: EdgeInsets.all(5 * s),
                                        child: Container(
                                            decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                    color: Colors.white,
                                                    width: 2 * s)),
                                            child: _busy
                                                ? const Center(
                                                    child: SizedBox(
                                                        width: 24,
                                                        height: 24,
                                                        child:
                                                            CircularProgressIndicator(
                                                                color: Colors
                                                                    .white,
                                                                strokeWidth:
                                                                    2)))
                                                : null))))),
                      ]),
                ),
              ),
            ));
  }
}
