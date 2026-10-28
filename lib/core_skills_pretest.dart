import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'core_setup_screens.dart';
import 'core_test_flow.dart';

const _purple = Color(0xFF210957);
const _teal = Color(0xFF039D8C);
const _red = Color(0xFFFF453C);

enum _Step {
  loading,
  about,
  connect,
  security,
  intro,
  volume,
  microphone,
  camera,
  selfie,
  review,
  test
}

/// UI preparation only: no code verification, device monitoring, or scoring.
class CoreSkillsPretest extends StatefulWidget {
  const CoreSkillsPretest({super.key});

  @override
  State<CoreSkillsPretest> createState() => _CoreSkillsPretestState();
}

class _CoreSkillsPretestState extends State<CoreSkillsPretest> {
  _Step _step = _Step.loading;
  bool _securityOn = false;
  bool _exitDialogOpen = false;
  bool _exiting = false;
  bool _connectPromptOpen = false;
  bool _connectPromptPending = false;
  Timer? _loadingTimer;
  final _code = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  void _startLoading() {
    // A brief visual transition, not a network request. Pause it while exit is
    // being confirmed so the screen behind the popup cannot change.
    _loadingTimer?.cancel();
    _loadingTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted || _exiting || _exitDialogOpen) return;
      setState(() {
        _step = _Step.about;
        _connectPromptPending = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_exitDialogOpen && !_exiting) _connectPrompt();
      });
    });
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _code.dispose();
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  Widget _exitGuard(Widget child) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _confirmExit();
        },
        child: child,
      );

  Future<void> _confirmExit() async {
    if (!mounted || _exitDialogOpen || _exiting) return;
    final navigator = Navigator.of(context);
    final flowRoute = ModalRoute.of(context);
    final s =
        (MediaQuery.sizeOf(context).width / 375).clamp(.85, 1.15).toDouble();
    FocusManager.instance.primaryFocus?.unfocus();
    _loadingTimer?.cancel();
    setState(() => _exitDialogOpen = true);
    var decisionMade = false;
    void decide(BuildContext dialogContext, bool exit) {
      if (decisionMade) return;
      decisionMade = true;
      Navigator.of(dialogContext).pop(exit);
    }

    final exit = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: .7),
      builder: (dialogContext) => PopScope(
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) decisionMade = true;
          },
          child: Dialog(
            backgroundColor: Colors.white,
            elevation: 0,
            insetPadding:
                EdgeInsets.symmetric(horizontal: 16 * s, vertical: 24 * s),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25 * s)),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20 * s, 50 * s, 20 * s, 14 * s),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 100 * s,
                    height: 100 * s,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Color(0xFFB5003C)),
                    child: Center(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                          width: 12 * s,
                          height: 47 * s,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6 * s))),
                      SizedBox(height: 8 * s),
                      Container(
                          width: 12 * s,
                          height: 12 * s,
                          decoration: const BoxDecoration(
                              color: Colors.white, shape: BoxShape.circle)),
                    ]))),
                SizedBox(height: 40 * s),
                Text('Are you sure you want\nto exit?',
                    textAlign: TextAlign.center,
                    style: _text(23 * s, bold: true)),
                SizedBox(height: 40 * s),
                Text(
                    'You will lose your setup progress and will need to start again',
                    textAlign: TextAlign.center,
                    style: _text(16.5 * s)),
                SizedBox(height: 40 * s),
                _button('Go back', () => decide(dialogContext, false), s),
                SizedBox(height: 22 * s),
                TextButton(
                    onPressed: () => decide(dialogContext, true),
                    child: Text('Exit the test',
                        style: _text(16 * s, bold: true))),
              ]),
            ),
          )),
    );
    if (!mounted) return;
    if (exit == true) {
      _exiting = true;
      // Remove any setup dialogs, then this single setup route. No saved
      // profile, authentication, result, or demo-state data is touched.
      navigator.popUntil((route) => route == flowRoute);
      navigator.pop(true);
      return;
    }
    setState(() => _exitDialogOpen = false);
    if (_step == _Step.loading) {
      _startLoading();
    } else if (_step == _Step.intro) {
      _armSetupIntro();
    } else if (_connectPromptPending && !_connectPromptOpen) {
      _connectPrompt();
    }
  }

  void _startSetup() {
    setState(() => _step = _Step.intro);
    _armSetupIntro();
  }

  void _armSetupIntro() {
    _loadingTimer?.cancel();
    _loadingTimer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted && !_exitDialogOpen && !_exiting && _step == _Step.intro) {
        setState(() => _step = _Step.volume);
      }
    });
  }

  void _advanceSetup(_Step expected) {
    if (_exiting || _exitDialogOpen || _step != expected) return;
    setState(() => _step = switch (_step) {
          _Step.volume => _Step.microphone,
          _Step.microphone => _Step.camera,
          _Step.camera => _Step.selfie,
          _Step.selfie => _Step.review,
          _Step.review => _Step.test,
          _ => _step,
        });
  }

  TextStyle _text(double size, {bool bold = false, Color color = _purple}) =>
      TextStyle(
        fontFamily: 'Arial',
        fontSize: size,
        height: 1.2,
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
        color: color,
      );

  Widget _art(String name, double size) => SvgPicture.asset(
        'assets/pretest/$name.svg',
        width: size,
        height: size,
        excludeFromSemantics: true,
      );

  Widget _button(String title, VoidCallback? onPressed, double s) => SizedBox(
        width: double.infinity,
        height: 52 * s,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: _purple,
            disabledBackgroundColor: _purple,
            foregroundColor: Colors.white,
            disabledForegroundColor: const Color(0xFF80709F),
            elevation: 1,
            padding: EdgeInsets.symmetric(horizontal: 12 * s),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24 * s)),
            textStyle: _text(16.5 * s, bold: true),
          ),
          child: Text(title, textAlign: TextAlign.center),
        ),
      );

  Widget _noCode(double s) => TextButton(
        onPressed: () {
          FocusManager.instance.primaryFocus?.unfocus();
          setState(() => _step = _Step.about);
        },
        child: Text("I don't have a code", style: _text(19 * s, bold: true)),
      );

  Future<void> _connectPrompt() async {
    if (_connectPromptOpen || _exiting || _exitDialogOpen) return;
    _connectPromptOpen = true;
    _connectPromptPending = false;
    final s =
        (MediaQuery.sizeOf(context).width / 375).clamp(.85, 1.15).toDouble();
    final enterCode = await showDialog<bool>(
      context: context,
      useSafeArea: false,
      useRootNavigator: false,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: .7),
      builder: (context) => _exitGuard(Dialog(
        backgroundColor: Colors.white,
        elevation: 0,
        insetPadding:
            EdgeInsets.symmetric(horizontal: 20 * s, vertical: 30 * s),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(25 * s)),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20 * s, 60 * s, 20 * s, 38 * s),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _art('connect_building', 145 * s),
            SizedBox(height: 48 * s),
            Text.rich(
                TextSpan(children: const [
                  TextSpan(text: 'Got a '),
                  TextSpan(text: 'Connect Code', style: TextStyle(color: _red)),
                  TextSpan(text: ' from\nan employer or\nuniversity?'),
                ]),
                textAlign: TextAlign.center,
                style: _text(22 * s, bold: true)),
            SizedBox(height: 60 * s),
            _button('Yes, enter the Connect Code',
                () => Navigator.pop(context, true), s),
            SizedBox(height: 14 * s),
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("I don't have a code",
                    style: _text(19 * s, bold: true))),
          ]),
        ),
      )),
    );
    _connectPromptOpen = false;
    if (mounted && !_exiting && enterCode == true) {
      setState(() => _step = _Step.connect);
    }
  }

  void _notImplemented(String title, String message) {
    showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(title),
              content: Text(message),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    final s =
        (MediaQuery.sizeOf(context).width / 375).clamp(.85, 1.15).toDouble();
    if (_step == _Step.loading) {
      return _exitGuard(Scaffold(
          backgroundColor: Colors.white,
          body: LayoutBuilder(
              builder: (context, box) => Stack(children: [
                    Positioned(
                        top: box.maxHeight * .425,
                        left: 24 * s,
                        right: 24 * s,
                        child: Text("Let's get you ready for\nthe test",
                            textAlign: TextAlign.center,
                            style: _text(23 * s, bold: true))),
                    Positioned(
                        top: box.maxHeight * .55,
                        left: 0,
                        right: 0,
                        child: Center(
                            child: CupertinoActivityIndicator(
                                radius: 17 * s,
                                animating: !_exitDialogOpen,
                                color: const Color(0xFF766197)))),
                  ]))));
    }
    if (_step == _Step.test) {
      return _exitGuard(CoreTestFlow(
        paused: _exitDialogOpen,
        onClose: _confirmExit,
        onFinish: () {
          if (_exiting || _exitDialogOpen) return;
          _exiting = true;
          Navigator.of(context).pop(true);
        },
      ));
    }
    if (_step.index >= _Step.intro.index) {
      final currentStep = _step;
      return _exitGuard(CoreSetupScreens(
        stage: SetupStage.values[_step.index - _Step.intro.index],
        paused: _exitDialogOpen,
        onClose: _confirmExit,
        onAdvance: () => _advanceSetup(currentStep),
        onRetake: () => setState(() => _step = _Step.selfie),
      ));
    }
    final title = switch (_step) {
      _Step.about => 'About the test',
      _Step.security => 'Test security',
      _ => '',
    };
    return _exitGuard(Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
          child: Column(children: [
        SizedBox(
            width: double.infinity,
            height: 56 * s,
            child: Stack(alignment: Alignment.center, children: [
              if (title.isNotEmpty)
                Padding(
                    padding: EdgeInsets.symmetric(horizontal: 48 * s),
                    child: Text(title,
                        textAlign: TextAlign.center,
                        style: _text(23 * s, bold: true))),
              Positioned(
                  left: 4 * s,
                  child: IconButton(
                      tooltip: 'Close pre-test',
                      onPressed: _confirmExit,
                      icon: _art('close', 29 * s))),
            ])),
        Expanded(
            child: switch (_step) {
          _Step.about => _about(s),
          _Step.connect => _connectForm(s),
          _Step.security => _security(s),
          _ => const SizedBox(),
        }),
        Padding(
            padding: EdgeInsets.fromLTRB(16 * s, 8 * s, 16 * s, 14 * s),
            child: _step == _Step.connect
                ? _noCode(s)
                : _button(
                    _step == _Step.about ? 'OK' : 'Next',
                    _step == _Step.about
                        ? () => setState(() => _step = _Step.security)
                        : _startSetup,
                    s)),
      ])),
    ));
  }

  Widget _about(double s) => LayoutBuilder(builder: (context, box) {
        final height = math.max(box.maxHeight, 480 * s);
        return SingleChildScrollView(
            child: SizedBox(
                height: height,
                child: Stack(children: [
                  Positioned(
                      top: height * .23,
                      left: 16 * s,
                      right: 16 * s,
                      child: Text('A 30–40 minute test of your\nCore Skills',
                          textAlign: TextAlign.center,
                          style: _text(23 * s, bold: true))),
                  Positioned(
                      top: height * .46,
                      left: 31 * s,
                      right: 20 * s,
                      child: Column(children: [
                        for (final entry in [
                          'Grammar and vocabulary',
                          'Reading',
                          'Listening'
                        ].asMap().entries) ...[
                          Row(children: [
                            Container(
                                width: 35 * s,
                                height: 35 * s,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: _purple, width: 2 * s)),
                                child: Text('${entry.key + 1}',
                                    style: _text(23 * s, bold: true))),
                            SizedBox(width: 17 * s),
                            Expanded(
                                child: Text(entry.value,
                                    style: _text(19 * s,
                                        color: const Color(0xFF181818)))),
                          ]),
                          if (entry.key < 2) SizedBox(height: 42 * s),
                        ],
                      ])),
                ])));
      });

  Widget _field(
          String label, String hint, TextEditingController controller, double s,
          {bool last = false}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: _text(16.5 * s)),
        SizedBox(height: 10 * s),
        TextField(
          controller: controller,
          onChanged: (_) => setState(() {}),
          textInputAction: last ? TextInputAction.done : TextInputAction.next,
          autocorrect: false,
          enableSuggestions: false,
          textCapitalization: controller == _code
              ? TextCapitalization.characters
              : TextCapitalization.words,
          style: _text(16 * s),
          decoration: InputDecoration(
              hintText: hint,
              hintStyle: _text(16 * s, color: const Color(0xFFC6C6C8)),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 17 * s, vertical: 15 * s),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4 * s),
                  borderSide: const BorderSide(color: Color(0xFFD5D5D5))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4 * s),
                  borderSide: const BorderSide(color: _purple))),
        ),
      ]);

  Widget _connectForm(double s) => SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(24 * s, 40 * s, 24 * s, 20 * s),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text.rich(
              TextSpan(children: const [
                TextSpan(text: 'Enter a '),
                TextSpan(text: 'Connect Code', style: TextStyle(color: _red))
              ]),
              textAlign: TextAlign.center,
              style: _text(19 * s, bold: true)),
          SizedBox(height: 36 * s),
          _field('Connect Code', 'Enter your ConnectCode', _code, s),
          SizedBox(height: 30 * s),
          _field('First name', 'Enter your first name', _firstName, s),
          SizedBox(height: 30 * s),
          _field('Last name', 'Enter your last name', _lastName, s, last: true),
          SizedBox(height: 30 * s),
          _button(
              'Apply Code',
              [_code, _firstName, _lastName]
                      .every((c) => c.text.trim().isNotEmpty)
                  ? () => _notImplemented(
                      'Connect Code verification unavailable',
                      'Connect Code verification is not connected in this demo. Your code and names have not been verified, saved, or sent.')
                  : null,
              s),
          SizedBox(height: 30 * s),
          Text(
              'A Connect Code lets someone else view the result of your test. You don’t need a code to take the test.',
              textAlign: TextAlign.center,
              style: _text(19 * s)),
        ]),
      );

  Widget _monitorIcon(String name, double s) => SizedBox(
      width: 40 * s,
      height: 40 * s,
      child: Stack(children: [
        _art(name, 40 * s),
        if (!_securityOn)
          Positioned.fill(child: CustomPaint(painter: _DisabledSlash())),
      ]));

  // Reference UI options only: no camera/microphone APIs are invoked and
  // no certificate is issued. Next opens further UI-only setup steps.
  Widget _security(double s) => SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 18 * s),
        child: Column(children: [
          Container(
              decoration: BoxDecoration(
                  color: _securityOn
                      ? const Color(0xFF27AC9F)
                      : const Color(0xFF68696B),
                  borderRadius: BorderRadius.circular(24 * s)),
              child: Column(children: [
                Container(
                    padding: EdgeInsets.all(6 * s),
                    decoration: BoxDecoration(
                        color: _securityOn ? _teal : const Color(0xFF55565A),
                        borderRadius: BorderRadius.circular(24 * s)),
                    child: Row(children: [
                      for (final value in [false, true])
                        Expanded(
                          child: Semantics(
                              selected: _securityOn == value,
                              button: true,
                              child: InkWell(
                                onTap: () =>
                                    setState(() => _securityOn = value),
                                borderRadius: BorderRadius.circular(24 * s),
                                child: Container(
                                    height: 46 * s,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                        color: _securityOn == value
                                            ? Colors.white
                                            : Colors.transparent,
                                        borderRadius:
                                            BorderRadius.circular(24 * s)),
                                    child: Text(value ? 'On' : 'Off',
                                        style: _text(17 * s,
                                            bold: _securityOn == value,
                                            color: _securityOn == value
                                                ? (_securityOn
                                                    ? const Color(0xFF008578)
                                                    : const Color(0xFF55565A))
                                                : Colors.white))),
                              )),
                        ),
                    ])),
                Padding(
                    padding:
                        EdgeInsets.fromLTRB(26 * s, 13 * s, 20 * s, 20 * s),
                    child: Column(children: [
                      for (final entry in {
                        'camera': 'Camera monitoring',
                        'microphone': 'Microphone monitoring'
                      }.entries) ...[
                        Row(children: [
                          _monitorIcon(entry.key, s),
                          SizedBox(width: 17 * s),
                          Expanded(
                              child: Text(entry.value,
                                  style: _text(19 * s, color: Colors.white)))
                        ]),
                        if (entry.key == 'camera') SizedBox(height: 10 * s),
                      ],
                    ])),
              ])),
          SizedBox(height: 26 * s),
          _art(_securityOn ? 'certificate_on' : 'certificate_off', 265 * s),
          SizedBox(height: 8 * s),
          Text('✓ Get your EnglishScore',
              textAlign: TextAlign.center, style: _text(21 * s, bold: true)),
          SizedBox(height: 4 * s),
          Text('${_securityOn ? '✓' : '×'} Get a certificate',
              textAlign: TextAlign.center,
              style: _text(21 * s,
                  bold: true,
                  color: _securityOn ? _purple : const Color(0xFFB6AEC4))),
        ]),
      );
}

class _DisabledSlash extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
        Offset(size.width * .04, size.height * .92),
        Offset(size.width * .96, size.height * .08),
        Paint()
          ..color = const Color(0xFFE90041)
          ..strokeWidth = size.width * .1
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _DisabledSlash oldDelegate) => false;
}
