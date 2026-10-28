import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'selfie_capture.dart';

const _purple = Color(0xFF210957);
const _teal = Color(0xFF039D8C);
const _ink = Color(0xFF181818);

enum SetupStage { intro, volume, microphone, camera, selfie, review }

/// Reference-matched setup UI only. Progress markers describe navigation,
/// not verified audio, running monitoring, camera access or identity checks.
class CoreSetupScreens extends StatefulWidget {
  const CoreSetupScreens(
      {super.key,
      required this.stage,
      required this.paused,
      required this.onClose,
      required this.onAdvance,
      this.onRetake});
  final SetupStage stage;
  final bool paused;
  final VoidCallback onClose;
  final VoidCallback onAdvance;
  final VoidCallback? onRetake;

  @override
  State<CoreSetupScreens> createState() => _CoreSetupScreensState();
}

class _CoreSetupScreensState extends State<CoreSetupScreens> {
  Timer? _waveTimer;
  int _waveTick = 0;
  bool _infoOpen = false;
  SelfieCaptureResult? _captureResult;
  static const _microphoneText =
      'You should be alone in a quiet place.\nYou must not talk during the exam,\nand you must not read the questions\naloud.';
  static const _microphoneInfo =
      'EnglishScore uses the microphone to detect if you or someone else is talking. Potential violations are recorded and reviewed.';
  static const _cameraText =
      'During the test, photos are taken\nto prove you took the test\nproperly.';

  @override
  void initState() {
    super.initState();
    _configureWave();
  }

  @override
  void didUpdateWidget(covariant CoreSetupScreens oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stage != widget.stage) _configureWave();
  }

  void _configureWave() {
    _waveTimer?.cancel();
    _waveTick = 0;
    if (widget.stage == SetupStage.volume) {
      // There is no audio asset/player. This deliberately labeled demo pulse
      // must never be used as evidence that speech audio was played or heard.
      _waveTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
        if (mounted && !widget.paused && !_infoOpen) {
          setState(() => _waveTick++);
        }
      });
    }
  }

  @override
  void dispose() {
    _waveTimer?.cancel();
    super.dispose();
  }

  TextStyle _text(double size, {bool bold = false, Color color = _ink}) =>
      TextStyle(
        fontFamily: 'Arial',
        fontSize: size,
        height: 1.2,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        color: color,
      );

  Widget _art(String name, double size, {Color? color}) => SvgPicture.asset(
        'assets/pretest/$name.svg',
        width: size,
        height: size,
        theme: SvgTheme(currentColor: color ?? _purple),
        excludeFromSemantics: true,
      );

  Widget _button(String label, VoidCallback action, double s) => SizedBox(
        width: double.infinity,
        height: 52 * s,
        child: ElevatedButton(
          onPressed: action,
          style: ElevatedButton.styleFrom(
              backgroundColor: _purple,
              foregroundColor: Colors.white,
              elevation: 1,
              padding: EdgeInsets.symmetric(horizontal: 12 * s),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24 * s)),
              textStyle: _text(16.5 * s, bold: true)),
          child: Text(label),
        ),
      );

  Future<void> _showInfo({required bool microphone}) async {
    if (_infoOpen) return;
    _infoOpen = true;
    final s =
        (MediaQuery.sizeOf(context).width / 375).clamp(.85, 1.15).toDouble();
    var closed = false;
    await showDialog<void>(
      context: context,
      useRootNavigator: false,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: .7),
      builder: (context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) widget.onClose();
        },
        child: Dialog(
          backgroundColor: Colors.white,
          elevation: 0,
          insetPadding:
              EdgeInsets.symmetric(horizontal: 16 * s, vertical: 24 * s),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25 * s)),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                20 * s, microphone ? 50 * s : 45 * s, 20 * s, 20 * s),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (microphone) ...[
                Container(
                    width: 100 * s,
                    height: 100 * s,
                    decoration: const BoxDecoration(
                        color: _teal, shape: BoxShape.circle),
                    child: Center(
                        child: _art('setup_microphone', 48 * s,
                            color: Colors.white))),
                SizedBox(height: 40 * s),
                Text('No talking',
                    style: _text(23 * s, bold: true, color: _purple)),
                SizedBox(height: 40 * s),
                Text(_microphoneInfo,
                    textAlign: TextAlign.center,
                    style: _text(16.5 * s, color: _purple)),
                SizedBox(height: 40 * s),
              ] else ...[
                Text('Why does EnglishScore use the camera?',
                    textAlign: TextAlign.center,
                    style: _text(23 * s, bold: true, color: _purple)),
                SizedBox(height: 40 * s),
                Text(
                    'Camera is required to verify you followed the test rules.',
                    textAlign: TextAlign.center,
                    style: _text(16.5 * s, color: _purple)),
                SizedBox(height: 22 * s),
                Text.rich(
                    const TextSpan(children: [
                      TextSpan(text: 'You must be '),
                      TextSpan(
                          text: 'alone in the room.',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      TextSpan(text: ' Your whole face should always be '),
                      TextSpan(
                          text: 'visible',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      TextSpan(text: ' in the camera.'),
                    ]),
                    textAlign: TextAlign.center,
                    style: _text(16.5 * s, color: _purple)),
                SizedBox(height: 22 * s),
                Text('Our team checks the photos if you get a certificate.',
                    textAlign: TextAlign.center,
                    style: _text(16.5 * s, color: _purple)),
                SizedBox(height: 36 * s),
                _art('camera_explained', 220 * s),
                SizedBox(height: 30 * s),
              ],
              _button('OK', () {
                if (closed) return;
                closed = true;
                Navigator.pop(context);
              }, s),
            ]),
          ),
        ),
      ),
    );
    _infoOpen = false;
  }

  Future<void> _retryVolume(double s) async {
    if (_infoOpen) return;
    _infoOpen = true;
    var closed = false;
    await showDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (context) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) widget.onClose();
        },
        child: AlertDialog(
          title: const Text('Try the volume check again'),
          content: const Text(
              'This demo has no speech audio asset. The yellow waveform is a visual animation only. Check your device volume and try again; this does not verify that you heard audio.'),
          actions: [
            TextButton(
                onPressed: () {
                  if (closed) return;
                  closed = true;
                  Navigator.pop(context);
                },
                child: const Text('Retry'))
          ],
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      _infoOpen = false;
      _waveTick = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s =
        (MediaQuery.sizeOf(context).width / 375).clamp(.85, 1.15).toDouble();
    if (widget.stage == SetupStage.intro) {
      return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
              child: Stack(children: [
            Center(
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24 * s),
                    child: Text("Let's get you\nset up",
                        textAlign: TextAlign.center,
                        style: _text(36 * s, bold: true, color: _purple)))),
            Positioned(top: 4 * s, left: 4 * s, child: _close(s)),
          ])));
    }
    final active = switch (widget.stage) {
      SetupStage.volume => 0,
      SetupStage.microphone => 1,
      SetupStage.review => 3,
      _ => 2
    };
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
            child: Column(children: [
          SizedBox(
              height: 96 * s,
              width: double.infinity,
              child: Stack(children: [
                Positioned.fill(child: LayoutBuilder(builder: (context, box) {
                  final centers = [.21, .40, .59, .785]
                      .map((x) => box.maxWidth * x)
                      .toList();
                  return Stack(children: [
                    Positioned.fill(
                        child: CustomPaint(
                            painter: _ProgressPainter(centers, active, s))),
                    for (var i = 0; i < 4; i++) ...[
                      Positioned(
                          top: 16 * s,
                          left: centers[i] - 10 * s,
                          child: Semantics(
                              label: '${[
                                'Volume',
                                'Microphone',
                                'Camera',
                                'Review'
                              ][i]}, ${i == active ? 'current step' : i < active ? 'completed step' : 'upcoming step'}',
                              selected: i == active,
                              child: _art(
                                  [
                                    'setup_ear',
                                    'setup_microphone',
                                    'setup_camera',
                                    'setup_shield'
                                  ][i],
                                  20 * s,
                                  color: i == active
                                      ? _teal
                                      : i < active
                                          ? const Color(0xFF555555)
                                          : const Color(0xFFB3B3B3)))),
                      if (i == active)
                        Positioned(
                            top: 69 * s,
                            left: centers[i] - 64 * s,
                            width: 128 * s,
                            child: Text(
                                ['Volume', 'Microphone', 'Camera', 'Review'][i],
                                textAlign: TextAlign.center,
                                style: _text(13.5 * s))),
                    ],
                  ]);
                })),
                Positioned(top: 4 * s, left: 4 * s, child: _close(s)),
              ])),
          Expanded(
              child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24 * s)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: .07),
                      blurRadius: 20 * s,
                      offset: Offset(0, -4 * s))
                ]),
            child: switch (widget.stage) {
              SetupStage.volume => _volume(s),
              SetupStage.microphone => _instructions(s, microphone: true),
              SetupStage.camera => _instructions(s, microphone: false),
              SetupStage.selfie => SelfieCapture(
                  paused: widget.paused,
                  onCaptured: (result) {
                    _captureResult = result;
                    widget.onAdvance();
                  }),
              _ => _review(s),
            },
          )),
        ])));
  }

  Widget _close(double s) => IconButton(
      tooltip: 'Close pre-test',
      onPressed: widget.onClose,
      icon: _art('close', 29 * s));

  Widget _volume(double s) => LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16 * s, 46 * s, 16 * s, 8 * s),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    minHeight: math.max(480 * s, box.maxHeight - 54 * s)),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Volume check', style: _text(23 * s, bold: true)),
                      Padding(
                          padding: EdgeInsets.symmetric(vertical: 70 * s),
                          child: Column(children: [
                            SizedBox(
                                width: 160 * s,
                                height: 35 * s,
                                child: CustomPaint(
                                    painter: _DemoWavePainter(_waveTick))),
                            SizedBox(height: 12 * s),
                            Text('Demo animation — no audio is playing',
                                textAlign: TextAlign.center,
                                style: _text(11 * s,
                                    color: const Color(0xFF777777))),
                          ])),
                      Column(children: [
                        Text('Can you hear the person speaking?',
                            textAlign: TextAlign.center,
                            style: _text(19 * s, bold: true)),
                        SizedBox(height: 12 * s),
                        _button('Yes', widget.onAdvance, s),
                        TextButton(
                            onPressed: () => _retryVolume(s),
                            child:
                                Text('No', style: _text(16 * s, bold: true))),
                      ]),
                    ]),
              ),
            ),
          ));

  Widget _instructions(double s, {required bool microphone}) => LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16 * s, 34 * s, 16 * s, 20 * s),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    minHeight: math.max(540 * s, box.maxHeight - 54 * s)),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(children: [
                        Text(microphone ? 'No talking' : 'Camera monitoring',
                            textAlign: TextAlign.center,
                            style: _text(23 * s, bold: true)),
                        SizedBox(height: 34 * s),
                        Text(microphone ? _microphoneText : _cameraText,
                            textAlign: TextAlign.center, style: _text(19 * s)),
                      ]),
                      Padding(
                          padding: EdgeInsets.symmetric(vertical: 24 * s),
                          child: _art(
                              microphone ? 'quiet_person' : 'camera_examples',
                              microphone ? 255 * s : 280 * s)),
                      Column(children: [
                        _button('OK', widget.onAdvance, s),
                        SizedBox(height: 18 * s),
                        TextButton(
                            onPressed: () => _showInfo(microphone: microphone),
                            child: Text('Find out more',
                                style: _text(16 * s,
                                    bold: true,
                                    color: microphone ? _ink : _purple))),
                      ]),
                    ]),
              ),
            ),
          ));

  Widget _review(double s) => SingleChildScrollView(
        padding: EdgeInsets.all(24 * s),
        child: Column(children: [
          Text('Review capture', style: _text(23 * s, bold: true)),
          SizedBox(height: 28 * s),
          if (_captureResult?.bytes != null)
            ClipRRect(
                borderRadius: BorderRadius.circular(24 * s),
                child: Image.memory(_captureResult!.bytes!,
                    width: 206 * s, height: 275 * s, fit: BoxFit.cover))
          else
            Container(
                width: 206 * s,
                height: 275 * s,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: const Color(0xFFEDECF1),
                    borderRadius: BorderRadius.circular(24 * s)),
                child: Text('Simulated capture\nNo photo was taken',
                    textAlign: TextAlign.center,
                    style: _text(17 * s, color: _purple))),
          SizedBox(height: 20 * s),
          Text(
              _captureResult?.simulated == false
                  ? 'Local photo only. Not uploaded or identity verified.'
                  : 'Demo image only. This is not a real selfie or identity verification.',
              textAlign: TextAlign.center,
              style: _text(14 * s)),
          SizedBox(height: 28 * s),
          _button('Done', widget.onAdvance, s),
          TextButton(
              onPressed: widget.onRetake == null
                  ? null
                  : () {
                      _captureResult = null;
                      widget.onRetake!();
                    },
              child: Text('Retake',
                  style: _text(16 * s, bold: true, color: _purple))),
        ]),
      );
}

class _ProgressPainter extends CustomPainter {
  _ProgressPainter(this.centers, this.active, this.scale);
  final List<double> centers;
  final int active;
  final double scale;
  @override
  void paint(Canvas canvas, Size size) {
    final y = 52 * scale;
    for (var i = 0; i < 3; i++) {
      canvas.drawLine(
          Offset(centers[i], y),
          Offset(centers[i + 1], y),
          Paint()
            ..color =
                i < active ? const Color(0xFF555555) : const Color(0xFFB3B3B3)
            ..strokeWidth = 2 * scale);
    }
    for (var i = 0; i < 4; i++) {
      final center = Offset(centers[i], y);
      final color = i == active
          ? _teal
          : i < active
              ? const Color(0xFF555555)
              : const Color(0xFFB3B3B3);
      canvas.drawCircle(
          center, (i <= active ? 9 : 5) * scale, Paint()..color = color);
      if (i > active) {
        canvas.drawCircle(center, 2.5 * scale, Paint()..color = Colors.white);
      }
      if (i < active) {
        canvas.drawPath(
            Path()
              ..moveTo(center.dx - 3 * scale, y)
              ..lineTo(center.dx - scale, y + 3 * scale)
              ..lineTo(center.dx + 4 * scale, y - 4 * scale),
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.8 * scale
              ..strokeCap = StrokeCap.round);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressPainter old) =>
      active != old.active ||
      scale != old.scale ||
      centers.toString() != old.centers.toString();
}

class _DemoWavePainter extends CustomPainter {
  _DemoWavePainter(this.tick);
  final int tick;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE5B600)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 10; i++) {
      final x = (i + .5) * size.width / 10;
      final amplitude = 1 + math.sin((tick + i) * .85).abs() * 9;
      canvas.drawLine(Offset(x, size.height / 2 - amplitude),
          Offset(x, size.height / 2 + amplitude), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DemoWavePainter old) => tick != old.tick;
}
