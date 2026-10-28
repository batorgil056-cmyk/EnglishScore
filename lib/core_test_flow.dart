import 'dart:async';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'selfie_camera_backend.dart';
import 'core_test/test_screen.dart';
import 'core_test/listening_audio.dart';

const _purple = Color(0xFF210957);
const _teal = Color(0xFF039D8C);

enum _TestStage {
  roomIntro,
  scanning,
  scanComplete,
  rules,
  agreement,
  ready,
  test
}

/// Local reference UI. No recording, monitoring, identity verification, uploads,
/// certificate issuance, or EnglishScore scoring occurs in this flow.
class CoreTestFlow extends StatefulWidget {
  const CoreTestFlow(
      {super.key,
      required this.paused,
      required this.onClose,
      required this.onFinish,
      this.cameraBackend,
      this.speechBackend});

  final bool paused;
  final VoidCallback onClose;
  final VoidCallback onFinish;
  final SelfieCameraBackend? cameraBackend;
  final SpeechBackend? speechBackend;

  @override
  State<CoreTestFlow> createState() => _CoreTestFlowState();
}

class _CoreTestFlowState extends State<CoreTestFlow>
    with WidgetsBindingObserver {
  late final SelfieCameraBackend _camera;
  SelfieEnvironment? _environment;
  _TestStage _stage = _TestStage.roomIntro;
  Timer? _clock;
  bool _active = true;
  bool _infoOpen = false;
  bool _cameraBusy = false;
  bool _cameraReady = false;
  bool _simulated = true;
  String? _cameraError;
  int _cameraGeneration = 0;
  int _agreementTicks = 0;
  int _scanSteps = 0;
  double _dragDistance = 0;

  bool get _paused => widget.paused || !_active || _infoOpen;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _camera = widget.cameraBackend ??
        IosSelfieCamera(lensDirection: CameraLensDirection.back);
    _detectEnvironment();
    // Timers are paused by exit confirmation, app backgrounding and info sheets.
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_paused) return;
      if (_stage == _TestStage.agreement) {
        if (++_agreementTicks >= 2) _go(_TestStage.ready);
      }
    });
  }

  Future<void> _detectEnvironment() async {
    SelfieEnvironment environment;
    try {
      environment = await _camera.environment();
    } catch (_) {
      environment = SelfieEnvironment.unsupported;
    }
    if (mounted) setState(() => _environment = environment);
  }

  @override
  void didUpdateWidget(covariant CoreTestFlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.paused && !oldWidget.paused) _stopCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (!_active) _stopCamera();
    if (mounted) setState(() {});
  }

  Future<void> _stopCamera() async {
    _cameraGeneration++;
    _cameraReady = false;
    _cameraBusy = false;
    await _camera.stop();
  }

  Future<void> _enableCamera() async {
    if (_cameraBusy || _paused || _environment != SelfieEnvironment.iosDevice) {
      return;
    }
    final generation = ++_cameraGeneration;
    setState(() {
      _cameraBusy = true;
      _cameraError = null;
    });
    try {
      await _camera.start();
      if (!mounted || generation != _cameraGeneration) return;
      setState(() {
        _cameraReady = true;
        _simulated = false;
      });
    } catch (_) {
      if (mounted && generation == _cameraGeneration) {
        await _camera.stop();
        if (!mounted || generation != _cameraGeneration) return;
        setState(() => _cameraError =
            'Camera unavailable. Allow camera access in Settings and retry, or use the demo scan.');
      }
    } finally {
      if (mounted && generation == _cameraGeneration) {
        setState(() => _cameraBusy = false);
      }
    }
  }

  void _go(_TestStage stage) {
    if (_paused) return;
    if (_stage == _TestStage.scanning && stage != _TestStage.scanComplete) {
      unawaited(_stopCamera());
    }
    setState(() {
      _stage = stage;
      if (stage == _TestStage.agreement) _agreementTicks = 0;
    });
  }

  void _scanForward() {
    if (_paused || _cameraBusy || (!_simulated && !_cameraReady)) return;
    setState(() => _scanSteps++);
    if (_scanSteps >= 4) {
      _go(_TestStage.scanComplete);
      unawaited(_stopCamera());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock?.cancel();
    unawaited(_stopCamera());
    super.dispose();
  }

  TextStyle _text(double size,
          {bool bold = false, Color color = const Color(0xFF181818)}) =>
      TextStyle(
          fontFamily: 'Arial',
          fontSize: size,
          height: 1.2,
          color: color,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400);

  Widget _art(String name, double height) =>
      SvgPicture.asset('assets/pretest/$name.svg',
          height: height, excludeFromSemantics: true);

  Widget _button(String label, VoidCallback? action, double s,
          {Color color = _purple, bool square = false}) =>
      SizedBox(
          width: double.infinity,
          height: 52 * s,
          child: ElevatedButton(
              onPressed: action,
              style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  disabledBackgroundColor: color,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white38,
                  elevation: 1,
                  padding: EdgeInsets.symmetric(horizontal: 12 * s),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular((square ? 4 : 23) * s)),
                  textStyle: _text(19 * s, bold: true)),
              child: Text(label)));

  Widget _close(double s, {bool white = false}) => IconButton(
      tooltip: 'Close pre-test',
      onPressed: widget.onClose,
      icon: Icon(Icons.close,
          size: 32 * s, color: white ? Colors.white : _purple));

  @override
  Widget build(BuildContext context) {
    final s =
        (MediaQuery.sizeOf(context).width / 375).clamp(.7, 1.3).toDouble();
    if (_stage == _TestStage.test) {
      return CoreSkillsTestScreen(
          paused: _paused,
          onClose: widget.onClose,
          onFinish: widget.onFinish,
          speechBackend: widget.speechBackend);
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: _stage == _TestStage.scanning
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: Scaffold(
            backgroundColor: Colors.white,
            body: switch (_stage) {
              _TestStage.scanning || _TestStage.scanComplete => _scan(s),
              _TestStage.agreement => _agreement(s),
              _ => _setup(s),
            }));
  }

  Widget _setupHeader(double s) {
    final active = _stage == _TestStage.roomIntro
        ? 2
        : _stage == _TestStage.rules
            ? 3
            : 4;
    return SizedBox(
        height: 96 * s,
        child: Stack(children: [
          Positioned(left: 4 * s, top: 4 * s, child: _close(s)),
          Padding(
              padding: EdgeInsets.only(left: 70 * s, right: 42 * s, top: 8 * s),
              child: Column(children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final (i, icon) in [
                        Icons.hearing,
                        Icons.mic_none,
                        Icons.camera_alt,
                        Icons.verified_user
                      ].indexed)
                        Icon(icon,
                            size: 22 * s,
                            color: i == active
                                ? _teal
                                : i < active
                                    ? const Color(0xFF555555)
                                    : Colors.grey),
                    ]),
                SizedBox(height: 10 * s),
                Row(children: [
                  for (var i = 0; i < 4; i++) ...[
                    if (i > 0)
                      Expanded(
                          child: Container(
                              height: 2 * s,
                              color: i <= active
                                  ? const Color(0xFF555555)
                                  : Colors.grey.shade400)),
                    Container(
                        width: 18 * s,
                        height: 18 * s,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i == active
                                ? _teal
                                : i < active
                                    ? const Color(0xFF555555)
                                    : Colors.white,
                            border: Border.all(
                                color: i <= active
                                    ? Colors.transparent
                                    : Colors.grey.shade400,
                                width: 3 * s)),
                        child: i < active
                            ? Icon(Icons.check,
                                color: Colors.white, size: 13 * s)
                            : null),
                  ]
                ]),
                SizedBox(height: 7 * s),
                if (active < 4)
                  Align(
                      alignment: active == 2
                          ? const Alignment(.38, 0)
                          : Alignment.centerRight,
                      child: Text(active == 2 ? 'Camera' : 'Rules',
                          style: _text(14 * s))),
              ])),
        ]));
  }

  Widget _setup(double s) => SafeArea(
          child: Column(children: [
        _setupHeader(s),
        Expanded(
            child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(25 * s)),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x11000000),
                          blurRadius: 18,
                          offset: Offset(0, -6))
                    ]),
                child: LayoutBuilder(
                    builder: (context, box) => SingleChildScrollView(
                        child: ConstrainedBox(
                            constraints:
                                BoxConstraints(minHeight: box.maxHeight),
                            child: IntrinsicHeight(
                                child: Padding(
                                    padding: EdgeInsets.fromLTRB(
                                        20 * s, 28 * s, 20 * s, 16 * s),
                                    child: _stage == _TestStage.roomIntro
                                        ? _roomIntro(s)
                                        : _stage == _TestStage.rules
                                            ? _rules(s)
                                            : _ready(s)))))))),
      ]));

  Widget _roomIntro(double s) => Column(children: [
        Text('Scanning your room',
            style: _text(24 * s, bold: true), textAlign: TextAlign.center),
        SizedBox(height: 22 * s),
        Text(
            'You’ll have to scan your surroundings to prove you’re taking the test alone.\nDuring the test we may ask you again to rescan your room',
            style: _text(19 * s),
            textAlign: TextAlign.center),
        SizedBox(height: 34 * s),
        ClipRRect(
            borderRadius: BorderRadius.circular(18 * s),
            child: _art('room_scan', 190 * s)),
        SizedBox(height: 12 * s),
        Text('Demo scan only • No video is recorded or verified',
            textAlign: TextAlign.center,
            style: _text(11 * s, color: Colors.grey.shade700)),
        const Spacer(),
        SizedBox(height: 24 * s),
        _button('Start scanning', () => _go(_TestStage.scanning), s),
        SizedBox(height: 22 * s),
        TextButton(
            onPressed: _findOutMore,
            child: Text('Find out more',
                style: _text(18 * s, bold: true, color: _purple))),
      ]);

  Future<void> _findOutMore() async {
    _infoOpen = true;
    await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Scanning your room'),
                content: const Text(
                    'The reference app asks you to scan your surroundings. This local demo does not record, upload or verify a room scan. On Simulator, swipe right to advance. On a physical iPhone, you may explicitly enable a rear-camera preview; progress is manual and does not verify motion or that you are alone.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'))
                ]));
    _infoOpen = false;
  }

  Widget _rules(double s) {
    const rules = [
      (Icons.pause_circle_filled, "You can't pause the test"),
      (
        Icons.volume_up,
        'You must be in a quiet place.\nNo talking or answering calls.'
      ),
      (Icons.people, 'Take the test alone and stay in the same room'),
      (
        Icons.menu_book,
        'No other devices in the room\n(monitors, laptops, other phones)'
      ),
      (Icons.face, "Don't cover your face\n(no hats or sunglasses)"),
    ];
    return Column(children: [
      SizedBox(height: 60 * s),
      Text('Test rules', style: _text(24 * s, bold: true)),
      SizedBox(height: 56 * s),
      for (final (icon, text) in rules) ...[
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          SizedBox(
              width: 34 * s,
              height: 34 * s,
              child: CustomPaint(
                  foregroundPainter: _ProhibitionPainter(),
                  child: Icon(icon,
                      color: const Color(0xFF4C50A4), size: 24 * s))),
          SizedBox(width: 16 * s),
          Expanded(child: Text(text, style: _text(18.5 * s))),
        ]),
        SizedBox(height: 40 * s),
      ],
      const Spacer(),
      _button('I agree', () => _go(_TestStage.agreement), s),
    ]);
  }

  Widget _ready(double s) => Column(children: [
        const Spacer(),
        _art('start_test', 350 * s),
        const Spacer(),
        SizedBox(height: 28 * s),
        _button('Start the test', () => _go(_TestStage.test), s, color: _teal),
      ]);

  Widget _agreement(double s) => SafeArea(
          child: Stack(children: [
        Positioned(top: 4 * s, left: 4 * s, child: _close(s)),
        Positioned(
            right: 22 * s,
            bottom: 28 * s,
            child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 900),
                builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.translate(
                        offset: Offset(0, 24 * (1 - value)),
                        child: Transform.rotate(angle: -.08, child: child))),
                child: Text('I agree ✓',
                    style: TextStyle(
                        fontFamily: 'Snell Roundhand',
                        fontStyle: FontStyle.italic,
                        fontSize: 42 * s,
                        fontWeight: FontWeight.w700,
                        color: _teal)))),
      ]));

  Widget _scan(double s) => Stack(fit: StackFit.expand, children: [
        if (_cameraReady && !_paused)
          _camera.preview()
        else
          Container(
              decoration: const BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                    Color(0xFF9EB9BD),
                    Color(0xFF526F77),
                    Color(0xFFC5AD8D)
                  ])),
              child: Center(
                  child:
                      Opacity(opacity: .6, child: _art('room_scan', 310 * s)))),
        SafeArea(
            child: Column(children: [
          Align(alignment: Alignment.centerLeft, child: _close(s, white: true)),
          Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 12 * s, vertical: 6 * s),
              color: Colors.black54,
              child: Text(
                  _simulated
                      ? 'SIMULATED ROOM SCAN • No recording'
                      : _cameraReady
                          ? 'Live preview • No recording or verification'
                          : 'Camera paused • No recording',
                  textAlign: TextAlign.center,
                  style: _text(12 * s, color: Colors.white))),
          const Spacer(),
          Container(
              margin: EdgeInsets.symmetric(horizontal: 28 * s),
              padding: EdgeInsets.all(14 * s),
              decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .8),
                  borderRadius: BorderRadius.circular(8 * s)),
              child: Row(children: [
                Icon(Icons.play_arrow, color: _teal, size: 22 * s),
                SizedBox(width: 8 * s),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Move the camera!',
                          style: _text(16 * s, bold: true, color: _teal)),
                      SizedBox(height: 4 * s),
                      Text('to the right in a straight line.',
                          style: _text(16 * s, color: Colors.white)),
                    ]))
              ])),
          SizedBox(height: 20 * s),
          GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: (_) => _dragDistance = 0,
              onHorizontalDragUpdate: (details) =>
                  _dragDistance += details.delta.dx,
              onHorizontalDragEnd: (_) {
                if (_dragDistance > 45) _scanForward();
              },
              child: Container(
                  height: 68 * s,
                  margin: EdgeInsets.only(left: 150 * s),
                  padding: EdgeInsets.all(8 * s),
                  color: Colors.black38,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                            width: 44 * s,
                            height: 44 * s,
                            child: CircularProgressIndicator(
                                value: _scanSteps / 4,
                                strokeWidth: 8 * s,
                                color: _teal,
                                backgroundColor: _teal.withValues(alpha: .55))),
                        for (var i = 0; i < 4; i++)
                          Icon(Icons.circle,
                              size: 9 * s,
                              color: i < _scanSteps ? _teal : Colors.white),
                      ]))),
          const Spacer(),
          if (_environment == SelfieEnvironment.iosDevice && !_cameraReady) ...[
            Padding(
                padding: EdgeInsets.symmetric(horizontal: 20 * s),
                child: _button(
                    _cameraBusy ? 'Opening camera…' : 'Enable rear camera',
                    _cameraBusy ? null : _enableCamera,
                    s)),
            TextButton(
                onPressed: () {
                  unawaited(_stopCamera());
                  setState(() => _simulated = true);
                },
                child: const Text('Use demo scan',
                    style: TextStyle(color: Colors.white))),
          ],
          if (_cameraError != null)
            Padding(
                padding: EdgeInsets.all(12 * s),
                child: Text(_cameraError!,
                    style: _text(14 * s, color: Colors.white),
                    textAlign: TextAlign.center)),
          Padding(
              padding: EdgeInsets.all(20 * s),
              child: _button(
                  _simulated
                      ? 'Swipe right or tap to scan →'
                      : 'Continue scan →',
                  _cameraBusy || (!_simulated && !_cameraReady)
                      ? null
                      : _scanForward,
                  s,
                  color: _teal)),
        ])),
        if (_stage == _TestStage.scanComplete) ...[
          const ModalBarrier(dismissible: false, color: Colors.black54),
          SafeArea(
              child: Center(
                  child: SingleChildScrollView(
                      padding: EdgeInsets.all(16 * s),
                      child: Container(
                          padding: EdgeInsets.fromLTRB(
                              20 * s, 48 * s, 20 * s, 20 * s),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24 * s)),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            CircleAvatar(
                                radius: 50 * s,
                                backgroundColor: _teal,
                                child: Icon(Icons.camera_alt_outlined,
                                    size: 48 * s, color: Colors.white)),
                            SizedBox(height: 40 * s),
                            Text('Scanning complete',
                                style:
                                    _text(24 * s, bold: true, color: _purple)),
                            SizedBox(height: 38 * s),
                            Text(
                                'Our security team will check your room scan video. If you break the test rules, we may cancel your certificate. We may ask you to scan your room again during the test.',
                                textAlign: TextAlign.center,
                                style: _text(18 * s, color: _purple)),
                            SizedBox(height: 14 * s),
                            Text(
                                'Reference UI only. No video was recorded, submitted or verified.',
                                textAlign: TextAlign.center,
                                style: _text(12 * s, color: _purple)),
                            SizedBox(height: 30 * s),
                            _button('OK', () => _go(_TestStage.rules), s),
                          ]))))),
        ],
      ]);
}

class _ProhibitionPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF47C9D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .05;
    canvas.drawCircle(size.center(Offset.zero), size.width * .47, paint);
    final inset = size.width * (1 - math.sqrt(.5)) / 2;
    canvas.drawLine(Offset(inset, size.height - inset),
        Offset(size.width - inset, inset), paint);
  }

  @override
  bool shouldRepaint(covariant _ProhibitionPainter oldDelegate) => false;
}
